from datetime import date, time

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_database_connection
from utils.dependencies import get_current_user


router = APIRouter(
    prefix="/appointments",
    tags=["Appointments"]
)


class AppointmentRequest(BaseModel):
    requested_date: date
    requested_time: time
    reason: str | None = None


@router.post("/request")
def request_appointment(
    appointment: AppointmentRequest,
    current_user=Depends(get_current_user)
):
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT id
            FROM patients
            WHERE user_id = %s
            """,
            (current_user["user_id"],)
        )

        patient = cursor.fetchone()

        if not patient:
            raise HTTPException(
                status_code=404,
                detail="Patient profile not found."
            )

        if appointment.requested_date < date.today():
            raise HTTPException(
                status_code=400,
                detail="Appointment date cannot be in the past."
            )

        cursor.execute(
            """
            SELECT id
            FROM appointments
            WHERE requested_date = %s
              AND requested_time = %s
              AND status IN ('pending', 'approved')
            """,
            (appointment.requested_date, appointment.requested_time)
        )

        if cursor.fetchone():
            raise HTTPException(
                status_code=409,
                detail="That time slot is already booked. Please choose a different time."
            )

        cursor.execute(
            """
            INSERT INTO appointments
            (
                patient_id,
                requested_date,
                requested_time,
                reason
            )
            VALUES (%s, %s, %s, %s)
            """,
            (
                patient["id"],
                appointment.requested_date,
                appointment.requested_time,
                appointment.reason
            )
        )

        connection.commit()

        return {
            "message": "Appointment request submitted successfully."
        }

    finally:
        cursor.close()
        connection.close()


@router.get("")
def get_my_appointments(
    current_user=Depends(get_current_user)
):
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT
                a.id,
                a.requested_date,
                a.requested_time,
                a.reason,
                a.status,
                a.notes,
                a.created_at,
                a.updated_at
            FROM appointments a
            JOIN patients p
                ON a.patient_id = p.id
            WHERE p.user_id = %s
            ORDER BY a.requested_date DESC, a.requested_time DESC
            """,
            (current_user["user_id"],)
        )

        return cursor.fetchall()

    finally:
        cursor.close()
        connection.close()

@router.get("/all")
def get_all_appointments(
    current_user=Depends(get_current_user)
):
    if current_user["role_id"] not in [2, 3, 4]:
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to view all appointments."
        )

    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT
                a.id,
                a.patient_id,
                p.first_name,
                p.last_name,
                a.requested_date,
                a.requested_time,
                a.reason,
                a.status,
                a.notes,
                a.created_at,
                a.updated_at
            FROM appointments a
            JOIN patients p
                ON a.patient_id = p.id
            ORDER BY a.requested_date DESC, a.requested_time DESC
            """
        )

        return cursor.fetchall()

    finally:
        cursor.close()
        connection.close()

class AppointmentStatusRequest(BaseModel):
    status: str
    notes: str | None = None

@router.put("/{appointment_id}/status")
def update_appointment_status(
    appointment_id: int,
    appointment: AppointmentStatusRequest,
    current_user=Depends(get_current_user)
):
    if current_user["role_id"] not in [2, 3, 4]:
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to update appointments."
        )

    allowed_statuses = [
        "pending",
        "approved",
        "rejected",
        "cancelled"
    ]

    if appointment.status not in allowed_statuses:
        raise HTTPException(
            status_code=400,
            detail="Invalid appointment status."
        )

    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT id
            FROM appointments
            WHERE id = %s
            """,
            (appointment_id,)
        )

        existing_appointment = cursor.fetchone()

        if not existing_appointment:
            raise HTTPException(
                status_code=404,
                detail="Appointment not found."
            )

        cursor.execute(
            """
            UPDATE appointments
            SET
                status = %s,
                notes = %s
            WHERE id = %s
            """,
            (
                appointment.status,
                appointment.notes,
                appointment_id
            )
        )

        connection.commit()

        return {
            "message": "Appointment status updated successfully."
        }

    finally:
        cursor.close()
        connection.close()