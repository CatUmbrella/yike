from secrets import compare_digest

from fastapi import Header, HTTPException, status

from config import API_TOKEN


def require_api_token(x_api_key: str | None = Header(default=None, alias="X-API-Key")):
    if not API_TOKEN:
        return
    expected = API_TOKEN.strip()
    provided = x_api_key.strip() if x_api_key else ""
    if not provided or not compare_digest(
        provided.encode("utf-8"),
        expected.encode("utf-8"),
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
        )
