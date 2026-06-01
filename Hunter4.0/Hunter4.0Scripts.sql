USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2800 - Insert ICD10 Code Into ICD_10_DIRECT_PICK Table.sql

---------------------------------------------------------------------------
--  DACS-2800  Add Z11.52 to commonly used codes in ICD_10_Direct_Pick Table
--  Affects the ChartDiagnosisCodesICD10.aspx page
---------------------------------------------------------------------------

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

-- End of 01) DACS-2800 - Insert ICD10 Code Into ICD_10_DIRECT_PICK Table.sql
GO

-- Start of 01) DACS-2836 - Add 'Analytic Reports - View SaaS Autonomous Coding' User Right and Groups.sql

----------------------------------------
-- 01) DACS-2836 - Add 'Analytic Reports - View SaaS Autonomous Coding' User Right and Groups.sql
----------------------------------------
GO

----------------------------------------
-- Step 1)  Get the needed variables in order to perform the task
----------------------------------------
DECLARE	@DEFINED_RIGHT_ID int =						162;  -- DEFINED_RIGHT_ID to be created
DECLARE	@DEFINED_RIGHT_NAME varchar(50) =			'Analytic Reports - View Autonomous Coding';
DECLARE	@DEFINED_RIGHT_DEFINITION varchar(2000) =	NULL;  -- If null, the stored procedure will use the @DEFINED_RIGHT_NAME value
DECLARE	@CREATING_USER_ID int =						10149; -- Marcus Ferrell
DECLARE @USER_GROUP_NAME varchar(35) =				'Analytic Rpt-View Autonomous Coding';

DECLARE	@DEFINED_RIGHT_RESULT_ID int;
DECLARE	@USER_GROUP_RESULT_ID int;
DECLARE	@GROUP_RIGHT_RESULT_ID int;


----------------------------------------
-- Step 2)  Create the DEFINED_RIGHT table entry
----------------------------------------
exec [dbo].[DEFINED_RIGHT_QUALIFY_INSERT]
	 @DEFINED_RIGHT_ID =				@DEFINED_RIGHT_ID
	,@DEFINED_RIGHT_NAME =				@DEFINED_RIGHT_NAME
	,@DEFINED_RIGHT_DEFINITION =		@DEFINED_RIGHT_DEFINITION
	,@DEFINED_RIGHT_CREATING_USER_ID =	@CREATING_USER_ID
	,@DEFINED_RIGHT_RESULT_ID =			@DEFINED_RIGHT_RESULT_ID OUTPUT;

--PRINT('DRTI_ID = ' + CAST(@DEFINED_RIGHT_RESULT_ID as VARCHAR(32)));


----------------------------------------
-- Step 3)  Create the associated USER_GROUP and GROUP_RIGHTS table entries
----------------------------------------
exec [dbo].[LINK_DEFINED_RIGHT_TO_USER_GROUP_NAME_AND_GROUP_RIGHTS_QUALIFY_INSERT]
	 @DEFINED_RIGHT_ID =	@DEFINED_RIGHT_RESULT_ID
	,@USER_GROUP_NAME =		@USER_GROUP_NAME
	,@CREATING_USER_ID =	@CREATING_USER_ID
	,@USER_GROUP_ID =		@USER_GROUP_RESULT_ID OUTPUT
	,@GROUP_RIGHTS_ID =		@GROUP_RIGHT_RESULT_ID OUTPUT

--PRINT('LDRTUGNAGRTI_UG_ID = ' + CAST(@USER_GROUP_RESULT_ID as VARCHAR(32)));
--PRINT('LDRTUGNAGRTI_GR_ID = ' + CAST(@GROUP_RIGHT_RESULT_ID as VARCHAR(32)));

-- End of 01) DACS-2836 - Add 'Analytic Reports - View SaaS Autonomous Coding' User Right and Groups.sql
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
