---------------------------------------------------------------------------
--  DACS-2800  Add Z11.52 to commonly used codes in ICD_10_Direct_Pick Table
--  Affects the ChartDiagnosisCodesICD10.aspx page
---------------------------------------------------------------------------

USE [RevCycleDB]
GO


INSERT INTO [dbo].[ICD_10_DIRECT_PICK]
(
	[ICD_10_CODE]
	,[DIRECT_PICK_TYPE]
	,[SEQUENCE_NUMBER]
	,[SHORT_DESCRIPTION]
	,[LONG_DESCRIPTION]
	,[EFFECTIVE_DATE]
	,[EXPIRATION_DATE]
)
VALUES
(	'Z11.52'								-- ICD_10_CODE - varchar(10)
	,2										-- DIRECT_PICK_TYPE - int  (External Cause /LTU section)
	,76										-- SEQUENCE_NUMBER - int (shooting for this specific location in the list)
	,'Encounter for screening for COVID-19' -- SHORT_DESCRIPTION - varchar(100)
	,'Encounter for screening for COVID-19' -- LONG_DESCRIPTION - varchar(500)
	,'1/1/2015'								-- EFFECTIVE_DATE - datetime  (going back further to make sure it shows up in existing charts for testing purposes)
	,'12/31/2099'							-- EXPIRATION_DATE - datetime
	)

GO

