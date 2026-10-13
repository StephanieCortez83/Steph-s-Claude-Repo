-- Undo for V044: remove the Data Station rights.
-- (Any USER_GROUP_RIGHT rows pointing at them must be removed first — adjust to the real FK table name.)
DELETE FROM dbo.DEFINED_RIGHT WHERE DEFINED_RIGHT_ID IN (172, 173);
GO
