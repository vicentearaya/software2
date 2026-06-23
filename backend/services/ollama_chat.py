"""Cliente de streaming hacia Ollama."""

import json
from collections.abc import AsyncIterator

import httpx

from config import Settings
from services.chat_prompt import CHAT_SYSTEM_PROMPT


class OllamaChatError(Exception):
    """Error al comunicarse con Ollama."""


async def stream_chat_response(
    settings: Settings,
    user_message: str,
) -> AsyncIterator[str]:
    """
    Envía el mensaje a Ollama y produce fragmentos de texto de la respuesta.
    """
    url = f"{settings.ollama_base_url.rstrip('/')}/api/chat"
    payload = {
        "model": settings.ollama_model,
        "stream": True,
        "messages": [
            {"role": "system", "content": CHAT_SYSTEM_PROMPT},
            {"role": "user", "content": user_message},
        ],
    }

    timeout = httpx.Timeout(
        connect=10.0,
        read=settings.ollama_timeout_seconds,
        write=10.0,
        pool=10.0,
    )

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            async with client.stream("POST", url, json=payload) as response:
                if response.status_code != 200:
                    body = await response.aread()
                    raise OllamaChatError(
                        f"Ollama respondió HTTP {response.status_code}: {body.decode(errors='replace')[:200]}"
                    )

                async for line in response.aiter_lines():
                    if not line:
                        continue
                    try:
                        chunk = json.loads(line)
                    except json.JSONDecodeError:
                        continue

                    message = chunk.get("message") or {}
                    content = message.get("content")
                    if content:
                        yield content

                    if chunk.get("done"):
                        break
    except httpx.TimeoutException as exc:
        raise OllamaChatError("El asistente tardó demasiado en responder.") from exc
    except httpx.RequestError as exc:
        raise OllamaChatError("No se pudo conectar con el servicio de IA.") from exc
