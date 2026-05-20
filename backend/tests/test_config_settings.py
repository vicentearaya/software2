import pytest
from pydantic import ValidationError

from config import Settings


def test_settings_secret_key_min_length():
    with pytest.raises(ValidationError):
        Settings(
            mongodb_uri="mongodb://localhost:27017",
            secret_key="short",
            api_key="test-key",
        )


def test_settings_defaults_aplican():
    cfg = Settings(
        mongodb_uri="mongodb://localhost:27017",
        secret_key="x" * 40,
        api_key="test-key",
    )

    assert cfg.algorithm == "HS256"
    assert cfg.access_token_expire_minutes == 30
    assert cfg.database_name == "cleanpool"
    assert cfg.api_version == "v1"
