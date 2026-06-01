SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 8/30/2013
-- Description:	SQL for the Operations Summary - OPS Mgmt Edition Report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_OperationsSummary_OpsMgmt] 
	-- Add the parameters for the stored procedure here
  @ReportDate DATE,
	@AccountManager INT = -1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @m_ReportDate DATE = @ReportDate;
    DECLARE @m_AccountManager INT = @AccountManager;

    ;WITH Times AS
    (
      SELECT c.CHART_ID ChartID,
             c.COMPLETION_DATE Completed,
             c.CHART_STATUS_ID Status,
             c.SENT_DATE Sent,
             c.APPROVED_DATE Approved,
             c.DATE_RECEIVED Received,
            ISNULL((SELECT MAX(CREATION_DATE_TIME) 
                    FROM IMPORT_IMAGE WITH (NOLOCK) 
                    WHERE CHART_ID = c.CHART_ID
                      AND CREATION_DATE_TIME <= CASE WHEN c.CHART_STATUS_ID = 5 THEN c.SENT_DATE
                                                     WHEN c.CHART_STATUS_ID = 4 THEN c.APPROVED_DATE
                                                     WHEN c.CHART_STATUS_ID = 3 THEN c.COMPLETION_DATE
                                                     ELSE c.DATE_RECEIVED END), c.DATE_RECEIVED) LastImageReceived,
            ISNULL((SELECT MAX(ln.COMPLETION_DATE) 
                    FROM LOG_NOTE ln WITH (NOLOCK)
                    WHERE ln.CHART_ID = c.CHART_ID 
                      AND (ln.CATEGORY_ID = 5 
                       OR (ln.CATEGORY_ID = 8 
                       AND ln.SUMMARY LIKE 'Chart status changed to Work in Progress%'))), c.DATE_RECEIVED) LastTransitionWIP
      FROM CHART c WITH (NOLOCK)
      WHERE c.CHART_STATUS_ID in (1,2,3,4,5)
    ),
    ClockStarted AS 
    (
      SELECT ChartID,
             CASE WHEN LastImageReceived > LastTransitionWIP AND Sent > LastImageReceived THEN LastImageReceived ELSE LastTransitionWIP END ClockStarted
      FROM Times
    )
    select case when sa.SERVICE_MODEL_CD = 'ASP' then 'Software as a Service (SaaS)' else 'Full Service' end 'Service',
           cpy.[NAME] Organization,
           sa.DESCRIPTION Account,
           x.ReceivedITD,
           x.CompletedITD,
           x.ReceivedToday,
           x.CompletedToday,
           x.ApprovedToday,
           x.SentToday,
           x.ReceivedMTD,
           x.CompletedMTD,
           sa.ANNUAL_VOLUME Volume,
           (select count(*) from import_image ii with (nolock)
			          where ii.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
				        and   convert(varchar, ii.CREATION_DATE_TIME, 112) = convert(varchar, @m_ReportDate, 112)) DocumentsToday,
           (select max(ii.CREATION_DATE_TIME) 
            from import_image ii with (nolock)
			      where ii.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID) LastDocumentRecd,
           x.WIP,
           x.WIP24_48,
           x.WIP48_72,
           x.WIP72,
           x.Pended,
           x.Pended24,
           x.Pended24_48,
           x.Pended48h_30d,
           x.Pended30_60,
           x.Pended60_90,
           x.Pended90,
           x.OldestDOS,
           x.TotalMinutes,
           x.TotalCompleted_DOS30,
           x.TotalMinutes_CompleteToApproved30,
           x.TotalCompleted_Recd30,
           x.TotalMinutes_Recd30,
           x.TotalMinutes_RecdToSent30,
           (SELECT CASE WHEN SUM(car.FA) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.oha) + SUM(car.oia) + SUM(car.opa) + SUM(car.DEMA) <> 0 
                        THEN (SUM(car.FLOSE) + SUM(car.FPROCE) + SUM(car.FINJE) + SUM(car.PLOSE) + SUM(car.PPROCE) + SUM(car.DE) +SUM(car.ohe) + SUM(car.oie) + SUM(car.ope) + SUM(car.DEME))/CONVERT(DECIMAL(9,4),(SUM(car.FA) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.oha) + SUM(car.oia) + SUM(car.opa) + SUM(car.DEMA))) ELSE 0 END
            FROM CHART_AUDIT_RESULT car WITH (NOLOCK)
              JOIN USER_PROFILE up WITH(NOLOCK) ON up.USER_PROFILE_ID = car.CUID
            WHERE  DATEADD(dd, DATEDIFF(dd, 0, car.APPROVED_DATE), 0) BETWEEN DATEADD(DAY, -30, @m_ReportDate) AND @m_ReportDate
              AND (car.FACILITY_ID=sa.FACILITY_ID)) AS AccuracyRate
    from SERVICE_AGREEMENT sa with (nolock), COMPANY cpy with (nolock),
        (select c.SERVICE_AGREEMENT_ID,
           count(*) ReceivedITD,
           sum(case when c.CHART_STATUS_ID in (3,4,5) then 1 else 0 end) CompletedITD,
           sum(case when DATEADD(dd, DATEDIFF(dd, 0, c.DATE_RECEIVED), 0) >= @m_ReportDate
              then 1 else 0 end) ReceivedMTD,
           sum(case when DATEADD(dd, DATEDIFF(dd, 0, c.COMPLETION_DATE), 0) >= @m_ReportDate
              then (case when c.chart_status_id in (3,4,5) then 1 else 0 end) else 0 end) CompletedMTD,
           sum(case when dateadd(dd, datediff(dd, 0, c.DATE_RECEIVED), 0) = @m_ReportDate
              then 1 else 0 end) ReceivedToday,
           sum(case when dateadd(dd, datediff(dd, 0, c.COMPLETION_DATE), 0) = @m_ReportDate
              then 1 else 0 end) CompletedToday,
           sum(case when dateadd(dd, datediff(dd, 0, c.APPROVED_DATE), 0) = @m_ReportDate
              then 1 else 0 end) ApprovedToday,
           sum(case when dateadd(dd, datediff(dd, 0, c.SENT_DATE), 0) = @m_ReportDate
              then 1 else 0 end) SentToday,
           sum(case when c.chart_status_id = 1 then 1 else 0 end) WIP,
           sum(case when c.chart_status_id = 1 then (case when DATEDIFF(hh,@m_ReportDate,cs.ClockStarted) <= -24 then (case when DATEDIFF(hh,@m_ReportDate,cs.ClockStarted) > -48 then 1 else 0 end) else 0 end) else 0 end) WIP24_48,
           sum(case when c.chart_status_id = 1 then (case when DATEDIFF(hh,@m_ReportDate,cs.ClockStarted) <= -48 then (case when DATEDIFF(hh,@m_ReportDate,cs.ClockStarted) > -72 then 1 else 0 end) else 0 end) else 0 end) WIP48_72,       
           sum(case when c.chart_status_id = 1 then (case when DATEDIFF(hh,@m_ReportDate,cs.ClockStarted) <= -72 then 1 else 0 end) else 0 end) WIP72,       
           sum(case when c.chart_status_id = 2 then 1 else 0 end) Pended,
           sum(case when c.chart_status_id = 2 then (case when DATEDIFF(hh,@m_ReportDate,cs.ClockStarted) > -24 then 1 else 0 end) else 0 end) Pended24,
           sum(case when c.chart_status_id = 2 then (case when DATEDIFF(hh,@m_ReportDate,cs.ClockStarted) <= -24 then (case when DATEDIFF(hh,@m_ReportDate,cs.ClockStarted) > -48 then 1 else 0 end) else 0 end) else 0 end) Pended24_48,
           sum(case when c.chart_status_id = 2 then (case when DATEDIFF(hh,@m_ReportDate,cs.ClockStarted) <= -48 then (case when DATEDIFF(dd,@m_ReportDate,cs.ClockStarted) > -30 then 1 else 0 end) else 0 end) else 0 end) Pended48h_30d,
           sum(case when c.chart_status_id = 2 then (case when DATEDIFF(dd,@m_ReportDate,cs.ClockStarted) <= -30 then (case when DATEDIFF(dd,@m_ReportDate,cs.ClockStarted) > -60 then 1 else 0 end) else 0 end) else 0 end) Pended30_60,
           sum(case when c.chart_status_id = 2 then (case when DATEDIFF(dd,@m_ReportDate,cs.ClockStarted) <= -60 then (case when DATEDIFF(dd,@m_ReportDate,cs.ClockStarted) > -90 then 1 else 0 end) else 0 end) else 0 end) Pended60_90,
           sum(case when c.chart_status_id = 2 then (case when DATEDIFF(dd,@m_ReportDate,cs.ClockStarted) <= -90 then 1 else 0 end) else 0 end) Pended90,
           min(case when c.chart_status_id in (1,2) then c.time_of_service else @m_ReportDate end) OldestDOS,
           sum(convert(bigint, case when c.chart_status_id in (3,4,5) then datediff(mi,c.date_received,completion_date) else 0 end)) TotalMinutes,
           sum(convert(bigint, case when c.chart_status_id in (3,4,5) then (case when datediff(dd,c.time_of_service,@m_ReportDate) <= 30 then 1 else 0 end) else 0 end)) TotalCompleted_DOS30,
           sum(convert(bigint, case when c.chart_status_id in (3,4,5) then (case when datediff(dd,c.COMPLETION_DATE,@m_ReportDate) <= 30 then datediff(mi,c.completion_date,c.approved_date) else 0 end) else 0 end)) TotalMinutes_CompleteToApproved30,
           sum(convert(bigint, case when c.chart_status_id in (3,4,5) then (case when datediff(dd,c.COMPLETION_DATE,@m_ReportDate) <= 30 then 1 else 0 end) else 0 end)) TotalCompleted_Recd30,
           sum(convert(bigint, case when c.chart_status_id in (3,4,5) then (case when datediff(dd,c.COMPLETION_DATE,@m_ReportDate) <= 30 then datediff(mi,cs.ClockStarted,c.completion_date) else 0 end) else 0 end)) TotalMinutes_Recd30,
           sum(convert(bigint, case when c.chart_status_id=5 then (case when datediff(dd,c.SENT_DATE,@m_ReportDate) <= 30 then datediff(mi,cs.ClockStarted,c.SENT_DATE) else 0 end) else 0 end)) TotalMinutes_RecdToSent30
    from chart c with (nolock)
      join ClockStarted cs on cs.ChartID = c.CHART_ID
    where c.CHART_STATUS_ID in (1,2,3,4,5)
    group by c.SERVICE_AGREEMENT_ID) x
    where x.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
    and   sa.DEMO_TEST_SITE_IND <> 1
    and   sa.COMPANY_ID <> 1
    and @m_ReportDate between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
    and   cpy.COMPANY_ID = sa.COMPANY_ID
    AND (@m_AccountManager =-1 or sa.[SERVICE_AGREEMENT_ID] IN (SELECT [SERVICE_AGREEMENT_ID] 
															      FROM [dbo].[SERVICE_AGREEMENT_MANAGEMENT_TEAM]
															      WHERE [USER_PROFILE_ID] = @m_AccountManager))
    order by sa.SERVICE_MODEL_CD desc, cpy.[NAME], sa.DESCRIPTION
END


GO
