import base64
import json
import os
from datetime import datetime, timedelta
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr

from webauthn import (
    generate_registration_options,
    verify_registration_response,
    generate_authentication_options,
    verify_authentication_response,
)
from webauthn.helpers import options_to_json
from webauthn.helpers.structs import (
    AuthenticatorAttachment,
    AuthenticatorSelectionCriteria,
    PublicKeyCredentialDescriptor,
    ResidentKeyRequirement,
    UserVerificationRequirement,
)

from config.database import get_database_connection
from utils.dependencies import get_current_user
from utils.security import create_access_token


router = APIRouter(
    prefix="/auth/passkeys",
    tags=["Passkeys"],
)


PortalType = Literal["patient", "admin"]


class RegistrationStartRequest(BaseModel):
    portal: PortalType = "patient"


class RegistrationFinishRequest(BaseModel):
    portal: PortalType = "patient"
    credential: dict
    device_name: str | None = None


class AuthenticationStartRequest(BaseModel):
    email: EmailStr
    portal: PortalType = "patient"


class AuthenticationFinishRequest(BaseModel):
    email: EmailStr
    portal: PortalType = "patient"
    credential: dict


def _base64url_encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def _allowed_origins(portal: str) -> list[str]:
    """
    Exact frontend origins allowed to complete WebAuthn ceremonies.

    Local development example:
        WEBAUTHN_PATIENT_ORIGINS=http://localhost:5173
        WEBAUTHN_ADMIN_ORIGINS=http://localhost:5174

    Multiple staging origins may be comma-separated.
    """
    env_name = (
        "WEBAUTHN_PATIENT_ORIGINS"
        if portal == "patient"
        else "WEBAUTHN_ADMIN_ORIGINS"
    )

    configured = [
        value.strip()
        for value in os.getenv(env_name, "").split(",")
        if value.strip()
    ]

    if configured:
        return configured

    # Development fallback only.
    if portal == "patient":
        return ["http://localhost:5173"]

    return ["http://localhost:5174"]


def _rp_id(portal: str) -> str:
    env_name = (
        "WEBAUTHN_PATIENT_RP_ID"
        if portal == "patient"
        else "WEBAUTHN_ADMIN_RP_ID"
    )

    return os.getenv(env_name, "localhost").strip()


def _validate_portal_role(role_id: int, portal: str):
    if portal == "patient" and role_id != 1:
        raise HTTPException(
            status_code=403,
            detail="This account is not a patient account.",
        )

    if portal == "admin" and role_id not in (2, 3, 4):
        raise HTTPException(
            status_code=403,
            detail="This account is not authorised for the staff portal.",
        )


def _get_active_user_by_email(cursor, email: str):
    cursor.execute(
        """
        SELECT id, role_id, email, is_active, is_verified, is_phone_verified
        FROM users
        WHERE LOWER(email) = LOWER(%s)
        """,
        (email,),
    )

    user = cursor.fetchone()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="No account found for this email address.",
        )

    if not user["is_active"]:
        raise HTTPException(
            status_code=403,
            detail="This account is inactive.",
        )

    if user["role_id"] == 1:
        verified = user["is_verified"] or user["is_phone_verified"]

        if not verified:
            raise HTTPException(
                status_code=403,
                detail="Please verify your email or phone number first.",
            )

    return user


def _save_challenge(
    cursor,
    user_id: int,
    purpose: str,
    challenge: bytes,
):
    cursor.execute(
        """
        INSERT INTO passkey_challenges
            (user_id, purpose, challenge, expires_at)
        VALUES
            (%s, %s, %s, %s)
        ON CONFLICT (user_id, purpose)
        DO UPDATE SET
            challenge = EXCLUDED.challenge,
            expires_at = EXCLUDED.expires_at,
            created_at = CURRENT_TIMESTAMP
        """,
        (
            user_id,
            purpose,
            challenge,
            datetime.utcnow() + timedelta(minutes=5),
        ),
    )


def _get_challenge(cursor, user_id: int, purpose: str) -> bytes:
    cursor.execute(
        """
        SELECT challenge, expires_at
        FROM passkey_challenges
        WHERE user_id = %s
          AND purpose = %s
        """,
        (user_id, purpose),
    )

    row = cursor.fetchone()

    if not row:
        raise HTTPException(
            status_code=400,
            detail="Device authentication session not found. Please try again.",
        )

    if row["expires_at"] < datetime.utcnow():
        cursor.execute(
            """
            DELETE FROM passkey_challenges
            WHERE user_id = %s AND purpose = %s
            """,
            (user_id, purpose),
        )

        raise HTTPException(
            status_code=400,
            detail="Device authentication session expired. Please try again.",
        )

    return bytes(row["challenge"])


def _delete_challenge(cursor, user_id: int, purpose: str):
    cursor.execute(
        """
        DELETE FROM passkey_challenges
        WHERE user_id = %s
          AND purpose = %s
        """,
        (user_id, purpose),
    )


@router.post("/register/options")
def begin_passkey_registration(
    request: RegistrationStartRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Starts device-unlock registration.

    The user must already be logged in normally before they can enable
    Face ID, Touch ID, fingerprint or device PIN.
    """
    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT id, role_id, email, is_active
            FROM users
            WHERE id = %s
            """,
            (current_user["user_id"],),
        )

        user = cursor.fetchone()

        if not user or not user["is_active"]:
            raise HTTPException(
                status_code=403,
                detail="This account is not available.",
            )

        _validate_portal_role(user["role_id"], request.portal)

        cursor.execute(
            """
            SELECT credential_id
            FROM passkey_credentials
            WHERE user_id = %s
            """,
            (user["id"],),
        )

        existing_credentials = cursor.fetchall()

        exclude_credentials = [
            PublicKeyCredentialDescriptor(
                id=bytes(row["credential_id"])
            )
            for row in existing_credentials
        ]

        options = generate_registration_options(
            rp_id=_rp_id(request.portal),
            rp_name="Her Health",
            user_id=str(user["id"]).encode("utf-8"),
            user_name=user["email"],
            user_display_name=user["email"],
            authenticator_selection=AuthenticatorSelectionCriteria(
                authenticator_attachment=AuthenticatorAttachment.PLATFORM,
                resident_key=ResidentKeyRequirement.PREFERRED,
                require_resident_key=False,
                user_verification=UserVerificationRequirement.REQUIRED,
            ),
            exclude_credentials=exclude_credentials,
        )

        _save_challenge(
            cursor,
            user["id"],
            "registration",
            options.challenge,
        )

        connection.commit()

        return json.loads(options_to_json(options))

    finally:
        connection.close()


@router.post("/register/verify")
def finish_passkey_registration(
    request: RegistrationFinishRequest,
    current_user: dict = Depends(get_current_user),
):
    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT id, role_id, email, is_active
            FROM users
            WHERE id = %s
            """,
            (current_user["user_id"],),
        )

        user = cursor.fetchone()

        if not user or not user["is_active"]:
            raise HTTPException(
                status_code=403,
                detail="This account is not available.",
            )

        _validate_portal_role(user["role_id"], request.portal)

        expected_challenge = _get_challenge(
            cursor,
            user["id"],
            "registration",
        )

        try:
            verification = verify_registration_response(
                credential=request.credential,
                expected_challenge=expected_challenge,
                expected_rp_id=_rp_id(request.portal),
                expected_origin=_allowed_origins(request.portal),
                require_user_verification=True,
            )
        except Exception:
            raise HTTPException(
                status_code=400,
                detail="Device authentication could not be verified.",
            )

        cursor.execute(
            """
            INSERT INTO passkey_credentials
                (
                    user_id,
                    credential_id,
                    public_key,
                    sign_count,
                    device_name
                )
            VALUES
                (%s, %s, %s, %s, %s)
            ON CONFLICT (credential_id)
            DO UPDATE SET
                public_key = EXCLUDED.public_key,
                sign_count = EXCLUDED.sign_count,
                device_name = EXCLUDED.device_name
            """,
            (
                user["id"],
                verification.credential_id,
                verification.credential_public_key,
                verification.sign_count,
                request.device_name,
            ),
        )

        _delete_challenge(
            cursor,
            user["id"],
            "registration",
        )

        connection.commit()

        return {
            "message": "Device unlock enabled successfully.",
            "credential_id": _base64url_encode(
                verification.credential_id
            ),
        }

    finally:
        connection.close()


@router.post("/login/options")
def begin_passkey_login(
    request: AuthenticationStartRequest,
):
    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)

        user = _get_active_user_by_email(
            cursor,
            request.email,
        )

        _validate_portal_role(
            user["role_id"],
            request.portal,
        )

        cursor.execute(
            """
            SELECT credential_id
            FROM passkey_credentials
            WHERE user_id = %s
            ORDER BY created_at DESC
            """,
            (user["id"],),
        )

        credentials = cursor.fetchall()

        if not credentials:
            raise HTTPException(
                status_code=404,
                detail="Device unlock has not been enabled for this account.",
            )

        allowed_credentials = [
            PublicKeyCredentialDescriptor(
                id=bytes(row["credential_id"])
            )
            for row in credentials
        ]

        options = generate_authentication_options(
            rp_id=_rp_id(request.portal),
            allow_credentials=allowed_credentials,
            user_verification=UserVerificationRequirement.REQUIRED,
        )

        _save_challenge(
            cursor,
            user["id"],
            "authentication",
            options.challenge,
        )

        connection.commit()

        return json.loads(options_to_json(options))

    finally:
        connection.close()


@router.post("/login/verify")
def finish_passkey_login(
    request: AuthenticationFinishRequest,
):
    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)

        user = _get_active_user_by_email(
            cursor,
            request.email,
        )

        _validate_portal_role(
            user["role_id"],
            request.portal,
        )

        expected_challenge = _get_challenge(
            cursor,
            user["id"],
            "authentication",
        )

        raw_id = request.credential.get("rawId")

        if not raw_id:
            raise HTTPException(
                status_code=400,
                detail="Device credential is missing.",
            )

        try:
            padding = "=" * (-len(raw_id) % 4)

            credential_id = base64.urlsafe_b64decode(
                raw_id + padding
            )
        except Exception:
            raise HTTPException(
                status_code=400,
                detail="Device credential is invalid.",
            )

        cursor.execute(
            """
            SELECT
                id,
                public_key,
                sign_count
            FROM passkey_credentials
            WHERE user_id = %s
              AND credential_id = %s
            """,
            (
                user["id"],
                credential_id,
            ),
        )

        saved_credential = cursor.fetchone()

        if not saved_credential:
            raise HTTPException(
                status_code=401,
                detail="This device is not registered for the account.",
            )

        try:
            verification = verify_authentication_response(
                credential=request.credential,
                expected_challenge=expected_challenge,
                expected_rp_id=_rp_id(request.portal),
                expected_origin=_allowed_origins(request.portal),
                credential_public_key=bytes(
                    saved_credential["public_key"]
                ),
                credential_current_sign_count=
                    saved_credential["sign_count"],
                require_user_verification=True,
            )
        except Exception:
            raise HTTPException(
                status_code=401,
                detail="Device authentication failed.",
            )

        cursor.execute(
            """
            UPDATE passkey_credentials
            SET
                sign_count = %s,
                last_used_at = CURRENT_TIMESTAMP
            WHERE id = %s
            """,
            (
                verification.new_sign_count,
                saved_credential["id"],
            ),
        )

        _delete_challenge(
            cursor,
            user["id"],
            "authentication",
        )

        token = create_access_token(
            user["id"],
            user["role_id"],
        )

        connection.commit()

        return {
            "message": "Device unlock successful.",
            "access_token": token,
            "token_type": "bearer",
        }

    finally:
        connection.close()