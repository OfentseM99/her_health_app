import pytest
from unittest.mock import patch

from knowledge_base import QA_BANK, ALTERNATIVE_QUESTIONS
from routers import chat


@pytest.mark.parametrize(
    "item",
    QA_BANK,
    ids=lambda item: f"Q{item['id']}",
)
def test_every_original_question_matches_its_own_answer(item):
    result = chat._match_knowledge_bank(item["question"])

    assert result["id"] == item["id"]
    assert result["answer"] == item["answer"]


@pytest.mark.parametrize(
    "phrase, expected_id",
    list(ALTERNATIVE_QUESTIONS.items()),
)
def test_every_alternative_phrase_matches_correct_answer(phrase, expected_id):
    result = chat._match_knowledge_bank(phrase)

    assert result["id"] == expected_id


@pytest.mark.parametrize(
    "message, expected_id",
    [
        ("AM I PREGNANT!!!", 1),
        ("   what are the signs of pregnancy   ", 1),
        ("WHY IS MY PERIOD LATE???", 34),
        ("I am pregnant and bleeding heavily", 137),
        ("I am struggling to breathe", 138),
        ("I am experiencing unbearable pain", 136),
        ("I am having suicidal thoughts", 139),
        ("What if I experience heavy bleeding?", 137),
        ("I cannot breathe properly", 138),
        ("My pain is unbearable", 136),
        ("I want to end my life", 139),
    ],
)
def test_normalisation_and_safety_matching(message, expected_id):
    result = chat._match_knowledge_bank(message)

    assert result["id"] == expected_id


@pytest.mark.parametrize(
    "message",
    [
        "I am not suicidal",
        "I am not having suicidal thoughts",
    ],
)
def test_negated_suicidal_statements_do_not_trigger_crisis_response(message):
    assert chat._get_safety_response_id(message) is None


@pytest.mark.parametrize(
    "message",
    [
        "What is the weather like today?",
        "I have ordinary period cramps",
        "I have mild stomach discomfort",
        "random unrelated words",
    ],
)
def test_unrecognised_questions_use_safe_fallback(message):
    result = chat._match_knowledge_bank(message)

    assert result["id"] == 142


def test_emergency_safety_response_overrides_general_matching():
    result = chat._match_knowledge_bank(
        "I am pregnant and bleeding heavily. What should I do?"
    )

    assert result["id"] == 137


def test_rule_based_reply_returns_curated_answer():
    expected = next(
        item["answer"] for item in QA_BANK if item["id"] == 121
    )

    assert chat.generate_reply(None, 1, "What is Her Health?") == expected


def test_primary_reply_does_not_call_claude():
    expected = next(
        item["answer"] for item in QA_BANK if item["id"] == 121
    )

    with patch.object(
        chat,
        "_generate_ai_reply",
        side_effect=AssertionError("Claude must not be called"),
    ):
        reply = chat.generate_reply(None, 1, "What is Her Health?")

    assert reply == expected


def test_knowledge_bank_has_142_unique_questions():
    ids = [item["id"] for item in QA_BANK]

    assert len(QA_BANK) == 142
    assert len(ids) == 142
    assert len(set(ids)) == 142


def test_all_knowledge_bank_entries_have_answers_and_categories():
    for item in QA_BANK:
        assert item["question"].strip()
        assert item["answer"].strip()
        assert item["category"].strip()


def test_alternative_phrases_have_valid_question_ids():
    valid_ids = {item["id"] for item in QA_BANK}

    assert len(ALTERNATIVE_QUESTIONS) == 40

    for phrase, question_id in ALTERNATIVE_QUESTIONS.items():
        assert phrase.strip()
        assert question_id in valid_ids
