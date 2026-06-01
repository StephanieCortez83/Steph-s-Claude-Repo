--------------------------------------------
-- 01) DACS-2485 - add modifier FS to [RevCycleDB].[dbo].[MODIFIER] table.SQL
--------------------------------------------
USE RevCycleDB
GO

-- expect 281 before addition -- SELECT TOP (1000) [MODIFIER_CD] ,[DESCRIPTION] FROM [RevCycleDB].[dbo].[MODIFIER];


INSERT INTO [RevCycleDB].[dbo].[MODIFIER]
	([MODIFIER_CD],[DESCRIPTION])
VALUES
	 ('FS','Medicare Patients: Split (or Shared) Service')

-- expect 282 after addition -- SELECT TOP (1000) [MODIFIER_CD] ,[DESCRIPTION] FROM [RevCycleDB].[dbo].[MODIFIER];

GO