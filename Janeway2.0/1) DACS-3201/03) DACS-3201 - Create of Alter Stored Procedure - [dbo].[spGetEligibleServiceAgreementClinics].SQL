------------------------------------------------------------------------------------
-- 03) DACS-3201 - Create of Alter Stored Procedure - [dbo].[spGetEligibleServiceAgreementClinics].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spGetEligibleServiceAgreementClinics] 
(
	@ServiceAgreementId INT
	,@DateOfService DATETIME = NULL
)
AS
BEGIN
	----------------
	-- This update created by Mr. Burge CDBT-330
	-- Modified by pippin DACS-3201
	----------------

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		[CLINIC_ID]
		,[DESCRIPTION]
	FROM 
		[dbo].[SERVICE_AGREEMENT_CLINIC]
	WHERE 
		[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND ( @DateOfService BETWEEN ISNULL(EFFECTIVE_DATE, @DateOfService) AND ISNULL(EXPIRATION_DATE, @DateOfService)	OR @DateOfService IS NULL )
	ORDER BY 
		[DESCRIPTION];

END -- end procedure

GO

/*
testing:
	--SELECT SERVICE_AGREEMENT_ID,count(1) FROM [SERVICE_AGREEMENT_CLINIC] group by SERVICE_AGREEMENT_ID order by count(1) desc
begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing

Replaces:
CREATE    PROCEDURE [dbo].[spGetEligibleServiceAgreementClinics]  
   @ServiceAgreementId int
 , @DateOfService datetime = null
  
AS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN
   IF @DateOfService IS NULL
   BEGIN
		SELECT   
			[CLINIC_ID]  
			,[DESCRIPTION]  
		FROM   
			[dbo].[SERVICE_AGREEMENT_CLINIC] 
		WHERE  
			[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		ORDER BY   
			[DESCRIPTION];
	END
	ELSE
	BEGIN
		SELECT   
			[CLINIC_ID]  
			,[DESCRIPTION]  
		FROM   
			[dbo].[SERVICE_AGREEMENT_CLINIC]
		WHERE  
			[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
			AND 
			((EFFECTIVE_DATE IS NULL OR EFFECTIVE_DATE <= @DateOfService)
			AND
			(EXPIRATION_DATE IS NULL OR EXPIRATION_DATE >= @DateOfService))
			ORDER BY   
			[DESCRIPTION];
	END
END

*/