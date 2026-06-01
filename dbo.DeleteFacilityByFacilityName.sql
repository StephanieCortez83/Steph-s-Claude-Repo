SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [dbo].[DeleteFacilityByFacilityName]  
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
