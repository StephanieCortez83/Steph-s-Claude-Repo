SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[PHYSICIAN_PROCEDURE_EVALUATION_DELETE_TIME_BASED_SERVICES_BY_CHART_ID]
	@CHART_ID INT = NULL
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Delete all Physician Procedure Evaluation rows containing
-- 'time-based' CPT codes '99417' and 'G2212'.
-- Only delete rows if the code is defined with a usage of 4 ('Physician Service')
-- in the chart's service agreement's charge master. 
-- Codes defined in this way are added through the Physican Evaluation and 
-- Management screen. Time-based codes with any other usage should NOT be deleted
DELETE
	[PPE]
FROM
	[PHYSICIAN_PROCEDURE_EVALUATION] AS [PPE]
JOIN
	[CHARGE_MASTER] AS [CMA]
ON	[PPE].[PHYSICIAN_PROCEDURE_ID] = [CMA].[CHARGE_MASTER_ID]
WHERE  
	[PPE].[CHART_ID] = @CHART_ID
AND
(
	(
		[CMA].[CPT_CODE] = '99417'
	AND	[CMA].[CHARGE_MASTER_USAGE_CODE] = 4
	)
	OR
	(
		[CMA].[CPT_CODE] = 'G2212'
	AND	[CMA].[CHARGE_MASTER_USAGE_CODE] = 4
	)
)

GO
