
"""
Health journey management for Her Health.

Supports multiple saved journeys per patient, one active journey,
journey-specific tracking entries, and journey history.
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from psycopg2.extras import Json
from pydantic import ValidationError

from config.database import get_database_connection
from utils.dependencies import get_current_user
from models.health_journey import (
    ANSWER_MODELS,
    HealthJourneySetupRequest,
    HealthJourneyResponse,
    HealthJourneyEntryRequest,
    HealthJourneyEntryResponse,
)

router = APIRouter(prefix="/health-journey", tags=["Health Journey"])


def _get_patient_id(cursor, user_id: int) -> int:
    cursor.execute(
        "SELECT id FROM patients WHERE user_id = %s",
        (user_id,),
    )
    row = cursor.fetchone()

    if not row:
        raise HTTPException(
            status_code=404,
            detail="No patient profile found. Complete your patient profile first.",
        )

    return row["id"]


def _journey_response(row):
    return {
        "id": row["id"],
        "patient_id": row["patient_id"],
        "journey_type": row["journey_type"],
        "answers": row["answers"],
        "is_active": row["is_active"],
        "created_at": str(row["created_at"]),
        "updated_at": str(row["updated_at"]),
    }


def _entry_response(row):
    return {
        "id": row["id"],
        "journey_id": row["journey_id"],
        "patient_id": row["patient_id"],
        "entry_date": str(row["entry_date"]),
        "pain_level": row["pain_level"],
        "mood": row["mood"],
        "data": row["data"],
        "created_at": str(row["created_at"]),
    }


@router.post("/setup", response_model=HealthJourneyResponse)
def setup_health_journey(
    request: HealthJourneySetupRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update the active journey if it has the same type.
    Otherwise, create a new journey and preserve the previous one.
    """
    model_cls = ANSWER_MODELS[request.journey_type]

    try:
        validated_answers = model_cls(**request.answers)
    except ValidationError as exc:
        raise HTTPException(status_code=422, detail=str(exc))

    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        # Serialize journey changes for this patient.
        cursor.execute(
            "SELECT id FROM patients WHERE id = %s FOR UPDATE",
            (patient_id,),
        )

        cursor.execute(
            """
            SELECT id, patient_id, journey_type, answers,
                   is_active, created_at, updated_at
            FROM health_journeys
            WHERE patient_id = %s AND is_active = TRUE
            FOR UPDATE
            """,
            (patient_id,),
        )
        active = cursor.fetchone()

        answers = validated_answers.dict()

        if active and active["journey_type"] == request.journey_type:
            cursor.execute(
                """
                UPDATE health_journeys
                SET answers = %s,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s AND patient_id = %s
                RETURNING id, patient_id, journey_type, answers,
                          is_active, created_at, updated_at
                """,
                (Json(answers), active["id"], patient_id),
            )
            row = cursor.fetchone()

        else:
            # Deactivate the previous journey before activating the new one.
            cursor.execute(
                """
                UPDATE health_journeys
                SET is_active = FALSE,
                    updated_at = CURRENT_TIMESTAMP
                WHERE patient_id = %s AND is_active = TRUE
                """,
                (patient_id,),
            )

            cursor.execute(
                """
                INSERT INTO health_journeys
                    (patient_id, journey_type, answers, is_active)
                VALUES (%s, %s, %s, TRUE)
                RETURNING id, patient_id, journey_type, answers,
                          is_active, created_at, updated_at
                """,
                (patient_id, request.journey_type, Json(answers)),
            )
            row = cursor.fetchone()

        connection.commit()
        return _journey_response(row)

    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


@router.get("/me", response_model=HealthJourneyResponse)
def get_my_health_journey(
    current_user: dict = Depends(get_current_user),
):
    """Return the caller's active health journey."""
    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        cursor.execute(
            """
            SELECT id, patient_id, journey_type, answers,
                   is_active, created_at, updated_at
            FROM health_journeys
            WHERE patient_id = %s AND is_active = TRUE
            """,
            (patient_id,),
        )

        row = cursor.fetchone()

        if not row:
            raise HTTPException(
                status_code=404,
                detail="No active health journey found.",
            )

        return _journey_response(row)

    finally:
        connection.close()


@router.get("/history", response_model=list[HealthJourneyResponse])
def get_health_journey_history(
    current_user: dict = Depends(get_current_user),
):
    """Return all saved journeys belonging to the caller."""
    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        cursor.execute(
            """
            SELECT id, patient_id, journey_type, answers,
                   is_active, created_at, updated_at
            FROM health_journeys
            WHERE patient_id = %s
            ORDER BY is_active DESC, created_at DESC, id DESC
            """,
            (patient_id,),
        )

        return [_journey_response(row) for row in cursor.fetchall()]

    finally:
        connection.close()


@router.post("/{journey_id}/activate", response_model=HealthJourneyResponse)
def activate_health_journey(
    journey_id: int,
    current_user: dict = Depends(get_current_user),
):
    """Activate one of the caller's previously saved journeys."""
    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        # Lock the patient row so simultaneous switches cannot conflict.
        cursor.execute(
            "SELECT id FROM patients WHERE id = %s FOR UPDATE",
            (patient_id,),
        )

        cursor.execute(
            """
            SELECT id
            FROM health_journeys
            WHERE id = %s AND patient_id = %s
            FOR UPDATE
            """,
            (journey_id, patient_id),
        )

        target = cursor.fetchone()

        if not target:
            raise HTTPException(
                status_code=404,
                detail="Journey not found in your health history.",
            )

        cursor.execute(
            """
            UPDATE health_journeys
            SET is_active = FALSE,
                updated_at = CURRENT_TIMESTAMP
            WHERE patient_id = %s AND is_active = TRUE
            """,
            (patient_id,),
        )

        cursor.execute(
            """
            UPDATE health_journeys
            SET is_active = TRUE,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s AND patient_id = %s
            RETURNING id, patient_id, journey_type, answers,
                      is_active, created_at, updated_at
            """,
            (journey_id, patient_id),
        )

        row = cursor.fetchone()
        connection.commit()

        return _journey_response(row)

    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


@router.post("/entries", response_model=HealthJourneyEntryResponse)
def log_health_journey_entry(
    entry: HealthJourneyEntryRequest,
    current_user: dict = Depends(get_current_user),
):
    """Save a tracking entry against the caller's active journey."""
    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        cursor.execute(
            """
            SELECT id
            FROM health_journeys
            WHERE patient_id = %s AND is_active = TRUE
            """,
            (patient_id,),
        )

        journey = cursor.fetchone()

        if not journey:
            raise HTTPException(
                status_code=400,
                detail="Set up an active health journey before logging entries.",
            )

        cursor.execute(
            """
            INSERT INTO health_journey_entries
                (journey_id, patient_id, entry_date, pain_level, mood, data)
            VALUES (%s, %s, COALESCE(%s, CURRENT_DATE), %s, %s, %s)
            RETURNING id, journey_id, patient_id, entry_date,
                      pain_level, mood, data, created_at
            """,
            (
                journey["id"],
                patient_id,
                entry.entry_date,
                entry.pain_level,
                entry.mood,
                Json(entry.data),
            ),
        )

        row = cursor.fetchone()
        connection.commit()

        return _entry_response(row)

    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


@router.get("/entries", response_model=list[HealthJourneyEntryResponse])
def list_health_journey_entries(
    journey_id: int | None = Query(default=None),
    current_user: dict = Depends(get_current_user),
):
    """
    Return entries for the active journey by default.
    A journey_id may be supplied to view a previous journey's entries.
    """
    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        if journey_id is None:
            cursor.execute(
                """
                SELECT id
                FROM health_journeys
                WHERE patient_id = %s AND is_active = TRUE
                """,
                (patient_id,),
            )
        else:
            cursor.execute(
                """
                SELECT id
                FROM health_journeys
                WHERE id = %s AND patient_id = %s
                """,
                (journey_id, patient_id),
            )

        journey = cursor.fetchone()

        if not journey:
            if journey_id is None:
                return []
            raise HTTPException(
                status_code=404,
                detail="Journey not found in your health history.",
            )

        cursor.execute(
            """
            SELECT id, journey_id, patient_id, entry_date,
                   pain_level, mood, data, created_at
            FROM health_journey_entries
            WHERE patient_id = %s AND journey_id = %s
            ORDER BY entry_date DESC, created_at DESC
            """,
            (patient_id, journey["id"]),
        )

        return [_entry_response(row) for row in cursor.fetchall()]

    finally:
        connection.close()
