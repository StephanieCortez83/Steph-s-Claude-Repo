------------------------------------------------------------------------------------
-- 01) DACS-1996- Create of Alter Stored Procedure - [dbo].[SaidAndFidIsValid].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[ServiceAgreementIdAndFacilityIdAndOptionalDateOfServiceIsValid] 
	 @ServiceAgreementId INT
	,@FacilityId INT
	,@DateOfService datetime = NULL
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- When charts are updated from one facility to another, sometimes the destination combination of service agreement and facility id is invalid due to account setting adjustments
	-- This will cause a foreign key violation.  This stored proceedure will help check for this possible issue
	----------------

	----------------
	-- validate parameters
	----------------
	IF @ServiceAgreementId IS NULL OR @ServiceAgreementId <= 0
	BEGIN
		PRINT('@SaId is invalid');
		RETURN;
	END;

	IF @FacilityId IS NULL OR @FacilityId <= 0
	BEGIN
		PRINT('@FacilityId is invalid');
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @DateOfService IS NULL
	BEGIN
		SELECT 1 
		FROM 
			SERVICE_AGREEMENT 
		WHERE 
			SERVICE_AGREEMENT_ID = @ServiceAgreementId 
			AND FACILITY_ID = @FacilityId;
		RETURN;
	END;

	SELECT 1 
	FROM 
		SERVICE_AGREEMENT 
	WHERE 
		SERVICE_AGREEMENT_ID = @ServiceAgreementId 
		AND FACILITY_ID = @FacilityId
		AND [EFFECTIVE_DATE] <= @DateOfService
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @DateOfService)

END -- end procedure

GO

/*
testing:
exec [dbo].[ServiceAgreementIdAndFacilityIdAndOptionalDateOfServiceIsValid] 
	  @ServiceAgreementId = 336 -- 336 will return 1, 337 will return null
	, @FacilityId = 472
	, @DateOfService = NULL

begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing
*/