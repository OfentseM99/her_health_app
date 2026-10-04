import os
import random
import time
from datetime import date, datetime, timedelta
from typing import List, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from psycopg2.extras import Json
from config.database import get_database_connection
from utils.security import hash_password, verify_password, create_access_token
from utils.dependencies import get_current_user


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


class RegisterRequest(BaseModel):
    email: EmailStr
    phone: str
    password: str

    # Optional so existing callers keep working. When full_name is sent, a
    # patient profile is created together with the account -- the health
    # journey endpoints need that profile to exist.
    full_name: Optional[str] = None
    date_of_birth: Optional[date] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None

    # Also optional, also only stored if a profile is being created
    # (i.e. full_name was sent). "None" selected on the frontend is a
    # real answer ("no allergies") and is sent through as the literal
    # string "None" in the list, same as any other selection -- the
    # backend doesn't treat it specially.
    address: Optional[str] = None
    city: Optional[str] = None
    blood_type: Optional[str] = None
    allergies: Optional[List[str]] = None
    medical_conditions: Optional[List[str]] = None
    current_medications: Optional[List[str]] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class VerifyRequest(BaseModel):
    email: EmailStr
    method: Literal["email", "phone"]
    code: str


class ResendCodesRequest(BaseModel):
    email: EmailStr


class RequestPasswordResetRequest(BaseModel):
    email: EmailStr
    method: Literal["email", "phone"]


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str


def _mask_phone(phone) -> str:
    """Shows only the last 4 digits, e.g. '******1961'."""
    if not phone:
        return ""
    if len(phone) <= 4:
        return phone
    return "*" * (len(phone) - 4) + phone[-4:]


def _split_name(full_name: str):
    """'Ada Lovelace King' -> ('Ada', 'Lovelace King'); 'Ada' -> ('Ada', '')."""
    parts = full_name.strip().split(None, 1)
    first = parts[0] if parts else ""
    last = parts[1] if len(parts) > 1 else ""
    return first, last


# ===========================================================
# Security settings
# ===========================================================

def _dev_mode() -> bool:
    """
    DEV_MODE=true in .env makes verification and reset codes come back in
    API responses, so the on-screen dev banner works without a real
    email/SMS provider. Anything else -- including leaving it out -- is
    the safe default: codes are never returned.

    Read on every call (not at import) so .env changes apply on restart
    without depending on import order.
    """
    return os.getenv("DEV_MODE", "false").strip().lower() == "true"


# Attempt limiting. Kept in memory: it resets when the server restarts
# and only covers a single server process -- fine for this project, but a
# multi-server deployment would need a shared store (e.g. Redis).
_MAX_ATTEMPTS = 5
_LOCKOUT_SECONDS = 15 * 60
_failed_attempts: dict = {}


def _too_many_attempts(key: str) -> bool:
    entry = _failed_attempts.get(key)
    if not entry:
        return False
    count, first_failure = entry
    if time.time() - first_failure > _LOCKOUT_SECONDS:
        _failed_attempts.pop(key, None)
        return False
    return count >= _MAX_ATTEMPTS


def _record_failure(key: str) -> int:
    now = time.time()
    count, first_failure = _failed_attempts.get(key, (0, now))
    if now - first_failure > _LOCKOUT_SECONDS:
        count, first_failure = 0, now
    _failed_attempts[key] = (count + 1, first_failure)
    return count + 1


def _clear_failures(key: str):
    _failed_attempts.pop(key, None)


def _generate_code() -> str:
    """6-digit numeric code, as a zero-padded string (e.g. '004821')."""
    return f"{random.randint(0, 999999):06d}"


@router.post("/register")
def register_user(user: RegisterRequest):

    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT id FROM users WHERE email = %s",
            (user.email,)
        )

        existing_user = cursor.fetchone()

        if existing_user:
            raise HTTPException(
                status_code=400,
                detail="An account with this email already exists."
            )

        password_hash = hash_password(user.password)

        email_code = _generate_code()
        phone_code = _generate_code()
        expires_at = datetime.utcnow() + timedelta(minutes=10)

        cursor.execute(
            """
            INSERT INTO users
            (role_id, email, phone, password_hash, is_verified, is_active,
             email_code, email_code_expires_at,
             phone_code, phone_code_expires_at, is_phone_verified)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (
                1,
                user.email,
                user.phone,
                password_hash,
                False,
                True,
                email_code,
                expires_at,
                phone_code,
                expires_at,
                False,
            )
        )

        # RETURNING is PostgreSQL syntax (MySQL would use cursor.lastrowid).
        new_user_id = cursor.fetchone()["id"]

        if user.full_name and user.full_name.strip():
            first_name, last_name = _split_name(user.full_name)
            cursor.execute(
                """
                INSERT INTO patients
                (user_id, first_name, last_name, phone, date_of_birth,
                 emergency_contact_name, emergency_contact_phone,
                 address, city, blood_type,
                 allergies, medical_conditions, current_medications)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    new_user_id,
                    first_name,
                    last_name,
                    user.phone,
                    user.date_of_birth,
                    user.emergency_contact_name,
                    user.emergency_contact_phone,
                    user.address,
                    user.city,
                    user.blood_type,
                    Json(user.allergies) if user.allergies is not None else None,
                    Json(user.medical_conditions) if user.medical_conditions is not None else None,
                    Json(user.current_medications) if user.current_medications is not None else None,
                )
            )

        # One commit for both inserts: the account and its profile are
        # created together or not at all.
        connection.commit()

        _clear_failures(f"verify:{user.email.lower()}")

        response = {
            "message": "Account created successfully. Verification codes generated.",
        }
        # SIMULATED SENDING: with no email/SMS provider connected, codes
        # are only returned in DEV_MODE so the on-screen banner can show
        # them. Never returned otherwise.
        if _dev_mode():
            response["email_code"] = email_code
            response["phone_code"] = phone_code
        return response

    finally:
        cursor.close()
        connection.close()


@router.post("/verify")
def verify_user(request: VerifyRequest):
    """
    Verifies the account using EITHER email or phone -- whichever the
    user chooses. Only one successful verification is required; the
    other channel's code is simply left unused.
    """

    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT id, email_code, email_code_expires_at,
                   phone_code, phone_code_expires_at,
                   is_verified, is_phone_verified
            FROM users
            WHERE email = %s
            """,
            (request.email,)
        )

        existing_user = cursor.fetchone()

        if not existing_user:
            raise HTTPException(
                status_code=404,
                detail="No account found for this email."
            )

        now = datetime.utcnow()

        if request.method == "email":
            stored_code = existing_user["email_code"]
            expires_at = existing_user["email_code_expires_at"]
        else:
            stored_code = existing_user["phone_code"]
            expires_at = existing_user["phone_code_expires_at"]

        if expires_at is None or now > expires_at:
            raise HTTPException(
                status_code=400,
                detail="This verification code has expired. Please request a new one."
            )

        verify_key = f"verify:{request.email.lower()}"

        if request.code != stored_code:
            if _record_failure(verify_key) >= _MAX_ATTEMPTS:
                # Too many wrong guesses: destroy both codes so they can't
                # be brute-forced. A new code must be requested.
                cursor.execute(
                    """
                    UPDATE users
                    SET email_code = NULL, email_code_expires_at = NULL,
                        phone_code = NULL, phone_code_expires_at = NULL
                    WHERE id = %s
                    """,
                    (existing_user["id"],)
                )
                connection.commit()
                _clear_failures(verify_key)
                raise HTTPException(
                    status_code=429,
                    detail="Too many incorrect codes. Please request a new code."
                )
            raise HTTPException(
                status_code=400,
                detail="Incorrect verification code."
            )

        _clear_failures(verify_key)

        if request.method == "email":
            cursor.execute(
                """
                UPDATE users
                SET is_verified = TRUE,
                    email_code = NULL,
                    email_code_expires_at = NULL
                WHERE id = %s
                """,
                (existing_user["id"],)
            )
        else:
            cursor.execute(
                """
                UPDATE users
                SET is_phone_verified = TRUE,
                    phone_code = NULL,
                    phone_code_expires_at = NULL
                WHERE id = %s
                """,
                (existing_user["id"],)
            )

        connection.commit()

        return {
            "message": f"Account verified successfully via {request.method}."
        }

    finally:
        cursor.close()
        connection.close()


@router.post("/resend-codes")
def resend_codes(request: ResendCodesRequest):

    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT id, phone FROM users WHERE email = %s",
            (request.email,)
        )

        existing_user = cursor.fetchone()

        if not existing_user:
            raise HTTPException(
                status_code=404,
                detail="No account found for this email."
            )

        email_code = _generate_code()
        phone_code = _generate_code()
        expires_at = datetime.utcnow() + timedelta(minutes=10)

        cursor.execute(
            """
            UPDATE users
            SET email_code = %s,
                email_code_expires_at = %s,
                phone_code = %s,
                phone_code_expires_at = %s
            WHERE id = %s
            """,
            (email_code, expires_at, phone_code, expires_at, existing_user["id"])
        )

        connection.commit()

        _clear_failures(f"verify:{request.email.lower()}")

        response = {
            "message": "New verification codes generated.",
            "phone": _mask_phone(existing_user["phone"]),
        }
        # SIMULATED SENDING -- see note in register_user above.
        if _dev_mode():
            response["email_code"] = email_code
            response["phone_code"] = phone_code
        return response

    finally:
        cursor.close()
        connection.close()


@router.post("/login")
def login_user(user: LoginRequest):

    login_key = f"login:{user.email.lower()}"

    if _too_many_attempts(login_key):
        raise HTTPException(
            status_code=429,
            detail="Too many failed login attempts. Please try again in 15 minutes."
        )

    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT id, role_id, email, password_hash, is_active,
                   is_verified, is_phone_verified
            FROM users
            WHERE email = %s
            """,
            (user.email,)
        )

        existing_user = cursor.fetchone()

        if not existing_user:
            raise HTTPException(
                status_code=401,
                detail="Invalid email or password."
            )

        if not existing_user["is_active"]:
            raise HTTPException(
                status_code=403,
                detail="This account is inactive."
            )

        password_correct = verify_password(
            user.password,
            existing_user["password_hash"]
        )

        if not password_correct:
            _record_failure(login_key)
            raise HTTPException(
                status_code=401,
                detail="Invalid email or password."
            )

        # Patients (role 1) must have verified at least one of email or
        # phone -- their choice. Staff accounts (roles 2, 3, 4) are created
        # directly by the admin rather than through registration, so they
        # skip this check.
        if existing_user["role_id"] == 1:
            verified = (
                existing_user["is_verified"]
                or existing_user["is_phone_verified"]
            )
            if not verified:
                raise HTTPException(
                    status_code=403,
                    detail="Please verify your email or phone number before logging in."
                )

        _clear_failures(login_key)

        token = create_access_token(
            existing_user["id"],
            existing_user["role_id"]
        )

        return {
            "message": "Login successful.",
            "access_token": token,
            "token_type": "bearer"
        }

    finally:
        cursor.close()
        connection.close()


@router.post("/request-password-reset")
def request_password_reset(request: RequestPasswordResetRequest):
    """
    Generates a single reset code and stores it for whichever channel
    the user picked (email or phone) -- only one code, unlike
    registration verification, since the user is choosing one delivery
    method up front rather than getting both.
    """
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            "SELECT id, phone FROM users WHERE email = %s",
            (request.email,)
        )
        existing_user = cursor.fetchone()

        if not existing_user:
            if _dev_mode():
                raise HTTPException(
                    status_code=404,
                    detail="No account found for this email."
                )
            # Outside dev mode, don't reveal whether an account exists:
            # give the same answer either way.
            return {
                "message": "If an account exists for this email, a reset code has been sent.",
                "phone": "",
            }

        reset_code = _generate_code()
        expires_at = datetime.utcnow() + timedelta(minutes=10)

        cursor.execute(
            """
            UPDATE users
            SET reset_code = %s,
                reset_code_expires_at = %s
            WHERE id = %s
            """,
            (reset_code, expires_at, existing_user["id"])
        )

        connection.commit()

        _clear_failures(f"reset:{request.email.lower()}")

        response = {
            "message": "If an account exists for this email, a reset code has been sent.",
            # Masked: this endpoint needs no login, so it must never hand
            # out someone's full phone number.
            "phone": _mask_phone(existing_user["phone"]),
        }
        # SIMULATED SENDING -- only in DEV_MODE, see register_user.
        if _dev_mode():
            response["reset_code"] = reset_code
        return response

    finally:
        cursor.close()
        connection.close()


@router.post("/reset-password")
def reset_password(request: ResetPasswordRequest):
    """Checks the reset code and, if valid, sets the new password."""
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            "SELECT id, reset_code, reset_code_expires_at FROM users WHERE email = %s",
            (request.email,)
        )
        existing_user = cursor.fetchone()

        if not existing_user:
            raise HTTPException(
                status_code=404,
                detail="No account found for this email."
            )

        expires_at = existing_user["reset_code_expires_at"]

        if expires_at is None or datetime.utcnow() > expires_at:
            raise HTTPException(
                status_code=400,
                detail="This reset code has expired. Please request a new one."
            )

        reset_key = f"reset:{request.email.lower()}"

        if request.code != existing_user["reset_code"]:
            if _record_failure(reset_key) >= _MAX_ATTEMPTS:
                cursor.execute(
                    """
                    UPDATE users
                    SET reset_code = NULL, reset_code_expires_at = NULL
                    WHERE id = %s
                    """,
                    (existing_user["id"],)
                )
                connection.commit()
                _clear_failures(reset_key)
                raise HTTPException(
                    status_code=429,
                    detail="Too many incorrect codes. Please request a new reset code."
                )
            raise HTTPException(
                status_code=400,
                detail="Incorrect reset code."
            )

        _clear_failures(reset_key)

        new_password_hash = hash_password(request.new_password)

        cursor.execute(
            """
            UPDATE users
            SET password_hash = %s,
                reset_code = NULL,
                reset_code_expires_at = NULL
            WHERE id = %s
            """,
            (new_password_hash, existing_user["id"])
        )

        connection.commit()

        return {
            "message": "Password reset successfully. You can now log in with your new password."
        }

    finally:
        cursor.close()
        connection.close()


# ===========================================================
# Current user's own profile (Health Profile screen)
# ===========================================================

class UpdateProfileRequest(BaseModel):
    # Every field optional: only the fields actually sent are updated.
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    date_of_birth: Optional[date] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    blood_type: Optional[str] = None
    allergies: Optional[List[str]] = None
    medical_conditions: Optional[List[str]] = None
    current_medications: Optional[List[str]] = None


# Whitelist of patient columns that can be edited. Column names in the
# UPDATE below come only from this list, never from the request, so the
# dynamic SQL can't be injected into.
_PROFILE_COLUMNS = [
    "first_name", "last_name", "date_of_birth",
    "emergency_contact_name", "emergency_contact_phone",
    "address", "city", "blood_type",
    "allergies", "medical_conditions", "current_medications",
]
_JSON_COLUMNS = {"allergies", "medical_conditions", "current_medications"}


@router.get("/me")
def get_me(current_user: dict = Depends(get_current_user)):
    """The logged-in user's account details plus their patient profile
    (profile is null for accounts without one, e.g. staff)."""
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT email, phone, role_id FROM users WHERE id = %s",
            (current_user["user_id"],)
        )
        user = cursor.fetchone()

        if not user:
            raise HTTPException(status_code=404, detail="Account not found.")

        cursor.execute(
            """
            SELECT first_name, last_name, date_of_birth,
                   emergency_contact_name, emergency_contact_phone,
                   address, city, blood_type,
                   allergies, medical_conditions, current_medications
            FROM patients
            WHERE user_id = %s
            """,
            (current_user["user_id"],)
        )
        row = cursor.fetchone()

        profile = None
        if row:
            profile = dict(row)
            if profile.get("date_of_birth") is not None:
                profile["date_of_birth"] = str(profile["date_of_birth"])

        return {
            "email": user["email"],
            "phone": user["phone"],
            "role_id": user["role_id"],
            "profile": profile,
        }

    finally:
        cursor.close()
        connection.close()


@router.put("/me/profile")
def update_my_profile(
    request: UpdateProfileRequest,
    current_user: dict = Depends(get_current_user),
):
    """Updates only the profile fields included in the request."""
    updates = request.dict(exclude_unset=True)

    if not updates:
        raise HTTPException(status_code=400, detail="Nothing to update.")

    if "first_name" in updates and not (updates["first_name"] or "").strip():
        raise HTTPException(status_code=400, detail="First name can't be empty.")

    # last_name is NOT NULL in the table; store a blank rather than NULL.
    if "last_name" in updates and updates["last_name"] is None:
        updates["last_name"] = ""

    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT id FROM patients WHERE user_id = %s",
            (current_user["user_id"],)
        )
        patient = cursor.fetchone()

        if not patient:
            raise HTTPException(
                status_code=404,
                detail="No patient profile found for this account."
            )

        set_parts = []
        values = []
        for column in _PROFILE_COLUMNS:
            if column in updates:
                value = updates[column]
                if column in _JSON_COLUMNS and value is not None:
                    value = Json(value)
                set_parts.append(f"{column} = %s")
                values.append(value)

        values.append(patient["id"])

        cursor.execute(
            f"UPDATE patients SET {', '.join(set_parts)} WHERE id = %s",
            tuple(values)
        )
        connection.commit()

        return {"message": "Profile updated."}

    finally:
        cursor.close()
        connection.close()
