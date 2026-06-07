from secrets import compare_digest

from fastapi import Header, HTTPException, status

from config import API_TOKEN


def require_api_token(x_api_key: str | None = Header(default=None, alias="X-API-Key")):
    if not API_TOKEN:
        return
    if not x_api_key or not compare_digest(x_api_key, API_TOKEN):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
        )
