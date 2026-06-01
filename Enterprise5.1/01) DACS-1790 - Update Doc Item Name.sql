-- NOTE, REVIEW THE EFFECTIVE DATE (on the insert) and the EXPIRATION_DATE (on the update) at the time this script is run.  
-- Lea or Stephanie should determine the date at the time of execution for production.
USE [RevCycleDB]
GO

DECLARE @StartDate datetime = '03/09/2015' 
DECLARE @ExpDate datetime = '03/08/2015'

INSERT INTO [dbo].[DOCUMENTATION_ITEM]
([SERVICE_AGREEMENT_ID],[NAME],[CATEGORY],[EFFECTIVE_DATE],[EXPIRATION_DATE],[CREATION_DATE_TIME],[CREATING_USER_PROFILE_ID],[CHANGED_DATE_TIME],[CHANGING_USER_PROFILE_ID],[DOCUMENTATION_DEFICIENCY_ID])
SELECT [SERVICE_AGREEMENT_ID],'External Records Reviewed From Unique Source Not Documented.',[CATEGORY],@StartDate,'12/31/2099',getDate(),6172,getdate(),6172,[DOCUMENTATION_DEFICIENCY_ID]
FROM DOCUMENTATION_ITEM 
WHERE NAME like '%Old records indicated but not documented%'
AND getdate() <= EXPIRATION_DATE

--expire the originals that were just copied and had the name modified.
UPDATE [DOCUMENTATION_ITEM]
SET EXPIRATION_DATE = @ExpDate
WHERE NAME like '%Old records indicated but not documented%'
AND getdate() <= EXPIRATION_DATE