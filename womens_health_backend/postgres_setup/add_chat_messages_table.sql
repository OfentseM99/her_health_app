-- add_chat_messages_table.sql
-- Backs the Nia chatbot. Stores the full conversation per patient so it
-- can be reloaded when they come back.

CREATE TABLE chat_messages (
    id          SERIAL PRIMARY KEY,
    patient_id  INT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    sender      VARCHAR(10) NOT NULL CHECK (sender IN ('user', 'ai')),
    message     TEXT NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_messages_patient_id ON chat_messages(patient_id);
