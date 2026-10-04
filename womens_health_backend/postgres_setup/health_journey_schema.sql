-- health_journey_schema.sql
-- Backs the health_setup_screen.dart / journey_questions_screen.dart flow.
-- Add this to your existing schema (roles, users, patients, services, appointments).

CREATE TABLE health_journeys (
      id           SERIAL PRIMARY KEY,
      patient_id   INT NOT NULL UNIQUE REFERENCES patients(id) ON DELETE CASCADE,
      journey_type VARCHAR(30) NOT NULL
                   CHECK (journey_type IN (
                       'pregnancy_care',
                       'menstrual_health',
                       'postpartum_recovery',
                       'general_health',
                       'cosmetic_gynecology'
                   )),
      answers      JSONB NOT NULL DEFAULT '{}',
      created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  );

CREATE TABLE health_journey_entries (
      id           SERIAL PRIMARY KEY,
      journey_id   INT NOT NULL REFERENCES health_journeys(id) ON DELETE CASCADE,
      patient_id   INT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      entry_date   DATE NOT NULL DEFAULT CURRENT_DATE,
      pain_level   VARCHAR(20),
      mood         VARCHAR(20),
      data         JSONB NOT NULL DEFAULT '{}',
      created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  );

CREATE INDEX idx_health_journeys_patient_id ON health_journeys(patient_id);
CREATE INDEX idx_journey_entries_patient_id ON health_journey_entries(patient_id);
CREATE INDEX idx_journey_entries_journey_id ON health_journey_entries(journey_id);
CREATE INDEX idx_journey_entries_date ON health_journey_entries(entry_date);

CREATE TRIGGER trg_health_journeys_updated_at
    BEFORE UPDATE ON health_journeys
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
