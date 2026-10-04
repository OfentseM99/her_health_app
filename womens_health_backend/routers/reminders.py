"""
routers/reminders.py

A patient's own reminders. Every endpoint acts only on the caller's
reminders (resolved from their token), and updates/deletes check
ownership in the same query, so one patient can never touch another's.
"""

from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_database_connection
from utils.dependencies import get_current_user

router = APIRouter(prefix="/reminders", tags=["Reminders"])


class ReminderRequest(BaseModel):
    title: str
    notes: Optional[str] = None
    remind_at: datetime


class ReminderDoneRequest(BaseModel):
    is_done: bool


class ReminderResponse(BaseModel):
    id: int
    title: str
    notes: Optional[str] = None
    remind_at: str
    is_done: bool
    created_at: str


_COLUMNS = "id, title, notes, remind_at, is_done, created_at"


def _get_patient_id(cursor, user_id: int) -> int:
    cursor.execute("SELECT id FROM patients WHERE user_id = %s", (user_id,))
    row = cursor.fetchone()
    if not row:
        raise HTTPException(
            status_code=404,
            detail="No patient profile found for this account.",
        )
    return row["id"]


def _row(r) -> dict:
    return {
        "id": r["id"],
        "title": r["title"],
        "notes": r["notes"],
        "remind_at": str(r["remind_at"]),
        "is_done": r["is_done"],
        "created_at": str(r["created_at"]),
    }


@router.get("", response_model=list[ReminderResponse])
def list_my_reminders(current_user: dict = Depends(get_current_user)):
    """The caller's reminders: open ones first, soonest first."""
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])
        cursor.execute(
            f"SELECT {_COLUMNS} FROM reminders WHERE patient_id = %s "
            "ORDER BY is_done ASC, remind_at ASC",
            (patient_id,),
        )
        return [_row(r) for r in cursor.fetchall()]
    finally:
        connection.close()


@router.post("", response_model=ReminderResponse)
def create_reminder(
    request: ReminderRequest,
    current_user: dict = Depends(get_current_user),
):
    if not request.title.strip():
        raise HTTPException(status_code=400, detail="Reminder title can't be empty.")

    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])
        cursor.execute(
            f"""
            INSERT INTO reminders (patient_id, title, notes, remind_at)
            VALUES (%s, %s, %s, %s)
            RETURNING {_COLUMNS}
            """,
            (patient_id, request.title.strip(), request.notes, request.remind_at),
        )
        row = cursor.fetchone()
        connection.commit()
        return _row(row)
    finally:
        connection.close()


@router.put("/{reminder_id}/done", response_model=ReminderResponse)
def set_reminder_done(
    reminder_id: int,
    request: ReminderDoneRequest,
    current_user: dict = Depends(get_current_user),
):
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])
        cursor.execute(
            f"""
            UPDATE reminders SET is_done = %s
            WHERE id = %s AND patient_id = %s
            RETURNING {_COLUMNS}
            """,
            (request.is_done, reminder_id, patient_id),
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Reminder not found.")
        connection.commit()
        return _row(row)
    finally:
        connection.close()


@router.delete("/{reminder_id}")
def delete_reminder(
    reminder_id: int,
    current_user: dict = Depends(get_current_user),
):
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])
        cursor.execute(
            "DELETE FROM reminders WHERE id = %s AND patient_id = %s RETURNING id",
            (reminder_id, patient_id),
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Reminder not found.")
        connection.commit()
        return {"message": "Reminder deleted."}
    finally:
        connection.close()
