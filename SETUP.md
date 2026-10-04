# Her Health App: Setup Guide

How to get the backend, patient app and admin portal running on a new machine.

## What's in this repo

| Folder | What it is |
|---|---|
| `womens_health_backend/` | FastAPI backend (Python) talking to PostgreSQL |
| `lib/` (repo root) | Patient app (Flutter) |
| `admin_portal/` | Staff admin portal (Flutter web) |

## 1. Prerequisites

- **PostgreSQL**: Postgres.app is easiest on Mac. Note its port (often 5433).
- **Python 3.12**
- **Flutter** with Chrome available

## 2. Database

The whole schema is in one file, exported straight from a working database.

```
createdb -p 5433 health
cd womens_health_backend
psql -p 5433 health -f postgres_setup/full_schema.sql
psql -p 5433 health -f postgres_setup/seed_data.sql
```

`full_schema.sql` creates every table. `seed_data.sql` adds the fixed lookup
data (roles and services) only. No patient data is ever exported.

The older individual files in `postgres_setup/` are kept as history of how the
schema grew. A fresh setup only needs the two files above.

### Updating the schema export

After adding or changing a table, re-export so this file stays current. Use
Postgres.app's own `pg_dump`. A Homebrew `pg_dump` will refuse with a
"server version mismatch" error if its version is older than the server's.

```
PGD=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_dump
$PGD -p 5433 --schema-only --no-owner --no-privileges health > postgres_setup/full_schema.sql
$PGD -p 5433 --data-only --no-owner --inserts -t roles -t services health > postgres_setup/seed_data.sql
```

## 3. Backend

```
cd womens_health_backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Edit `.env` (at least `DB_PORT` and `DB_USER`), then run:

```
python3 harden_config.py
uvicorn main:app --reload
```

`harden_config.py` replaces the placeholder secrets with random ones. Check
`http://127.0.0.1:8000/docs` to see every endpoint.

## 4. Patient app and admin portal

Run each in its own terminal tab:

```
flutter run -d chrome                         # patient app, from the repo root
cd admin_portal && flutter run -d chrome      # admin portal
```

## 5. Creating a staff account

Staff can't sign up through the app. Register a normal account in the patient
app, then promote it (2 = nurse, 3 = doctor, 4 = admin):

```
psql -p 5433 health -c "UPDATE users SET role_id = 4 WHERE email = 'you@example.com';"
```

## 6. Running the tests

```
cd womens_health_backend
source venv/bin/activate
pip install pytest httpx
python -m pytest tests -v
```

The tests use an in-memory stand-in for the database, so they don't need
Postgres running and never touch real data.

## 7. DEV_MODE: important before real use

No real email or SMS provider is connected. With `DEV_MODE=true`, verification
and password-reset codes are returned by the API and shown in a yellow banner
so the app can be demoed. **Anyone could read those codes**, so `DEV_MODE` must
be `false` before real patients use the app. With it `false`, codes are only
usable once a real email/SMS provider is wired in.

## Known limits

- Login and code attempt limits are kept in memory: they reset when the server
  restarts and don't cover multiple server processes.
- CORS allows `localhost` only. Add the real domain before deploying.
- Nia uses rule-based replies unless `ANTHROPIC_API_KEY` holds a funded key.
