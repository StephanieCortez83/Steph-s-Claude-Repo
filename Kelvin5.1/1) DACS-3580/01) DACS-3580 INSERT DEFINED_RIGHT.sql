------------------------------------------------------------------------------------
-- 01) DACS-3580 - INSERT New Right for Time Recon
------------------------------------------------------------------------------------

USE RevCycleDB;
GO

INSERT INTO dbo.DEFINED_RIGHT 
(
	DEFINED_RIGHT_ID, 
	NAME, 
	CREATION_DATE_TIME, 
	CREATING_USER_PROFILE_ID,
	CHANGED_DATE_TIME, 
	CHANGING_USER_PROFILE_ID, 
	ALLOW_INHERITANCE, 
	DEFINITION,
    IS_ADMIN
)
VALUES 
(
	168, 
	'Allow Access to Time Recon',
	GETDATE(), 
	10149, 
	GETDATE(), 
	10149, 
	1, 
	'Allow user access to Time Recon Menu',
    0
);
