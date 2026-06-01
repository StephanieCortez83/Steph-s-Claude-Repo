----------------------------------------------------------------
-- 03) DACS-2581 - Alter Procedure - dbo.spSaveServiceAgreementClinic.SQL
----------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spSaveServiceAgreementClinic]
	  @ServiceAgreementId int = null
	, @ClinicId varchar(10) = null
	, @Description varchar(100) = null
	, @NewClinicId varchar(10) = null
	, @DefaultSelection bit = null
	
-- added field DEFAULT_SELECTION 20230720 - DACS-2581
	
WITH EXEC AS CALLER
AS
	UPDATE 
		[dbo].[SERVICE_AGREEMENT_CLINIC]
	SET
		 [SERVICE_AGREEMENT_ID] = @ServiceAgreementId 
		,[CLINIC_ID] = @NewClinicId
		,[DESCRIPTION] = @Description
		,[DEFAULT_SELECTION] = @DefaultSelection
	WHERE 
		[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND [CLINIC_ID] = @ClinicId
		
	IF @@ROWCOUNT = 0
	BEGIN
	  INSERT INTO [dbo].[SERVICE_AGREEMENT_CLINIC] ( 
		 [SERVICE_AGREEMENT_ID]
		,[CLINIC_ID]
		,[DESCRIPTION]
		,[SERVICE_LINE_ID]
		,[DEFAULT_SELECTION]
	  )
	  VALUES 
	  (
		 @ServiceAgreementId
		,@ClinicId
		,@Description
		,-1
		,@DefaultSelection
	  )
	END
GO


