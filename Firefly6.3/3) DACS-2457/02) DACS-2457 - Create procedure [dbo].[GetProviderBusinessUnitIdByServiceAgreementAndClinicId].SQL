--------------------------------------------------------------------------
-- 02) DACS-2457 - Create procedure [dbo].[GetProviderBusinessUnitIdByServiceAgreementAndClinicId].SQL
--------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[GetProviderBusinessUnitIdByServiceAgreementAndClinicId]
	@ServiceAgreementId int, 
	@ClinicId varchar(10)
WITH EXEC AS CALLER
AS

-- Testing:
-- DECLARE @ServiceAgreementId int = 555115;
-- DECLARE @ClinicId varchar(10) = 'XXX' -- no returned data
-- DECLARE @ClinicId varchar(10) = 'COA' -- returned data
-- DECLARE @ClinicId varchar(10) = '&X<>X''X' -- no returned data
-- DECLARE @ClinicId varchar(10) = '<C>O&A''' -- returned data

-- some adjustments to avoid most hacking attempts.
SET @ClinicId = REPLACE(@ClinicId, '&', '')
SET @ClinicId = REPLACE(@ClinicId, '<', '')
SET @ClinicId = REPLACE(@ClinicId, '>', '')
SET @ClinicId = REPLACE(@ClinicId, '''', '')

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT TOP 1 
	[PROVIDER_BUSINESS_UNIT_ID]
FROM 
	[dbo].[PROVIDER_BUSINESS_UNIT]
    INNER JOIN [dbo].[SERVICE_AGREEMENT_CLINIC] 
		ON [SERVICE_AGREEMENT_CLINIC].[SERVICE_AGREEMENT_ID] = [PROVIDER_BUSINESS_UNIT].[SERVICE_AGREEMENT_ID]
		AND [SERVICE_AGREEMENT_CLINIC].[CLINIC_ID] = [PROVIDER_BUSINESS_UNIT].[BUSINESS_UNIT_NAME]
WHERE 
	[SERVICE_AGREEMENT_CLINIC].[SERVICE_AGREEMENT_ID] = @ServiceAgreementId 
	AND [SERVICE_AGREEMENT_CLINIC].[CLINIC_ID] = @ClinicId;

GO

-- Testing: 
-- exec [dbo].[GetProviderBusinessUnitIdByServiceAgreementAndClinicId] @ServiceAgreementId = 555115, @ClinicId = '<C>O&A''';


