from functools import lru_cache

from pydantic import MongoDsn, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # MongoDB Atlas
    mongodb_uri: MongoDsn

    # Seguridad
    secret_key: str
    api_key: str  # Clave que usará el ESP8266 en header X-API-KEY
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    # Opcionales
    database_name: str = "cleanpool"
    api_version: str = "v1"
    debug: bool = False

    @field_validator("secret_key")
    @classmethod
    def _secret_key_length(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError("SECRET_KEY debe tener al menos 32 caracteres.")
        return v


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
