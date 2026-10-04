"""
routers/health_journey.py

Backs health_setup_screen.dart and journey_questions_screen.dart. Same
style as the other routers -- raw psycopg2 queries via
get_database_connection(), JWT auth via get_current_user().

    from routers.health_journey import router as health_journey_router
    app.include_router(health_journey_router, prefix="/health-journey", tags=["Health Journey"])
"""

from fastapi import APIRouter, Depends, HTTPException
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
    """Every endpoint here acts on the caller's own patient record."""
    cursor.execute("SELECT id FROM patients WHERE user_id = %s", (user_id,))
    row = cursor.fetchone()
    if not row:
        raise HTTPException(
            status_code=404,
            detail="No patient profile found for this account. Complete your patient profile first.",
        )
    return row["id"]


@router.post("/setup", response_model=HealthJourneyResponse)
def setup_health_journey(
    request: HealthJourneySetupRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Create or update the caller's health journey. A patient has exactly one
    CURRENT journey -- calling this again (even with a different
    journey_type) updates the existing row rather than creating a new one.
    """
    model_cls = ANSWER_MODELS[request.journey_type]
    try:
        validated_answers = model_cls(**request.answers)
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=str(e))

    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        cursor.execute(
            """
            INSERT INTO health_journeys (patient_id, journey_type, answers)
            VALUES (%s, %s, %s)
            ON CONFLICT (patient_id)
            DO UPDATE SET
                journey_type = EXCLUDED.journey_type,
                answers = EXCLUDED.answers,
                updated_at = CURRENT_TIMESTAMP
            RETURNING id, patient_id, journey_type, answers, created_at, updated_at
            """,
            (patient_id, request.journey_type, Json(validated_answers.dict())),
        )
        row = cursor.fetchone()
        connection.commit()

        return {
            "id": row["id"],
            "patient_id": row["patient_id"],
            "journey_type": row["journey_type"],
            "answers": row["answers"],
            "created_at": str(row["created_at"]),
            "updated_at": str(row["updated_at"]),
        }
    finally:
        connection.close()


@router.get("/me", response_model=HealthJourneyResponse)
def get_my_health_journey(current_user: dict = Depends(get_current_user)):
    """Fetch the caller's current health journey and onboarding answers."""
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        cursor.execute(
            "SELECT id, patient_id, journey_type, answers, created_at, updated_at "
            "FROM health_journeys WHERE patient_id = %s",
            (patient_id,),
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="No health journey set up yet.")

        return {
            "id": row["id"],
            "patient_id": row["patient_id"],
            "journey_type": row["journey_type"],
            "answers": row["answers"],
            "created_at": str(row["created_at"]),
            "updated_at": str(row["updated_at"]),
        }
    finally:
        connection.close()


@router.post("/entries", response_model=HealthJourneyEntryResponse)
def log_health_journey_entry(
    entry: HealthJourneyEntryRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Log an ongoing entry against the caller's health journey (e.g. today's
    mood, pain level, or symptoms). Not called from any screen yet.
    """
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        cursor.execute("SELECT id FROM health_journeys WHERE patient_id = %s", (patient_id,))
        journey = cursor.fetchone()
        if not journey:
            raise HTTPException(
                status_code=400,
                detail="Complete health journey setup before logging entries.",
            )

        cursor.execute(
            """
            INSERT INTO health_journey_entries
                (journey_id, patient_id, entry_date, pain_level, mood, data)
            VALUES (%s, %s, COALESCE(%s, CURRENT_DATE), %s, %s, %s)
            RETURNING id, journey_id, patient_id, entry_date, pain_level, mood, data, created_at
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
    finally:
        connection.close()


@router.get("/entries", response_model=list[HealthJourneyEntryResponse])
def list_health_journey_entries(current_user: dict = Depends(get_current_user)):
    """List all logged entries for the caller's health journey, most recent first."""
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        cursor.execute(
            """
            SELECT id, journey_id, patient_id, entry_date, pain_level, mood, data, created_at
            FROM health_journey_entries
            WHERE patient_id = %s
            ORDER BY entry_date DESC, created_at DESC
            """,
            (patient_id,),
        )
        rows = cursor.fetchall()

        return [
            {
                "id": r["id"],
                "journey_id": r["journey_id"],
                "patient_id": r["patient_id"],
                "entry_date": str(r["entry_date"]),
                "pain_level": r["pain_level"],
                "mood": r["mood"],
                "data": r["data"],
                "created_at": str(r["created_at"]),
            }
            for r in rows
        ]
    finally:
        connection.close()
