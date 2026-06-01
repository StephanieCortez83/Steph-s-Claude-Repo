----------------------------------------------------
-- 01) DACS-2928 - SQL Script - MultiCare facility expiration script - take 2.SQL
----------------------------------------------------
USE [RevCycleDB]
GO

/*
expiration date: 12/31/23

facility list:
	(935,936,1276,939,1168,1152,937,1215,934,1277,938,1628,1169,1928,1170)

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

select top 10 SIGN_ON_ID,LAST_NAME,FIRST_NAME,USER_PROFILE_ID from user_profile where last_name LIKE 'Cletus%'

user list:
	('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR',
	'PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM',
	'GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','SRAGHURAM','ARAGHURAMAN',
	'NRANJITH','NDRODDA','GVAITY1','BVISWANATHAN1','SYELLAPU')

	AADAM	=	Adam, Angela
	SAKULA	=	Akula, Swathi
	YALLAKONDA	=	Allakonda, Yogeshwar
	JANNEPU	=	ANNEPU, JYOTHINADH
	SARABALE	=	Arabale, Samarth
	SBANE	=	Bane, Samiksha Darshan
	RRBOMMANA	=	Bommana, Rajasekhara Reddy
	JCLETUS	=	Cletus, John
	GPRASAD	=	DURGAPRASAD, GADUSULA
	SGHANEKAR	=	Ghanekar, Swapnil
	PGUNDI	=	GUNDI, PRAVEEN
	MHARRINGTON1	=	Harrington, Michelle
	SHEGGER	=	HEGGER, SUSAN
	MIMTYAZUDDIN	=	IMTYAZUDDIN, MOHAMMAD
	SJAGADALE	=	Jagadale, Shubhangi
	AJEYARAM	=	Jeyaram, Alageshwari
	GKANKAL	=	Kankal, Gopinath
	HKATEPALLI	=	Katepalli, Harikrishna
	MKUNCHE	=	KUNCHE, MADHURI
	SMALI1	=	Mali, Supriya
	ANEERUDU	=	Neerudu, Ashwini
	JPATIL	=	PATIL, JANHAVI
	SRAGHURAM	=	RAGHURAM, SUGANYA
	ARAGHURAMAN	=	Raghuraman, Archana
	NRANJITH	=	Ranjith, Nara
	NDRODDA	=	Rodda, Nirmala
	SSHINDE	=	Shinde, Sonal Tanaji
	GVAITY1	=	VAITY, GITANJALI
	BVISWANATHAN1	=	VISWANATHAN, BHARATHI
	SYELLAPU	=	YELLAPU, SRINIVASA RAO	
*/

-------------------------
-- begin tran; -- testing
-------------------------

DECLARE @expirationDate datetime = '12-31-2023';
DECLARE @changedDate datetime = GETDATE();
DECLARE @changingUserId INT = 10149;   -- MFERRELL
DECLARE @changingUserName VARCHAR(50) = 'MFERRELL';

--backup the target table
exec [dbo].[Maintenance_BackupTable] @SrcTable = 'FACILITY_USER_AUTHORIZATION', @DestTable = 'FACILITY_USER_AUTHORIZATION_DACS-2928';

-- User profile id list to process: expect 11 for QA, 29 for production
SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN (
	'AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR',
	'PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM',
	'GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','SRAGHURAM','ARAGHURAMAN',
	'NRANJITH','NDRODDA','GVAITY1','BVISWANATHAN1','SYELLAPU'
	);

-- SELECT TOP 1000 * FROM [FACILITY_USER_AUTHORIZATION] WHERE user_profile_id = @targetUId ORDER BY facility_id ASC
DECLARE @countFacsBeforeUpdate INT = (
	SELECT COUNT(*) 
	FROM [FACILITY_USER_AUTHORIZATION] 
	WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN (
		'AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR',
		'PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM',
		'GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','SRAGHURAM','ARAGHURAMAN',
		'NRANJITH','NDRODDA','GVAITY1','BVISWANATHAN1','SYELLAPU'))
	AND [EFFECTIVE_DATE] <= GETDATE() 
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
	);
	
-- expect 11 for QA, 367 for production
SELECT '@countFacsBeforeUpdate' = @countFacsBeforeUpdate;

DECLARE @countFacsToUpdate INT = (
	SELECT COUNT(*) 
		FROM [FACILITY_USER_AUTHORIZATION] 
		WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN (
			'AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR',
				'PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM',
				'GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','SRAGHURAM','ARAGHURAMAN',
				'NRANJITH','NDRODDA','GVAITY1','BVISWANATHAN1','SYELLAPU'		
		)) 
		AND [EFFECTIVE_DATE] <= GETDATE() 
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
		AND [FACILITY_ID] IN (935,936,1276,939,1168,1152,937,1215,934,1277,938,1628,1169,1928,1170) 
	);

-- expect 11 for QA, 367 for production
SELECT '@countFacsToUpdate' = @countFacsToUpdate;

PRINT('performing update...')

UPDATE [FACILITY_USER_AUTHORIZATION]
	SET [EXPIRATION_DATE] = @expirationDate
		, [CHANGED_DATE_TIME] = @changedDate
		, [CHANGING_USER_PROFILE_ID] = @changingUserId
	WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN (
		'AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR',
			'PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM',
			'GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','SRAGHURAM','ARAGHURAMAN',
			'NRANJITH','NDRODDA','GVAITY1','BVISWANATHAN1','SYELLAPU'
		))
	AND [EFFECTIVE_DATE] <= GETDATE() 
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
	AND [FACILITY_ID] IN (935,936,1276,939,1168,1152,937,1215,934,1277,938,1628,1169,1928,1170);

DECLARE @countFacsAfterUpdate INT = (
	SELECT COUNT(*) FROM [FACILITY_USER_AUTHORIZATION] 
	WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN (
		'AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR',
			'PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM',
			'GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','SRAGHURAM','ARAGHURAMAN',
			'NRANJITH','NDRODDA','GVAITY1','BVISWANATHAN1','SYELLAPU'
		))
		AND [EFFECTIVE_DATE] <= GETDATE() 
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
	);
	
-- expect 11 for QA, 367 (but cannot test this due to lack of write access) for production
SELECT '@countFacsAfterUpdate' = @countFacsAfterUpdate;

-- log the action :[dbo].[Maintenance_LogAdminAction]
DECLARE @comment VARCHAR(500) = 'Expired Facility Authorization records for user list. Stats: [start,updated,result] :: [ ' +  
	CAST(@countFacsBeforeUpdate AS VARCHAR(50)) + ' , ' +  
	CAST(@countFacsToUpdate AS VARCHAR(50)) + ' , ' +  
	CAST(@countFacsAfterUpdate AS VARCHAR(50)) + ']';
DECLARE @stateString VARCHAR(MAX) = 'Facility List: 935,936,1276,939,1168,1152,937,1215,934,1277,938,1628,1169,1928,1170. User Sign On List: AADAM,SAKULA,YALLAKONDA,JANNEPU,SARABALE,SBANE,RRBOMMANA,JCLETUS,GPRASAD,SGHANEKAR,PGUNDI,MHARRINGTON1,SHEGGER,MIMTYAZUDDIN,SJAGADALE,AJEYARAM,GKANKAL,HKATEPALLI,MKUNCHE,SMALI1,ANEERUDU,JPATIL,SRAGHURAM,ARAGHURAMAN,NRANJITH,NDRODDA,GVAITY1,BVISWANATHAN1,SYELLAPU';

exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  935, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  936, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1276, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  939, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1168, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1152, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  937, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1215, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  934, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1277, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  938, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1628, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1169, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1928, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1170, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;

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