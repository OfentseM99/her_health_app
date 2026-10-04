from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_database_connection
from utils.dependencies import get_current_user


router = APIRouter(
    prefix="/patients",
    tags=["Patients"]
)


class PatientProfileRequest(BaseModel):
    first_name: str
    last_name: str
    phone: str | None = None
    date_of_birth: date | None = None
    emergency_contact_name: str | None = None
    emergency_contact_phone: str | None = None


@router.post("/profile")
def create_patient_profile(
    profile: PatientProfileRequest,
    current_user=Depends(get_current_user)
):
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT id FROM patients WHERE user_id = %s",
            (current_user["user_id"],)
        )

        existing_patient = cursor.fetchone()

        if existing_patient:
            raise HTTPException(
                status_code=400,
                detail="Patient profile already exists."
            )

        cursor.execute(
            """
            INSERT INTO patients
            (user_id, first_name, last_name, phone, date_of_birth, emergency_contact_name, emergency_contact_phone)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                current_user["user_id"],
                profile.first_name,
                profile.last_name,
                profile.phone,
                profile.date_of_birth,
                profile.emergency_contact_name,
                profile.emergency_contact_phone
            )
        )

        connection.commit()

        return {
            "message": "Patient profile created successfully."
        }

    finally:
        cursor.close()
        connection.close()

@router.get("/profile")
def get_patient_profile(
    current_user=Depends(get_current_user)
):
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT
                id,
                user_id,
                first_name,
                last_name,
                phone,
                date_of_birth,
                emergency_contact_name,
                emergency_contact_phone,
                created_at,
                updated_at
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

        return patient

    finally:
        cursor.close()
        connection.close()

@router.put("/profile")
def update_patient_profile(
    profile: PatientProfileRequest,
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

        cursor.execute(
            """
            UPDATE patients
            SET
                first_name = %s,
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
                current_user["user_id"]
            )
        )

        connection.commit()

        return {
            "message": "Patient profile updated successfully."
        }

    finally:
        cursor.close()
        connection.close()

class PatientServiceRequest(BaseModel):
    service_id: int

@router.post("/service")
def select_patient_service(
    service: PatientServiceRequest,
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

        cursor.execute(
            """
            SELECT id
            FROM services
            WHERE id = %s AND is_active = TRUE
            """,
            (service.service_id,)
        )

        selected_service = cursor.fetchone()

        if not selected_service:
            raise HTTPException(
                status_code=404,
                detail="Service not found."
            )

        cursor.execute(
            """
            SELECT id
            FROM patient_services
            WHERE patient_id = %s AND service_id = %s
            """,
            (
                patient["id"],
                service.service_id
            )
        )

        existing_selection = cursor.fetchone()

        if existing_selection:
            raise HTTPException(
                status_code=400,
                detail="Patient has already selected this service."
            )

        cursor.execute(
            """
            INSERT INTO patient_services
            (patient_id, service_id)
            VALUES (%s, %s)
            """,
            (
                patient["id"],
                service.service_id
            )
        )

        connection.commit()

        return {
            "message": "Service selected successfully."
        }

    finally:
        cursor.close()
        connection.close()

@router.get("/services")
def get_patient_services(
    current_user=Depends(get_current_user)
):
    connection = get_database_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT
                s.id,
                s.name,
                s.description
            FROM patient_services ps
            JOIN patients p
                ON ps.patient_id = p.id
            JOIN services s
                ON ps.service_id = s.id
            WHERE p.user_id = %s
            ORDER BY s.id
            """,
            (current_user["user_id"],)
        )

        return cursor.fetchall()

    finally:
        cursor.close()
        connection.close()

@router.get("/all")
def get_all_patients(
    current_user=Depends(get_current_user)
):
    if current_user["role_id"] not in [2, 3, 4]:
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to view patients."
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
                p.created_at,
                p.updated_at
            FROM patients p
            ORDER BY p.last_name, p.first_name
            """
        )

        return cursor.fetchall()

    finally:
        cursor.close()
        connection.close()

@router.get("/{patient_id}")
def get_patient_by_id(
    patient_id: int,
    current_user=Depends(get_current_user)
):
    if current_user["role_id"] not in [2, 3, 4]:
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to view patient information."
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
                p.created_at,
                p.updated_at
            FROM patients p
            WHERE p.id = %s
            """,
            (patient_id,)
        )

        patient = cursor.fetchone()

        if not patient:
            raise HTTPException(
                status_code=404,
                detail="Patient not found."
            )

        return patient

    finally:
        cursor.close()
        connection.close()