import json
import logging
import sqlite3
import uuid
from contextlib import closing
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

from config import AGENT_TRACE_DB_PATH, AGENT_TRACE_ENABLED

logger = logging.getLogger("yike.agent_trace")


@dataclass
class AgentRunTrace:
    trace_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    endpoint: str = "/api/events/parse"
    prompt_version: str = ""
    policy_version: str = ""
    model: str = ""
    input_length: int = 0
    llm_call_count: int = 0
    policy_tool_called: bool = False
    policy_ids: list[str] = field(default_factory=list)
    repaired: bool = False
    validation_warnings: list[str] = field(default_factory=list)
    events_count: int = 0
    elapsed_ms: int = 0
    error_type: str = ""


def init_agent_trace_db() -> None:
    if not AGENT_TRACE_ENABLED:
        return

    _ensure_parent(AGENT_TRACE_DB_PATH)
    with closing(sqlite3.connect(AGENT_TRACE_DB_PATH)) as conn:
        with conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS agent_run_traces (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    trace_id TEXT NOT NULL,
                    endpoint TEXT NOT NULL DEFAULT '',
                    prompt_version TEXT NOT NULL DEFAULT '',
                    policy_version TEXT NOT NULL DEFAULT '',
                    model TEXT NOT NULL DEFAULT '',
                    input_length INTEGER NOT NULL DEFAULT 0,
                    llm_call_count INTEGER NOT NULL DEFAULT 0,
                    policy_tool_called INTEGER NOT NULL DEFAULT 0,
                    policy_ids_json TEXT NOT NULL DEFAULT '[]',
                    repaired INTEGER NOT NULL DEFAULT 0,
                    validation_warnings_json TEXT NOT NULL DEFAULT '[]',
                    events_count INTEGER NOT NULL DEFAULT 0,
                    elapsed_ms INTEGER NOT NULL DEFAULT 0,
                    error_type TEXT NOT NULL DEFAULT '',
                    created_at TEXT NOT NULL
                )
                """
            )
            conn.execute(
                """
                CREATE INDEX IF NOT EXISTS idx_agent_run_traces_created_at
                ON agent_run_traces(created_at)
                """
            )
            conn.execute(
                """
                CREATE INDEX IF NOT EXISTS idx_agent_run_traces_trace_id
                ON agent_run_traces(trace_id)
                """
            )


def record_agent_run_trace(trace: AgentRunTrace) -> None:
    if not AGENT_TRACE_ENABLED:
        return

    try:
        init_agent_trace_db()
        with closing(sqlite3.connect(AGENT_TRACE_DB_PATH)) as conn:
            with conn:
                conn.execute(
                    """
                    INSERT INTO agent_run_traces (
                        trace_id,
                        endpoint,
                        prompt_version,
                        policy_version,
                        model,
                        input_length,
                        llm_call_count,
                        policy_tool_called,
                        policy_ids_json,
                        repaired,
                        validation_warnings_json,
                        events_count,
                        elapsed_ms,
                        error_type,
                        created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        trace.trace_id,
                        trace.endpoint,
                        trace.prompt_version,
                        trace.policy_version,
                        trace.model,
                        trace.input_length,
                        trace.llm_call_count,
                        1 if trace.policy_tool_called else 0,
                        _json_text(trace.policy_ids),
                        1 if trace.repaired else 0,
                        _json_text(trace.validation_warnings),
                        trace.events_count,
                        trace.elapsed_ms,
                        trace.error_type,
                        datetime.now().isoformat(),
                    ),
                )
    except Exception as exc:
        logger.warning("agent_trace.record_failed error_type=%s", type(exc).__name__)


def _ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def _json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False)
