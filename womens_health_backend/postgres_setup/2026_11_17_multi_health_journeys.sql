
-- Her Health: Support multiple saved health journeys.
-- Only one journey may be active per patient.
-- Existing journeys and tracking entries are preserved.

BEGIN;

-- Add the active journey indicator.
ALTER TABLE health_journeys
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- Remove the old restriction allowing only one journey per patient.
ALTER TABLE health_journeys
DROP CONSTRAINT IF EXISTS health_journeys_patient_id_key;

-- Ensure each patient can have only one active journey.
CREATE UNIQUE INDEX IF NOT EXISTS
idx_health_journeys_one_active_per_patient
ON health_journeys (patient_id)
WHERE is_active = TRUE;

-- Make patient journey history easier to retrieve.
CREATE INDEX IF NOT EXISTS
idx_health_journeys_patient_created
ON health_journeys (patient_id, created_at DESC);

COMMIT;
