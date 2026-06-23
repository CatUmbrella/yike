import os
import tempfile
import unittest
from contextlib import closing
from unittest.mock import patch

from models import ParseRequest
from routers import events as events_router
from services import agent_trace
from services.ai_parser import (
    EventParseAgent,
    build_prompt,
    retrieve_parse_policy,
    sanitize_model_json,
    validate_event_contract,
)


class _FakeMessage:
    def __init__(self, content=None, tool_calls=None):
        self.content = content
        self.tool_calls = tool_calls or []


class _FakeFunction:
    def __init__(self, name, arguments):
        self.name = name
        self.arguments = arguments


class _FakeToolCall:
    def __init__(self, tool_call_id, name, arguments):
        self.id = tool_call_id
        self.type = "function"
        self.function = _FakeFunction(name, arguments)


class _FakeChoice:
    def __init__(self, message):
        self.message = message


class _FakeResponse:
    def __init__(self, response):
        if isinstance(response, _FakeMessage):
            message = response
        else:
            message = _FakeMessage(response)
        self.choices = [_FakeChoice(message)]


class _FakeCompletions:
    def __init__(self, responses):
        self.responses = list(responses)
        self.calls = []

    def create(self, **kwargs):
        self.calls.append(kwargs)
        return _FakeResponse(self.responses.pop(0))


class _FakeChat:
    def __init__(self, responses):
        self.completions = _FakeCompletions(responses)


class _FakeClient:
    def __init__(self, responses):
        self.chat = _FakeChat(responses)


class AiParserToolTests(unittest.TestCase):
    def test_build_prompt_keeps_versioned_contract(self):
        prompt = build_prompt()

        self.assertIn("Prompt version: event_parse_v2", prompt)
        self.assertIn("steps 允许为空", prompt)
        self.assertIn("retrieve_parse_policy", prompt)
        self.assertIn('"events"', prompt)

    def test_retrieve_parse_policy_returns_default_and_requested_items(self):
        default_result = retrieve_parse_policy()
        requested_result = retrieve_parse_policy(
            ["simple_task_no_steps", "unknown_duration_zero", "unknown_key"]
        )

        self.assertEqual(default_result["policy_version"], "task_parse_policy_v1")
        self.assertGreater(len(default_result["items"]), 0)
        self.assertEqual(
            [item["id"] for item in requested_result["items"]],
            ["simple_task_no_steps", "unknown_duration_zero"],
        )

    def test_sanitize_model_json_extracts_fenced_json(self):
        content = '```json\n{"events": []}\n```'

        self.assertEqual(sanitize_model_json(content), '{"events": []}')

    def test_sanitize_model_json_extracts_json_from_wrapped_text(self):
        content = '说明文本\n{"events": [{"title": "写报告"}]}\n结束文本'

        self.assertEqual(
            sanitize_model_json(content),
            '{"events": [{"title": "写报告"}]}',
        )

    def test_validate_event_contract_cleans_fields_without_semantic_rewrite(self):
        result, warnings = validate_event_contract(
            {
                "events": [
                    {"title": ""},
                    {
                        "title": " 写报告 ",
                        "summary": None,
                        "total_minutes": -10,
                        "extra": "ignored",
                        "steps": [
                            {
                                "step_order": 9,
                                "description": None,
                                "estimated_min": -1,
                            },
                            {
                                "step_order": 20,
                                "description": " 写正文 ",
                                "estimated_min": "20",
                            },
                        ],
                    },
                ],
                "ignored": True,
            }
        )

        self.assertEqual(len(result["events"]), 1)
        self.assertIn("empty_title_event_filtered", warnings)
        self.assertIn("total_minutes_filled_from_steps", warnings)
        event = result["events"][0]
        self.assertEqual(event["title"], "写报告")
        self.assertEqual(event["summary"], "")
        self.assertEqual(event["total_minutes"], 20)
        self.assertNotIn("extra", event)
        self.assertEqual(
            event["steps"],
            [
                {"step_order": 1, "description": "", "estimated_min": 0},
                {"step_order": 2, "description": "写正文", "estimated_min": 20},
            ],
        )

    def test_validate_event_contract_keeps_zero_total_when_steps_empty(self):
        result, warnings = validate_event_contract(
            {
                "events": [
                    {
                        "title": "整理资料",
                        "summary": "整理资料",
                        "total_minutes": 0,
                        "steps": [],
                    }
                ]
            }
        )

        self.assertEqual(result["events"][0]["total_minutes"], 0)
        self.assertEqual(result["events"][0]["steps"], [])
        self.assertEqual(warnings, [])

    def test_validate_event_contract_does_not_override_positive_total(self):
        result, warnings = validate_event_contract(
            {
                "events": [
                    {
                        "title": "准备汇报",
                        "summary": "准备汇报",
                        "total_minutes": 60,
                        "steps": [
                            {
                                "step_order": 1,
                                "description": "写提纲",
                                "estimated_min": 20,
                            }
                        ],
                    }
                ]
            }
        )

        self.assertEqual(result["events"][0]["total_minutes"], 60)
        self.assertEqual(warnings, [])


class EventParseAgentTests(unittest.TestCase):
    def setUp(self):
        self.trace_patcher = patch("services.ai_parser.record_agent_run_trace")
        self.trace_patcher.start()
        self.addCleanup(self.trace_patcher.stop)

    def test_agent_uses_one_llm_call_for_valid_json(self):
        client = _FakeClient(
            [
                '```json\n{"events": [{"title": "写报告", "summary": "写报告", "total_minutes": 0, "steps": []}]}\n```'
            ]
        )
        agent = EventParseAgent(client)

        result = agent.parse("写报告")

        self.assertEqual(len(client.chat.completions.calls), 1)
        self.assertIn("tools", client.chat.completions.calls[0])
        self.assertEqual(client.chat.completions.calls[0]["tool_choice"], "auto")
        self.assertEqual(result["events"][0]["title"], "写报告")

    def test_agent_executes_policy_tool_call_before_final_json(self):
        client = _FakeClient(
            [
                _FakeMessage(
                    tool_calls=[
                        _FakeToolCall(
                            "call_1",
                            "retrieve_parse_policy",
                            '{"policy_keys": ["simple_task_no_steps", "unknown_duration_zero"]}',
                        )
                    ]
                ),
                '{"events": [{"title": "写报告", "summary": "写报告", "total_minutes": 0, "steps": []}]}',
            ]
        )
        agent = EventParseAgent(client)

        result = agent.parse("写报告")

        self.assertEqual(len(client.chat.completions.calls), 2)
        self.assertIn("tools", client.chat.completions.calls[0])
        self.assertNotIn("tools", client.chat.completions.calls[1])
        messages = client.chat.completions.calls[1]["messages"]
        tool_messages = [message for message in messages if message["role"] == "tool"]
        self.assertEqual(len(tool_messages), 1)
        self.assertIn("simple_task_no_steps", tool_messages[0]["content"])
        self.assertIn("unknown_duration_zero", tool_messages[0]["content"])
        self.assertEqual(result["events"][0]["title"], "写报告")

    def test_agent_repairs_invalid_json_once(self):
        client = _FakeClient(
            [
                "不是合法 JSON",
                '{"events": [{"title": "写报告", "summary": "写报告", "total_minutes": 0, "steps": []}]}',
            ]
        )
        agent = EventParseAgent(client)

        result = agent.parse("写报告")

        self.assertEqual(len(client.chat.completions.calls), 2)
        self.assertEqual(client.chat.completions.calls[1]["temperature"], 0)
        self.assertEqual(result["events"][0]["title"], "写报告")


class AgentTraceTests(unittest.TestCase):
    def test_agent_records_trace_to_dedicated_sqlite_db(self):
        fd, path = tempfile.mkstemp(suffix=".db")
        os.close(fd)
        os.remove(path)

        previous_enabled = agent_trace.AGENT_TRACE_ENABLED
        previous_path = agent_trace.AGENT_TRACE_DB_PATH
        agent_trace.AGENT_TRACE_ENABLED = True
        agent_trace.AGENT_TRACE_DB_PATH = agent_trace.Path(path)
        client = _FakeClient(
            [
                _FakeMessage(
                    tool_calls=[
                        _FakeToolCall(
                            "call_1",
                            "retrieve_parse_policy",
                            '{"policy_keys": ["simple_task_no_steps"]}',
                        )
                    ]
                ),
                '{"events": [{"title": "写报告", "summary": "写报告", "total_minutes": 0, "steps": []}]}',
            ]
        )

        try:
            agent = EventParseAgent(client)
            agent.parse("写报告", input_length=3)

            with closing(agent_trace.sqlite3.connect(path)) as conn:
                rows = conn.execute(
                    """
                    SELECT model, input_length, llm_call_count,
                           policy_tool_called, policy_ids_json, events_count,
                           error_type
                    FROM agent_run_traces
                    """
                ).fetchall()
        finally:
            agent_trace.AGENT_TRACE_ENABLED = previous_enabled
            agent_trace.AGENT_TRACE_DB_PATH = previous_path
            if os.path.exists(path):
                os.remove(path)

        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0][1], 3)
        self.assertEqual(rows[0][2], 2)
        self.assertEqual(rows[0][3], 1)
        self.assertIn("simple_task_no_steps", rows[0][4])
        self.assertEqual(rows[0][5], 1)
        self.assertEqual(rows[0][6], "")


class EventsRouterContractTests(unittest.TestCase):
    def test_parse_endpoint_keeps_original_response_shape(self):
        parsed = {
            "events": [
                {
                    "title": "写报告",
                    "summary": "写报告",
                    "total_minutes": 0,
                    "steps": [],
                }
            ]
        }

        with patch("routers.events.parse_event_text", return_value=parsed):
            response = events_router.parse_event_text_api(ParseRequest(text="写报告"))

        self.assertEqual(response.model_dump(), parsed)


if __name__ == "__main__":
    unittest.main()
