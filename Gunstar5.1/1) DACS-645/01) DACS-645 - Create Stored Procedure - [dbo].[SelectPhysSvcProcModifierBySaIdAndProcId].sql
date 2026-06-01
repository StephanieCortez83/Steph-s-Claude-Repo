----------------------------------------
-- 01) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcProcModifierBySaIdAndProcId].sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysSvcProcModifierBySaIdAndProcId]
    @SAId INT,
    @ProcId INT
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		[MODIFIER]
	FROM 
		[dbo].[PHYSICIAN_SERVICE_PROCEDURE]
	WHERE
		[SERVICE_AGREEMENT_ID] = @SAId
		AND [PHYSICIAN_SERVICE_PROC_ID] = @ProcId;

END
GO


