-- ============================================================================
-- Data Station — add the rights that gate the self-service raw-data export.
--
--   172  AllowAccessToDataStation     see the Data Station menu item and run exports
--   173  AllowDataStationUnmaskedPhi  turn PHI masking off in a Data Station export
--
-- PLACEHOLDERS: confirm 172/173 are free in every environment, and renumber
-- this file (V044) to the next free Flyway version, before merging.
-- Idempotent: safe to re-run.
-- ============================================================================
INSERT INTO dbo.DEFINED_RIGHT (DEFINED_RIGHT_ID, NAME, CREATION_DATE_TIME, ALLOW_INHERITANCE, DEFINITION, IS_ADMIN)
SELECT 172, 'Allow Access To Data Station', GETDATE(), 1,
       'Can open the Data Station (Analytics menu) and export raw chart data. Also requires Can See Dashboard (32).', 0
WHERE NOT EXISTS (SELECT 1 FROM dbo.DEFINED_RIGHT WHERE DEFINED_RIGHT_ID = 172);

INSERT INTO dbo.DEFINED_RIGHT (DEFINED_RIGHT_ID, NAME, CREATION_DATE_TIME, ALLOW_INHERITANCE, DEFINITION, IS_ADMIN)
SELECT 173, 'Allow Data Station Unmasked PHI', GETDATE(), 1,
       'Can turn PHI masking off in a Data Station export (patient name, MRN, date of birth, long patient ID, free-text notes).', 0
WHERE NOT EXISTS (SELECT 1 FROM dbo.DEFINED_RIGHT WHERE DEFINED_RIGHT_ID = 173);
GO
