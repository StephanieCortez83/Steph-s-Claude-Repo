SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectChargeMasterDepartmentNameByChargeMasterDepartmentId]   
	 @ChargeMasterDepartmentId INT
AS
BEGIN  
	IF @ChargeMasterDepartmentId IS NULL OR @ChargeMasterDepartmentId <= 0 
		RETURN;

	DECLARE @Name VARCHAR(50) = (
		SELECT TOP 1 
			[NAME] 
		FROM 
			[CHARGE_MASTER_DEPARTMENT] WITH (NOLOCK)
		WHERE 
			[CHARGE_MASTER_DEPT_ID] = @ChargeMasterDepartmentId
	);
	
	SELECT 'RESULT' = @Name;
	
	RETURN IIF(@Name IS NOT NULL, 1, 0);

/*
usage:
EXEC [dbo].[SelectChargeMasterDepartmentNameByChargeMasterDepartmentId] @ChargeMasterDepartmentId=2100118399
DECLARE @res INT = 0;
EXEC @res = [dbo].[SelectChargeMasterDepartmentNameByChargeMasterDepartmentId] @ChargeMasterDepartmentId=2100118399
SELECT 'res' = @res; -- testing

*/
END -- end SPROC

GO
