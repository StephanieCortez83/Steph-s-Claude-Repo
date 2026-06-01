SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectChargeMasterCptCodeByMipsCodeAndServiceAgreementId]   
	 @MipsCode VARCHAR(10)
	,@ServiceAgreementId INT
AS
BEGIN  
	IF @ServiceAgreementId IS NULL OR @ServiceAgreementId <= 0 OR @MipsCode IS NULL OR LEN(RTrim(@MipsCode)) < 5
		RETURN;

	DECLARE @CptCode VARCHAR(5) = (
		SELECT TOP 1 
			[CPT_CODE] 
		FROM 
			[CHARGE_MASTER] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID]=@ServiceAgreementId
			AND [BILLING_CODE]=@MipsCode
			AND [CHARGE_MASTER_USAGE_CODE]=9	-- MIPS usage code
			AND LEN([CPT_CODE]) = 5
	);
	
	SELECT 'RESULT' = @CptCode;
	
	RETURN IIF(@CptCode IS NOT NULL, 1, 0);

/*
usage:
EXEC [dbo].[SelectChargeMasterCptCodeByMipsCodeAndServiceAgreementId] @ServiceAgreementId=555390,@MipsCode='XD3321';
DECLARE @res INT = 0;
EXEC @res = [dbo].[SelectChargeMasterCptCodeByMipsCodeAndServiceAgreementId] @ServiceAgreementId=555390,@MipsCode='XD3321';
SELECT 'res' = @res; -- testing

*/
END -- end SPROC

GO
