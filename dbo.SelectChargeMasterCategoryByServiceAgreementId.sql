SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectChargeMasterCategoryByServiceAgreementId] 
	@ServiceAgreementId INT
WITH EXEC AS CALLER AS
BEGIN
	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		 [CHARGE_MASTER_CATEGORY_ID]
		,[DESCRIPTION]
		,[VISIBLE]
	FROM 
		[CHARGE_MASTER_CATEGORY]
	WHERE 
		[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
	ORDER BY 
		[DESCRIPTION]
	;

/*
usage example:
exec [dbo].[SelectChargeMasterCategoryByServiceAgreementId] 2578
*/
END -- end procedure

GO
