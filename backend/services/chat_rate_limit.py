"""Rate limiter en memoria por usuario para el chat."""

from collections import defaultdict, deque
from datetime import datetime, timedelta, timezone
from threading import Lock

_lock = Lock()
_windows: dict[str, deque[datetime]] = defaultdict(deque)


def check_rate_limit(
    user_key: str,
    *,
    max_requests: int,
    window_seconds: int,
) -> tuple[bool, int]:
    """
    Devuelve (permitido, segundos_para_reintentar).
  """
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(seconds=window_seconds)

    with _lock:
        window = _windows[user_key]
        while window and window[0] < cutoff:
            window.popleft()

        if len(window) >= max_requests:
            retry_after = int((window[0] + timedelta(seconds=window_seconds) - now).total_seconds())
            return False, max(retry_after, 1)

        window.append(now)
        return True, 0


def reset_rate_limits() -> None:
    """Solo para tests."""
    with _lock:
        _windows.clear()
