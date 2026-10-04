"""
routers/chat.py

Backs chatbot_screen.dart. Every message the patient sends is saved,
answered, and the answer is saved too -- so the conversation survives
logging out and back in.

Replies now come from the Claude API when ANTHROPIC_API_KEY is set,
using the patient's recent conversation history and their health journey
(if they have one) as context, so Nia can actually reference what the
patient told the app about themselves.

If the key isn't set, or the API call fails for any reason (network
issue, rate limit, bad key), this falls back to the original rule-based
keyword matcher rather than erroring the whole request out. That keeps
the chat working even with no key configured at all, which matters for
running this locally without every teammate needing their own API key.
"""

import os
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_database_connection
from utils.dependencies import get_current_user

router = APIRouter(prefix="/chat", tags=["Chat"])

# The model used for Nia's replies. Haiku is the fast, inexpensive option
# in the current Claude lineup -- appropriate for short supportive chat
# replies rather than long-form reasoning.
_CLAUDE_MODEL = "claude-haiku-4-5-20251001"

_SYSTEM_PROMPT = """You are Nia, the supportive AI assistant inside Her Health, a women's health app tied to a real doctor's practice.

Your role:
- Be warm, brief, and genuinely supportive -- this is a chat bubble, not an essay. Two to four short sentences is usually right.
- You can discuss menstrual health, pregnancy, postpartum recovery, general women's wellness, and cosmetic gynecology at a general, educational level.
- You are NOT a doctor. Never diagnose, never tell someone what condition they have, never recommend a specific medication or dosage.
- For anything that sounds urgent, severe, or persistent, clearly encourage booking an appointment (the app has a real Appointments feature) or seeking care directly, rather than trying to resolve it yourself.
- If the patient's health journey context is provided below, you may refer to it naturally when it's relevant, but don't force it into every reply.
- Keep a gentle, encouraging tone. Occasional use of soft emoji (🌸🌿💛) fits the app's style, but don't overdo it.
"""


class ChatMessageRequest(BaseModel):
    message: str


class ChatMessageResponse(BaseModel):
    id: int
    sender: str
    message: str
    created_at: str


def _get_patient_id(cursor, user_id: int) -> int:
    cursor.execute("SELECT id FROM patients WHERE user_id = %s", (user_id,))
    row = cursor.fetchone()
    if not row:
        raise HTTPException(
            status_code=404,
            detail="No patient profile found for this account. Complete your patient profile first.",
        )
    return row["id"]


def _get_recent_history(cursor, patient_id: int, limit: int = 12) -> list[dict]:
    """Most recent messages, oldest first (the order Claude expects)."""
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


def _get_journey_context(cursor, patient_id: int) -> Optional[str]:
    """
    A short plain-text summary of the patient's health journey, if they
    have one, to give Claude relevant context. Returns None if they
    haven't set one up -- the prompt just omits this section entirely.
    """
    cursor.execute(
        "SELECT journey_type, answers FROM health_journeys WHERE patient_id = %s",
        (patient_id,),
    )
    row = cursor.fetchone()
    if not row:
        return None

    answers_text = ", ".join(
        f"{key}: {value}" for key, value in row["answers"].items() if value
    )
    return (
        f"This patient's selected health journey is '{row['journey_type']}'. "
        f"Their onboarding answers: {answers_text or 'none provided'}."
    )


# keyword -> response. This is the fallback used when the AI is
# unavailable -- kept exactly as before, unchanged.
_RULES = [
    (["period", "menstru", "cycle", "cramp"],
     "Tracking your cycle is a great step \U0001F338. Irregular periods, "
     "heavy flow, or severe cramps are worth mentioning to your doctor, "
     "especially if they're new or getting worse. Want to book an "
     "appointment to talk it through?"),
    (["pregnan", "due date", "trimester", "antenatal"],
     "Congratulations on your pregnancy journey \U0001F930. Regular "
     "antenatal visits really matter for you and your baby. If you're "
     "experiencing any pain, bleeding, or symptoms that worry you, please "
     "reach out to your doctor directly rather than waiting."),
    (["postpartum", "breastfeed", "newborn"],
     "The postpartum period can be a lot to navigate \U0001F476. Be gentle "
     "with yourself, physically and emotionally. If your mood, sleep, or "
     "recovery feels off, that's worth raising with your doctor at your "
     "next check-up."),
    (["nausea", "nauseous", "vomit", "throwing up", "sick to my stomach"],
     "Nausea can come from a lot of different things -- your cycle, "
     "pregnancy, or something unrelated entirely. If it's persistent, "
     "sudden, or paired with other symptoms, it's worth getting checked "
     "rather than waiting it out. Want to book an appointment?"),
    (["tired", "fatigue", "exhaust", "no energy", "low energy"],
     "Fatigue that doesn't let up is worth paying attention to \U0001F33F "
     "-- it can be tied to sleep, stress, your cycle, or something else "
     "entirely. If it's been going on for a while, mention it to your "
     "doctor at your next visit."),
    (["headache", "migraine"],
     "Headaches can have a lot of different causes. If they're frequent, "
     "severe, or new for you, that's worth flagging to your doctor rather "
     "than just pushing through them."),
    (["fever", "temperature", "chills"],
     "A fever is your body telling you something's going on. If it's "
     "high, doesn't come down, or comes with other symptoms, please "
     "don't wait -- reach out to your doctor or urgent care."),
    (["bleed", "spotting", "discharge"],
     "Any bleeding or discharge that's unusual for you, whether the "
     "amount, color, or timing, is worth having a doctor take a look at "
     "directly rather than guessing over chat."),
    (["dizzy", "dizziness", "faint", "lightheaded"],
     "Feeling dizzy or lightheaded is worth taking seriously, especially "
     "if it happens more than once. If you can, sit or lie down when it "
     "happens, and let your doctor know."),
    (["sleep", "insomnia", "can't sleep", "trouble sleeping"],
     "Sleep affects pretty much everything else \U0001F33F. If it's been "
     "hard to get good rest for a while, that's a real thing worth "
     "mentioning at your next check-up, not something to just push "
     "through."),
    (["pain", "hurt", "ache", "sore"],
     "I'm sorry you're dealing with pain. I can't diagnose what's causing "
     "it, but persistent or severe pain is always worth having checked. "
     "Would you like help booking an appointment?"),
    (["appointment", "book", "doctor", "visit", "reschedule"],
     "You can request an appointment any time from the Appointments menu "
     "-- just pick a date and time and your doctor's office will confirm "
     "it."),
    (["sad", "anxious", "anxiety", "mood", "stress", "depress", "overwhelm"],
     "Thank you for sharing how you're feeling \U0001F33F. Your mental "
     "health matters just as much as your physical health. If this "
     "feeling has been sticking around, it's worth talking to your "
     "doctor about."),
    (["thank", "thanks", "thank you"],
     "You're so welcome \U0001F338. I'm always here if you want to talk "
     "through anything else."),
    (["hello", "hi", "hey", "morning", "evening"],
     "Hi there \U0001F338! I'm here to support your wellness journey. You "
     "can ask me about your cycle, pregnancy, postpartum recovery, or "
     "general wellness, or just tell me what's on your mind."),
    (["what can you", "help me", "what do you do"],
     "I can chat with you about your cycle, pregnancy, postpartum "
     "recovery, and general wellness, and point you toward booking an "
     "appointment when something's worth a doctor's opinion. I'm not a "
     "replacement for medical care, just a starting point \U0001F33F."),
]

_FALLBACK = (
    "Thank you for sharing that with me \U0001F33F. I'm still learning, "
    "so I might not have the perfect answer for everything -- but if "
    "this is something you'd like a professional opinion on, I'd "
    "recommend booking an appointment."
)


def _generate_rule_based_reply(message: str) -> str:
    """The original keyword-matched reply. Used as the fallback whenever
    the AI path isn't available."""
    lowered = message.lower()
    for keywords, response in _RULES:
        if any(keyword in lowered for keyword in keywords):
            return response
    return _FALLBACK


def _generate_ai_reply(
    history: list[dict],
    journey_context: Optional[str],
) -> Optional[str]:
    """
    Calls the Claude API with the conversation so far. Returns None (not
    an exception) if there's no API key configured or the call fails for
    any reason -- the caller falls back to the rule-based reply in
    either case, so a missing key or a network hiccup never breaks the
    chat.
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
                "role": "user" if m["sender"] == "user" else "assistant",
                "content": m["message"],
            }
            for m in history
        ]

        response = client.messages.create(
            model=_CLAUDE_MODEL,
            max_tokens=300,
            system=system,
            messages=claude_messages,
        )

    except Exception as e:
        print(f"AI REPLY FAILED: {type(e).__name__}: {e}")
        return None


def generate_reply(
    cursor,
    patient_id: int,
    latest_message: str,
) -> str:
    """
    THE single entry point the endpoint calls for a reply. Tries the real
    AI first (with conversation history and health journey context), and
    falls back to keyword matching on just the latest message if the AI
    path isn't available for any reason.
    """
    history = _get_recent_history(cursor, patient_id)
    journey_context = _get_journey_context(cursor, patient_id)

    ai_reply = _generate_ai_reply(history, journey_context)
    if ai_reply:
        return ai_reply

    return _generate_rule_based_reply(latest_message)


@router.post("/message", response_model=list[ChatMessageResponse])
def send_message(
    request: ChatMessageRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Saves the user's message, generates a reply, saves that too, and
    returns both as a pair -- so the frontend can append them in order
    without a second round trip.
    """
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

        cursor.execute(
            """
            INSERT INTO chat_messages (patient_id, sender, message)
            VALUES (%s, 'user', %s)
            RETURNING id, sender, message, created_at
            """,
            (patient_id, request.message),
        )
        user_row = cursor.fetchone()
        connection.commit()

        reply_text = generate_reply(cursor, patient_id, request.message)

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


@router.get("/messages", response_model=list[ChatMessageResponse])
def get_messages(current_user: dict = Depends(get_current_user)):
    """Full conversation history, oldest first."""
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        patient_id = _get_patient_id(cursor, current_user["user_id"])

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
                "id": r["id"],
                "sender": r["sender"],
                "message": r["message"],
                "created_at": str(r["created_at"]),
            }
            for r in rows
        ]
    finally:
        connection.close()
