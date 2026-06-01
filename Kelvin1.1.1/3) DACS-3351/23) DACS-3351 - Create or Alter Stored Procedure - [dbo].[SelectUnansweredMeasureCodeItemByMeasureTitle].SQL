------------------------------------------------------------------------------------
-- 23) DACS-3351 - Create or Alter Stored Procedure - [dbo].[SelectUnansweredMeasureCodeItemByMeasureTitle].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectUnansweredMeasureCodeItemByMeasureTitle] 
	@measureTitle15CharFragment VARCHAR(15) = NULL
WITH EXEC AS CALLER AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	------------------------------------------------------
	/*
	 replaces inline SQL from LoadUnansweredMeasureCodeItemByMeasureTitle(...) of "\CCSBusinessObjects\DAO\CMSRules\CMSPQRIMeasureCodeDAO.cs" within ACS project
	  original var sql = $@"DECLARE @cpmId INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM CMS_PQRI_MEASURE WITH (NOLOCK) WHERE SUBSTRING([MEASURE_TITLE], 1, 15) = SUBSTRING('{measureTitle.TakeFirst(15)}', 1, 15));
                        IF @cpmId IS NULL OR @cpmId <= 0 RETURN;
                        SELECT TOP 1 {m_Fields} FROM [CMS_PQRI_MEASURE_CODE] WITH (NOLOCK)  
                        WHERE [CMS_PQRI_MEASURE_ID] = @cpmId AND [CODING_SYSTEM] = 'OTHER' AND [CODE] = '99999';";	  
	*/
	------------------------------------------------------

	DECLARE @cpmId INT = (
		SELECT TOP 1 
			[CMS_PQRI_MEASURE_ID] 
		FROM 
			[CMS_PQRI_MEASURE]
		WHERE 
			SUBSTRING([MEASURE_TITLE], 1, 15) = SUBSTRING(@measureTitle15CharFragment, 1, 15)
			AND @measureTitle15CharFragment is not null 
			AND LEN(@measureTitle15CharFragment) > 0
	);

    IF @cpmId IS NULL OR @cpmId <= 0 
		RETURN;
		
    SELECT TOP 1 
		  [CMS_PQRI_MEASURE_CODE_ID]
		, [CMS_PQRI_MEASURE_ID]
		, [CODING_SYSTEM]
		, [OPTION_GROUP]
		, [CODE]
		, [MODIFIER]
		, [DESCRIPTION]
		, [PLACE_OF_SERVICE]
		, [END_DATE]
		, [CODE_2]
		, [MODIFIER_2]
	FROM 
		[CMS_PQRI_MEASURE_CODE]
    WHERE 
		[CMS_PQRI_MEASURE_ID] = @cpmId 
		AND [CODING_SYSTEM] = 'OTHER' 
		AND [CODE] = '99999';

	
END -- end procedure

GO

/*
testing:
exec [dbo].[SelectUnansweredMeasureCodeItemByMeasureTitle] 
	@measureTitle15CharFragment = 'MIPS# 005-A [Re'


*/