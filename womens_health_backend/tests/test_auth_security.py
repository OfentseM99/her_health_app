"""
Automated tests for the security rules in routers/auth.py.

Run from the womens_health_backend folder (venv active):

    python -m pytest tests -v

These swap the real database for a small in-memory fake, so they don't
need Postgres running and never touch real patient data. They check the
RULES (lockouts, DEV_MODE, verification gate, reset flow), not SQL.
"""
from datetime import datetime, timedelta

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

import routers.auth as auth
from utils.security import hash_password


# ---------------------------------------------------------------- fake DB

class FakeDB:
    """Just enough of the users table for the auth endpoints under test."""

    def __init__(self):
        self.users = {}

    def add_user(self, email, password, role_id=1, verified=True, phone="0698691961"):
        self.users[email] = {
            "id": len(self.users) + 1, "role_id": role_id, "email": email,
            "password_hash": hash_password(password), "is_active": True,
            "is_verified": verified, "is_phone_verified": False, "phone": phone,
            "reset_code": None, "reset_code_expires_at": None,
        }
        return self.users[email]

    def connect(self):
        return _Conn(self)


class _Conn:
    def __init__(self, db): self.db = db
    def cursor(self, dictionary=True): return _Cursor(self.db)
    def commit(self): pass
    def close(self): pass


class _Cursor:
    def __init__(self, db):
        self.db = db
        self._result = None

    def _by_id(self, uid):
        return next(u for u in self.db.users.values() if u["id"] == uid)

    def execute(self, sql, params=()):
        s = " ".join(sql.split()).lower()
        if s.startswith("select") and "from users where email" in s:
            u = self.db.users.get(params[0])
            self._result = dict(u) if u else None
        elif s.startswith("update users set reset_code = %s"):
            code, expires, uid = params
            u = self._by_id(uid)
            u["reset_code"], u["reset_code_expires_at"] = code, expires
        elif "set password_hash" in s:
            u = self._by_id(params[-1])
            u["password_hash"] = params[0]
            u["reset_code"] = u["reset_code_expires_at"] = None
        elif s.startswith("update users set reset_code = null"):
            u = self._by_id(params[-1])
            u["reset_code"] = u["reset_code_expires_at"] = None

    def fetchone(self):
        return self._result

    def close(self):
        pass


# ---------------------------------------------------------------- fixtures

@pytest.fixture
def setup(monkeypatch):
    db = FakeDB()
    monkeypatch.setattr(auth, "get_database_connection", db.connect)
    monkeypatch.delenv("DEV_MODE", raising=False)
    auth._failed_attempts.clear()
    app = FastAPI()
    app.include_router(auth.router)
    return TestClient(app), db


def login(client, email, password):
    return client.post("/auth/login", json={"email": email, "password": password})


# ---------------------------------------------------------------- login

def test_correct_password_logs_in(setup):
    client, db = setup
    db.add_user("ada@test.com", "right")
    r = login(client, "ada@test.com", "right")
    assert r.status_code == 200
    assert "access_token" in r.json()


def test_wrong_password_is_rejected(setup):
    client, db = setup
    db.add_user("ada@test.com", "right")
    assert login(client, "ada@test.com", "wrong").status_code == 401


def test_unverified_patient_cannot_log_in(setup):
    client, db = setup
    db.add_user("new@test.com", "right", role_id=1, verified=False)
    assert login(client, "new@test.com", "right").status_code == 403


def test_unverified_staff_can_still_log_in(setup):
    client, db = setup
    db.add_user("doc@test.com", "right", role_id=4, verified=False)
    assert login(client, "doc@test.com", "right").status_code == 200


def test_five_wrong_passwords_lock_the_account(setup):
    client, db = setup
    db.add_user("ada@test.com", "right")
    for _ in range(5):
        assert login(client, "ada@test.com", "wrong").status_code == 401
    # Locked: even the correct password is refused.
    assert login(client, "ada@test.com", "right").status_code == 429


def test_successful_login_resets_the_failure_count(setup):
    client, db = setup
    db.add_user("ada@test.com", "right")
    for _ in range(4):
        login(client, "ada@test.com", "wrong")
    assert login(client, "ada@test.com", "right").status_code == 200
    # Count was reset, so 4 more mistakes still don't lock the account.
    for _ in range(4):
        login(client, "ada@test.com", "wrong")
    assert login(client, "ada@test.com", "right").status_code == 200


# ---------------------------------------------------------------- DEV_MODE

def test_dev_mode_off_never_returns_the_reset_code(setup):
    client, db = setup
    db.add_user("ada@test.com", "right")
    r = client.post("/auth/request-password-reset",
                    json={"email": "ada@test.com", "method": "email"}).json()
    assert "reset_code" not in r


def test_reset_request_masks_the_phone_number(setup):
    client, db = setup
    db.add_user("ada@test.com", "right", phone="0698691961")
    r = client.post("/auth/request-password-reset",
                    json={"email": "ada@test.com", "method": "phone"}).json()
    assert r["phone"] == "******1961"


def test_dev_mode_off_does_not_reveal_which_emails_exist(setup):
    client, db = setup
    db.add_user("ada@test.com", "right")
    real = client.post("/auth/request-password-reset",
                       json={"email": "ada@test.com", "method": "email"})
    fake = client.post("/auth/request-password-reset",
                       json={"email": "nobody@test.com", "method": "email"})
    assert real.status_code == fake.status_code == 200
    assert real.json()["message"] == fake.json()["message"]


def test_dev_mode_on_returns_the_code_for_the_demo_banner(setup, monkeypatch):
    client, db = setup
    monkeypatch.setenv("DEV_MODE", "true")
    db.add_user("ada@test.com", "right")
    r = client.post("/auth/request-password-reset",
                    json={"email": "ada@test.com", "method": "email"}).json()
    assert len(r["reset_code"]) == 6


# ---------------------------------------------------------------- password reset

def _request_code(client, monkeypatch, email):
    monkeypatch.setenv("DEV_MODE", "true")
    return client.post("/auth/request-password-reset",
                       json={"email": email, "method": "email"}).json()["reset_code"]


def test_full_password_reset_flow(setup, monkeypatch):
    client, db = setup
    db.add_user("ada@test.com", "old-password")
    code = _request_code(client, monkeypatch, "ada@test.com")
    r = client.post("/auth/reset-password",
                    json={"email": "ada@test.com", "code": code, "new_password": "new-password"})
    assert r.status_code == 200
    assert login(client, "ada@test.com", "new-password").status_code == 200
    assert login(client, "ada@test.com", "old-password").status_code == 401


def test_reset_code_is_destroyed_after_five_wrong_guesses(setup, monkeypatch):
    client, db = setup
    db.add_user("ada@test.com", "right")
    code = _request_code(client, monkeypatch, "ada@test.com")
    wrong = "000000" if code != "000000" else "111111"
    statuses = [
        client.post("/auth/reset-password",
                    json={"email": "ada@test.com", "code": wrong, "new_password": "x"}).status_code
        for _ in range(5)
    ]
    assert statuses == [400, 400, 400, 400, 429]
    # Brute force is dead: the real code no longer works either.
    r = client.post("/auth/reset-password",
                    json={"email": "ada@test.com", "code": code, "new_password": "x"})
    assert r.status_code == 400


def test_expired_reset_code_is_rejected(setup, monkeypatch):
    client, db = setup
    user = db.add_user("ada@test.com", "right")
    code = _request_code(client, monkeypatch, "ada@test.com")
    user["reset_code_expires_at"] = datetime.utcnow() - timedelta(minutes=1)
    r = client.post("/auth/reset-password",
                    json={"email": "ada@test.com", "code": code, "new_password": "x"})
    assert r.status_code == 400
    assert "expired" in r.json()["detail"]
