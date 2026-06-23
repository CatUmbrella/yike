import json
import logging
import time
from dataclasses import dataclass, field
from json import JSONDecodeError
from typing import Any

from openai import OpenAI

from config import AI_BASE_URL, AI_MODEL, OPENAI_API_KEY
from models import ParseResponse
from services.agent_trace import AgentRunTrace, record_agent_run_trace
from services.ai_policy import (
    POLICY_VERSION,
    RETRIEVE_PARSE_POLICY_TOOL,
    retrieve_parse_policy,
)

logger = logging.getLogger("yike.ai_parser")

PROMPT_VERSION = "event_parse_v2"

BASE_PROMPT = """你是任务事件抽取与轻量拆解助手。只处理当前用户输入，返回纯 JSON。

规则：
- 只提取用户刻意要执行、推进、完成或提醒的事情。
- 忽略修饰词、情绪、状态、背景、愿望、节奏描述和空泛规划。
- 日常本来会做的生活动作不输出，如起床、洗漱、吃饭、午休、散步、放松、通勤、去常规地点；除非用户明确要求提醒或专门安排。
- 不按日期、星期、频率、时间段拆事件；时间只用于理解、排序、估时和判断合并粒度，不写进 title/summary。
- 本次返回是完整替换结果，不追加历史结果；无有效任务返回 {"events": []}。
- 一个 event 必须是真实可执行、可单独安排到日程里的事情。
- 能合并的尽量合并，但合并后必须仍是一件真实可执行的事。
- 日程粒度以 3 小时为界限；明显超过 3 小时或主题不同，应拆成多个 events。
- 不逐句拆，不把修饰词、背景描述拆成事件。
- 已取消事项不输出；不确定事项不输出，除非用户要求确认、查询、询问或决定。
- title 只写具体要做的事，删除时间词、频率词和空泛词。
- summary 是 title 的六字左右中文短总结，不含时间、频率、日期。
- steps 允许为空；一步能完成的简单事件不拆步骤。
- 复杂事件才拆 steps；个性化高且缺少背景时，只给通用执行步骤。
- steps 只写具体执行动作，不写心理准备、复盘、检查、打开页面、点击按钮等微动作。
- total_minutes 和 estimated_min 都是分钟整数；steps 非空时 total_minutes 等于 estimated_min 之和。
- 能合理估计时返回 5 到 180；少于 5 按 5；无法合理估计返回 0。
- 不返回 null；无法判断的文本字段用空字符串。
- title、summary、description 必须使用中文。

工具：
- 如果需要确认任务抽取、事件拆分、步骤拆分或耗时规则，可以调用 retrieve_parse_policy 获取规则片段和示例。
- retrieve_parse_policy 只提供只读规则参考，不负责生成事件，也不替你做业务判断。"""

STATIC_POLICY_EXAMPLES = """固定规则示例：
- 输入只描述日常生活动作，且没有明确提醒或专门安排时，返回 {"events": []}。
- 输入明确取消某个事项时，不输出该事项，返回 {"events": []}。
- 输入表达不确定想法但没有要求确认、查询、询问或决定时，返回 {"events": []}。
- 简单任务可以 steps 为空；不好合理估时的任务 total_minutes 可以为 0。"""

OUTPUT_SCHEMA = """只返回以下 JSON 结构，不要 Markdown、解释或额外字段：
{
  "events": [
    {
      "title": "事件完整名称",
      "summary": "六字左右短标题",
      "total_minutes": 50,
      "steps": [
        {
          "step_order": 1,
          "description": "第一步要做什么",
          "estimated_min": 20
        }
      ]
    }
  ]
}"""


def build_prompt() -> str:
    return "\n\n".join(
        [
            f"Prompt version: {PROMPT_VERSION}",
            BASE_PROMPT,
            STATIC_POLICY_EXAMPLES,
            OUTPUT_SCHEMA,
        ]
    )


SYSTEM_PROMPT = build_prompt()

@dataclass
class AgentModelResult:
    content: str
    llm_call_count: int = 1
    policy_ids: list[str] = field(default_factory=list)
    tool_called: bool = False


class EventParseAgent:
    def __init__(self, client: Any, model: str = AI_MODEL):
        self.client = client
        self.model = model

    def parse(self, text: str, input_length: int | None = None) -> dict:
        started = time.perf_counter()
        trace = AgentRunTrace(
            prompt_version=PROMPT_VERSION,
            policy_version=POLICY_VERSION,
            model=self.model,
            input_length=input_length if input_length is not None else len(text or ""),
        )
        if not text or not text.strip():
            trace.elapsed_ms = _elapsed_ms(started)
            record_agent_run_trace(trace)
            return {"events": []}

        try:
            model_result = self._call_llm(build_prompt(), text)
            trace.llm_call_count = model_result.llm_call_count
            trace.policy_tool_called = model_result.tool_called
            trace.policy_ids = model_result.policy_ids

            raw_content = model_result.content
            try:
                payload = json.loads(sanitize_model_json(raw_content))
            except JSONDecodeError as exc:
                trace.repaired = True
                trace.llm_call_count += 1
                raw_content = repair_invalid_json_once(
                    self.client,
                    self.model,
                    raw_content,
                    exc,
                )
                payload = json.loads(sanitize_model_json(raw_content))

            result, validation_warnings = validate_event_contract(payload)
            trace.validation_warnings = validation_warnings
            trace.events_count = len(result.get("events") or [])
            trace.elapsed_ms = _elapsed_ms(started)
            logger.info(
                (
                    "agent.parse.success trace_id=%s prompt_version=%s model=%s "
                    "llm_calls=%s policy_tool_called=%s policy_ids=%s "
                    "repaired=%s events=%s"
                ),
                trace.trace_id,
                PROMPT_VERSION,
                self.model,
                trace.llm_call_count,
                trace.policy_tool_called,
                ",".join(trace.policy_ids),
                trace.repaired,
                trace.events_count,
            )
            record_agent_run_trace(trace)
            return result
        except Exception as exc:
            trace.error_type = type(exc).__name__
            trace.elapsed_ms = _elapsed_ms(started)
            record_agent_run_trace(trace)
            raise

    def _call_llm(self, system_prompt: str, user_text: str) -> AgentModelResult:
        messages: list[dict[str, Any]] = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_text},
        ]

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                tools=[RETRIEVE_PARSE_POLICY_TOOL],
                tool_choice="auto",
                temperature=0.3,
            )
        except Exception as exc:
            if not _looks_like_tool_support_error(exc):
                raise
            logger.warning(
                "agent.policy_tool.unsupported model=%s error_type=%s",
                self.model,
                type(exc).__name__,
            )
            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                temperature=0.3,
            )

        message = response.choices[0].message
        tool_calls = list(getattr(message, "tool_calls", None) or [])
        if not tool_calls:
            content = getattr(message, "content", None) or ""
            return AgentModelResult(content=content.strip(), llm_call_count=1)

        assistant_message = _assistant_message_to_dict(message)
        messages.append(assistant_message)

        policy_ids: list[str] = []
        for tool_call in tool_calls:
            function = getattr(tool_call, "function", None)
            name = getattr(function, "name", "")
            arguments = getattr(function, "arguments", "{}")
            tool_call_id = getattr(tool_call, "id", "")
            if name != "retrieve_parse_policy":
                tool_payload = {
                    "error": f"Unsupported tool: {name}",
                    "policy_version": POLICY_VERSION,
                    "items": [],
                }
            else:
                args = _parse_tool_arguments(arguments)
                tool_payload = retrieve_parse_policy(args.get("policy_keys"))
                policy_ids.extend(item["id"] for item in tool_payload["items"])

            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call_id,
                    "name": name,
                    "content": json.dumps(tool_payload, ensure_ascii=False),
                }
            )

        final_response = self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            temperature=0.3,
        )
        content = final_response.choices[0].message.content or ""
        return AgentModelResult(
            content=content.strip(),
            llm_call_count=2,
            policy_ids=policy_ids,
            tool_called=True,
        )

def sanitize_model_json(content: str) -> str:
    text = (content or "").strip()
    fenced = _extract_fenced_json(text)
    if fenced is not None:
        text = fenced.strip()

    if text.startswith("{") and text.endswith("}"):
        return text

    extracted = _extract_first_json_object(text)
    return extracted if extracted is not None else text


def validate_event_contract(payload: Any) -> tuple[dict, list[str]]:
    warnings: list[str] = []
    if not isinstance(payload, dict):
        warnings.append("payload_not_object")
        payload = {}

    events = payload.get("events")
    if not isinstance(events, list):
        warnings.append("events_not_list")
        events = []

    cleaned_events: list[dict[str, Any]] = []
    for event in events:
        if not isinstance(event, dict):
            warnings.append("event_not_object")
            continue

        title = _text_value(event.get("title"))
        if not title.strip():
            warnings.append("empty_title_event_filtered")
            continue

        steps, step_warnings = _clean_steps(event.get("steps"))
        warnings.extend(step_warnings)
        total_minutes = _non_negative_int(event.get("total_minutes"))
        if steps and total_minutes == 0:
            total_minutes = sum(step["estimated_min"] for step in steps)
            if total_minutes > 0:
                warnings.append("total_minutes_filled_from_steps")

        cleaned_events.append(
            {
                "title": title,
                "summary": _text_value(event.get("summary")),
                "total_minutes": total_minutes,
                "steps": steps,
            }
        )

    response = ParseResponse(events=cleaned_events)
    if hasattr(response, "model_dump"):
        return response.model_dump(), warnings
    return response.dict(), warnings


def repair_invalid_json_once(
    client: Any,
    model: str,
    raw_content: str,
    error: JSONDecodeError,
) -> str:
    response = client.chat.completions.create(
        model=model,
        messages=[
            {
                "role": "system",
                "content": (
                    "你只修复 JSON 格式。不要改写业务含义，不要补充新事件，"
                    "不要添加解释，只返回一个合法 JSON 对象。"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"JSON 解析错误：{error.msg}\n"
                    "请把以下内容修复为合法 JSON，结构必须是 {\"events\": [...]}：\n"
                    f"{raw_content}"
                ),
            },
        ],
        temperature=0,
    )
    content = response.choices[0].message.content or ""
    return content.strip()


def parse_event_text(text: str, input_length: int | None = None) -> dict:
    if not OPENAI_API_KEY:
        raise RuntimeError("OPENAI_API_KEY is not configured")

    client = OpenAI(
        api_key=OPENAI_API_KEY,
        base_url=AI_BASE_URL,
    )
    return EventParseAgent(client).parse(text, input_length=input_length)


def _extract_fenced_json(text: str) -> str | None:
    if not text.startswith("```"):
        return None

    lines = text.splitlines()
    if not lines:
        return None

    if lines[0].lstrip().startswith("```"):
        lines = lines[1:]
    if lines and lines[-1].strip().startswith("```"):
        lines = lines[:-1]
    return "\n".join(lines)


def _extract_first_json_object(text: str) -> str | None:
    start = text.find("{")
    if start < 0:
        return None

    depth = 0
    in_string = False
    escaped = False
    for index in range(start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue

        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start : index + 1]

    return None


def _clean_steps(value: Any) -> tuple[list[dict[str, Any]], list[str]]:
    warnings: list[str] = []
    if not isinstance(value, list):
        if value is not None:
            warnings.append("steps_not_list")
        return [], warnings

    steps: list[dict[str, Any]] = []
    for item in value:
        if not isinstance(item, dict):
            warnings.append("step_not_object")
            continue
        steps.append(
            {
                "step_order": len(steps) + 1,
                "description": _text_value(item.get("description")),
                "estimated_min": _non_negative_int(item.get("estimated_min")),
            }
        )
    return steps, warnings


def _text_value(value: Any) -> str:
    if isinstance(value, str):
        return value.strip()
    return ""


def _non_negative_int(value: Any) -> int:
    if isinstance(value, bool) or value is None:
        return 0
    if isinstance(value, int):
        return max(value, 0)
    if isinstance(value, float):
        return max(int(value), 0)
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return 0
        try:
            return max(int(text), 0)
        except ValueError:
            return 0
    return 0


def _parse_tool_arguments(arguments: Any) -> dict[str, Any]:
    if isinstance(arguments, dict):
        return arguments
    if not isinstance(arguments, str) or not arguments.strip():
        return {}
    try:
        value = json.loads(arguments)
    except JSONDecodeError:
        return {}
    return value if isinstance(value, dict) else {}


def _assistant_message_to_dict(message: Any) -> dict[str, Any]:
    if hasattr(message, "model_dump"):
        data = message.model_dump(exclude_none=True)
    else:
        data = {
            "role": "assistant",
            "content": getattr(message, "content", None),
            "tool_calls": [
                _tool_call_to_dict(tool_call)
                for tool_call in (getattr(message, "tool_calls", None) or [])
            ],
        }
    data.setdefault("role", "assistant")
    return data


def _tool_call_to_dict(tool_call: Any) -> dict[str, Any]:
    if hasattr(tool_call, "model_dump"):
        return tool_call.model_dump(exclude_none=True)

    function = getattr(tool_call, "function", None)
    return {
        "id": getattr(tool_call, "id", ""),
        "type": getattr(tool_call, "type", "function"),
        "function": {
            "name": getattr(function, "name", ""),
            "arguments": getattr(function, "arguments", "{}"),
        },
    }


def _looks_like_tool_support_error(exc: Exception) -> bool:
    text = str(exc).lower()
    return any(
        marker in text
        for marker in [
            "tool",
            "tools",
            "tool_choice",
            "function calling",
            "function_calling",
        ]
    )


def _elapsed_ms(started: float) -> int:
    return int((time.perf_counter() - started) * 1000)
