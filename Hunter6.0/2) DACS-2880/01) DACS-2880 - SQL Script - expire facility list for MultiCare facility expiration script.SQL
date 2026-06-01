----------------------------------------------------
-- 01) DACS-2880 - SQL Script - expire facility list for MultiCare facility expiration script.SQL
----------------------------------------------------
USE [RevCycleDB]
GO

/*
expiration date: 12/31/23

facility list:
	(1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288)

	MultiCare Allenmore Hospital - 935/1061
	MultiCare Auburn Med Center - 936/1062
	MultiCare Bonney Lake - 1276/1377
	MultiCare Covington Medical Center - 939/1059
	MultiCare Deaconess Hospital - 1168/1268
	MultiCare Deaconess Hospital North ED - 1152/1267
	MultiCare Good Samaritan Hospital - 937/1063
	MultiCare Good Samaritan Hospital - Parkland - 1215/1328
	MultiCare Mary Bridge Childrens Hospital - 934/1060
	MultiCare South Hill - 1277/1378
	MultiCare Tacoma General Hospital - 938/1064
	MultiCare TG Federal Way ED - 1628/1750
	MultiCare Valley Hospital - 1169/1269
	MultiCare Yakima Memorial Hospital - 1928/2031
	PRACTICE CHARTS - MultiCare - 1170/1288

user list:
	('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU')

	Adam, Angela				= AADAM
	Akula, Swathi				= SAKULA
	Allakonda, Yogeshwar		= YALLAKONDA
	ANNEPU, JYOTHINADH			= JANNEPU
	Arabale, Samarth			= SARABALE
	Bane, Samiksha Darshan		= SBANE
	Bommana, Rajasekhara Reddy	= RRBOMMANA
	Cletus, John				= JCLETUS
	DURGAPRASAD, GADUSULA		= GPRASAD
	Ghanekar, Swapnil			= SGHANEKAR
	GUNDI, PRAVEEN				= PGUNDI
	Harrington, Michelle		= MHARRINGTON1
	HEGGER, SUSAN				= SHEGGER
	IMTYAZUDDIN, MOHAMMAD		= MIMTYAZUDDIN
	Jagadale, Shubhangi			= SJAGADALE
	Jeyaram, Alageshwari		= AJEYARAM
	Kankal, Gopinath			= GKANKAL
	Katepalli, Harikrishna		= HKATEPALLI
	KUNCHE, MADHURI				= MKUNCHE
	Mali, Supriya				= SMALI1
	Neerudu, Ashwini			= ANEERUDU
	PATIL, JANHAVI				= JPATIL
	Porter, Debbie				= DEPORTER
	RAGHURAM, SUGANYA			= SRAGHURAM
	Raghuraman, Archana			= ARAGHURAMAN
	Ranjith, Nara				= NRANJITH
	Rodda, Nirmala				= NDRODDA
	SANDERS, MEREDITH			= MESANDERS
	Shinde, Sonal Tanaji		= SSHINDE
	VAITY, GITANJALI			= GVAITY1
	VISWANATHAN, BHARATHI		= BVISWANATHAN1
	YELLAPU, SRINIVASA RAO		= SYELLAPU
*/

-------------------------
-- begin tran; -- testing
-------------------------

DECLARE @expirationDate datetime = '12-31-2023';
DECLARE @changedDate datetime = GETDATE();
DECLARE @changingUserId INT = 10149;   -- MFERRELL
DECLARE @changingUserName VARCHAR(50) = 'MFERRELL';

--backup the target table
exec [dbo].[Maintenance_BackupTable] @SrcTable = 'FACILITY_USER_AUTHORIZATION', @DestTable = 'FACILITY_USER_AUTHORIZATION_DACS-2880';

-- User profile id list to process:
SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN ('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU');

-- SELECT TOP 1000 * FROM [FACILITY_USER_AUTHORIZATION] WHERE user_profile_id = @targetUId ORDER BY facility_id ASC
DECLARE @countFacsBeforeUpdate INT = (
	SELECT COUNT(*) 
	FROM [FACILITY_USER_AUTHORIZATION] 
	WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN ('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU'))
	AND [EFFECTIVE_DATE] <= GETDATE() 
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
	);
	
-- expect 26 for QA, 421 for production
SELECT '@countFacsBeforeUpdate' = @countFacsBeforeUpdate;

DECLARE @countFacsToUpdate INT = (
	SELECT COUNT(*) 
		FROM [FACILITY_USER_AUTHORIZATION] 
		WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN ('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU')) 
		AND [EFFECTIVE_DATE] <= GETDATE() 
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
		AND [FACILITY_ID] IN (1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288) 
	);

-- expect 13 for QA, 416 for production
SELECT '@countFacsToUpdate' = @countFacsToUpdate;

PRINT('performing update...')

UPDATE [FACILITY_USER_AUTHORIZATION]
	SET [EXPIRATION_DATE] = @expirationDate
		, [CHANGED_DATE_TIME] = @changedDate
		, [CHANGING_USER_PROFILE_ID] = @changingUserId
	WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN ('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU'))
	AND [EFFECTIVE_DATE] <= GETDATE() 
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
	AND [FACILITY_ID] IN (1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288);

DECLARE @countFacsAfterUpdate INT = (
	SELECT COUNT(*) FROM [FACILITY_USER_AUTHORIZATION] 
	WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN ('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU'))
		AND [EFFECTIVE_DATE] <= GETDATE() 
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
	);
	
-- expect 26 for QA, 5 (but cannot test this due to lack of write access) for production
SELECT '@countFacsAfterUpdate' = @countFacsAfterUpdate;

-- log the action :[dbo].[Maintenance_LogAdminAction]
DECLARE @comment VARCHAR(500) = 'Expired Facility Authorization records for user list. Stats: [start,updated,result] :: [ ' +  
	CAST(@countFacsBeforeUpdate AS VARCHAR(50)) + ' , ' +  
	CAST(@countFacsToUpdate AS VARCHAR(50)) + ' , ' +  
	CAST(@countFacsAfterUpdate AS VARCHAR(50)) + ']';
DECLARE @stateString VARCHAR(MAX) = 'Facility List: 1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288. User Sign On List: AADAM,SAKULA,YALLAKONDA,JANNEPU,SARABALE,SBANE,RRBOMMANA,JCLETUS,GPRASAD,SGHANEKAR,PGUNDI,MHARRINGTON1,SHEGGER,MIMTYAZUDDIN,SJAGADALE,AJEYARAM,GKANKAL,HKATEPALLI,MKUNCHE,SMALI1,ANEERUDU,JPATIL,DEPORTER,SRAGHURAM,ARAGHURAMAN,NRANJITH,NDRODDA,MESANDERS,SSHINDE,GVAITY1,BVISWANATHAN1,SYELLAPU';

exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1061, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1062, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1377, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1059, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1268, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1267, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1063, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1328, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1060, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1378, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1064, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1750, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1269, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  2031, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1288, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
	
/*
-------------------------
-- testing
-- rollback tran;
-- commit tran;	
-------------------------

FACILITY_AUTH_ID	FACILITY_ID	USER_PROFILE_ID	CREATION_DATE_TIME	CREATING_USER_PROFILE_ID	CHANGED_DATE_TIME	CHANGING_USER_PROFILE_ID	EFFECTIVE_DATE	EXPIRATION_DATE	CAN_APPROVE_CHARTS	AUDIT_APPROVAL_RATE	NUMBER_COMPLETED	AUDIT_PROCEDURE_RATE	PROCEDURE_NUMBER_COMPLETED	ACCOUNT_MANAGER_IND	AUDIT_INFUSION_RATE	INFUSION_NUMBER_COMPLETED	AUDIT_OBSERVATION_RATE	OBSERVATION_NUMBER_COMPLETED	CODER_AUTHORIZED_SERVICE_CODE	FACILITY_PROF_ID	SECOND_LEVEL_AUDIT_APPROVAL_RATE	FORCE_AUDIT	ACTIVE_CHART_ID	FACILITY_USER_AUTHORIZATION_EXPIRATION_DATE_CHANGE_REASON_ID	FACILITY_USER_AUTHORIZATION_EXPIRATION_DATE_CHANGE_OTHER_REASON	EMR_ACCESS_EFFECTIVE_DATE	EMR_ACCESS_EXPIRATION_DATE	ALLOW_EMR_ACCESS	EMR_ACCESS_USER_PROFILE_ID
1	1	1	2007-10-28 19:09:00.000	0	2010-12-20 22:38:00.000	696	2003-01-01 00:00:00.000	2099-12-31 00:00:00.000	1	0	3	0	0	NULL	0	0	0	0	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL

select top 10 * from audit_log order by audit_log_id desc;
[drcmsqlaz03].[RevCycleDB].[dbo].
*/	