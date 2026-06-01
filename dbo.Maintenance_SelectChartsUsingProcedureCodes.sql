SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_SelectChartsUsingProcedureCodes]
	 @SAIdList VARCHAR(1000)			-- i.e. 440,1029,333, ....
	,@ProcedureCodeList VARCHAR(2000)	-- i.e. 99999,99292,0010A, ....
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- copy string lists to temp tables
	DECLARE @tempSAIds TABLE	( SAID INT );
	INSERT @tempSAIds(SAID)
		SELECT 
			CAST(RTRIM(LTRIM(value)) AS INT) AS SAID
		FROM STRING_SPLIT (@SAIdList, ',')

	DECLARE @tempProcedureCodes TABLE	( PCCD VARCHAR(5) );
	INSERT @tempProcedureCodes(PCCD)
		SELECT 
			CAST(RTRIM(LTRIM(value)) AS VARCHAR(5)) AS PCCD
		FROM STRING_SPLIT (@ProcedureCodeList, ',')

	-- select * from @tempSAIds; -- testing
	-- select * from @tempProcedureCodes; -- testing

	SELECT top 1000 
		 cm.CPT_CODE
		,coer.CHART_ID
		FROM CHART_OBSERVATION_ENCOUNTER_RESULT coer
		inner join CHARGE_MASTER cm ON cm.charge_master_id = coer.charge_master_id
		inner join SERVICE_AGREEMENT sa ON sa.service_agreement_id = cm.service_agreement_id
		WHERE
		(sa.[EXPIRATION_DATE] IS NULL OR sa.[EXPIRATION_DATE] >= GETDATE())
		AND 
		cm.SERVICE_AGREEMENT_ID IN (SELECT DISTINCT SAID FROM @tempSAIds)
		AND 
		cm.CPT_CODE IN (SELECT DISTINCT PCCD FROM @tempProcedureCodes)
	
	
END -- end of stored procedure
GO
