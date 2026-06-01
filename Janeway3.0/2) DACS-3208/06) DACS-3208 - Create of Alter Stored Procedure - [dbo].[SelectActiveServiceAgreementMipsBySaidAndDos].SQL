------------------------------------------------------------------------------------
-- 06) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] 
	  @SaId INT
	, @Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN
		
	IF @SaId IS NULL OR @SaId <= 0
		RETURN;

	IF @Dos IS NULL
		SET @Dos = GETDATE();

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP 500
		[PQRS#]
	FROM 
		SERVICE_AGREEMENT_PQRS p
		INNER JOIN CMS_PQRI_MEASURE c ON c.CMS_PQRI_MEASURE_ID = p.CMS_PQRI_MEASURE_ID
	WHERE 
		SERVICE_AGREEMENT_ID= @SaId
		AND @Dos >= c.[EFFECTIVE_DATE]
		AND (c.[EXPIRATION_DATE] IS NULL OR c.[EXPIRATION_DATE] >= @Dos)
		AND @Dos >= p.[EFFECTIVE_DATE]
		AND (p.[EXPIRATION_DATE] IS NULL OR p.[EXPIRATION_DATE] >= @Dos)
	;

END -- end procedure

GO

/*
testing:
EXEC SelectActiveServiceAgreementMipsBySaidAndDos
	@SaId = 555266,
    @Dos = '1/22/2024 12:00:00 AM'
begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing
*/