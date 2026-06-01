SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectChargeMasterCptCodeByChargeMasterId]   
	 @ChargeMasterId INT
AS
BEGIN  
	IF @ChargeMasterId IS NULL OR @ChargeMasterId <= 0 
		RETURN;

	DECLARE @CptCode VARCHAR(5) = (
		SELECT TOP 1 
			[CPT_CODE] 
		FROM 
			[CHARGE_MASTER] WITH (NOLOCK)
		WHERE 
			[CHARGE_MASTER_ID] =  @ChargeMasterId
			AND LEN([CPT_CODE]) = 5
	);
	
	SELECT 'RESULT' = @CptCode;
	
	RETURN IIF(@CptCode IS NOT NULL, 1, 0);

/*
usage:
EXEC [dbo].[SelectChargeMasterCptCodeByChargeMasterId] @ChargeMasterId=2100118399
DECLARE @res INT = 0;
EXEC @res = [dbo].[SelectChargeMasterCptCodeByChargeMasterId] @ChargeMasterId=2100118399
SELECT 'res' = @res; -- testing

*/
END -- end SPROC

GO
