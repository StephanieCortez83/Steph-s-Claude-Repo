-----------------------------------------------------------------------------------------
-- 03) DACS-2603 - Alter stored procedure - DeleteFacilityByFacilityName.SQL
-----------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [dbo].[DeleteFacilityByFacilityName]  
	 @FacilityName VARCHAR(50)
	,@TestMode INT = 0  -- 1 = in test mode: no deletes performed, 0 = will perform deletes
	,@ThrowException INT = 1
AS  
	PRINT('TestMode = ' + CAST(@TestMode AS VARCHAR(20)));

	IF @FacilityName IS NULL OR @FacilityName = ''
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'Error: Facility Name is invalid.';
		RETURN;
	END;

	DECLARE @FacilityId INT = (SELECT TOP 1 FACILITY_ID FROM FACILITY WITH (NOLOCK) WHERE [NAME] = @FacilityName)

	IF @FacilityId IS NULL OR @FacilityId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'Error: Facility Id is invalid.';
		RETURN;
	END;

	PRINT('FacilityName = ' + @FacilityName);
	PRINT('FacilityId = ' + CAST(@FacilityId AS VARCHAR(20)));
	
	PRINT('calling DeleteFacilityByFacilityId @FacilityId= ' + CAST(@FacilityId AS VARCHAR(20)));

	EXEC [dbo].[DeleteFacilityByFacilityId] @FacilityId = @FacilityId, @TestMode = @TestMode, @ThrowException = @ThrowException;

GO


/*
	see stored procedure DeleteServiceAgreementByServiceAgreementId for more info
testing on QA:	
BEGIN TRANSACTION
EXEC [dbo].[DeleteFacilityByFacilityName] @FacilityName = '????', @TestMode = 1, @ThrowException = 1;
-- COMMIT TRANSACTION
-- ROLLBACK TRANSACTION	



BEGIN TRANSACTION
EXEC [dbo].[DeleteFacilityByFacilityId] @FacilityId = 555130, @TestMode = 1, @ThrowException = 1;
-- COMMIT TRANSACTION
-- ROLLBACK TRANSACTION	

select top 10 * FROM facility where facility_id = 555130 order by facility_id desc
--select top 1000 * FROM facility order by facility_id desc

  
	 

BEGIN TRANSACTION
--EXEC [dbo].[DeleteFacilityByFacilityName] @FacilityName = 'Test DACS-2546a', @TestMode = 1, @ThrowException = 1;
EXEC [dbo].[DeleteFacilityByFacilityName] @FacilityName = 'Test DACS-2546a';
-- COMMIT TRANSACTION
-- ROLLBACK TRANSACTION	

select top 10 * FROM facility where [NAME] ='Test DACS-2546a' order by facility_id desc
--select top 1000 * FROM facility order by facility_id desc



*/

