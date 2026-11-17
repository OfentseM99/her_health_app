"""Connects the Nia engine to routers/chat.py.

nia_reply_text(message) returns plain text for the chat bubble when Nia knows
the answer (or when it is an emergency / small talk / "did you mean"), and
returns None when Nia has nothing, so chat.py can carry on with its old logic.
"""
from pathlib import Path
from typing import Optional

from .engine import Nia

_nia = None


def _get() -> Nia:
    global _nia
    if _nia is None:
        _nia = Nia(str(Path(__file__).with_name("knowledge_base.json")))
    return _nia


def nia_reply_text(message: str) -> Optional[str]:
    try:
        r = _get().reply(message)
    except Exception as e:  # never let the chatbot break the chat
        print(f"NIA ENGINE ERROR: {type(e).__name__}: {e}")
        return None

    kind = r["type"]
    if kind in ("safety", "small_talk"):
        return r["answer"]

    if kind == "answer":
        text = r["summary"]
        if r["details"]:
            text += " " + r["details"]
        if r["when_to_get_help"]:
            text += "\n\nWhen to get help: " + r["when_to_get_help"]
        if r["follow_ups"]:
            text += "\n\nYou might also want to ask:\n" + "\n".join(
                "\u2022 " + f["question"] for f in r["follow_ups"]
            )
        if r["disclaimer"]:
            text += "\n\n" + r["disclaimer"]
        return text

    if kind == "suggest" and r["suggestions"]:
        return (
            "I want to make sure I give you the right information. Did you mean:\n"
            + "\n".join("\u2022 " + s["question"] for s in r["suggestions"])
            + "\n\nTap or type the one you meant."
        )

    return None  # fallback: let chat.py's AI / keyword replies handle it
