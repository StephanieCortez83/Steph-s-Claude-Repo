----------------------------------------------------------------
-- 02) DACS-2581 - Alter Procedure - dbo.spGetServiceAgreementClinics.SQL
----------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spGetServiceAgreementClinics]
	  @ServiceAgreementId int = null
	, @ClinicId varchar(10) = null

-- added field DEFAULT_SELECTION 20230720 - DACS-2581
	
WITH EXEC AS CALLER
AS
	DECLARE @service_agreement_id int = @ServiceAgreementId;
	DECLARE @clinic_id datetime = @ClinicId;

	SELECT 
		 [SERVICE_AGREEMENT_ID] 
		,[CLINIC_ID]
		,[DESCRIPTION]
		,[SERVICE_LINE_ID]
		,[NEW_PATIENT_CLASS_ID]
		,[ESTABLISHED_PATIENT_CLASS_ID]
		,[DEFAULT_SELECTION]
	FROM 
		[dbo].[SERVICE_AGREEMENT_CLINIC] WITH (NOLOCK)
	WHERE
		(@service_agreement_id IS NULL OR [SERVICE_AGREEMENT_ID] = @service_agreement_id)
		AND (@clinic_id IS NULL OR [CLINIC_ID] = @clinic_id)
	ORDER BY 
		[DESCRIPTION]; -- add ordering 20230607 - DACS-2457

GO


