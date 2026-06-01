--------------------------------------------------------------------
-- 01) DACS-2246 - Populate [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] .sql
--------------------------------------------------------------------
USE RevCycleDB
GO

-- Step 1:  Set the target SAID for the specific service agreement to update.
-- qa is (Service Agreement ID = 555115 Facility ID = 555114) prod is (Service Agreement ID = 1960 Facility ID = 2063)
DECLARE @SAID int = 555115;

-- Step 2:  Set the user Id of the account performing the actions
DECLARE @UID int = 12089;

/*
see who the SAID is related to, if desired as a check.  [description] should be one ofn the San Mateo Facilities
  select * from service_Agreement where service_Agreement_id = @SAID;

see what records already exist, if desired as a check.
  select * FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS]
  WHERE [SERVICE_AGREEMENT_ID] = @SAID
  ORDER BY [FINANCIAL_CLASS_ID];
*/

-- Step 3:  Remove all existing records
-- BEGIN TRAN;
DELETE FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS]
  WHERE [SERVICE_AGREEMENT_ID] = @SAID;
-- expect 0 affected  
-- COMMIT TRAN;
-- ROLLBACK TRAN 
 
-- Step 4: insert new records
-- BEGIN TRAN;
DECLARE @InsertionDate DATETIME = '06/01/2023';

INSERT INTO [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS]
	(FINANCIAL_CLASS_CD,[DESCRIPTION],SERVICE_AGREEMENT_ID,CREATION_DATE_TIME,CREATING_USER_PROFILE_ID,CHANGED_DATE_TIME,CHANGING_USER_PROFILE_ID)
VALUES
	-- (FINANCIAL_CLASS_CD,[DESCRIPTION],@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	 ('B'	,'Medi-Cal HPSM',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('C'	,'Medi-Cal',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('D'	,'County Programs',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('E'	,'Charity Care',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('F'	,'Full Pay',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('G'	,'Govn Non Manage Care',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('H'	,'Medicare-HMO',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('I'	,'Insurance',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('J'	,'Jail',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('K'	,'Workmans Comp',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('M'	,'Medicare',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('N'	,'County Indigent',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('O'	,'Govn Manage Care',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('P'	,'Medicare Psy IP',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('U'	,'Undetermined',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('W'	,'Well Program',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('Z'	,'Local/State Fed',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('1'	,'Legal Pending B/D',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('2'	,'Well Program B/D',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('3'	,'Full Pay-Bad Debt',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('4'	,'Medicare Bad Debt',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('5'	,'Ins/Work Comp-B/D',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('6'	,'Medi-Cal Bad Debt',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('7'	,'Legal Pending B/D',@SAID,@InsertionDate,@UID,@InsertionDate,@UID);
-- Expect 24 affected
-- COMMIT TRAN;
-- ROLLBACK TRAN 


  


