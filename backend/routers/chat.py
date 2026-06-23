from collections.abc import AsyncIterator

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse

from config import Settings, get_settings
from models import ChatAskRequest
from routers.auth import get_current_user
from services.chat_rate_limit import check_rate_limit
from services.ollama_chat import OllamaChatError, stream_chat_response

router = APIRouter(prefix="/chat", tags=["Chat"])


async def _stream_tokens(
    settings: Settings,
    message: str,
) -> AsyncIterator[str]:
    try:
        async for token in stream_chat_response(settings, message):
            yield token
    except OllamaChatError as exc:
        yield f"\n[Error: {exc}]"


@router.post(
    "/ask",
    summary="Preguntar al asistente de la app",
    description=(
        "Envía una pregunta sobre el uso de CleanPool y recibe la respuesta "
        "en streaming (text/plain). Requiere JWT."
    ),
)
async def ask_chat(
    body: ChatAskRequest,
    current_user: dict = Depends(get_current_user),
    settings: Settings = Depends(get_settings),
):
    message = body.message.strip()
    if not message:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="El mensaje no puede estar vacío.",
        )

    if len(message) > settings.chat_max_message_length:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"El mensaje no puede superar {settings.chat_max_message_length} caracteres.",
        )

    user_key = current_user.get("username") or current_user.get("email") or "unknown"
    allowed, retry_after = check_rate_limit(
        user_key,
        max_requests=settings.chat_rate_limit_requests,
        window_seconds=settings.chat_rate_limit_window_seconds,
    )
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Demasiadas preguntas. Intenta de nuevo en {retry_after} segundos.",
            headers={"Retry-After": str(retry_after)},
        )

    return StreamingResponse(
        _stream_tokens(settings, message),
        media_type="text/plain; charset=utf-8",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )
