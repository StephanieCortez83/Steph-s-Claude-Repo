----------------------------------------
-- 07) DACS-3581 - Create or Alter procedure - [dbo].[spMipsReturnQuestionResponses].SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- drop PROCEDURE
DROP PROCEDURE IF EXISTS spMipsReturnQuestionResponses;

-- drop TYPE 
DROP TYPE IF EXISTS tDenominatorInfo;

CREATE TYPE tDenominatorInfo AS TABLE
(
	 [Code] VARCHAR(32) NULL
	,[CodingSystem] VARCHAR(32) NULL
	,[Description] VARCHAR(500) NULL
	,[Modifier] VARCHAR(64) NULL
) --WITH ( MEMORY_OPTIMIZED = ON )
GO	
------------------------------------------------------------------------------------


CREATE or ALTER PROCEDURE [dbo].[spMipsReturnQuestionResponses]
(
	 @DenominatorInfo tDenominatorInfo READONLY
	,@MeasureId INT
)
WITH EXECUTE AS CALLER
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM @DenominatorInfo tdl WHERE tdl.[CodingSystem] = 'DQ411' AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0)
		SELECT 'RESULT' = '411', 'QUESTION' = ' ', 'CODE' = '00001';
	ELSE
		SELECT TOP 5
			'411' AS 'RESULT'
			, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
			, tdl.[Code] AS 'CODE'
		FROM 
			@DenominatorInfo tdl
		WHERE 
			tdl.[CodingSystem] = 'DQ411'
			AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0
		ORDER BY
			tdl.[Code];
END;

GO

/*
-- testing
DECLARE @DenominatorInfo tDenominatorInfo;
-- fill with data
EXEC spMipsReturnQuestionResponses @DenominatorInfo=@DenominatorInfo, @MeasureId=148;
*/

