-- add_verification_fields.sql
-- Adds phone number and dual-channel (email + phone) verification code
-- support to the users table.
--
-- Design notes:
-- - is_verified (already existed) now specifically means "email verified".
-- - is_phone_verified is new, parallel to it.
-- - A user counts as fully verified once BOTH are true -- the frontend
--   and /auth/verify enforce this, not a database constraint.
-- - Codes are 6-digit strings with a 10-minute expiry, checked against
--   *_code_expires_at. Expired or mismatched codes are rejected.
-- - This is a SIMULATED verification system: no real email or SMS
--   provider is connected. The codes are generated and checked for
--   real, but /auth/register and /auth/resend-codes currently return
--   the codes directly in the API response so the frontend can display
--   them on-screen for development/demo purposes. Before this goes to
--   real users, /auth/register and /auth/resend-codes need to actually
--   call an email provider and an SMS provider instead of returning
--   the codes in the response body.

ALTER TABLE users ADD COLUMN phone VARCHAR(30);

ALTER TABLE users ADD COLUMN email_code VARCHAR(6);
ALTER TABLE users ADD COLUMN email_code_expires_at TIMESTAMP;

ALTER TABLE users ADD COLUMN phone_code VARCHAR(6);
ALTER TABLE users ADD COLUMN phone_code_expires_at TIMESTAMP;

ALTER TABLE users ADD COLUMN is_phone_verified BOOLEAN NOT NULL DEFAULT FALSE;
