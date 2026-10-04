import bcrypt
import jwt
import os
from datetime import datetime, timedelta

def hash_password(password: str) -> str:
    password_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt()
    hashed_password = bcrypt.hashpw(password_bytes, salt)

    return hashed_password.decode("utf-8")

def verify_password(password: str, hashed_password: str) -> bool:
    password_bytes = password.encode("utf-8")
    hashed_password_bytes = hashed_password.encode("utf-8")

    return bcrypt.checkpw(password_bytes, hashed_password_bytes)

def create_access_token(user_id: int, role_id: int):
    secret_key = os.getenv("JWT_SECRET")
    expire_minutes = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

    payload = {
        "user_id": user_id,
        "role_id": role_id,
        "exp": datetime.utcnow() + timedelta(minutes=expire_minutes)
    }

    return jwt.encode(payload, secret_key, algorithm="HS256")

def decode_access_token(token: str):
    secret_key = os.getenv("JWT_SECRET")

    try:
        payload = jwt.decode(
            token,
            secret_key,
            algorithms=["HS256"]
        )

        return payload

    except jwt.ExpiredSignatureError:
        return None

    except jwt.InvalidTokenError:
        return None