
"""
routers/chat.py

Backs chatbot_screen.dart.

Every message the patient sends is saved, answered, and the answer is
saved too, so the conversation survives logging out and back in.

When ANTHROPIC_API_KEY is configured, Nia uses Claude with recent
conversation history and the patient's active health journey.

If Claude is unavailable, the original rule-based keyword matcher
provides a fallback.
"""

import os
import re
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_database_connection
from utils.dependencies import get_current_user
from knowledge_base import QA_BANK, ALTERNATIVE_QUESTIONS

router = APIRouter(prefix="/chat", tags=["Chat"])

_CLAUDE_MODEL = "claude-haiku-4-5-20251001"

_SYSTEM_PROMPT = """You are Nia, the supportive AI assistant inside Her Health, a women's health app tied to a real doctor's practice.

Your role:
- Be warm, brief, and genuinely supportive. Two to four short sentences is usually right.
- You can discuss menstrual health, pregnancy, postpartum recovery, general women's wellness, and cosmetic gynecology at a general, educational level.
- You are NOT a doctor. Never diagnose, never tell someone what condition they have, and never recommend a specific medication or dosage.
- For anything urgent, severe, or persistent, clearly encourage seeking medical care rather than trying to resolve it yourself.
- If the patient's active health journey context is provided, refer to it naturally when relevant.
- Keep a gentle, encouraging tone. Occasional soft emoji (🌸🌿💛) is appropriate, but do not overuse it.
- Do not pretend to have access to information that has not been provided.
"""


class ChatMessageRequest(BaseModel):
    message: str


class ChatMessageResponse(BaseModel):
    id: int
    sender: str
    message: str
    created_at: str


# Patient-facing topic labels mapped to the existing knowledge-bank categories.
_GUIDED_TOPICS = [
    {"id": 1, "title": "Pregnancy and prenatal care",
     "category": "Pregnancy and Prenatal Care"},
    {"id": 2, "title": "Menstrual health",
     "category": "Menstrual Health"},
    {"id": 3, "title": "Postpartum recovery",
     "category": "Postpartum Recovery"},
    {"id": 4, "title": "Cosmetic gynaecology",
     "category": "Cosmetic Gynaecology"},
    {"id": 5, "title": "General women's health and wellness",
     "category": "General Women's Health and Wellness"},
    {"id": 6, "title": "Sexual and reproductive health",
     "category": "Sexual and Reproductive Health"},
    {"id": 7, "title": "Symptoms and common health concerns",
     "category": "Common Symptoms and Health Concerns"},
    {"id": 8, "title": "Medication and supplements",
     "category": "Medication, Supplements and Nutrition"},
    {"id": 9, "title": "App-related questions",
     "category": "Her Health Application"},
]


@router.get("/topics")
def get_guided_topics(
    current_user: dict = Depends(get_current_user),
):
    """Return guided topics and their existing curated questions."""
    return [
        {
            "id": topic["id"],
            "title": topic["title"],
            "questions": [
                {
                    "id": item["id"],
                    "question": item["question"],
                }
                for item in QA_BANK
                if item["category"] == topic["category"]
            ],
        }
        for topic in _GUIDED_TOPICS
    ]



def _get_patient_id(cursor, user_id: int) -> int:
    cursor.execute(
        "SELECT id FROM patients WHERE user_id = %s",
        (user_id,),
    )
    row = cursor.fetchone()

    if not row:
        raise HTTPException(
            status_code=404,
            detail="No patient profile found for this account. Complete your patient profile first.",
        )

    return row["id"]


def _get_recent_history(
    cursor,
    patient_id: int,
    limit: int = 12,
) -> list[dict]:
    """Retrieve recent messages in chronological order."""

    cursor.execute(
        """
        SELECT sender, message
        FROM chat_messages
        WHERE patient_id = %s
        ORDER BY created_at DESC, id DESC
        LIMIT %s
        """,
        (patient_id, limit),
    )

    rows = cursor.fetchall()
    return list(reversed(rows))


def _get_journey_context(
    cursor,
    patient_id: int,
) -> Optional[str]:
    """Retrieve the patient's active health journey only."""

    cursor.execute(
        """
        SELECT journey_type, answers
        FROM health_journeys
        WHERE patient_id = %s AND is_active = TRUE
        """,
        (patient_id,),
    )

    row = cursor.fetchone()

    if not row:
        return None

    answers = row["answers"] or {}

    answers_text = ", ".join(
        f"{key}: {value}"
        for key, value in answers.items()
        if value
    )

    return (
        f"This patient's active health journey is "
        f"'{row['journey_type']}'. "
        f"Their onboarding answers: "
        f"{answers_text or 'none provided'}."
    )


# Original rule-based responses are retained as the fallback.

_RULES = [
    (
        ["period", "menstru", "cycle", "cramp"],
        "Tracking your cycle is a great step 🌸. Irregular periods, "
        "heavy flow, or severe cramps are worth mentioning to your doctor, "
        "especially if they're new or getting worse. Want to book an "
        "appointment to talk it through?",
    ),
    (
        ["pregnan", "due date", "trimester", "antenatal"],
        "Congratulations on your pregnancy journey 🤰. Regular "
        "antenatal visits really matter for you and your baby. If you're "
        "experiencing any pain, bleeding, or symptoms that worry you, please "
        "reach out to your doctor directly rather than waiting.",
    ),
    (
        ["postpartum", "breastfeed", "newborn"],
        "The postpartum period can be a lot to navigate 👶. Be gentle "
        "with yourself, physically and emotionally. If your mood, sleep, or "
        "recovery feels off, that's worth raising with your doctor at your "
        "next check-up.",
    ),
    (
        ["nausea", "nauseous", "vomit", "throwing up", "sick to my stomach"],
        "Nausea can come from a lot of different things -- your cycle, "
        "pregnancy, or something unrelated entirely. If it's persistent, "
        "sudden, or paired with other symptoms, it's worth getting checked "
        "rather than waiting it out. Want to book an appointment?",
    ),
    (
        ["tired", "fatigue", "exhaust", "no energy", "low energy"],
        "Fatigue that doesn't let up is worth paying attention to 🌿 "
        "-- it can be tied to sleep, stress, your cycle, or something else "
        "entirely. If it's been going on for a while, mention it to your "
        "doctor at your next visit.",
    ),
    (
        ["headache", "migraine"],
        "Headaches can have a lot of different causes. If they're frequent, "
        "severe, or new for you, that's worth flagging to your doctor rather "
        "than just pushing through them.",
    ),
    (
        ["fever", "temperature", "chills"],
        "A fever is your body telling you something's going on. If it's "
        "high, doesn't come down, or comes with other symptoms, please "
        "don't wait -- reach out to your doctor or urgent care.",
    ),
    (
        ["bleed", "spotting", "discharge"],
        "Any bleeding or discharge that's unusual for you, whether the "
        "amount, color, or timing, is worth having a doctor take a look at "
        "directly rather than guessing over chat.",
    ),
    (
        ["dizzy", "dizziness", "faint", "lightheaded"],
        "Feeling dizzy or lightheaded is worth taking seriously, especially "
        "if it happens more than once. If you can, sit or lie down when it "
        "happens, and let your doctor know.",
    ),
    (
        ["sleep", "insomnia", "can't sleep", "trouble sleeping"],
        "Sleep affects pretty much everything else 🌿. If it's been "
        "hard to get good rest for a while, that's a real thing worth "
        "mentioning at your next check-up, not something to just push "
        "through.",
    ),
    (
        ["pain", "hurt", "ache", "sore"],
        "I'm sorry you're dealing with pain. I can't diagnose what's causing "
        "it, but persistent or severe pain is always worth having checked. "
        "Would you like help booking an appointment?",
    ),
    (
        ["appointment", "book", "doctor", "visit", "reschedule"],
        "You can request an appointment any time from the Appointments menu "
        "-- just pick a date and time and your doctor's office will confirm "
        "it.",
    ),
    (
        ["sad", "anxious", "anxiety", "mood", "stress", "depress", "overwhelm"],
        "Thank you for sharing how you're feeling 🌿. Your mental "
        "health matters just as much as your physical health. If this "
        "feeling has been sticking around, it's worth talking to your "
        "doctor about.",
    ),
    (
        ["thank", "thanks", "thank you"],
        "You're so welcome 🌸. I'm always here if you want to talk "
        "through anything else.",
    ),
    (
        ["hello", "hi", "hey", "morning", "evening"],
        "Hi there 🌸! I'm here to support your wellness journey. You "
        "can ask me about your cycle, pregnancy, postpartum recovery, or "
        "general wellness, or just tell me what's on your mind.",
    ),
    (
        ["what can you", "help me", "what do you do"],
        "I can chat with you about your cycle, pregnancy, postpartum "
        "recovery, and general wellness, and point you toward booking an "
        "appointment when something's worth a doctor's opinion. I'm not a "
        "replacement for medical care, just a starting point 🌿.",
    ),
]

_FALLBACK = (
    "Thank you for sharing that with me 🌿. I'm still learning, "
    "so I might not have the perfect answer for everything -- but if "
    "this is something you'd like a professional opinion on, I'd "
    "recommend booking an appointment."
)



def _normalise_question(text: str) -> str:
    """Normalise case, punctuation and whitespace for matching."""

    text = text.lower().strip()
    text = re.sub(r"[^\w\s]", " ", text)
    return " ".join(text.split())


def _get_question_by_id(question_id: int) -> dict:
    """Retrieve a curated question by its unique ID."""

    for item in QA_BANK:
        if item["id"] == question_id:
            return item

    return next(item for item in QA_BANK if item["id"] == 142)


def _get_safety_response_id(message: str):
    """
    Detect urgent safety concerns before ordinary question matching.

    A negated suicidal statement is not treated as a positive disclosure.
    """

    text = _normalise_question(message)
    words = text.split()

    # Suicidal thoughts and immediate self-harm concerns.
    suicide_terms = (
        "suicidal",
        "suicide",
        "kill myself",
        "end my life",
        "want to die",
        "self harm",
        "hurt myself",
    )

    negations = {
        "not", "no", "never", "dont", "doesnt",
        "isnt", "arent", "without",
    }

    for term in suicide_terms:
        if term in text:
            position = text.find(term)
            preceding_words = text[:position].split()[-4:]

            if any(word in negations for word in preceding_words):
                continue

            return 139

    # Difficulty breathing.
    breathing_terms = (
        "difficulty breathing",
        "trouble breathing",
        "shortness of breath",
        "cant breathe",
        "cannot breathe",
        "struggling to breathe",
        "hard to breathe",
    )

    if any(term in text for term in breathing_terms):
        return 138

    # Heavy bleeding.
    bleeding_terms = (
        "heavy bleeding",
        "bleeding heavily",
        "bleeding a lot",
        "losing a lot of blood",
        "soaking through pads",
        "soaking pads",
    )

    if any(term in text for term in bleeding_terms):
        return 137

    # Severe pain, not ordinary menstrual cramps or mild discomfort.
    severe_pain_terms = (
        "severe pain",
        "unbearable pain",
        "excruciating pain",
        "extreme pain",
        "worst pain",
        "pain is unbearable",
        "cannot stand the pain",
        "cant stand the pain",
    )

    if any(term in text for term in severe_pain_terms):
        return 136

    return None


def _build_question_index():
    """Build a normalised phrase-to-answer index."""

    index = {}

    for item in QA_BANK:
        phrase = _normalise_question(item["question"])
        if phrase:
            index[phrase] = item["id"]

    for phrase, question_id in ALTERNATIVE_QUESTIONS.items():
        normalised = _normalise_question(phrase)
        if normalised:
            index[normalised] = question_id

    return index


_QUESTION_INDEX = _build_question_index()


def _match_knowledge_bank(message: str) -> dict:
    """
    Match a user message to a curated Q&A.

    Priority:
    1. Safety responses.
    2. Exact normalised question or alternative phrase.
    3. A complete question phrase contained in a longer message.
    4. High-confidence content-word overlap.
    5. Q142 when no confident match exists.
    """

    safety_id = _get_safety_response_id(message)

    if safety_id is not None:
        return _get_question_by_id(safety_id)

    normalised = _normalise_question(message)

    if not normalised:
        return _get_question_by_id(142)

    # Exact match.
    if normalised in _QUESTION_INDEX:
        return _get_question_by_id(_QUESTION_INDEX[normalised])

    # Match a complete known question inside a longer user message.
    for phrase, question_id in sorted(
        _QUESTION_INDEX.items(),
        key=lambda item: len(item[0]),
        reverse=True,
    ):
        if len(phrase) >= 12 and phrase in normalised:
            return _get_question_by_id(question_id)

    # Conservative content-word matching.
    stop_words = {
        "what", "why", "when", "where", "who", "how",
        "is", "are", "am", "do", "does", "did",
        "the", "a", "an", "and", "or", "to", "of",
        "my", "me", "i", "you", "your", "can",
        "could", "should", "would", "please", "for",
        "during", "with", "about", "on", "in", "if",
        "have", "has", "had", "it", "this", "that",
    }

    user_words = {
        word for word in normalised.split()
        if word not in stop_words and len(word) > 2
    }

    if len(user_words) >= 2:
        best_id = None
        best_score = 0.0
        second_score = 0.0

        candidates = {}

        for phrase, question_id in _QUESTION_INDEX.items():
            candidate_words = {
                word for word in phrase.split()
                if word not in stop_words and len(word) > 2
            }

            if len(candidate_words) < 2:
                continue

            overlap = len(user_words & candidate_words)
            score = overlap / len(candidate_words)

            if score > candidates.get(question_id, 0):
                candidates[question_id] = score

        ranked = sorted(
            candidates.items(),
            key=lambda item: item[1],
            reverse=True,
        )

        if ranked:
            best_id, best_score = ranked[0]
            if len(ranked) > 1:
                second_score = ranked[1][1]

            if best_score >= 0.80 and best_score - second_score >= 0.15:
                return _get_question_by_id(best_id)

    return _get_question_by_id(142)


def _generate_rule_based_reply(message: str) -> str:
    """Return a curated answer or refer unmatched questions to the help desk."""

    matched = _match_knowledge_bank(message)

    if matched["id"] == 142:
        return (
            "I'm sorry, I couldn't find a reliable answer to that question "
            "in the Her Health information bank. I don't want to guess about "
            "your health. Please contact the Her Health help desk for further "
            "assistance.\\n\\n"
            "Call: 0814592754\\n"
            "WhatsApp: 0814592754"
        )

    return matched["answer"]


def _generate_ai_reply(
    history: list[dict],
    journey_context: Optional[str],
) -> Optional[str]:
    """
    Generate a reply using Claude.

    Returns None if the API key is missing or the API call fails.
    """

    api_key = os.getenv("ANTHROPIC_API_KEY")

    if not api_key:
        return None

    try:
        from anthropic import Anthropic

        client = Anthropic(api_key=api_key)

        system = _SYSTEM_PROMPT

        if journey_context:
            system += f"\n\nPatient context: {journey_context}"

        claude_messages = [
            {
                "role": (
                    "user"
                    if message["sender"] == "user"
                    else "assistant"
                ),
                "content": message["message"],
            }
            for message in history
        ]

        response = client.messages.create(
            model=_CLAUDE_MODEL,
            max_tokens=300,
            system=system,
            messages=claude_messages,
        )

        # Extract and return Claude's actual response text.
        if response.content and hasattr(response.content[0], "text"):
            return response.content[0].text.strip() or None

        return None

    except Exception as error:
        print(
            f"AI REPLY FAILED: "
            f"{type(error).__name__}: {error}"
        )
        return None


def generate_reply(
    cursor,
    patient_id: int,
    latest_message: str,
) -> str:
    """
    Use the curated rule-based knowledge bank as Nia's primary response.

    The existing chat history and journey data remain available to the
    application, but curated answers take priority over generated AI.
    """

    return _generate_rule_based_reply(latest_message)


@router.post(
    "/message",
    response_model=list[ChatMessageResponse],
)
def send_message(
    request: ChatMessageRequest,
    current_user: dict = Depends(get_current_user),
):
    """Save the user's message and Nia's reply."""

    if not request.message.strip():
        raise HTTPException(
            status_code=400,
            detail="Message cannot be empty.",
        )

    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)

        patient_id = _get_patient_id(
            cursor,
            current_user["user_id"],
        )

        cursor.execute(
            """
            INSERT INTO chat_messages (patient_id, sender, message)
            VALUES (%s, 'user', %s)
            RETURNING id, sender, message, created_at
            """,
            (patient_id, request.message.strip()),
        )

        user_row = cursor.fetchone()
        connection.commit()

        reply_text = generate_reply(
            cursor,
            patient_id,
            request.message.strip(),
        )

        cursor.execute(
            """
            INSERT INTO chat_messages (patient_id, sender, message)
            VALUES (%s, 'ai', %s)
            RETURNING id, sender, message, created_at
            """,
            (patient_id, reply_text),
        )

        ai_row = cursor.fetchone()
        connection.commit()

        return [
            {
                "id": user_row["id"],
                "sender": user_row["sender"],
                "message": user_row["message"],
                "created_at": str(user_row["created_at"]),
            },
            {
                "id": ai_row["id"],
                "sender": ai_row["sender"],
                "message": ai_row["message"],
                "created_at": str(ai_row["created_at"]),
            },
        ]

    finally:
        connection.close()


@router.get(
    "/messages",
    response_model=list[ChatMessageResponse],
)
def get_messages(
    current_user: dict = Depends(get_current_user),
):
    """Return the patient's full conversation history."""

    connection = get_database_connection()

    try:
        cursor = connection.cursor(dictionary=True)

        patient_id = _get_patient_id(
            cursor,
            current_user["user_id"],
        )

        cursor.execute(
            """
            SELECT id, sender, message, created_at
            FROM chat_messages
            WHERE patient_id = %s
            ORDER BY created_at ASC, id ASC
            """,
            (patient_id,),
        )

        rows = cursor.fetchall()

        return [
            {
                "id": row["id"],
                "sender": row["sender"],
                "message": row["message"],
                "created_at": str(row["created_at"]),
            }
            for row in rows
        ]

    finally:
        connection.close()
