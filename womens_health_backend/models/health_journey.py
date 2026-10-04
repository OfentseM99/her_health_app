"""
models/health_journey.py

Pydantic models for the health journey feature, matched field-for-field
against what journey_questions_screen.dart actually asks (checked directly
against the running file on 2026-09-29 -- not the original design, which
had drifted).

Every field is optional free text, because every question in the screen is
a plain TextField (buildQuestion()), even ones phrased as yes/no ("Do you
have any pregnancy complications?"). That's the screen's own choice, not
something to silently turn into a checkbox here.

Two fields the original design assumed (pain_level, mood) don't exist
anywhere in the rendered screen -- selectedPainLevel and selectedMood are
declared in the Flutter state but never shown. They're left out here to
match.
"""

from typing import Literal, Optional
from pydantic import BaseModel


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
    regular_periods: Optional[str] = None
    birth_control: Optional[str] = None


class PostpartumRecoveryAnswers(BaseModel):
    weeks_postpartum: Optional[str] = None
    breastfeeding: Optional[str] = None
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


class CosmeticGynecologyAnswers(BaseModel):
    improvement_goal: Optional[str] = None
    previous_procedures: Optional[str] = None
    consulted_specialist: Optional[str] = None
    expected_outcome: Optional[str] = None


# journey_type -> the model that validates its answers. The router picks
# the model explicitly from journey_type rather than asking Pydantic to
# guess from a Union -- guessing was the original design's flaw, since
# every field on every model was optional, so the wrong model could
# silently "match" and quietly drop fields it didn't recognise.
ANSWER_MODELS = {
    "pregnancy_care": PregnancyCareAnswers,
    "menstrual_health": MenstrualHealthAnswers,
    "postpartum_recovery": PostpartumRecoveryAnswers,
    "general_health": GeneralHealthAnswers,
    "cosmetic_gynecology": CosmeticGynecologyAnswers,
}


class HealthJourneySetupRequest(BaseModel):
    journey_type: JourneyType
    # Raw dict, not a typed Union -- the router validates it against the
    # correct model looked up from journey_type above.
    answers: dict


class HealthJourneyResponse(BaseModel):
    id: int
    patient_id: int
    journey_type: JourneyType
    answers: dict
    created_at: str
    updated_at: str


class HealthJourneyEntryRequest(BaseModel):
    entry_date: Optional[str] = None  # defaults to today if omitted
    pain_level: Optional[str] = None
    mood: Optional[str] = None
    data: dict = {}


class HealthJourneyEntryResponse(BaseModel):
    id: int
    journey_id: int
    patient_id: int
    entry_date: str
    pain_level: Optional[str] = None
    mood: Optional[str] = None
    data: dict
    created_at: str
