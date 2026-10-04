-- schema_postgres.sql
-- Her Health Companion, PostgreSQL version
-- Matches the queries already written in auth.py, patients.py, appointments.py, services.py
-- Run this against your local Postgres database before starting the API.

-- ---------------------------------------------------------------------------
-- roles
-- ---------------------------------------------------------------------------
CREATE TABLE roles (
      id   INT PRIMARY KEY,
      name VARCHAR(50) NOT NULL UNIQUE
  );

INSERT INTO roles (id, name) VALUES
    (1, 'patient'),
    (2, 'nurse'),
    (3, 'doctor'),
    (4, 'admin');

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
CREATE TABLE users (
      id            SERIAL PRIMARY KEY,
      role_id       INT NOT NULL REFERENCES roles(id),
      email         VARCHAR(255) NOT NULL UNIQUE,
      password_hash VARCHAR(255) NOT NULL,
      is_verified   BOOLEAN NOT NULL DEFAULT FALSE,
      is_active     BOOLEAN NOT NULL DEFAULT TRUE,
      created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  );

-- ---------------------------------------------------------------------------
-- patients
-- ---------------------------------------------------------------------------
CREATE TABLE patients (
      id                       SERIAL PRIMARY KEY,
      user_id                  INT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
      first_name               VARCHAR(100) NOT NULL,
      last_name                VARCHAR(100) NOT NULL,
      phone                    VARCHAR(30),
      date_of_birth            DATE,
      emergency_contact_name   VARCHAR(150),
      emergency_contact_phone  VARCHAR(30),
      created_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  );

-- ---------------------------------------------------------------------------
-- services
-- ---------------------------------------------------------------------------
CREATE TABLE services (
      id          SERIAL PRIMARY KEY,
      name        VARCHAR(150) NOT NULL,
      description TEXT,
      is_active   BOOLEAN NOT NULL DEFAULT TRUE
  );

-- ---------------------------------------------------------------------------
-- appointments
-- ---------------------------------------------------------------------------
CREATE TABLE appointments (
      id              SERIAL PRIMARY KEY,
      patient_id      INT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      requested_date  DATE NOT NULL,
      requested_time  TIME NOT NULL,
      reason          TEXT,
      status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                      CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
      notes           TEXT,
      created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  );

CREATE INDEX idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX idx_patients_user_id ON patients(user_id);

-- ---------------------------------------------------------------------------
-- keep updated_at fresh on every UPDATE
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_patients_updated_at
    BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_appointments_updated_at
    BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- seed data
-- ---------------------------------------------------------------------------
INSERT INTO services (name, description, is_active) VALUES
    ('General Consultation', 'General womens health check-up', TRUE),
    ('Prenatal Care', 'Pregnancy monitoring and check-ups', TRUE),
    ('Family Planning', 'Contraception and reproductive health guidance', TRUE);
