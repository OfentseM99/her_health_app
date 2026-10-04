-- add_password_reset_fields.sql
-- Backs the forgot-password flow. A single code (not two, unlike
-- registration verification) since the user picks ONE channel to send
-- it to at request time -- there's no need to generate both.

ALTER TABLE users ADD COLUMN reset_code VARCHAR(6);
ALTER TABLE users ADD COLUMN reset_code_expires_at TIMESTAMP;
