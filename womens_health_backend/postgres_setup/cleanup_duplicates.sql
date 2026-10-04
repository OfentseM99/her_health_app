-- Removes duplicate rows in services, keeping only the earliest (lowest id)
-- for each unique service name.
DELETE FROM services
WHERE id NOT IN (
    SELECT MIN(id)
    FROM services
    GROUP BY name
);

-- Confirm only 3 rows remain
SELECT * FROM services;
