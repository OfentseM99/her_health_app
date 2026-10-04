-- add_patient_profile_fields.sql
-- Adds the remaining register-screen fields that had nowhere to go:
-- address, city, blood type, allergies, medical conditions, current
-- medications. Only used when a patient profile is created at
-- registration (i.e. full_name was sent) -- all nullable, all optional.
--
-- allergies, medical_conditions, and current_medications are JSONB
-- arrays of strings, e.g. ["Peanuts", "Latex", "Seasonal pollen"] --
-- matching the pattern already used for health_journeys.answers.

ALTER TABLE patients ADD COLUMN address VARCHAR(255);
ALTER TABLE patients ADD COLUMN city VARCHAR(100);
ALTER TABLE patients ADD COLUMN blood_type VARCHAR(10);
ALTER TABLE patients ADD COLUMN allergies JSONB;
ALTER TABLE patients ADD COLUMN medical_conditions JSONB;
ALTER TABLE patients ADD COLUMN current_medications JSONB;
