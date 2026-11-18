
"""
Pydantic models for Her Health journeys and tracking entries.
"""

from typing import Literal, Optional

from pydantic import BaseModel, Field


JourneyType = Literal[
    "pregnancy_care",
    "menstrual_health",
    "postpartum_recovery",
    "general_health",
    "cosmetic_gynecology",
]


class PregnancyCareAnswers(BaseModel):
    weeks_pregnant: Optional[str] = None
    first_pregnancy: Optional[str] = None
    had_antenatal_visit: Optional[str] = None
    complications: Optional[str] = None
    taking_vitamins: Optional[str] = None
    due_date: Optional[str] = None


class MenstrualHealthAnswers(BaseModel):
    last_period: Optional[str] = None
    cycle_length: Optional[str] = None
    period_length: Optional[str] = None
    cramps: Optional[str] = None
    heavy_flow: Optional[str] = None
    regular_periods: Optional[str] = None
    birth_control: Optional[str] = None


class PostpartumRecoveryAnswers(BaseModel):
    weeks_postpartum: Optional[str] = None
    baby_birth_date: Optional[str] = None
    delivery_type: Optional[str] = None
    breastfeeding: Optional[str] = None
    breastfeeding_difficulty: Optional[str] = None
    sleep_quality: Optional[str] = None
    mood: Optional[str] = None
    postpartum_checkup: Optional[str] = None
    concerns: Optional[str] = None


class GeneralHealthAnswers(BaseModel):
    height: Optional[str] = None
    weight: Optional[str] = None
    exercise: Optional[str] = None
    water_intake: Optional[str] = None
    sleep_hours: Optional[str] = None
    health_concerns: Optional[str] = None
    yearly_checkup: Optional[str] = None
    last_checkup: Optional[str] = None
    health_category: Optional[str] = None


class CosmeticGynecologyAnswers(BaseModel):
    improvement_goal: Optional[str] = None
    previous_procedures: Optional[str] = None
    consulted_specialist: Optional[str] = None
    expected_outcome: Optional[str] = None
    procedure_interest: Optional[str] = None
    procedure_timing: Optional[str] = None


ANSWER_MODELS = {
    "pregnancy_care": PregnancyCareAnswers,
    "menstrual_health": MenstrualHealthAnswers,
    "postpartum_recovery": PostpartumRecoveryAnswers,
    "general_health": GeneralHealthAnswers,
    "cosmetic_gynecology": CosmeticGynecologyAnswers,
}


class HealthJourneySetupRequest(BaseModel):
    journey_type: JourneyType
    answers: dict = Field(default_factory=dict)


class HealthJourneyResponse(BaseModel):
    id: int
    patient_id: int
    journey_type: JourneyType
    answers: dict
    is_active: bool
    created_at: str
    updated_at: str


class HealthJourneyEntryRequest(BaseModel):
    entry_date: Optional[str] = None
    pain_level: Optional[str] = None
    mood: Optional[str] = None
    data: dict = Field(default_factory=dict)


class HealthJourneyEntryResponse(BaseModel):
    id: int
    journey_id: int
    patient_id: int
    entry_date: str
    pain_level: Optional[str] = None
    mood: Optional[str] = None
    data: dict
    created_at: str
