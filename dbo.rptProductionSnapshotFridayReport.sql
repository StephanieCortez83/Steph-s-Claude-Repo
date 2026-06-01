SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









-- ==========================================================
-- Author:		Don Hutton
-- Create date: 2/12/2016
-- Description:	Based on Production Snapshot Report Stored Procedure

-- ==========================================================
CREATE PROCEDURE [dbo].[rptProductionSnapshotFridayReport]
	-- Add the parameters for the stored procedure here
	@AcctMgrID varchar(MAX),
	@Facility varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @m_AcctMgrID varchar(MAX) = @AcctMgrID,
	    @m_Facility varchar(MAX) = @Facility ,
		@Today DATE = GETDATE(),
		@TodayM60 DATE = GETDATE() - 7;

		WITH ProductionSnapshot
	AS (
		SELECT 
		sa.SERVICE_AGREEMENT_ID,
		CASE 
				WHEN sa.[RCP_BILLING_IND] = 1
					THEN 'Billing'
				WHEN sa.[SERVICE_MODEL_CD] = 'ASP'
					THEN 'Software as a Service (SaaS)'
				ELSE 'Full Service'
				END [Service],
			f.[NAME] Faclity,
			SUM(CASE 
					WHEN c.CHART_STATUS_ID = 1
						THEN 1
					ELSE 0
					END) 'Work in Process',
			SUM(CASE 
					WHEN c.CHART_STATUS_ID = 2
						THEN 1
					ELSE 0
					END) 'Pending',
			SUM(CASE 
					WHEN c.CHART_STATUS_ID = 3
						THEN 1
					ELSE 0
					END) 'Complete',
			SUM(CASE 
					WHEN c.CHART_STATUS_ID = 4
						THEN 1
					ELSE 0
					END) 'Approved',
			SUM(CASE 
					WHEN c.CHART_STATUS_ID = 8
						THEN 1
					ELSE 0
					END) 'SecondAudit',					
			SUM(CASE 
					WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.CREATION_DATE_TIME), 0) = @Today
						THEN 1
					ELSE 0
					END) 'Received',			
			SUM(CASE 
					WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.SENT_DATE), 0) = DATEADD(DD, - 1, @Today)
						THEN 1
					ELSE 0
					END) 'SentYestrday',
			
			(
				SELECT SUM(TOTAL) / COUNT(*)
				FROM (
					SELECT DATEADD(DAY, DATEDIFF(DAY, 0, TIME_OF_SERVICE), 0) DOS,
						COUNT(*) TOTAL
					FROM CHART WITH (NOLOCK)
					WHERE SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
            AND TIME_OF_SERVICE >= sa.EFFECTIVE_DATE
            AND TIME_OF_SERVICE < @Today
            AND CHART_STATUS_ID IN (1,2,3,4,5,8)
			and facility_id in (SELECT * FROM SPLITSTRING(@m_Facility, ','))
						AND DATEDIFF(DAY, @TodayM60, DATEADD(DAY, DATEDIFF(DAY, 0, TIME_OF_SERVICE), 0)) > 0
					GROUP BY DATEADD(DAY, DATEDIFF(DAY, 0, TIME_OF_SERVICE), 0)
					) x
				) 'Avg Daily Volume'
		FROM SERVICE_AGREEMENT sa WITH (NOLOCK)
		INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = sa.FACILITY_ID
		LEFT JOIN CHART c WITH (NOLOCK) ON c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		WHERE ISNULL(sa.DEMO_TEST_SITE_IND, 0) = 0
			AND @Today BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE
			AND sa.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_Facility, ','))
			
		GROUP BY 
		sa.SERVICE_AGREEMENT_ID,
		sa.SERVICE_MODEL_CD,
		f.NAME,
		sa.EFFECTIVE_DATE,
		sa.RCP_BILLING_IND
		)
	SELECT *,
	CAST([Work in Process] AS DECIMAL) / [Avg Daily Volume] 'DOS in WIP'		
	FROM ProductionSnapsHot
	where  SERVICE_AGREEMENT_ID IN (
					SELECT [SERVICE_AGREEMENT_ID]
					FROM [SERVICE_AGREEMENT_MANAGEMENT_TEAM] WITH (NOLOCK)
					WHERE USER_PROFILE_ID IN (SELECT * FROM SPLITSTRING(@m_AcctMgrID, ','))
					)
	ORDER BY [Service],
		[Faclity]


	
END









GO
GRANT EXECUTE ON  [dbo].[rptProductionSnapshotFridayReport] TO [dbx_ExecuteReportProcs]
GO
