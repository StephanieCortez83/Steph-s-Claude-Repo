------------------------------------------------------------------------------------
-- 01) DACS-3243 - Create of Alter Stored Procedure - [dbo].[SelectPhysicianServiceProcIdAndInUseByServiceAgreementId].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysicianServiceProcIdAndInUseByServiceAgreementId] 
	  @serviceAgreementId INT
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- SQL Originally created by Mr. Sexton
	-- Leaving substantially as written
	----------------

	----------------
	-- validate parameters
	----------------
	IF @serviceAgreementId IS NULL OR @serviceAgreementId <= 0
	BEGIN
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- DECLARE @ServiceAgreementId INT = 1009 -- testing
	 
	IF OBJECT_ID('TempDB..#ProcIDs', 'U') IS NOT NULL DROP TABLE #ProcIDs
	IF OBJECT_ID('TempDB..#Results', 'U') IS NOT NULL DROP TABLE #Results
	 
	SELECT  
		physician_service_proc_ID
		, Service_Agreement_Id
	INTO 
		#ProcIDs
	FROM 
		PHYSICIAN_SERVICE_PROCEDURE 
	WHERE 
		SERVICE_AGREEMENT_ID = @serviceAgreementId
	 
	SELECT 
		service_agreement_ID
		, physician_service_proc_ID
		, RowCnt = count(*)
	INTO 
		#Results
	FROM 
		chart
	WHERE 
		service_agreement_ID = @serviceAgreementId
		AND (
				physician_service_proc_ID IN (SELECT physician_service_proc_ID FROM #ProcIDs)
				OR override_physician_service_proc_ID IN (SELECT physician_service_proc_ID FROM #ProcIDs)
			)
	GROUP BY 
		service_agreement_ID
		, physician_service_proc_ID
	 
	-- SELECT * FROM #Results	 -- for reference/testing		 
	-- SELECT sum(RowCnt) FROM #Results		-- 256666       -- for reference/testing
	 
	SELECT 
		--t1.service_agreement_ID,
		t1.physician_service_proc_ID
		, IN_USE = CASE WHEN t2.RowCnt IS NULL THEN 0 ELSE 1 END
	FROM 
		#ProcIDs AS t1
		LEFT JOIN #Results AS t2 
			ON t1.service_agreement_ID = t2.service_agreement_ID
			AND t1.physician_service_proc_ID = t2.physician_service_proc_ID
	ORDER BY 
		IN_USE DESC
		, physician_service_proc_ID

END -- end procedure

GO

/*
testing:
begin tran; -- testing
EXEC [SelectPhysicianServiceProcIdAndInUseByServiceAgreementId] @serviceAgreementId=1009
rollback tran; -- testing
commit tran; -- testing
*/
