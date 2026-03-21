from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext

from config import get_settings
from db import get_db
from models import Token, UserLogin

router = APIRouter(prefix="/auth", tags=["Auth"])

settings = get_settings()
_db = get_db()

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
_oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def _verify_password(plain: str, hashed: str) -> bool:
    return _pwd_context.verify(plain, hashed)


def _create_access_token(data: dict) -> str:
    payload = data.copy()
    expires = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    payload["exp"] = expires
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


def get_current_user(token: str = Depends(_oauth2_scheme)) -> dict:
    """
    Valida el JWT del header Authorization: Bearer <token>.
    Lista para inyectar en cualquier endpoint con Depends(get_current_user).
    No aplicada a ningún endpoint todavía — eso viene en tareas posteriores.
    """
    credentials_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido o expirado.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token, settings.secret_key, algorithms=[settings.algorithm]
        )
        username: str | None = payload.get("sub")
        if username is None:
            raise credentials_exc
    except JWTError:
        raise credentials_exc

    user = _db["usuarios"].find_one({"username": username}, {"_id": 0})
    if user is None:
        raise credentials_exc
    return user


@router.post(
    "/login",
    response_model=Token,
    summary="Login con usuario y contraseña",
    description="Autentica contra la colección `usuarios`. Retorna JWT firmado con HS256.",
)
def login(credentials: UserLogin) -> Token:
    # Schema esperado: {"username": str, "password": str (bcrypt hash)}
    user = _db["usuarios"].find_one({"username": credentials.username})

    if not user or not _verify_password(credentials.password, user.get("password", "")):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales incorrectas.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = _create_access_token({"sub": credentials.username})
    return Token(access_token=token)
