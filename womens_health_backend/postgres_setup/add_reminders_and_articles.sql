-- add_reminders_and_articles.sql
-- Safe to re-run: IF NOT EXISTS means a second run changes nothing.

-- A patient's own reminders (appointments, medication, anything).
CREATE TABLE IF NOT EXISTS reminders (
    id          SERIAL PRIMARY KEY,
    patient_id  INT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    title       VARCHAR(200) NOT NULL,
    notes       TEXT,
    remind_at   TIMESTAMP NOT NULL,
    is_done     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reminders_patient_id ON reminders(patient_id);

-- Health articles written by staff in the admin portal, read by patients.
CREATE TABLE IF NOT EXISTS articles (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    category        VARCHAR(50),
    body            TEXT NOT NULL,
    author_user_id  INT NOT NULL REFERENCES users(id),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
