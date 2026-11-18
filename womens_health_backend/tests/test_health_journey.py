
from datetime import date, datetime

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

import routers.health_journey as journey_router
from utils.dependencies import get_current_user


class FakeDB:
    def __init__(self):
        self.patients = {10: 1, 20: 2}
        self.journeys = {}
        self.entries = {}
        self.next_journey_id = 1
        self.next_entry_id = 1

    def connect(self):
        return FakeConnection(self)


class FakeConnection:
    def __init__(self, db):
        self.db = db

    def cursor(self, dictionary=True):
        return FakeCursor(self.db)

    def commit(self):
        pass

    def rollback(self):
        pass

    def close(self):
        pass


class FakeCursor:
    def __init__(self, db):
        self.db = db
        self.result = None
        self.results = []

    def execute(self, sql, params=()):
        s = " ".join(sql.split()).lower()
        self.result = None
        self.results = []

        if s.startswith("select id from patients where user_id"):
            patient_id = self.db.patients.get(params[0])
            self.result = {"id": patient_id} if patient_id else None

        elif s.startswith("select id from patients where id"):
            self.result = {"id": params[0]}

        elif "from health_journeys" in s and "for update" in s:
            if "where patient_id" in s and "is_active = true" in s:
                patient_id = params[0]
                self.result = next(
                    (
                        dict(j)
                        for j in self.db.journeys.values()
                        if j["patient_id"] == patient_id and j["is_active"]
                    ),
                    None,
                )
            elif "where id = %s and patient_id = %s" in s:
                journey = self.db.journeys.get(params[0])
                if journey and journey["patient_id"] == params[1]:
                    self.result = {"id": journey["id"]}

        elif s.startswith("update health_journeys") and "answers = %s" in s:
            answers, journey_id, patient_id = params
            journey = self.db.journeys[journey_id]
            journey["answers"] = answers.adapted
            journey["updated_at"] = datetime.now()
            self.result = dict(journey)

        elif s.startswith("update health_journeys") and "is_active = false" in s:
            patient_id = params[0]
            for journey in self.db.journeys.values():
                if journey["patient_id"] == patient_id and journey["is_active"]:
                    journey["is_active"] = False
                    journey["updated_at"] = datetime.now()

        elif s.startswith("insert into health_journeys"):
            patient_id, journey_type, answers = params
            now = datetime.now()
            journey_id = self.db.next_journey_id
            self.db.next_journey_id += 1

            journey = {
                "id": journey_id,
                "patient_id": patient_id,
                "journey_type": journey_type,
                "answers": answers.adapted,
                "is_active": True,
                "created_at": now,
                "updated_at": now,
            }
            self.db.journeys[journey_id] = journey
            self.result = dict(journey)

        elif "from health_journeys" in s and "order by is_active desc" in s:
            patient_id = params[0]
            self.results = [
                dict(j) for j in self.db.journeys.values()
                if j["patient_id"] == patient_id
            ]
            self.results.sort(
                key=lambda j: (j["is_active"], j["created_at"], j["id"]),
                reverse=True,
            )

        elif "from health_journeys" in s and "is_active = true" in s:
            patient_id = params[0]
            journey = next(
                (
                    j for j in self.db.journeys.values()
                    if j["patient_id"] == patient_id and j["is_active"]
                ),
                None,
            )
            self.result = {"id": journey["id"]} if journey else None

        elif "from health_journeys" in s and "where id = %s and patient_id = %s" in s:
            journey = self.db.journeys.get(params[0])
            if journey and journey["patient_id"] == params[1]:
                self.result = {"id": journey["id"]}

        elif s.startswith("update health_journeys") and "is_active = true" in s:
            journey_id, patient_id = params
            journey = self.db.journeys[journey_id]
            journey["is_active"] = True
            journey["updated_at"] = datetime.now()
            self.result = dict(journey)

        elif s.startswith("insert into health_journey_entries"):
            journey_id, patient_id, entry_date, pain, mood, data = params
            entry_id = self.db.next_entry_id
            self.db.next_entry_id += 1

            entry = {
                "id": entry_id,
                "journey_id": journey_id,
                "patient_id": patient_id,
                "entry_date": entry_date or date.today(),
                "pain_level": pain,
                "mood": mood,
                "data": data.adapted,
                "created_at": datetime.now(),
            }
            self.db.entries[entry_id] = entry
            self.result = dict(entry)

        elif "from health_journey_entries" in s:
            patient_id, journey_id = params
            self.results = [
                dict(e) for e in self.db.entries.values()
                if e["patient_id"] == patient_id
                and e["journey_id"] == journey_id
            ]
            self.results.sort(
                key=lambda e: (e["entry_date"], e["created_at"]),
                reverse=True,
            )

        else:
            raise AssertionError(f"Unhandled SQL in test: {s}")

    def fetchone(self):
        return self.result

    def fetchall(self):
        return self.results

    def close(self):
        pass


@pytest.fixture
def setup(monkeypatch):
    db = FakeDB()

    monkeypatch.setattr(
        journey_router, "get_database_connection", db.connect
    )

    app = FastAPI()
    app.include_router(journey_router.router)

    app.dependency_overrides[get_current_user] = lambda: {
        "user_id": 10
    }

    return TestClient(app), db


def test_create_pregnancy_journey(setup):
    client, db = setup

    response = client.post(
        "/health-journey/setup",
        json={
            "journey_type": "pregnancy_care",
            "answers": {"weeks_pregnant": "20"},
        },
    )

    assert response.status_code == 200
    assert response.json()["journey_type"] == "pregnancy_care"
    assert response.json()["is_active"] is True
    assert len(db.journeys) == 1


def test_updating_same_journey_does_not_create_duplicate(setup):
    client, db = setup

    for weeks in ["20", "21"]:
        response = client.post(
            "/health-journey/setup",
            json={
                "journey_type": "pregnancy_care",
                "answers": {"weeks_pregnant": weeks},
            },
        )
        assert response.status_code == 200

    assert len(db.journeys) == 1
    assert response.json()["answers"]["weeks_pregnant"] == "21"


def test_switching_journeys_preserves_previous_journey(setup):
    client, db = setup

    client.post(
        "/health-journey/setup",
        json={"journey_type": "pregnancy_care", "answers": {}},
    )

    response = client.post(
        "/health-journey/setup",
        json={"journey_type": "menstrual_health", "answers": {}},
    )

    assert response.status_code == 200
    assert len(db.journeys) == 2

    active = [j for j in db.journeys.values() if j["is_active"]]
    assert len(active) == 1
    assert active[0]["journey_type"] == "menstrual_health"


def test_tracking_entries_remain_with_original_journey(setup):
    client, db = setup

    first = client.post(
        "/health-journey/setup",
        json={"journey_type": "pregnancy_care", "answers": {}},
    ).json()

    entry = client.post(
        "/health-journey/entries",
        json={
            "pain_level": "2",
            "mood": "Good",
            "data": {"symptoms": "Mild backache"},
        },
    )

    assert entry.status_code == 200
    assert entry.json()["journey_id"] == first["id"]

    client.post(
        "/health-journey/setup",
        json={"journey_type": "postpartum_recovery", "answers": {}},
    )

    old_entries = client.get(
        "/health-journey/entries",
        params={"journey_id": first["id"]},
    )

    assert old_entries.status_code == 200
    assert len(old_entries.json()) == 1
    assert old_entries.json()[0]["data"]["symptoms"] == "Mild backache"


def test_old_journey_can_be_reactivated(setup):
    client, db = setup

    first = client.post(
        "/health-journey/setup",
        json={"journey_type": "pregnancy_care", "answers": {}},
    ).json()

    client.post(
        "/health-journey/setup",
        json={"journey_type": "menstrual_health", "answers": {}},
    )

    response = client.post(
        f"/health-journey/{first['id']}/activate"
    )

    assert response.status_code == 200
    assert response.json()["journey_type"] == "pregnancy_care"
    assert response.json()["is_active"] is True

    active = [j for j in db.journeys.values() if j["is_active"]]
    assert len(active) == 1


def test_patient_cannot_access_another_patients_journey(setup):
    client, db = setup

    db.patients[20] = 2

    other_journey_id = db.next_journey_id
    db.next_journey_id += 1

    db.journeys[other_journey_id] = {
        "id": other_journey_id,
        "patient_id": 2,
        "journey_type": "general_health",
        "answers": {},
        "is_active": True,
        "created_at": datetime.now(),
        "updated_at": datetime.now(),
    }

    response = client.post(
        f"/health-journey/{other_journey_id}/activate"
    )

    assert response.status_code == 404


def test_history_returns_all_saved_journeys(setup):
    client, db = setup

    for journey_type in ["pregnancy_care", "menstrual_health", "general_health"]:
        client.post(
            "/health-journey/setup",
            json={"journey_type": journey_type, "answers": {}},
        )

    response = client.get("/health-journey/history")

    assert response.status_code == 200
    assert len(response.json()) == 3
    assert sum(j["is_active"] for j in response.json()) == 1
