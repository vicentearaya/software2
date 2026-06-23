"""Tests del endpoint de chat."""

import os
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

os.environ.setdefault("MONGODB_URI", "mongodb://localhost")
os.environ.setdefault("SECRET_KEY", "supersecretkey_for_testing_min_32_chars!!!")
os.environ.setdefault("API_KEY", "dummy_api_key")

_mock_db = MagicMock()

with patch("pymongo.MongoClient", return_value=MagicMock(**{"__getitem__.return_value": _mock_db})):
    from main import app  # noqa: E402
    from db import get_db
    from routers.auth import get_current_user
    from services.chat_rate_limit import reset_rate_limits


client = TestClient(app)


@pytest.fixture(autouse=True)
def reset_state():
    _mock_db.reset_mock()
    app.dependency_overrides[get_db] = lambda: _mock_db
    reset_rate_limits()
    yield
    app.dependency_overrides.clear()
    reset_rate_limits()


@pytest.fixture
def auth_user():
    user = {"username": "testuser", "email": "test@example.com"}
    app.dependency_overrides[get_current_user] = lambda: user
    return user


async def _fake_stream(_settings, _message):
    yield "Hola "
    yield "mundo"


def test_chat_requires_auth():
    response = client.post("/chat/ask", json={"message": "¿Dónde está el dashboard?"})
    assert response.status_code == 401


def test_chat_rejects_empty_message(auth_user):
    response = client.post("/chat/ask", json={"message": "   "})
    assert response.status_code == 422


@patch("routers.chat.stream_chat_response", side_effect=_fake_stream)
def test_chat_streams_response(mock_stream, auth_user):
    response = client.post("/chat/ask", json={"message": "¿Dónde veo el historial?"})
    assert response.status_code == 200
    assert response.text == "Hola mundo"
    assert response.headers["content-type"].startswith("text/plain")
    mock_stream.assert_called_once()


@patch("routers.chat.stream_chat_response", side_effect=_fake_stream)
def test_chat_rate_limit(mock_stream, auth_user):
    for _ in range(15):
        res = client.post("/chat/ask", json={"message": "pregunta"})
        assert res.status_code == 200

    blocked = client.post("/chat/ask", json={"message": "una más"})
    assert blocked.status_code == 429
    assert "Retry-After" in blocked.headers
