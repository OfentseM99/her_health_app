"""
config/database.py (PostgreSQL version)

Drop-in replacement for Buhle's MySQL version — keeps the exact same
function name and dictionary-style row access, so routers.py files
don't need to change how they call it. Uses psycopg2's RealDictCursor
to mimic mysql.connector's cursor(dictionary=True) behaviour.
"""

import os
from dotenv import load_dotenv
import psycopg2
from psycopg2.extras import RealDictCursor

load_dotenv()


class _CompatConnection:
    """
    Thin wrapper so existing routers written for mysql.connector keep
    working unchanged. Those routers call:

        connection.cursor(dictionary=True)

    which mysql.connector supports but psycopg2 does not — psycopg2
    raises a TypeError on the unexpected `dictionary` kwarg. This
    wrapper strips that kwarg and always hands back a dict-style
    (RealDictCursor) cursor, so `row["column_name"]` access keeps
    working exactly as before. Everything else (commit, close,
    is_connected, etc.) passes straight through to the real
    connection.
    """

    def __init__(self, connection):
        self._connection = connection

    def cursor(self, *args, **kwargs):
        kwargs.pop("dictionary", None)  # swallow the MySQL-only kwarg
        return self._connection.cursor(cursor_factory=RealDictCursor)

    def is_connected(self):
        # psycopg2 has no is_connected(); main.py's /database-test route
        # calls this, so approximate it via the connection's closed flag.
        return self._connection.closed == 0

    def __getattr__(self, name):
        # Delegate anything else (commit, close, rollback, ...) untouched.
        return getattr(self._connection, name)


def get_database_connection():
    """
    Returns a Postgres connection that behaves like the MySQL one
    Buhle's routers were written against — same function name, same
    dictionary-style row access, same is_connected() check.
    """
    raw_connection = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
    )
    return _CompatConnection(raw_connection)
