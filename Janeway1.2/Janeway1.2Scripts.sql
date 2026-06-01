USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 1) DACS-3143 Add Columns to ChartAuditAnesthesiaVersionItem.sql

GO

ALTER TABLE ChartAuditAnesthesiaVersionItem 
ADD [StartTime] [datetime] NULL,
 	[StopTime] [datetime] NULL,
 	[ExcludeMinutes] [int] NULL,
 	[Units] [int] NULL,
 	[Minutes] [int] NULL,
 	[ProviderModifiers] [varchar](100) NULL,
 	[MacModifiers] [varchar](2) NULL,
 	[PhysicalStatusModifier] [varchar](2) NULL,
 	[BaseUnitExceptionFieldAvoidance] [bit] NULL,
 	[BaseUnitExceptionNonSupine] [bit] NULL,
 	[BaseUnitExceptionModifier] [varchar](2) NULL,
 	[QualifyingCircumstanceCode] [varchar](100) NULL,
 	[ChargeMasterId] [int] NULL,
 	[BaseUnitExceptionLimitedAccessToAirway] [bit] NULL,
 	[DocumentationSupportsIncreasedComplexity] [bit] NULL,
 	[DocumentationSupportsIncreasedComplexityReasonId] [int] NULL,
 	[CptModifiers] [varchar](100) NULL
-- End of 1) DACS-3143 Add Columns to ChartAuditAnesthesiaVersionItem.sql
GO

-- Start of 2) DACS-3143 Modify Stored Procs for ChartAuditAnesthesiaVersionItem.sql

GO 
---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChartAuditAnesthesiaVersionItem', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChartAuditAnesthesiaVersionItem.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChartAuditAnesthesiaVersionItem
END
GO

IF OBJECT_ID('dbo.UpdateByChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId
END
GO
IF OBJECT_ID('dbo.DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId]
END
GO
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChartAuditAnesthesiaVersionItem', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.InsertChartAuditAnesthesiaVersionItem
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditAnesthesiaVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit
	,@ExcludeFromQA bit
	,@ExcludeFromQAReasonID int = NULL
	,@AnesthesiaCode varchar(10) = NULL
	,@StartTime datetime = NULL
	,@StopTime datetime = NULL
	,@ExcludeMinutes int = NULL
	,@Units int = NULL
	,@Minutes int = NULL
	,@ProviderModifiers varchar(100) = NULL
	,@MacModifiers varchar(2) = NULL
	,@PhysicalStatusModifier varchar(2) = NULL
	,@BaseUnitExceptionFieldAvoidance bit = NULL
	,@BaseUnitExceptionNonSupine bit = NULL
	,@BaseUnitExceptionModifier varchar(2) = NULL
	,@QualifyingCircumstanceCode varchar(100) = NULL
	,@ChargeMasterId int = NULL
	,@BaseUnitExceptionLimitedAccessToAirway bit = NULL
	,@DocumentationSupportsIncreasedComplexity bit = NULL
	,@DocumentationSupportsIncreasedComplexityReasonId int = NULL
	,@CptModifiers varchar(100) = NULL
	,@ChartAuditAnesthesiaVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditAnesthesiaVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditAnesthesiaVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[AnesthesiaCode]
	,[StartTime]
	,[StopTime]
	,[ExcludeMinutes]
	,[Units]
	,[Minutes]
	,[ProviderModifiers]
	,[MacModifiers]
	,[PhysicalStatusModifier]
	,[BaseUnitExceptionFieldAvoidance]
	,[BaseUnitExceptionNonSupine]
	,[BaseUnitExceptionModifier]
	,[QualifyingCircumstanceCode]
	,[ChargeMasterId]
	,[BaseUnitExceptionLimitedAccessToAirway]
	,[DocumentationSupportsIncreasedComplexity]
	,[DocumentationSupportsIncreasedComplexityReasonId]
	,[CptModifiers]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditAnesthesiaVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@AnesthesiaCode
	,@StartTime
	,@StopTime
	,@ExcludeMinutes
	,@Units
	,@Minutes
	,@ProviderModifiers
	,@MacModifiers
	,@PhysicalStatusModifier
	,@BaseUnitExceptionFieldAvoidance
	,@BaseUnitExceptionNonSupine
	,@BaseUnitExceptionModifier
	,@QualifyingCircumstanceCode
	,@ChargeMasterId
	,@BaseUnitExceptionLimitedAccessToAirway
	,@DocumentationSupportsIncreasedComplexity
	,@DocumentationSupportsIncreasedComplexityReasonId
	,@CptModifiers 
)

SET @ChartAuditAnesthesiaVersionItemId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId
	 @ChartAuditAnesthesiaVersionItemId int
	,@ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditAnesthesiaVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit
	,@ExcludeFromQA bit
	,@ExcludeFromQAReasonID int = NULL
	,@AnesthesiaCode varchar(10) = NULL
	,@StartTime datetime = NULL
	,@StopTime datetime = NULL
	,@ExcludeMinutes int = NULL
	,@Units int = NULL
	,@Minutes int = NULL
	,@ProviderModifiers varchar(100) = NULL
	,@MacModifiers varchar(2) = NULL
	,@PhysicalStatusModifier varchar(2) = NULL
	,@BaseUnitExceptionFieldAvoidance bit = NULL
	,@BaseUnitExceptionNonSupine bit = NULL
	,@BaseUnitExceptionModifier varchar(2) = NULL
	,@QualifyingCircumstanceCode varchar(100) = NULL
	,@ChargeMasterId int = NULL
	,@BaseUnitExceptionLimitedAccessToAirway bit = NULL
	,@DocumentationSupportsIncreasedComplexity bit = NULL
	,@DocumentationSupportsIncreasedComplexityReasonId int = NULL
	,@CptModifiers varchar(100) = NULL
AS

UPDATE [dbo].[ChartAuditAnesthesiaVersionItem] SET
	 [ChartAuditVersionId] = @ChartAuditVersionId
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[ChartAuditActionTypeCode] = @ChartAuditActionTypeCode
	,[ActionDescription] = @ActionDescription
	,[PrevChartAuditAnesthesiaVersionItemId] = @PrevChartAuditAnesthesiaVersionItemId
	,[IsPreviousVersionCorrect] = @IsPreviousVersionCorrect
	,[ExcludeFromQA] = @ExcludeFromQA
	,[ExcludeFromQAReasonID] = @ExcludeFromQAReasonID
	,[AnesthesiaCode] = @AnesthesiaCode
	,[StartTime] = @StartTime
	,[StopTime] = @StopTime
	,[ExcludeMinutes] = @ExcludeMinutes
	,[Units] = @Units
	,[Minutes] = @Minutes
	,[ProviderModifiers] = @ProviderModifiers
	,[MacModifiers] = @MacModifiers
	,[PhysicalStatusModifier] = @PhysicalStatusModifier
	,[BaseUnitExceptionFieldAvoidance] = @BaseUnitExceptionFieldAvoidance
	,[BaseUnitExceptionNonSupine] = @BaseUnitExceptionNonSupine
	,[BaseUnitExceptionModifier] = @BaseUnitExceptionModifier
	,[QualifyingCircumstanceCode] = @QualifyingCircumstanceCode
	,[ChargeMasterId] = @ChargeMasterId
	,[BaseUnitExceptionLimitedAccessToAirway] = @BaseUnitExceptionLimitedAccessToAirway
	,[DocumentationSupportsIncreasedComplexity] = @DocumentationSupportsIncreasedComplexity
	,[DocumentationSupportsIncreasedComplexityReasonId] = @DocumentationSupportsIncreasedComplexityReasonId
	,[CptModifiers] = @CptModifiers
WHERE
	[ChartAuditAnesthesiaVersionItemId] = @ChartAuditAnesthesiaVersionItemId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId
	@ChartAuditAnesthesiaVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditAnesthesiaVersionItem]
WHERE
	[ChartAuditAnesthesiaVersionItemId] = @ChartAuditAnesthesiaVersionItemId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId]', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId]
	@ChartAuditAnesthesiaVersionItemId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId]
	,[ChartAuditAnesthesiaVersionItem].[ChartAuditVersionId]
	,[ChartAuditAnesthesiaVersionItem].[DateTimeCreated]
	,[ChartAuditAnesthesiaVersionItem].[CreatedByUserProfileId]
	,[ChartAuditAnesthesiaVersionItem].[DateTimeLastUpdated]
	,[ChartAuditAnesthesiaVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditAnesthesiaVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditAnesthesiaVersionItem].[ActionDescription]
	,[ChartAuditAnesthesiaVersionItem].[PrevChartAuditAnesthesiaVersionItemId]
	,[ChartAuditAnesthesiaVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeFromQA]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditAnesthesiaVersionItem].[AnesthesiaCode]
	,[ChartAuditAnesthesiaVersionItem].[StartTime]
	,[ChartAuditAnesthesiaVersionItem].[StopTime]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeMinutes]
	,[ChartAuditAnesthesiaVersionItem].[Units]
	,[ChartAuditAnesthesiaVersionItem].[Minutes]
	,[ChartAuditAnesthesiaVersionItem].[ProviderModifiers]
	,[ChartAuditAnesthesiaVersionItem].[MacModifiers]
	,[ChartAuditAnesthesiaVersionItem].[PhysicalStatusModifier]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionFieldAvoidance]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionNonSupine]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionModifier]
	,[ChartAuditAnesthesiaVersionItem].[QualifyingCircumstanceCode]
	,[ChartAuditAnesthesiaVersionItem].[ChargeMasterId]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionLimitedAccessToAirway]
	,[ChartAuditAnesthesiaVersionItem].[DocumentationSupportsIncreasedComplexity]
	,[ChartAuditAnesthesiaVersionItem].[DocumentationSupportsIncreasedComplexityReasonId]
	,[ChartAuditAnesthesiaVersionItem].[CptModifiers]
FROM
	[dbo].[ChartAuditAnesthesiaVersionItem]
WHERE
	[ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId] = @ChartAuditAnesthesiaVersionItemId

GO	
		
------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId]', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId]
	 @ChartAuditVersionId int
	,@PageIndex int = NULL
    ,@PageSize int = 25
    ,@WhereClause varchar(1000) = NULL
    ,@OrderByClause varchar(250) = NULL
    ,@RecordCount int OUTPUT
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--[ID LIST]------------------------------------------------------

CREATE TABLE #tmp
(
	[IndexId] int IDENTITY (1, 1) NOT NULL,
	[ChartAuditAnesthesiaVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditAnesthesiaVersionItemId) ' +
		   'SELECT [ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId] ' +
		   'FROM [ChartAuditAnesthesiaVersionItem] ' +
		   'WHERE [ChartAuditAnesthesiaVersionItem].[ChartAuditVersionId] = ' + CAST(@ChartAuditVersionId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditAnesthesiaVersionItem].[DateTimeCreated] '

EXEC sp_executesql @sql

--[RANGE]----------------------------------------------------------

SELECT @RecordCount = @@ROWCOUNT

DECLARE @FirstRecord int
DECLARE @LastRecord  int

IF @PageIndex IS NOT NULL
BEGIN
	SET @FirstRecord = (@PageIndex * @PageSize) + 1
	SET @LastRecord  = (@PageIndex  + 1) * @PageSize
END
ELSE
BEGIN
	SET @FirstRecord = 1
	SET @LastRecord  = @RecordCount
END

--[DATA]------------------------------------------------------------

SELECT
	 [ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId]
	,[ChartAuditAnesthesiaVersionItem].[ChartAuditVersionId]
	,[ChartAuditAnesthesiaVersionItem].[DateTimeCreated]
	,[ChartAuditAnesthesiaVersionItem].[CreatedByUserProfileId]
	,[ChartAuditAnesthesiaVersionItem].[DateTimeLastUpdated]
	,[ChartAuditAnesthesiaVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditAnesthesiaVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditAnesthesiaVersionItem].[ActionDescription]
	,[ChartAuditAnesthesiaVersionItem].[PrevChartAuditAnesthesiaVersionItemId]
	,[ChartAuditAnesthesiaVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeFromQA]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditAnesthesiaVersionItem].[AnesthesiaCode]
	,[ChartAuditAnesthesiaVersionItem].[StartTime]
	,[ChartAuditAnesthesiaVersionItem].[StopTime]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeMinutes]
	,[ChartAuditAnesthesiaVersionItem].[Units]
	,[ChartAuditAnesthesiaVersionItem].[Minutes]
	,[ChartAuditAnesthesiaVersionItem].[ProviderModifiers]
	,[ChartAuditAnesthesiaVersionItem].[MacModifiers]
	,[ChartAuditAnesthesiaVersionItem].[PhysicalStatusModifier]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionFieldAvoidance]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionNonSupine]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionModifier]
	,[ChartAuditAnesthesiaVersionItem].[QualifyingCircumstanceCode]
	,[ChartAuditAnesthesiaVersionItem].[ChargeMasterId]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionLimitedAccessToAirway]
	,[ChartAuditAnesthesiaVersionItem].[DocumentationSupportsIncreasedComplexity]
	,[ChartAuditAnesthesiaVersionItem].[DocumentationSupportsIncreasedComplexityReasonId]
	,[ChartAuditAnesthesiaVersionItem].[CptModifiers]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditAnesthesiaVersionItem] 
			ON [ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId] = [tmp].[ChartAuditAnesthesiaVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

-- End of 2) DACS-3143 Modify Stored Procs for ChartAuditAnesthesiaVersionItem.sql
GO

-- Start of 01) DACS-1993 - Alter Table [CMSRules].[dbo].[CMS_PQRI_MEASURE] - Add column REQ_2_DX_OR_3CPT.SQL

------------------------------------------------------------------------------------
-- 01) DACS-1993 - Alter Table [CMSRules].[dbo].[CMS_PQRI_MEASURE] - Add column REQ_2_DX_OR_3CPT.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing

	-- table lock because this table is used a fair amount in ACS
	SELECT TOP (1) 1 FROM [dbo].[CMS_PQRI_MEASURE] WITH (TABLOCKX)

	ALTER TABLE [dbo].[CMS_PQRI_MEASURE]
	ADD [REQ_2_DX_OR_3CPT] BIT NULL;

-- rollback tran; -- testing
-- commit tran; -- testing

GO



-- End of 01) DACS-1993 - Alter Table [CMSRules].[dbo].[CMS_PQRI_MEASURE] - Add column REQ_2_DX_OR_3CPT.SQL
GO

-- Start of 02) DACS-1993 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 332.SQL

------------------------------------------------------------------------------------
-- 02) DACS-1993 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 332.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = '332';
	DECLARE @Dos DATETIME = GETDATE();

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	IF @countPQRS >= 0
	BEGIN 
		PRINT('Updating...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [REQ_2_DX_OR_3CPT] = 1
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 '332'
				,'Efficiency and Cost Reduction'
				,'PQRS# 332 Adult Sinusitis: Appropriate Choice of Antibiotic: Amoxicillin With or Without Clavulanate Prescribed for Patients with Acute Bacterial Sinusitis (Appropriate Use)'	
				,'B'
				,18
				,999
				,'2019-11-25'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);



	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '332'
*/
-- End of 02) DACS-1993 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 332.SQL
GO

-- Start of 03) DACS-1993 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt].SQL

------------------------------------------------------------------------------------
-- 03) DACS-1993 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt] 
	  @ChartId INT
	, @MeasureId INT
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G9315
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9313
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G9314
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList

	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList


	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	DECLARE @gender VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempChartInfo);

	IF (@gender IS NULL OR @gender IN ('U', 'X')) SET @gender = 'B';
	
	IF @gender <> 'B'
	BEGIN 
		DECLARE @genderCheck VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempMeasureInfo);
		
		IF @genderCheck IS NULL SET @genderCheck = 'B';

		IF @gender <> @genderCheck
		BEGIN 
			PRINT('@ChartId does not match gender test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not match gender test', 'Code' = 'ERR-0-GEN';
			RETURN;
		END;
	END;

	PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	
	SELECT TOP 1 
		@PSP_CPT = [CPT_CODE]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorGroup2Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2');
	DECLARE @foundDenominatorGroup2Pick3MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P3 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P3 records';
		RETURN;
	END;

	-- do we have a diag for acute sinusitus?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		PRINT('Date completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no acute sinusitus)', 'Code' = 'ERR-1-NAS';
		RETURN;
	END;
	
	-- are we missing both bacterial infection and G9364?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));

	IF @foundDenominatorGroup1Pick2MatchCount <= 0 AND @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no bacterial infection)', 'Code' = 'ERR-2-NBI';
		RETURN;
	END;
	
	-- do we have a Phys Svcs E and M code?
	SET @foundDenominatorGroup2Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2'));

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no E&M code match)', 'Code' = 'ERR-3-NEC';
		RETURN;
	END;

	-- do we have a antibiotic regimine (G9498) code?
	SET @foundDenominatorGroup2Pick3MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3'));

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no antibiotic regimine)', 'Code' = 'ERR-4-NAR';
		RETURN;
	END;

	-- all Data Completion steps satisified.
	PRINT('Performance Met: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + Performance Met) - G9315
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + denominator exception) - G9313
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + Performance NOT Met) - G9314
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + But no codes in chart already found for denominator value) - ????
	-- DECLARE @ResultPerformanceCodeMet VARCHAR(20) = (SELECT TOP 1 [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'HCPCS' AND [DESCRIPTION] LIKE 'Performance Met:%')
	-- DECLARE @ResultPerformanceCodeNotMet VARCHAR(20) = (SELECT TOP 1 [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'HCPCS' AND [DESCRIPTION] LIKE 'Performance Not Met:%')
	-- DECLARE @ResultPerformanceCodeExMet VARCHAR(20) = (SELECT TOP 1 [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'HCPCS' AND [DESCRIPTION] LIKE '%Performance Exclusion:%')

	DECLARE @foundG9315Count INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9315');  /*@ResultPerformanceCodeMet*/

	IF @foundG9315Count >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = 'G9315';
		RETURN;
	END;

	DECLARE @foundG9313Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9313');  /*@ResultPerformanceCodeExMet*/

	IF @foundG9313Count >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'G9313';
		RETURN;
	END;

	DECLARE @foundG9314Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9314');  /*@ResultPerformanceCodeNotMet*/

	IF @foundG9314Count >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = 'G9314';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code set from list (G9315,G9313,G9314)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '332'
begin tran; -- testing
*/
-- End of 03) DACS-1993 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt].SQL
GO

-- Start of 04) DACS-1993 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for ne processing method = 332.SQL

------------------------------------------------------------------------------------
-- 04) DACS-1993 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 332.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = '332';
	DECLARE @Dos DATETIME = GETDATE();

	DECLARE @MeasureId INT = 
		(
			SELECT [CMS_PQRI_MEASURE_ID]
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN 
		PRINT('No Measure loaded for 332.  Cannot continue.');
		SELECT 'Error' = -1;
		RETURN;
	END;

	PRINT('@MeasureId = ' + CAST(@MeasureId AS VARCHAR(30)));

	DECLARE @countPQRSCodes INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
		);

	SELECT '@countPQRSCodes' = @countPQRSCodes; -- testing



	IF @countPQRSCodes > 0
	BEGIN 
		PRINT('Found Measure Codes.  Expiring existing.');
	
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET [END_DATE] = DATEADD(minute,-1,CAST(CAST(@Dos AS DATE) AS DATETIME))
		WHERE
			[CMS_PQRI_MEASURE_ID] = @MeasureId
			AND [START_DATE] <= @Dos
			AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
			AND [CODE] IS NOT NULL
			AND [CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	END;

	DECLARE @countPQRSCodesAfterExpiration INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Exiting.');
		RETURN;
	END;




	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[START_DATE],[DESCRIPTION])
	VALUES
		-- measure code denominators
		 (@MeasureId,'DG1P1','J01.00',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.01',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.10',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.11',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.20',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.21',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.30',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.31',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.40',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.41',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.80',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.81',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.90',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.91',@Dos,NULL)

		,(@MeasureId,'DG1P2','B95.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.1',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.2',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.3',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.4',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.5',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.61',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.62',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.7',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.8',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.1',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.20',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.21',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.22',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.23',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.29',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.3',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.4',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.5',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.6',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.7',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.81',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.82',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.89',@Dos,NULL)
		
		,(@MeasureId,'DG2P1','G9364',@Dos,NULL)
		
		,(@MeasureId,'DG2P2','99202',@Dos,NULL)
		,(@MeasureId,'DG2P2','99203',@Dos,NULL)
		,(@MeasureId,'DG2P2','99204',@Dos,NULL)
		,(@MeasureId,'DG2P2','99205',@Dos,NULL)
		,(@MeasureId,'DG2P2','99212',@Dos,NULL)
		,(@MeasureId,'DG2P2','99213',@Dos,NULL)
		,(@MeasureId,'DG2P2','99214',@Dos,NULL)
		,(@MeasureId,'DG2P2','99215',@Dos,NULL)
		,(@MeasureId,'DG2P2','99281',@Dos,NULL)
		,(@MeasureId,'DG2P2','99282',@Dos,NULL)
		,(@MeasureId,'DG2P2','99283',@Dos,NULL)
		,(@MeasureId,'DG2P2','99284',@Dos,NULL)
		,(@MeasureId,'DG2P2','99285',@Dos,NULL)
		,(@MeasureId,'DG2P2','99304',@Dos,NULL)
		,(@MeasureId,'DG2P2','99305',@Dos,NULL)
		,(@MeasureId,'DG2P2','99306',@Dos,NULL)
		,(@MeasureId,'DG2P2','99307',@Dos,NULL)
		,(@MeasureId,'DG2P2','99308',@Dos,NULL)
		,(@MeasureId,'DG2P2','99309',@Dos,NULL)
		,(@MeasureId,'DG2P2','99310',@Dos,NULL)
		,(@MeasureId,'DG2P2','99341',@Dos,NULL)
		,(@MeasureId,'DG2P2','99342',@Dos,NULL)
		,(@MeasureId,'DG2P2','99344',@Dos,NULL)
		,(@MeasureId,'DG2P2','99345',@Dos,NULL)
		,(@MeasureId,'DG2P2','99347',@Dos,NULL)
		,(@MeasureId,'DG2P2','99348',@Dos,NULL)
		,(@MeasureId,'DG2P2','99349',@Dos,NULL)
		,(@MeasureId,'DG2P2','99350',@Dos,NULL)
		,(@MeasureId,'DG2P2','99424',@Dos,NULL)
		,(@MeasureId,'DG2P2','99491',@Dos,NULL)
		
		,(@MeasureId,'DG2P3','G9498',@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G9315',@Dos,'Performance Met: Amoxicillin, with or without clavulanate, prescribed asa first line antibiotic at the time of diagnosis')
		,(@MeasureId,'HCPCS','G9313',@Dos,'Other Performance Exclusion: Amoxicillin, with or without clavulanate, notprescribed as first line antibiotic at the time of diagnosis for documented reason')
		,(@MeasureId,'HCPCS','G9314',@Dos,'Performance Not Met: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis, reason not given')
		; -- expect 74 total inserts
		
		
		
	DECLARE @countPQRSCodesFinal INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
		);

	SELECT '@countPQRSCodesFinal' = @countPQRSCodesFinal;

	-- testing:
	SELECT 
		*
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '332'
*/
-- End of 04) DACS-1993 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for ne processing method = 332.SQL
GO

-- Start of 05) DACS-1993 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByPqrsNumAndREQ2DxOr3Cpt].SQL

------------------------------------------------------------------------------------
-- 05) DACS-1993 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByPqrsNumAndREQ2DxOr3Cpt].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByPqrsNumAndREQ2DxOr3Cpt] 
	  @ChartId INT
	, @PqrsNum varchar(20)
	, @Dos DATETIME = NULL
	, @IsValidTestOnly BIT = 0
	, @ShowDebug BIT = 0
	, @UseTodayForDos BIT = 1 -- For backwards compatibility
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @PqrsNum IS NULL OR LEN(@PqrsNum) <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @PqrsNum';
		RETURN;
	END;

	IF @Dos IS NULL OR @UseTodayForDos <> 0
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- validate Measure Id
	DECLARE @MeasureId INT = 
		(
			SELECT TOP 1 
				[CMS_PQRI_MEASURE_ID] 
			FROM 
				[CMS_PQRI_MEASURE] 
			WHERE 
				[PQRS#] = @PqrsNum 
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos)
			ORDER BY 
				[CMS_PQRI_MEASURE_ID] DESC
		);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'unable to find valid @MeasureId from @PqrsNum';
		RETURN;
	END;

	-- Validate Chart Id
	DECLARE @chartRangeDate DATETIME = DATEADD(day,-720, GETDATE()); -- limit to last 2 years to save database resources

	DECLARE @testChartId INT = 
		(
			SELECT TOP 1 
				[CHART_ID] 
			FROM 
				[CHART] 
			WHERE 
				[CHART_ID] = @ChartId
				AND [TIME_OF_SERVICE] >= @chartRangeDate
			ORDER BY 
				[CHART_ID] DESC
		);

	IF @testChartId IS NULL OR @testChartId <= 0 OR @ChartId <> @testChartId 
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'unable to find valid @ChartId';
		RETURN;
	END;
	
	-- Validate Service Agreement needs the given PQRS Measure check
	DECLARE @SaId INT = 
		(
			SELECT TOP 1 
				[SERVICE_AGREEMENT_ID] 
			FROM 
				[CHART] 
			WHERE 
				[CHART_ID] = @ChartId
				AND [TIME_OF_SERVICE] >= @chartRangeDate
			ORDER BY 
				[CHART_ID] DESC
		);
	
	IF @SaId IS NULL OR @SaId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'invalid chart @SaId';
		RETURN;
	END;

	DECLARE @testSaId INT = 
		(
			SELECT TOP 1 
				[SERVICE_AGREEMENT_ID] 
			FROM 
				[SERVICE_AGREEMENT_PQRS]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND [SERVICE_AGREEMENT_ID] = @SaId
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos)
			ORDER BY 
				[SERVICE_AGREEMENT_PQRS_ID] DESC
		);

	IF @testSaId IS NULL OR @testSaId <= 0 OR @testSaId <> @SaId
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'invalid PQRI @TestSaId';
		RETURN;
	END;

	-- Are we running in test only mode?
	IF @IsValidTestOnly <> 0 
	BEGIN
		SELECT 'Result' = 1, 'Message' = 'Test Only: Valid combination of ACSCId, PQRS# and Dos', 'MeasureId' = CAST(IIF(@MeasureId IS NULL, -1, @MeasureId) AS VARCHAR(20));
		RETURN;
	END;

	EXEC [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt] 
			  @ChartId = @ChartId
			, @MeasureId = @MeasureId
			, @Dos = @Dos
			, @ShowDebug = @ShowDebug;

END; -- end procedure


GO


/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByPqrsNumAndREQ2DxOr3Cpt] 
			  @ChartId = 2100107862
			, @PqrsNum ='332'
			, @IsValidTestOnly = 1
*/
-- End of 05) DACS-1993 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByPqrsNumAndREQ2DxOr3Cpt].SQL
GO

-- Start of 1) DACS-3133 Delete Denial Rights.sql

----------------------------------------
-- 02) DACS-3131 - SQL Script will remove Denial entries from Group Rights and Defined_Rights table
----------------------------------------
GO

SELECT * FROM [dbo].[GROUP_RIGHTS]
WHERE defined_right_id IN (84,85)

DELETE FROM [dbo].[GROUP_RIGHTS]
WHERE defined_right_id IN (84,85)

DELETE FROM [dbo].[DEFINED_RIGHT]
WHERE DEFINED_RIGHT_ID = 84
AND [NAME] = 'Allow User Access to Denial Management Module'

DELETE FROM [dbo].[DEFINED_RIGHT]
WHERE DEFINED_RIGHT_ID = 85
AND [NAME] = 'Allow Denial Management Administration'
-- End of 1) DACS-3133 Delete Denial Rights.sql
GO

-- Start of 2) DACS-3133 DELETE SERVICE_AGREEMENT_DOCUMENT.sql

----------------------------------------
-- 03) DACS-3131 - SQL Script will delete all documents for Service agreement for Document type id = 7 (Denials). Also, remove type id =7 from SERVICE_AGREEMENT_DOCUMENT_TYPE TABLE
----------------------------------------
GO

SELECT * FROM SERVICE_AGREEMENT_DOCUMENT 
WHERE service_agreement_document_type_id = 7

DELETE FROM SERVICE_AGREEMENT_DOCUMENT 
WHERE service_agreement_document_type_id = 7

DELETE FROM SERVICE_AGREEMENT_DOCUMENT_TYPE
WHERE service_agreement_document_type_id = 7
-- End of 2) DACS-3133 DELETE SERVICE_AGREEMENT_DOCUMENT.sql
GO

-- Start of 3) DACS-3133 Drop Proc and View.sql

----------------------------------------
-- 04) DACS-3131 - SQL Script will remove Denial Stored procs and views
----------------------------------------
GO

DROP PROC [dbo].[VW_DENIAL_CLAIM_OUTCOME_NOTE_SUMMARY_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[VW_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_SUMMARY_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[VW_DENIAL_CLAIM_PROCEDURE_REVISION_SUMMARY_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[VW_DENIAL_CLAIM_PROCEDURE_SUMMARY_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[VW_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_SUMMARY_SELECT_BY_DENIAL_CLAIM_PROCEDURE_REVISION_ID]
DROP PROC [dbo].[VW_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_SUMMARY_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[VW_DENIAL_CLAIM_STATUS_ASSIGNED_USER_PROFILE_SUMMARY_SELECT_BY_ASSIGNED_TO_USER_PROFILE_ID]
DROP PROC [dbo].[VW_DENIAL_CLAIM_SUMMARY_SELECT]
DROP PROC [dbo].[VW_DENIAL_CLAIM_SUMMARY_SELECT_BY_CHANGING_USER_PROFILE_ID]
DROP PROC [dbo].[VW_DENIAL_OUTCOME_NOTE_TEMPLATE_SUMMARY_SELECT]
DROP PROC [dbo].[VW_DENIAL_SERVICE_AGREEMENT_PAYOR_SELECT_BY_SERVICE_AGREEMENT_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_SELECT_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_SELECT_BY_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_UPDATE_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_UPDATE_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID_AND_ICD10_CODE]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_UPDATE_BY_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_SELECT_BY_DENIAL_PAYOR_CATEGORY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_INSERT]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_SELECT_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION_DELETE_BY_DENIAL_CLAIM_PROCEDURE_REVISION_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_SELECT_BY_SERVICE_AGREEMENT_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION_INSERT]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_UPDATE_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON_DELETE_BY_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_REVISION_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON_INSERT_DEFAULT_REASONS]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON_SELECT_BY_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON_SELECT_BY_SERVICE_AGREEMENT_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_SELECT_BY_DENIAL_REVENUE_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON_UPDATE_BY_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_DELETE_BY_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_DELETE_BY_DENIAL_SERVICE_LOCATION_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_INSERT]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DELETE_BY_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DELETE_BY_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_ID]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_INSERT]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_SELECT_BY_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_SELECT_BY_DENIAL_SERVICE_LOCATION_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_REVISION_ID]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_SELECT_BY_DENIAL_SERVICE_PLACE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_UPDATE_BY_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_ID]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_SELECT_BY_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_SELECT_BY_DENIAL_SERVICE_LOCATION_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_SELECT_BY_DENIAL_REMIT_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_SELECT_BY_SERVICE_AGREEMENT_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_UPDATE_BY_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_ID]
DROP PROC [dbo].[DENIAL_SERVICE_LOCATION_UPDATE_BY_DENIAL_SERVICE_LOCATION_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_PLACE_DELETE_BY_DENIAL_SERVICE_PLACE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_SELECT_BY_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_PLACE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_SELECT_BY_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_PLACE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_SELECT_BY_DENIAL_REMIT_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_PLACE_SELECT_BY_DENIAL_SERVICE_LOCATION_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_UPDATE_BY_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_PLACE_SELECT_BY_DENIAL_SERVICE_PLACE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_DELETE_BY_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID]
DROP PROC [dbo].[DENIAL_SERVICE_PLACE_UPDATE_BY_DENIAL_SERVICE_PLACE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_INSERT]
DROP PROC [dbo].[DENIAL_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DELETE_BY_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_REVISION_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_UPDATE_BY_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_SELECT_BY_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_UPDATE_BY_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_UPDATE_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_NORMALIZE]
DROP PROC [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_SELECT_BY_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_UPDATE_BY_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_SELECT_BY_ASSIGNED_TO_USER_PROFILE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_SELECT_BY_CHANGING_USER_PROFILE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_CLAIM_SELECT_BY_DENIAL_SERVICE_LOCATION_ID]
DROP PROC [dbo].[DENIAL_CLAIM_SELECT_BY_DENIAL_SERVICE_PLACE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_SELECT_BY_FACILITY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_SELECT_BY_FACILITY_ID_AND_SERVICE_AGREEMENT_ID]
DROP PROC [dbo].[DENIAL_CLAIM_STATUS_REASON_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_STATUS_REASON_TYPE_CODE_SELECT_BY_DENIAL_CLAIM_STATUS_REASON_TYPE_CODE]
DROP PROC [dbo].[DENIAL_CLAIM_STATUS_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_STATUS_TYPE_CODE_SELECT_BY_DENIAL_CLAIM_STATUS_TYPE_CODE]
DROP PROC [dbo].[DENIAL_CLAIM_UPDATE_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_DOCUMENT_TYPE_DELETE_BY_DENIAL_DOCUMENT_TYPE_ID]
DROP PROC [dbo].[DENIAL_DOCUMENT_TYPE_INSERT]
DROP PROC [dbo].[DENIAL_DOCUMENT_TYPE_SELECT]
DROP PROC [dbo].[DENIAL_DOCUMENT_TYPE_SELECT_BY_DENIAL_DOCUMENT_CATEGORY_TYPE_CODE]
DROP PROC [dbo].[DENIAL_DOCUMENT_TYPE_SELECT_BY_DENIAL_DOCUMENT_TYPE_ID]
DROP PROC [dbo].[DENIAL_ADJUSTMENT_REASON_CODE_UPDATE_BY_DENIAL_ADJUSTMENT_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_DOCUMENT_TYPE_UPDATE_BY_DENIAL_DOCUMENT_TYPE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_ACTION_REASON_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_INSURANCE_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_ACTION_REASON_TYPE_CODE_SELECT_BY_DENIAL_CLAIM_ACTION_REASON_TYPE_CODE]
DROP PROC [dbo].[DENIAL_INSURANCE_TYPE_CODE_SELECT_BY_DENIAL_INSURANCE_TYPE_CODE]
DROP PROC [dbo].[DENIAL_CLAIM_ACTION_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_OUTCOME_ANALYZER_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_ACTION_TYPE_CODE_SELECT_BY_DENIAL_CLAIM_ACTION_TYPE_CODE]
DROP PROC [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_DELETE_BY_DENIAL_OUTCOME_NOTE_TEMPLATE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_DELETE_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_DELETE_BY_FACILITY_ID]
DROP PROC [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_DELETE_BY_FACILITY_ID_AND_SERVICE_AGREEMENT_ID]
DROP PROC [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_SELECT_BY_DENIAL_OUTCOME_NOTE_TEMPLATE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_DOCUMENT_DELETE_BY_DENIAL_CLAIM_DOCUMENT_ID]
DROP PROC [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_SELECT_BY_DENIAL_OUTCOME_NOTE_TEMPLATE_TYPE_CODE]
DROP PROC [dbo].[DENIAL_CLAIM_DOCUMENT_INSERT]
DROP PROC [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_DOCUMENT_SELECT_BY_DENIAL_CLAIM_DOCUMENT_ID]
DROP PROC [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_UPDATE_BY_DENIAL_OUTCOME_NOTE_TEMPLATE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_DOCUMENT_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_DOCUMENT_SELECT_BY_DENIAL_DOCUMENT_TYPE_ID]
DROP PROC [dbo].[DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE_SELECT_BY_DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE]
DROP PROC [dbo].[DENIAL_CLAIM_DOCUMENT_UPDATE_BY_DENIAL_CLAIM_DOCUMENT_ID]
DROP PROC [dbo].[DENIAL_PAYOR_CATEGORY_DELETE_BY_DENIAL_PAYOR_CATEGORY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_DELETE_BY_DENIAL_CLAIM_FACILITY_PROFESSIONAL_ID]
DROP PROC [dbo].[DENIAL_PAYOR_CATEGORY_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_INSERT]
DROP PROC [dbo].[DENIAL_PAYOR_CATEGORY_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_SELECT_BY_DENIAL_CLAIM_FACILITY_PROFESSIONAL_ID]
DROP PROC [dbo].[DENIAL_PAYOR_CATEGORY_SELECT_BY_DENIAL_PAYOR_CATEGORY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_PAYOR_CATEGORY_UPDATE_BY_DENIAL_PAYOR_CATEGORY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_SELECT_BY_FACILITY_PROFESSIONAL_ID]
DROP PROC [dbo].[DENIAL_PAYOR_DETERMINATION_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_REASON_CATEGORY_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE_SELECT_BY_DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE]
DROP PROC [dbo].[DENIAL_REASON_CODE_DELETE_BY_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_UPDATE_BY_DENIAL_CLAIM_FACILITY_PROFESSIONAL_ID]
DROP PROC [dbo].[DENIAL_REASON_CODE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_FORM_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_REASON_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_FORM_TYPE_CODE_SELECT_BY_DENIAL_CLAIM_FORM_TYPE_CODE]
DROP PROC [dbo].[DENIAL_REASON_CODE_SELECT_BY_CODE]
DROP PROC [dbo].[DENIAL_CLAIM_INSERT]
DROP PROC [dbo].[DENIAL_REASON_CODE_SELECT_BY_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_INSERT]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_SELECT_BY_SERVICE_AGREEMENT_ID_AND_FACILITY_PAYOR_NAME]
DROP PROC [dbo].[DENIAL_REASON_CODE_SELECT_BY_SHORT_DESCRIPTION]
DROP PROC [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_NORMALIZE]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_DELETE_BY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_SELECT_BY_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_ID]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_SELECT_BY_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_UPDATE_BY_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_ID]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_SELECT_BY_DENIAL_REASON_GROUP_TYPE_CODE]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_DELETE_BY_DENIAL_CLAIM_OUTCOME_ID]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_UPDATE_BY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_INSERT]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DELETE_BY_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_NOTE_DELETE_BY_DENIAL_CLAIM_OUTCOME_NOTE_ID]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_NOTE_EVENT_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_DELETE_BY_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_ID]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_SELECT_BY_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_DELETE_BY_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_SELECT_BY_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_INSERT]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_SELECT_BY_DENIAL_REMIT_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_DELETE_BY_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID]
DROP PROC [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_UPDATE_BY_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_ID]
DROP PROC [dbo].[DENIAL_REASON_CODE_UPDATE_BY_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_REASON_GROUP_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_REMIT_CODE_DELETE_BY_DENIAL_REMIT_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_REMIT_CODE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_SELECT_BY_DENIAL_CLAIM_OUTCOME_ID]
DROP PROC [dbo].[DENIAL_REMIT_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_UPDATE_BY_DENIAL_CLAIM_OUTCOME_ID]
DROP PROC [dbo].[DENIAL_REMIT_CODE_SELECT_BY_CODE]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_CONDITION_DELETE_BY_DENIAL_CLAIM_PATIENT_CONDITION_ID]
DROP PROC [dbo].[DENIAL_REMIT_CODE_SELECT_BY_DENIAL_REASON_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_CONDITION_INSERT]
DROP PROC [dbo].[DENIAL_REMIT_CODE_SELECT_BY_DENIAL_REMIT_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_CONDITION_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_REMIT_CODE_UPDATE_BY_DENIAL_REMIT_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_CONDITION_SELECT_BY_DENIAL_CLAIM_PATIENT_CONDITION_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_CATEGORY_DELETE_BY_DENIAL_REVENUE_CODE_CATEGORY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_CONDITION_SELECT_BY_DENIAL_CLAIM_PATIENT_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_CATEGORY_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_CONDITION_UPDATE_BY_DENIAL_CLAIM_PATIENT_CONDITION_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_CATEGORY_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_DELETE_BY_DENIAL_CLAIM_PATIENT_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_CATEGORY_SELECT_BY_CODE]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_ACTION_TYPE_CODE_SELECT_BY_DENIAL_ACTION_TYPE_CODE]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_CATEGORY_SELECT_BY_DENIAL_REVENUE_CODE_CATEGORY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_ANALYZER_TYPE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_CATEGORY_UPDATE_BY_DENIAL_REVENUE_CODE_CATEGORY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_NOTE_SELECT_BY_OBJECT_TYPE]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_SELECT_BY_DENIAL_CLAIM_PATIENT_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_DELETE_BY_DENIAL_REVENUE_CODE_CATEGORY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_NOTE_SELECT_BY_USER_PROFILE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PATIENT_UPDATE_BY_DENIAL_CLAIM_PATIENT_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_DELETE_BY_DENIAL_REVENUE_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_NOTE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_PAYOR_DELETE_BY_DENIAL_CLAIM_PAYOR_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_NOTE_SELECT_BY_DENIAL_CLAIM_OUTCOME_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PAYOR_INSERT]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_SELECT]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_NOTE_SELECT_BY_DENIAL_CLAIM_OUTCOME_NOTE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PAYOR_SELECT_BY_DENIAL_CLAIM_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_SELECT_BY_CODE]
DROP PROC [dbo].[DENIAL_CLAIM_OUTCOME_NOTE_UPDATE_BY_DENIAL_CLAIM_OUTCOME_NOTE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PAYOR_SELECT_BY_DENIAL_CLAIM_PAYOR_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_SELECT_BY_DENIAL_REVENUE_CODE_CATEGORY_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PAYOR_SELECT_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_SELECT_BY_DENIAL_REVENUE_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PAYOR_UPDATE_BY_DENIAL_CLAIM_PAYOR_ID]
DROP PROC [dbo].[DENIAL_REVENUE_CODE_UPDATE_BY_DENIAL_REVENUE_CODE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DELETE_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DELETE_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_NORMALIZE]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_DELETE_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DELETE_BY_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_INSERT]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_SELECT_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_SELECT_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_SELECT_BY_SERVICE_AGREEMENT_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_DELETE_BY_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_ID]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_SELECT_BY_DENIAL_CLAIM_PROCEDURE_REVISION_ID]
DROP PROC [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_INSERT]
DROP PROC [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_UPDATE_BY_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_ID]
DROP PROC [dbo].[GLOBAL_CPT_CODE_SELECT]
DROP PROC [dbo].[GLOBAL_CPT_CODE_SELECT_BY_CODE]
DROP PROC [dbo].[GLOBAL_CPT_CODE_SELECT_BY_GLOBAL_CPT_CODE_ID]
DROP PROC [dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_SELECT]
DROP PROC [dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_SELECT_BY_GLOBAL_CPT_CODE_ID]
DROP PROC [dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_SELECT_BY_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_ID]
DROP PROC [dbo].[GLOBAL_HCPCS_CODE_DELETE_BY_GLOBAL_HCPCS_CODE_ID]
DROP PROC [dbo].[GLOBAL_HCPCS_CODE_INSERT]
DROP PROC [dbo].[GLOBAL_HCPCS_CODE_SELECT]
DROP PROC [dbo].[GLOBAL_HCPCS_CODE_SELECT_BY_CODE]
DROP PROC [dbo].[GLOBAL_HCPCS_CODE_SELECT_BY_GLOBAL_HCPCS_CODE_ID]
DROP PROC [dbo].[GLOBAL_HCPCS_CODE_UPDATE_BY_GLOBAL_HCPCS_CODE_ID]
DROP PROC [dbo].[GLOBAL_HCPCS_DELETE_BY_GLOBAL_HCPCS_ID]
DROP PROC [dbo].[GLOBAL_HCPCS_INSERT]
DROP PROC [dbo].[GLOBAL_HCPCS_SELECT]
DROP PROC [dbo].[GLOBAL_HCPCS_SELECT_BY_CODE]
DROP PROC [dbo].[GLOBAL_HCPCS_SELECT_BY_GLOBAL_HCPCS_ID]
DROP PROC [dbo].[GLOBAL_HCPCS_UPDATE_BY_GLOBAL_HCPCS_ID]
DROP PROC [dbo].[GLOBAL_MODIFIER_INSERT]
DROP PROC [dbo].[GLOBAL_MODIFIER_SELECT]
DROP PROC [dbo].[GLOBAL_MODIFIER_SELECT_BY_GLOBAL_MODIFIER_ID]
DROP PROC [dbo].[GLOBAL_MODIFIER_SELECT_BY_MODIFIER]
DROP PROC [dbo].[GLOBAL_MODIFIER_UPDATE_BY_GLOBAL_MODIFIER_ID]
DROP PROC [dbo].[GLOBAL_PROCEDURE_CODE_TYPE_CODE_SELECT]
-- End of 3) DACS-3133 Drop Proc and View.sql
GO

-- Start of 01) DACS-3013 - Create of Alter Stored Procedure - [dbo].[SelectChartByServiceAgreementIdAndFacilityChartId].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3013 - Create of Alter Stored Procedure - [dbo].[SelectChartByServiceAgreementIdAndFacilityChartId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartByServiceAgreementIdAndFacilityChartId] 
	  @SAId INT
	, @FacilityChartId varchar(50)
WITH EXEC AS CALLER AS
BEGIN

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		PRINT('bad @SAId');
		RETURN;
	END;
		
	IF @FacilityChartId IS NULL OR LEN(@FacilityChartId) <= 0
	BEGIN
		PRINT('bad @FacilityChartId');
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT top 1
		     CHART_ID 
            ,SERVICE_AGREEMENT_ID
		    ,FACILITY_ID
		    ,FACILITY_CHART_ID
		    ,FACILITY_ADMIN_CHART_ID
            ,MEDICAL_RECORD_NUM
		    ,PATIENT_TITLE
		    ,PATIENT_FIRST_NAME
			,PATIENT_MIDDLE_NAME
			,PATIENT_LAST_NAME
		    ,PATIENT_NAME_SUFFIX
		    ,PATIENT_ADDR_LINE_1
			,PATIENT_ADDR_LINE_2
			,PATIENT_CITY
		    ,PATIENT_STATE
		    ,PATIENT_ZIPCODE
			,PATIENT_DOB
			,TIME_OF_SERVICE
		    ,TIME_TO_ROOM
		    ,TIME_OF_PHYS_EVAL
			,TIME_OF_PHYS_DIS
			,TIME_OF_TRIAGE
		    ,TIME_OF_DIS
		    ,PHYSICIAN_ID
		    ,TRIAGE_NURSE_ID
			,DIS_NURSE_ID
			,DATE_RECEIVED 
            ,ASSIGNED_TO_ID 
            ,CHART_STATUS_ID 
            ,PENDING_REASON_ID
            ,CODER_COMMENT 
            ,FAC_SVCS_COMPLETED 
            ,FAC_PROC_COMPLETED
            ,PHYS_COMPLETED
			,PHYS_PROC_COMPLETED
			,PREBILL_AUDIT_COMPLETED
			,DEMOGRAPHICS_COMPLETED
			,RESULTS_COMPLETED
			,INFUSIONS_COMPLETED
			,FACILITY_CRITICAL_CARE
			,FACILITY_CRITICAL_CARE_MINUTES
			,PHYSICIAN_CRITICAL_CARE
			,PHYSICIAN_CRITICAL_CARE_MINUTES
			,FACILITY_LEVEL_ID
			,OVERRIDE_FACILITY_LEVEL_ID
			,PATIENT_DISPOSITION_ID
			,PHYSICIAN_HISTORY_ID
			,PHYSICIAN_EXAM_ID
			,PHYSICIAN_MDM_ID
			,PHYSICIAN_SERVICE_PROC_ID
			,PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID 
			,OVERRIDE_PHYS_HIST_ID
			,OVERRIDE_PHYS_EXAM_ID
			,OVERRIDE_PHYS_MDM_ID
			,OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
			,PHYSICIAN_SERVICE_MOD
			,COMPLETED_BY_USER_PROFILE_ID
			,APPROVED_BY_USER_PROFILE_ID
			,SENT_BY_USER_PROFILE_ID
			,COMPLETION_DATE
			,APPROVED_DATE
			,SENT_DATE
			,NON_ER_PROCEDURES_OVERRIDE 
            ,NO_FACILITY_SERVICES 
            ,NO_FACILITY_PROCEDURES 
            ,NO_PHYSICIAN_SERVICES 
            ,NO_PHYSICIAN_PROCEDURES 
            ,NO_PREBILL_AUDIT 
			,NO_INJECTIONS_OR_INFUSIONS
			,EDITED_BY_EXPERT 
            ,NUMBER_OF_IV_PUSHES 
            ,IMAGES_AVAILABLE 
            ,DIAGNOSIS_CODING_COMPLETE 
            ,NO_DIAGNOSIS_CODING 
			,CHIEF_COMPLAINT
			,PATIENT_CLASS_ID 
			,PATIENT_CLASS_CD
			,INSUFFICIENT_PHYSICIAN_PROCEDURE_DOC 
			,INSUFFICIENT_PHYSICIAN_PROCEDURE_REASON_ID
			,CLIENT_COMMENT 
			,CHART_IMAGES_TRANSMITTED
			,FINANCIAL_CLASS_CD 
			,DOCUMENTATION_COMPLETED 
			,DOCUMENTATION_EVALUATION_OK
			,RESIDENT_ID 
			,DEPARTMENT 
			,LONG_PATIENT_ID1 
			,LONG_PATIENT_ID2
			,NUMBER_OF_IV_PUSHES_SAME_SUB 
			,APPROVAL_REASON_CODE 
			,PRIMARY_COMPLAINT 
			,PATIENT_DISPOSITION_MAP_ID
			,HORMONAL
			,NON_HORMONAL
			,INTERLESIONAL_7_OR_LESS
			,INTERLESIONAL_MORE_THAN_7
			,NUMBER_CHEMOTHERAPY_IV_PUSH
			,PROLONGED_IV_CHEMOTHERAPY
			,PROLONGED_IA_CHEMOTHERAPY
			,ADDITIONAL_CRITICAL_CARE_UNITS
			,SUPPLIES_COMPLETED
			,NO_SUPPLIES
			,ADDITIONAL_COMPLAINT
			,ADDITIONAL_COMPLAINT2
			,GENDER
			,HOSPITAL_POINTS
			,HOSPITAL_CHIEF_COMPLAINT
			,APPEARS_TO_QUALIFY_FOR_CRITICAL_CARE
			,SERVICES_PERFORMED_BY_RESIDENT
			,RESIDENT_PHYS_PRESENT
			,RESIDENT_PHYS_PRESENT_REF_RES_NOTES
			,RESIDENT_PHYS_PRESENT_DISCUSSED_PLAN
			,RESIDENT_PHYS_INDEPENDENT_REF_RES_NOTES
			,RESIDENT_PHYS_INDEPENDENT_PERSONALLY_SAW
			,RESIDENT_PHYS_INDEPENDENT_DISCUSSED
			,RESIDENT_CPT_ENTIRELY_PRESENT
			,RESIDENT_CPT_PRESENT_DURING_KEY_PORTION
			,FACILITY_LEVEL_CODER_COMMENT
            ,CREATION_DATE_TIME 
			,CREATING_USER_PROFILE_ID 
            ,CHANGED_DATE_TIME 
            ,CHANGING_USER_PROFILE_ID 
            ,OVERRIDE_LCD_ERRORS
			,EVER_COMPLETED
			,LAST_ENCOUNTER_DATE 
            ,SAFETY_DEVICE_CD 
            ,SPORT_TYPE_CD 
            ,RESIDENT_PARTICIPATED_IN_CARE
			,ATTESTATION_SIGNED_BY_ATTENDING
			,REPORT_CHIEF_COMPLAINT_AS_SECONDARY 
            ,REPORT_ADDITIONAL_COMPLAINT_AS_SECONDARY 
            ,REPORT_ADDITIONAL_COMPLAINT2_AS_SECONDARY 
            ,PATIENT_AGE 
            ,START_QA_USER_PROFILE_ID
			,START_QA_DATE
			,PHYSICIAN_SIGNATURE_PRESENT
			,OBS_DEPT_EVAL_COMPLETED
			,INITIAL_CHARGE_MASTER_DEPT_ID
			,PHYSICIAN_LEVEL_CODER_COMMENT
			,EXCLUDE_OBSERVATION_DIRECT_CHARGE
			,NURSE_PRACTITIONER_ID 
			,ADD_MODIFIER_32_TO_PHYSICIAN_LOS
			,NO_PHYSICIAN_LOS_REASON_ID
			,CLINIC_ID
			,SERIAL_CODE
			,REGISTRATION_AREA
			,REGISTRATION_CODE 
            ,SERVICE_LINE_ID 
            ,TERMINAL_DIGITS 
            ,IMAGE_SOURCE_ID 
            ,PAYOR_CD 
            ,POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE 
            ,IS_PRIORITY 
            ,NO_ACTIVITY_CODES
			,NO_LCD_SERVICES 
			,MODIFIER_25_REQUIRED_REASON_ID
			,CONDITION_OF_ACCIDENT_ID
			,ACCIDENT_DATE
			,ADMISSION_DATE_TIME
			,OBSERVATION_ATTENDING_PROVIDER_ID 
			,OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
			,PATIENT_DISPOSITION_DESTINATION_ID
			,NO_OBSERVATION_HOURS 
			,OBSERVATION_COMPLETED_BY_USER_PROFILE_ID 
			,OBSERVATION_COMPLETION_DTTM
			,OBSERVATION_PROCEDURES_AUDIT_COMMENT
			,OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT 
			,OBSERVATION_AUDITOR_REVIEW_FEEDBACK
			,FACILITY_LOS_27_MODIFIER
			,OBSERVATION_BILLING_METHOD_CD 
			,ARRIVAL_DATE_TIME
			,SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
			,SERVICE_AGREEMENT_ARRIVAL_MODE_ID 
			,FACILITY_CRITICAL_CARE_CALC_METHOD_CD
			,FACILITY_CRITICAL_CARE_START_DATE
			,FACILITY_CRITICAL_CARE_STOP_DATE 
			,PHYSICIAN_CRITICAL_CARE_CALC_METHOD_CD
			,PHYSICIAN_CRITICAL_CARE_START_DATE 
			,PHYSICIAN_CRITICAL_CARE_STOP_DATE 
			,AUDIT_REQUIRED
			,ARRIVAL_DATE_TIME_NOT_AVAILABLE 
			,TIME_OF_TRIAGE_NOT_AVAILABLE 
            ,TIME_TO_ROOM_NOT_AVAILABLE 
            ,TIME_OF_PHYSICIAN_EVAL_NOT_AVAILABLE 
            ,ARRIVAL_MODE_NOT_AVAILABLE
			,TRIAGE_ACUITY_NOT_AVAILABLE 
			,OBSERVATION_TELEMETRY 
            ,DEMOGRAPHIC_AUDIT_COMMENT 
            ,LAST_MENSTRUAL_PERIOD 
            ,PAYOR_NAME
			,SERVICE_AGREEMENT_MODE_OF_DEPARTURE_ID
			,ORGAN_DONATION
			,REASON_FOR_VISIT_CATEGORY_DETAIL_ID 
			,ADD_MODIFIER_57_TO_PHYSICIAN_LOS
			,DO_NOT_APPLY_PHYSICIAN_MODIFER_25
			,ADD_MODIFIER_GW_TO_PHYSICIAN_LOS
			,PRIMARY_CARE_PHYSICIAN_ID
			,SCRIBE_ID
			,NO_ATTENDING_PROVIDER_SELECTED_IND 
			,PROVIDER_EVAL_PERFORMED_BY_IND
			,BILLING_INSTRUCTIONS
		    ,PHYSICIAN_SERVICE_OBSERVATION_ADMIT_DATETIME
			,PHYSICIAN_SERVICE_OBSERVATION_DISCHARGE_DATETIME
			,PHYSICIAN_SERVICE_OBSERVATION_FINAL_EXAM
			,SUBSEQUENT_VISIT_CODE
			,SERVICE_AGREEMENT_ADMIT_TYPE_ID
			,LOCATION_CODE
			,BILLING_AREA
			,ADD_GC_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL
			,ADD_GE_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL
			,MEDICAL_EXAMINER_NOTIFIED
			,SEEN_IN_ED_WITHIN_48_HOURS_OF_OR
			,ADD_24_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL
			,ADD_PHYSICIAN_SVC_25_MODIFIER 
			,LMP_DATE_NOT_AVAILABLE
			,OBSERVATION_DISCHARGE_PROVIDER_ID
			,FORCED_AUDIT
			,FLAGGED_FOR_AUDIT 
			,START_SECOND_LEVEL_QA_DATETIME
			,START_SECOND_LEVEL_QA_USER_PROFILE_ID
			,SECOND_LEVEL_QA_APPROVED_DATETIME
			,SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
			,QUALIFIED_FOR_SECOND_AUDIT_AT_COMPLETION 
			,FRACTURE_CARE_CPT_CHARGED
			,SERVICE_AGREEMENT_TRANSFER_FACILITY_ID
			,OVERRIDE_PHYSICIAN_SERVICE_GUIDELINE_ID
			,PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID 
			,USE_TIME_BASED_CHARGE_CAPTURE
			,TIME_BASED_CHARGE_CAPTURE_COMMENT
			,TIME_BASED_PHYSICIAN_LOS
			,POST_BILL_AUDIT_STARTED
			,POST_BILL_AUDIT_STARTED_BY_USER_ID 
			,POST_BILL_AUDIT_COMPLETED
			,POST_BILL_AUDIT_COMPLETED_BY_USER_ID
			,FLAGGED_FOR_POST_BILL_AUDIT_DT
			,ADD_59_XU_MODIFIER 
			,ANESTHESIA_CODING_COMPLETE
			,NO_ANESTHESIA_CODING
			,USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE
			,PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID
			,USE_INPATIENT_DOWNCODE_OPTION
			,BYPASS_AUTO_APPROVAL 
			,FACILITY_LOS_AF_MODIFIER
			,FACILITY_LOS_AG_MODIFIER
			,ADD_AI_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL
			,DO_NOT_APPLY_FACILITY_MODIFIER_25
			,ADD_MODIFIER_CG_TO_PHYSICIAN_LOS
			,USE_EXPERT_HISTORY_WORKSHEET_SECTION
			,USE_EXPERT_EXAM_WORKSHEET_SECTION
			,USE_EXPERT_MDM_WORKSHEET_SECTION 
			,ADD_MODIFIER_GQ_TO_PHYSICIAN_LOS
			,ADD_MODIFIER_GT_TO_PHYSICIAN_LOS
			,ADD_MODIFIER_G0_TO_PHYSICIAN_LOS
			,ADD_MODIFIER_95_TO_PHYSICIAN_LOS
			,FACILITY_LOS_CS_MODIFIER
			,ADD_MODIFIER_CS_TO_PHYSICIAN_LOS
			,FACILITY_LOS_95_MODIFIER
			,ADD_MODIFIER_CR_TO_PHYSICIAN_LOS
			,CHART_HAS_QA_SCORECARD_DATA 
			,CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES
			,CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE
			,CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE 
			,CLINIC_2021_TIME_BASED_ADDITIONAL_QUANTITY
			,CLINIC_2021_TIME_BASED_ADDITIONAL_CPT_CODE
			,ADD_MODIFIER_GV_TO_PHYSICIAN_LOS
			,PROVIDER_TYPE_CREDENTIALS_MODIFIER
			,SERVICE_AGREEMENT_PROVIDER_TYPE_CREDENTIAL_ID 
			,ADD_MODIFIER_EP_TO_PHYSICIAN_LOS
			,PROVIDER_SPECIFIED_LOS_PHYSICIAN_SERVICE_PROC_ID
			,PROVIDER_SPECIFIED_LOS_MODIFIER
			,ADMIT_SOURCE_ID, DATE_TIME_OF_DEATH 
			,FACILITY_AUTOMATION_CODING_COMPLETE
			,FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME
			,PHYSICIAN_AUTOMATION_CODING_COMPLETE
			,PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME
			,FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT 
			,ADD_MODIFIER_AF_TO_PHYSICIAN_LOS
            ,ADD_MODIFIER_AG_TO_PHYSICIAN_LOS
            ,CODER_ERROR_RESPONSE
            ,CODER_ERROR_RESPONSE_COMMENTS
            ,AUDITOR_ERROR_RESPONSE
            ,AUDITOR_ERROR_RESPONSE_COMMENTS
            ,CODER_RESPONSE_DATE
            ,AUDITOR_RESPONSE_DATE
            ,USE_TELEHEALTH
            ,ATTESTATION_SYNCHRONIZED_AV_PRESENT
            ,PLOS_ICD_10_CODE
            ,ADD_MODIFIER_AM_TO_PHYSICIAN_LOS
            ,ADD_MODIFIER_U7_TO_PHYSICIAN_LOS
            ,FACILITY_LOS_32_MODIFIER
            ,NO_PROVIDER_SPECIFIED_PROCEDURES
		    ,ADD_MODIFIER_SA_TO_PHYSICIAN_LOS
		    ,ADD_MODIFIER_93_TO_PHYSICIAN_LOS
		    ,FACILITY_LOS_93_MODIFIER
		    ,ADD_MODIFIER_FS_TO_PHYSICIAN_LOS 
	FROM 
		CHART
	WHERE 
	    SERVICE_AGREEMENT_ID= @SAId
		AND FACILITY_CHART_ID= @FacilityChartId;
			
END; -- end procedure


GO


/*
testing:
EXEC [dbo].[SelectChartByServiceAgreementIdAndFacilityChartId] 
			  @SAId = 93
			, @FacilityChartId ='FacChID2086061'
*/
-- End of 01) DACS-3013 - Create of Alter Stored Procedure - [dbo].[SelectChartByServiceAgreementIdAndFacilityChartId].SQL
GO

-- Start of 02) DACS-3013 - Create of Alter Stored Procedure - [dbo].[SelectChartIdByServiceAgreementIdAndFacilityChartId].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3013 - Create of Alter Stored Procedure - [dbo].[SelectChartIdByServiceAgreementIdAndFacilityChartId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartIdByServiceAgreementIdAndFacilityChartId] 
	  @SAId INT
	, @FacilityChartId varchar(50)
WITH EXEC AS CALLER AS
BEGIN

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		PRINT('bad @SAId');
		SELECT 'ERROR' = -1;
		RETURN 
	END;
		
	IF @FacilityChartId IS NULL OR LEN(@FacilityChartId) <= 0
	BEGIN
		PRINT('bad @FacilityChartId');
		SELECT 'ERROR' = -1;
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT top 1
		CHART_ID
	FROM 
		CHART
	WHERE 
	    SERVICE_AGREEMENT_ID= @SAId
		AND FACILITY_CHART_ID= @FacilityChartId;
			
END; -- end procedure


GO


/*
testing:
EXEC [dbo].[SelectChartIdByServiceAgreementIdAndFacilityChartId] 
			  @SAId = 93
			, @FacilityChartId ='FacChID2086061'
*/
-- End of 02) DACS-3013 - Create of Alter Stored Procedure - [dbo].[SelectChartIdByServiceAgreementIdAndFacilityChartId].SQL
GO

-- Start of 01) DACS-3163 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt] - gender correction.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3163 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt] - gender correction.SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt] 
	  @ChartId INT
	, @MeasureId INT
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G9315
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9313
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G9314
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList

	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList


	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	DECLARE @gender VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempChartInfo);

	IF (@gender IS NULL OR @gender IN ('U', 'X')) SET @gender = 'B';
	
	IF @gender <> 'B'
	BEGIN 
		DECLARE @genderCheck VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempMeasureInfo);
		
		IF @genderCheck IS NULL SET @genderCheck = 'B';

		IF @gender <> @genderCheck AND @genderCheck <> 'B'
		BEGIN 
			PRINT('@ChartId does not match gender test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not match gender test', 'Code' = 'ERR-0-GEN';
			RETURN;
		END;
	END;

	PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	
	SELECT TOP 1 
		@PSP_CPT = [CPT_CODE]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorGroup2Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2');
	DECLARE @foundDenominatorGroup2Pick3MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P3 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P3 records';
		RETURN;
	END;

	-- do we have a diag for acute sinusitus?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		PRINT('Date completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no acute sinusitus)', 'Code' = 'ERR-1-NAS';
		RETURN;
	END;
	
	-- are we missing both bacterial infection and G9364?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));

	IF @foundDenominatorGroup1Pick2MatchCount <= 0 AND @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no bacterial infection)', 'Code' = 'ERR-2-NBI';
		RETURN;
	END;
	
	-- do we have a Phys Svcs E and M code?
	SET @foundDenominatorGroup2Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2'));

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no E&M code match)', 'Code' = 'ERR-3-NEC';
		RETURN;
	END;

	-- do we have a antibiotic regimine (G9498) code?
	SET @foundDenominatorGroup2Pick3MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3'));

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no antibiotic regimine)', 'Code' = 'ERR-4-NAR';
		RETURN;
	END;

	-- all Data Completion steps satisified.
	PRINT('Performance Met: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + Performance Met) - G9315
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + denominator exception) - G9313
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + Performance NOT Met) - G9314
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + But no codes in chart already found for denominator value) - ????
	-- DECLARE @ResultPerformanceCodeMet VARCHAR(20) = (SELECT TOP 1 [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'HCPCS' AND [DESCRIPTION] LIKE 'Performance Met:%')
	-- DECLARE @ResultPerformanceCodeNotMet VARCHAR(20) = (SELECT TOP 1 [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'HCPCS' AND [DESCRIPTION] LIKE 'Performance Not Met:%')
	-- DECLARE @ResultPerformanceCodeExMet VARCHAR(20) = (SELECT TOP 1 [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'HCPCS' AND [DESCRIPTION] LIKE '%Performance Exclusion:%')

	DECLARE @foundG9315Count INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9315');  /*@ResultPerformanceCodeMet*/

	IF @foundG9315Count >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = 'G9315';
		RETURN;
	END;

	DECLARE @foundG9313Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9313');  /*@ResultPerformanceCodeExMet*/

	IF @foundG9313Count >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'G9313';
		RETURN;
	END;

	DECLARE @foundG9314Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9314');  /*@ResultPerformanceCodeNotMet*/

	IF @foundG9314Count >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = 'G9314';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code set from list (G9315,G9313,G9314)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '332'
begin tran; -- testing
*/
-- End of 01) DACS-3163 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt] - gender correction.SQL
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
