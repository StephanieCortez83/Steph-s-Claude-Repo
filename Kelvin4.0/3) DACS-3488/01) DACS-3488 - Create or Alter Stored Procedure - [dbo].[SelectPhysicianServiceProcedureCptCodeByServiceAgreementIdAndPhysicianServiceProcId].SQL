------------------------------------------------------------------------------------
-- 01) DACS-3488 - Create or Alter Stored Procedure - [dbo].[SelectPhysicianServiceProcedureCptCodeByServiceAgreementIdAndPhysicianServiceProcId].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysicianServiceProcedureCptCodeByServiceAgreementIdAndPhysicianServiceProcId] 
	  @ServiceAgreementId INT
	 ,@PhysicianServiceProcId INT
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- This SPROC is used a great deal.
	-- validation of parameters being handled within ACS for better efficiency.
	-- replaces the following C# segment:
	/*
		sql = "SELECT CPT_CODE "
					+ "FROM PHYSICIAN_SERVICE_PROCEDURE "
					+ "WHERE "
					+ "     SERVICE_AGREEMENT_ID = " + saID.ToString()
					+ " AND PHYSICIAN_SERVICE_PROC_ID = " + procID.ToString()
					+ andStr;
		in method "public String GetCPTCode(int saId, int procId)" of file "\ACS\CCSBusinessObjects\DAO\Physician\PhysicianServiceEvaluationListDAO.cs" at ~line# 1808
	*/
	----------------
	
	--IF @ServiceAgreementId IS NULL OR @ServiceAgreementId <= 0 OR @PhysicianServiceProcId IS NULL OR @PhysicianServiceProcId <= 0
	--	RETURN;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- result
	----------------
	SELECT TOP 1 
		[CPT_CODE] 
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
    WHERE 
        [SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND [PHYSICIAN_SERVICE_PROC_ID] = @PhysicianServiceProcId;	

END -- end procedure

GO
