
from datetime import date
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_database_connection
from utils.dependencies import get_current_user
from utils.audit import log_access


router = APIRouter(prefix="/patients", tags=["Patients"])


JourneyType = Literal[
    "pregnancy_care",
    "menstrual_health",
    "postpartum_recovery",
    "general_health",
    "cosmetic_gynecology",
]


class PatientJourneyUpdateRequest(BaseModel):
    journey_type: JourneyType


class PatientProfileRequest(BaseModel):
    first_name: str
    last_name: str
    phone: str | None = None
    date_of_birth: date | None = None
    emergency_contact_name: str | None = None
    emergency_contact_phone: str | None = None


class PatientServiceRequest(BaseModel):
    service_id: int


@router.post("/profile")
def create_patient_profile(
    profile: PatientProfileRequest,
    current_user=Depends(get_current_user),
):
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT id FROM patients WHERE user_id = %s",
            (current_user["user_id"],),
        )

        if cursor.fetchone():
            raise HTTPException(
                status_code=400,
                detail="Patient profile already exists.",
            )

        cursor.execute(
            """
            INSERT INTO patients
                (user_id, first_name, last_name, phone, date_of_birth,
                 emergency_contact_name, emergency_contact_phone)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                current_user["user_id"],
                profile.first_name,
                profile.last_name,
                profile.phone,
                profile.date_of_birth,
                profile.emergency_contact_name,
                profile.emergency_contact_phone,
            ),
        )

        connection.commit()

        return {"message": "Patient profile created successfully."}

    finally:
        cursor.close()
        connection.close()


@router.get("/profile")
def get_patient_profile(current_user=Depends(get_current_user)):
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT id, user_id, first_name, last_name, phone,
                   date_of_birth, emergency_contact_name,
                   emergency_contact_phone, created_at, updated_at
            FROM patients
            WHERE user_id = %s
            """,
            (current_user["user_id"],),
        )

        patient = cursor.fetchone()

        if not patient:
            raise HTTPException(
                status_code=404,
                detail="Patient profile not found.",
            )

        return patient

    finally:
        cursor.close()
        connection.close()


@router.put("/profile")
def update_patient_profile(
    profile: PatientProfileRequest,
    current_user=Depends(get_current_user),
):
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT id FROM patients WHERE user_id = %s",
            (current_user["user_id"],),
        )

        if not cursor.fetchone():
            raise HTTPException(
                status_code=404,
                detail="Patient profile not found.",
            )

        cursor.execute(
            """
            UPDATE patients
            SET first_name = %s,
                last_name = %s,
                phone = %s,
                date_of_birth = %s,
                emergency_contact_name = %s,
                emergency_contact_phone = %s
            WHERE user_id = %s
            """,
            (
                profile.first_name,
                profile.last_name,
                profile.phone,
                profile.date_of_birth,
                profile.emergency_contact_name,
                profile.emergency_contact_phone,
                current_user["user_id"],
            ),
        )

        connection.commit()

        return {"message": "Patient profile updated successfully."}

    finally:
        cursor.close()
        connection.close()


@router.post("/service")
def select_patient_service(
    service: PatientServiceRequest,
    current_user=Depends(get_current_user),
):
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT id FROM patients WHERE user_id = %s",
            (current_user["user_id"],),
        )

        patient = cursor.fetchone()

        if not patient:
            raise HTTPException(
                status_code=404,
                detail="Patient profile not found.",
            )

        cursor.execute(
            """
            SELECT id FROM services
            WHERE id = %s AND is_active = TRUE
            """,
            (service.service_id,),
        )

        if not cursor.fetchone():
            raise HTTPException(
                status_code=404,
                detail="Service not found.",
            )

        cursor.execute(
            """
            SELECT id FROM patient_services
            WHERE patient_id = %s AND service_id = %s
            """,
            (patient["id"], service.service_id),
        )

        if cursor.fetchone():
            raise HTTPException(
                status_code=400,
                detail="Patient has already selected this service.",
            )

        cursor.execute(
            """
            INSERT INTO patient_services (patient_id, service_id)
            VALUES (%s, %s)
            """,
            (patient["id"], service.service_id),
        )

        connection.commit()

        return {"message": "Service selected successfully."}

    finally:
        cursor.close()
        connection.close()


@router.get("/services")
def get_patient_services(current_user=Depends(get_current_user)):
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT s.id, s.name, s.description
            FROM patient_services ps
            JOIN patients p ON ps.patient_id = p.id
            JOIN services s ON ps.service_id = s.id
            WHERE p.user_id = %s
            ORDER BY s.id
            """,
            (current_user["user_id"],),
        )

        return cursor.fetchall()

    finally:
        cursor.close()
        connection.close()


@router.get("/all")
def get_all_patients(current_user=Depends(get_current_user)):
    if current_user["role_id"] not in [2, 3, 4]:
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to view patients.",
        )

    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT
                p.id,
                p.user_id,
                p.first_name,
                p.last_name,
                p.date_of_birth,
                p.phone,
                p.emergency_contact_name,
                p.emergency_contact_phone,
                hj.journey_type,
                p.created_at,
                p.updated_at
            FROM patients p
            LEFT JOIN health_journeys hj
                ON hj.patient_id = p.id
                AND hj.is_active = TRUE
            ORDER BY p.last_name, p.first_name
            """
        )

        patients = cursor.fetchall()
        log_access(cursor, current_user["user_id"], "list_patients")
        connection.commit()

        return patients

    finally:
        cursor.close()
        connection.close()


@router.put("/{patient_id}/health-journey")
def update_patient_health_journey(
    patient_id: int,
    request: PatientJourneyUpdateRequest,
    current_user=Depends(get_current_user),
):
    """
    Admin changes a patient's active journey without deleting
    any previously saved journeys or their answers.
    """
    if current_user["role_id"] not in [2, 3, 4]:
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to update patient information.",
        )

    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT id FROM patients WHERE id = %s FOR UPDATE",
            (patient_id,),
        )

        if not cursor.fetchone():
            raise HTTPException(
                status_code=404,
                detail="Patient not found.",
            )

        cursor.execute(
            """
            SELECT id, journey_type
            FROM health_journeys
            WHERE patient_id = %s AND is_active = TRUE
            FOR UPDATE
            """,
            (patient_id,),
        )

        active = cursor.fetchone()

        if active and active["journey_type"] == request.journey_type:
            # Do not erase answers when the requested journey is already active.
            journey_id = active["id"]

        else:
            # Deactivate the previous journey.
            cursor.execute(
                """
                UPDATE health_journeys
                SET is_active = FALSE,
                    updated_at = CURRENT_TIMESTAMP
                WHERE patient_id = %s AND is_active = TRUE
                """,
                (patient_id,),
            )

            # Reactivate the most recently saved journey of this type,
            # if one exists. Otherwise create a new journey.
            cursor.execute(
                """
                SELECT id
                FROM health_journeys
                WHERE patient_id = %s AND journey_type = %s
                ORDER BY created_at DESC, id DESC
                LIMIT 1
                FOR UPDATE
                """,
                (patient_id, request.journey_type),
            )

            existing = cursor.fetchone()

            if existing:
                journey_id = existing["id"]

                cursor.execute(
                    """
                    UPDATE health_journeys
                    SET is_active = TRUE,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = %s AND patient_id = %s
                    """,
                    (journey_id, patient_id),
                )

            else:
                cursor.execute(
                    """
                    INSERT INTO health_journeys
                        (patient_id, journey_type, answers, is_active)
                    VALUES (%s, %s, '{}'::jsonb, TRUE)
                    RETURNING id
                    """,
                    (patient_id, request.journey_type),
                )

                journey_id = cursor.fetchone()["id"]

        log_access(
            cursor,
            current_user["user_id"],
            "update_patient_health_journey",
            patient_id,
        )

        connection.commit()

        return {
            "message": "Patient health experience updated successfully.",
            "journey_id": journey_id,
            "journey_type": request.journey_type,
        }

    except Exception:
        connection.rollback()
        raise
    finally:
        cursor.close()
        connection.close()


@router.get("/{patient_id}")
def get_patient_by_id(
    patient_id: int,
    current_user=Depends(get_current_user),
):
    if current_user["role_id"] not in [2, 3, 4]:
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to view patient information.",
        )

    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT
                p.id,
                p.user_id,
                p.first_name,
                p.last_name,
                p.date_of_birth,
                p.phone,
                p.emergency_contact_name,
                p.emergency_contact_phone,
                hj.journey_type,
                p.created_at,
                p.updated_at
            FROM patients p
            LEFT JOIN health_journeys hj
                ON hj.patient_id = p.id
                AND hj.is_active = TRUE
            WHERE p.id = %s
            """,
            (patient_id,),
        )

        patient = cursor.fetchone()

        if not patient:
            raise HTTPException(
                status_code=404,
                detail="Patient not found.",
            )

        log_access(
            cursor,
            current_user["user_id"],
            "view_patient",
            patient_id,
        )
        connection.commit()

        return patient

    finally:
        cursor.close()
        connection.close()
