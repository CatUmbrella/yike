import os
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parent
DEFAULT_DATA_DIR = BACKEND_DIR / "data"


def _split_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


DATA_DIR = Path(os.getenv("YIKE_DATA_DIR", DEFAULT_DATA_DIR)).expanduser().resolve()
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    f"sqlite:///{(DATA_DIR / 'yike.db').as_posix()}",
)
AGENT_TRACE_DB_PATH = Path(
    os.getenv("AGENT_TRACE_DB_PATH", DATA_DIR / "yike_agent_traces.db")
).expanduser().resolve()
AGENT_TRACE_ENABLED = os.getenv("AGENT_TRACE_ENABLED", "true").lower() not in {
    "0",
    "false",
    "no",
    "off",
}

CORS_ORIGINS = _split_csv(os.getenv("CORS_ORIGINS", "*"))
API_TOKEN = os.getenv("API_TOKEN", "")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
AI_BASE_URL = os.getenv("AI_BASE_URL", "https://api.deepseek.com")
AI_MODEL = os.getenv("AI_MODEL", "deepseek-v4-flash")
