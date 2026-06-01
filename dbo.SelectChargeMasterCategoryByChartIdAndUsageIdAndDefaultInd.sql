SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectChargeMasterCategoryByChartIdAndUsageIdAndDefaultInd]
    @ChartId INT,
    @UsageCode INT,
    @DefaultInd BIT
WITH EXEC AS CALLER
AS
BEGIN
    -- setup resources
    SET NOCOUNT ON;

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    ----------------
    -- validate parameters
    ----------------
    DECLARE @TimeOfService DATETIME,
            @ServiceAgreementId INT,
            @PatientClassId INT;

    SELECT @TimeOfService = TIME_OF_SERVICE,
           @ServiceAgreementId = SERVICE_AGREEMENT_ID,
           @PatientClassId = PATIENT_CLASS_ID
    FROM CHART
    WHERE [CHART_ID] = @ChartId;

    IF @TimeOfService IS NULL
        RETURN;



    WITH codes
    AS (SELECT DISTINCT
               cm.CHARGE_MASTER_ID,
               cm.CHARGE_MASTER_CATEGORY_ID
        FROM dbo.CHARGE_MASTER cm
        WHERE cm.SERVICE_AGREEMENT_ID = @ServiceAgreementId
              AND [CHARGE_MASTER_USAGE_CODE] = @UsageCode
              AND
              (
                  [PATIENT_CLASS_ID] = -1
                  OR [PATIENT_CLASS_ID] = @PatientClassId
              )
              AND @TimeOfService
              BETWEEN [EFFECTIVE_DATE] AND [EXPIRATION_DATE])
    SELECT cmc.[CHARGE_MASTER_CATEGORY_ID],
           cmc.[DESCRIPTION],
           CAST(CASE
                    WHEN
                    (
                        @DefaultInd = 1
                        AND [VISIBLE] = 1
                    ) THEN
                        1
                    WHEN
                    (
                        @DefaultInd = 0
                        AND EXISTS
                            (
                                SELECT TOP 1
                                       1
                                FROM [PHYSICIAN_PROCEDURE_EVALUATION] ppe
                                    INNER JOIN codes c
                                        ON ppe.PHYSICIAN_PROCEDURE_ID = c.CHARGE_MASTER_ID
                                WHERE [CHART_ID] = @ChartId
                            )
                    ) THEN
                        1
                    ELSE
                        0
                END AS BIT) VISIBLE
    FROM dbo.CHARGE_MASTER_CATEGORY cmc
    WHERE EXISTS
    (
        SELECT 1
        FROM codes cm
        WHERE cmc.CHARGE_MASTER_CATEGORY_ID = cm.CHARGE_MASTER_CATEGORY_ID
    )
    ORDER BY cmc.[DESCRIPTION];
----------------
-- Replaces the following ACS inline SQL:
----------------
/*
C:\Repos\ACS\CCSBusinessObjects\DAO\Physician\SimplePhysicianProcedureCategoryListDAO.cs
    public List<SimplePhysicianProcedureCategoryListItem> LoadAllForChart(int chartId, int usageCode, bool defaultInd)
    
Chart chart = new ChartDAO(RequestManager).Load(chartId);
const string sql = @"select CHARGE_MASTER_CATEGORY_ID,
                            [DESCRIPTION],  
                            case when (@defaultInd=1 and VISIBLE=1) then cast(1 as bit)
                                 when (@defaultInd=0 
                                    and (select count(*) 
                                         from PHYSICIAN_PROCEDURE_EVALUATION
                                         where CHART_ID = c.CHART_ID
                                           and PHYSICIAN_PROCEDURE_ID = (select cm.CHARGE_MASTER_ID
                                                                         from CHARGE_MASTER cm
                                                                         where cm.CHARGE_MASTER_ID=PHYSICIAN_PROCEDURE_ID
                                                                           and cm.CHARGE_MASTER_CATEGORY_ID=cmc.CHARGE_MASTER_CATEGORY_ID
                                                                           and cm.CHARGE_MASTER_USAGE_CODE=@usageCode
                                                                           and @chartDOS between cm.EFFECTIVE_DATE	and cm.EXPIRATION_DATE
                                                                           and (cm.PATIENT_CLASS_ID=-1 or cm.PATIENT_CLASS_ID=c.PATIENT_CLASS_ID))) > 0) then cast(1 as bit) 
                                 else cast(0 as bit) end VISIBLE
                     from CHARGE_MASTER_CATEGORY cmc
                       join CHART c on c.CHART_ID=@chartId
                     where CHARGE_MASTER_CATEGORY_ID in (select distinct CHARGE_MASTER_CATEGORY_ID
                                                         from CHARGE_MASTER
                                                         where SERVICE_AGREEMENT_ID=c.SERVICE_AGREEMENT_ID
                                                           and CHARGE_MASTER_USAGE_CODE=@usageCode
                                                           and (PATIENT_CLASS_ID=-1 or PATIENT_CLASS_ID=c.PATIENT_CLASS_ID)
                                                           and @chartDOS between EFFECTIVE_DATE	and EXPIRATION_DATE)
                     order by [DESCRIPTION]";

using (var cmd = RequestManager.DBManager.GetCommand(sql))
{
    AddParameter(cmd, "@chartId", chartId);
    AddParameter(cmd, "@usageCode", usageCode);
    AddParameter(cmd, "@defaultInd", defaultInd);
    AddParameter(cmd, "@chartDOS", chart.TimeOfService.Date);

usage example:
exec [dbo].[SelectChargeMasterCategoryByChartIdAndUsageIdAndDefaultInd] 
     @ChartId = 136625105
    ,@UsageCode = 5
    ,@DefaultInd = 1 ;
*/
END; -- end procedure
GO
