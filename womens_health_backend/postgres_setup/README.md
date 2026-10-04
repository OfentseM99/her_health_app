# Local PostgreSQL Setup

Alternative to Buhle's MySQL setup, for anyone who wants to run the backend against a local Postgres database.

## Files here

schema_postgres.sql creates all 5 tables (roles, users, patients, services, appointments) plus seed data, matching what the routers already expect.

database.py is a drop-in replacement for config/database.py. Same function name and dictionary-style row access as the MySQL version, so none of the router files need to change.

cleanup_duplicates.sql fixes duplicate seed rows if the schema file gets run more than once.

## Setup steps

Install Postgres, either Postgres.app (GUI, no terminal needed, postgresapp.com) or brew install postgresql@16.

Create the database: createdb -p PORT health (default port is 5432, check Postgres.app's server list for the actual port if you changed it to avoid a conflict).

Run the schema: psql -p PORT health -f womens_health_backend/postgres_setup/schema_postgres.sql

Copy the Postgres database.py into place: cp womens_health_backend/postgres_setup/database.py womens_health_backend/config/database.py

Create .env in womens_health_backend/ (this file is gitignored, never commit it) with: DB_HOST=localhost, DB_PORT=your port, DB_NAME=health, DB_USER=your macOS username, DB_PASSWORD blank, and JWT_SECRET=any long random string.

Important: the code reads JWT_SECRET, not SECRET_KEY. Using the wrong variable name causes a TypeError Expected a string value when logging in.

Set up a virtual environment, since Homebrew Python is externally managed and a plain pip install will fail without one: python3.12 -m venv venv, then source venv/bin/activate, then pip install fastapi uvicorn psycopg2-binary python-dotenv passlib[bcrypt] python-jose pyjwt email-validator.

Run it: uvicorn main:app --reload

Test it at http://127.0.0.1:8000/docs, register a user, log in, then hit GET /database-test with the token to confirm the connection works.

## Gotchas we hit getting this working

If Postgres.app says port already in use, something else (often a Homebrew Postgres instance) is already on 5432. Just switch Postgres.app to a different port, like 5433, in its server settings.

Python 3.9 from Xcode Command Line Tools cannot run this code. The routers use str | None syntax, which needs Python 3.10 or newer.

If uvicorn will not start with Address already in use, another terminal window still has a server running on port 8000. Kill it with: lsof -ti:8000 followed by xargs kill -9
