----------------------------------------
-- 01) DACS-2987 - Add Defined Right - Analytic Reports - Distribution.sql
----------------------------------------
USE [RevCycleDB]
GO

----------------------------------------
-- Step 1)  Get the needed variables in order to perform the task
----------------------------------------
DECLARE	@DEFINED_RIGHT_ID int =						164;  -- DEFINED_RIGHT_ID to be created
DECLARE	@DEFINED_RIGHT_NAME varchar(50) =			'Analytic Reports - Distribution';
DECLARE	@DEFINED_RIGHT_DEFINITION varchar(2000) =	NULL;  -- If null, the stored procedure will use the @DEFINED_RIGHT_NAME value
DECLARE	@CREATING_USER_ID int =						10149; -- Marcus Ferrell
DECLARE @USER_GROUP_NAME varchar(35) =				'Analytic Reports - Distribution';

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

