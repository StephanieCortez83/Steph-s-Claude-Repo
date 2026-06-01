------------------------------------------------------------------------------------
-- 01) DACS-3201 - Create of Alter Stored Procedure - [dbo].[GetServiceLevelCD].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[GetServiceLevelCD] 
 	 @DateOfService DATE
	,@ServiceClassCD VARCHAR(10)
	,@ServiceGuidelineID INT
	,@ServiceTypeCD INT
	,@Cat1Rating INT
	,@Cat2Rating INT
	,@Cat3Rating INT
AS
BEGIN
	----------------
	-- Initially created by Mr. Burge CDBT-330
	-- Modified by pippin DACS-3201
	----------------

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP 1
		[SERVICE_LEVEL_CD]
	FROM	
		[dbo].[PHYSICIAN_SERVICE_LEVEL]
	WHERE	
		@DateOfService BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
		AND PHYSICIAN_SERVICE_CLASS_CD = @ServiceClassCD
		AND PHYSICIAN_SERVICE_GUIDELINE_ID = @ServiceGuidelineID
		AND PHYSICIAN_SERVICE_TYPE_CD = @ServiceTypeCD
		AND CAT_1_RATING = @Cat1Rating
		AND CAT_2_RATING = @Cat2Rating
		AND CAT_3_RATING = @Cat3Rating;

END -- end procedure

GO

/*
testing:
select top 1000 * from PHYSICIAN_SERVICE_LEVEL
begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing
*/