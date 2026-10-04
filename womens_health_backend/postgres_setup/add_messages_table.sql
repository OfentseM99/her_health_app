-- add_messages_table.sql
-- One thread per patient. Any staff member (role 2/3/4) can view and
-- reply to any patient's thread -- this models a small practice where
-- whoever's available answers, not a strict one-doctor-per-patient
-- assignment. sender_user_id records exactly who sent each message,
-- even though staff replies aren't separated into per-staff threads.

CREATE TABLE messages (
    id              SERIAL PRIMARY KEY,
    patient_id      INT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    sender_role     VARCHAR(10) NOT NULL CHECK (sender_role IN ('patient', 'staff')),
    sender_user_id  INT NOT NULL REFERENCES users(id),
    message         TEXT NOT NULL,
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_patient_id ON messages(patient_id);
