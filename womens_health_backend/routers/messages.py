"""
routers/messages.py

Real in-app messaging between a patient and the practice's staff. One
thread per patient -- any staff member (role 2/3/4) can view and reply
to any patient's thread, matching how a small practice actually works
rather than a strict one-doctor-per-patient assignment.

Patient-facing endpoints act on the CALLER's own thread (resolved from
their token, same as health_journey.py and chat.py). Staff-facing
endpoints take a patient_id explicitly, since staff need to reach any
patient's thread.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_database_connection
from utils.dependencies import get_current_user

router = APIRouter(prefix="/messages", tags=["Messages"])


class SendMessageRequest(BaseModel):
    message: str


class MessageResponse(BaseModel):
    id: int
    patient_id: int
    sender_role: str
    sender_user_id: int
    message: str
    is_read: bool
    created_at: str


class ThreadSummaryResponse(BaseModel):
    patient_id: int
    first_name: str
    last_name: str
    last_message: str
    last_message_at: str
    unread_count: int


def _get_patient_id(cursor, user_id: int) -> int:
    cursor.execute("SELECT id FROM patients WHERE user_id = %s", (user_id,))
    row = cursor.fetchone()
    if not row:
        raise HTTPException(
            status_code=404,
            detail="No patient profile found for this account. Complete your patient profile first.",
        )
    return row["id"]


def _require_staff(current_user: dict):
    if current_user["role_id"] not in (2, 3, 4):
        raise HTTPException(
            status_code=403,
            detail="Only staff can access this.",
        )


def _row_to_response(r) -> dict:
    return {
        "id": r["id"],
        "patient_id": r["patient_id"],
        "sender_role": r["sender_role"],
        "sender_user_id": r["sender_user_id"],
        "message": r["message"],
        "is_read": r["is_read"],
        "created_at": str(r["created_at"]),
    }


# ===========================================================
# Patient-facing
# ===========================================================

@router.post("/send", response_model=MessageResponse)
def send_message(
    request: SendMessageRequest,
    current_user: dict = Depends(get_current_user),
):
    """Patient sends a message into their own thread."""
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        cursor.execute(
            """
            INSERT INTO messages (patient_id, sender_role, sender_user_id, message)
            VALUES (%s, 'patient', %s, %s)
            RETURNING id, patient_id, sender_role, sender_user_id, message, is_read, created_at
            """,
            (patient_id, current_user["user_id"], request.message),
        )
        row = cursor.fetchone()
        connection.commit()

        return _row_to_response(row)
    finally:
        connection.close()


@router.get("/mine", response_model=list[MessageResponse])
def get_my_thread(current_user: dict = Depends(get_current_user)):
    """
    Patient's own full thread, oldest first. Marks any unread staff
    messages as read, since the patient is looking at them right now.
    """
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        cursor.execute(
            """
            UPDATE messages
            SET is_read = TRUE
            WHERE patient_id = %s AND sender_role = 'staff' AND is_read = FALSE
            """,
            (patient_id,),
        )
        connection.commit()

        cursor.execute(
            """
            SELECT id, patient_id, sender_role, sender_user_id, message, is_read, created_at
            FROM messages
            WHERE patient_id = %s
            ORDER BY created_at ASC, id ASC
            """,
            (patient_id,),
        )
        rows = cursor.fetchall()

        return [_row_to_response(r) for r in rows]
    finally:
        connection.close()


# ===========================================================
# Staff-facing
# ===========================================================

@router.get("/threads", response_model=list[ThreadSummaryResponse])
def list_threads(current_user: dict = Depends(get_current_user)):
    """
    One row per patient who has at least one message, with a preview of
    the last message and how many are unread from the patient's side.
    Staff-only (role 2/3/4).
    """
    _require_staff(current_user)

    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                p.id AS patient_id,
                p.first_name,
                p.last_name,
                latest.message AS last_message,
                latest.created_at AS last_message_at,
                COALESCE(unread.unread_count, 0) AS unread_count
            FROM patients p
            JOIN LATERAL (
                SELECT message, created_at
                FROM messages m
                WHERE m.patient_id = p.id
                ORDER BY m.created_at DESC
                LIMIT 1
            ) latest ON TRUE
            LEFT JOIN (
                SELECT patient_id, COUNT(*) AS unread_count
                FROM messages
                WHERE sender_role = 'patient' AND is_read = FALSE
                GROUP BY patient_id
            ) unread ON unread.patient_id = p.id
            ORDER BY latest.created_at DESC
            """
        )
        rows = cursor.fetchall()

        return [
            {
                "patient_id": r["patient_id"],
                "first_name": r["first_name"],
                "last_name": r["last_name"],
                "last_message": r["last_message"],
                "last_message_at": str(r["last_message_at"]),
                "unread_count": r["unread_count"],
            }
            for r in rows
        ]
    finally:
        connection.close()


@router.get("/patient/{patient_id}", response_model=list[MessageResponse])
def get_patient_thread(
    patient_id: int,
    current_user: dict = Depends(get_current_user),
):
    """
    Staff view of one patient's full thread. Marks any unread patient
    messages as read, since staff is looking at them right now.
    Staff-only (role 2/3/4).
    """
    _require_staff(current_user)

    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            UPDATE messages
            SET is_read = TRUE
            WHERE patient_id = %s AND sender_role = 'patient' AND is_read = FALSE
            """,
            (patient_id,),
        )
        connection.commit()

        cursor.execute(
            """
            SELECT id, patient_id, sender_role, sender_user_id, message, is_read, created_at
            FROM messages
            WHERE patient_id = %s
            ORDER BY created_at ASC, id ASC
            """,
            (patient_id,),
        )
        rows = cursor.fetchall()

        return [_row_to_response(r) for r in rows]
    finally:
        connection.close()


@router.post("/patient/{patient_id}/reply", response_model=MessageResponse)
def reply_to_patient(
    patient_id: int,
    request: SendMessageRequest,
    current_user: dict = Depends(get_current_user),
):
    """Staff sends a reply into a specific patient's thread. Staff-only (role 2/3/4)."""
    _require_staff(current_user)

    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute("SELECT id FROM patients WHERE id = %s", (patient_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Patient not found.")

        cursor.execute(
            """
            INSERT INTO messages (patient_id, sender_role, sender_user_id, message)
            VALUES (%s, 'staff', %s, %s)
            RETURNING id, patient_id, sender_role, sender_user_id, message, is_read, created_at
            """,
            (patient_id, current_user["user_id"], request.message),
        )
        row = cursor.fetchone()
        connection.commit()

        return _row_to_response(row)
    finally:
        connection.close()
