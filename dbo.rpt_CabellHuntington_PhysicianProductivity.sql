SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 5/1/2013
-- Description:	Cabel Huntington Physician Productivity Report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_CabellHuntington_PhysicianProductivity] 
	-- Add the parameters for the stored procedure here
	@ReportUser int, 
	@StartDate date,
  @EndDate date
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  declare @m_ReportUser int = @ReportUser;
  declare @m_StartDate date = @StartDate;
  declare @m_EndDate date = @EndDate;

  ;with AverageMinutes as (
    select case when sp.cpt_code not in ('99291', '99292') then substring(sp.cpt_code, 5,1) else 'Critical Care' end 'Level',
           sum(datediff(mi, crd.CHECK_IN_DATE, crd.CHECK_OUT_DATE))/count('x') AvgMin 
    from SENT_PROCEDURE sp
      left outer join CHART_REPORTING_DATA crd on crd.SERVICE_AGREEMENT_ID = sp.service_agreement_id and crd.FACILITY_CHART_ID = sp.facility_chart_id
    where sp.facility_id = 417
      and dateadd(day, datediff(day, 0, sp.time_of_service), 0) between @m_StartDate and @m_EndDate
      and 417 in (select FACILITY_ID
                          from FACILITY_USER_AUTHORIZATION
                          where USER_PROFILE_ID=@m_ReportUser)
      and sp.class in ('PL')
      and datediff(mi, crd.CHECK_IN_DATE, crd.CHECK_OUT_DATE) > 0
    group by case when sp.cpt_code not in ('99291', '99292') then substring(sp.cpt_code, 5,1) else 'Critical Care' end),
    PhysicianLosSummary as (
    select isnull(nullif(fp.LAST_NAME + ', ' + fp.FIRST_NAME, ', '), 'Unknown Provider') Physician,
           case when sp.cpt_code not in ('99291', '99292') then substring(sp.cpt_code, 5,1) else 'Critical Care' end 'Level',
           sum(case when sp.TIME_OF_SERVICE between @m_StartDate and @m_EndDate then sp.QUANTITY else 0 end) Qty,
           sum(datediff(mi, crd.CHECK_IN_DATE, crd.CHECK_OUT_DATE))/count('x') AvgMin,
           sum(datediff(mi, crd.CHECK_IN_DATE, crd.CHECK_OUT_DATE))/count('x') - (select AvgMin 
                                                                                  from AverageMinutes 
                                                                                  where [Level] = case when sp.cpt_code not in ('99291', '99292') then substring(sp.cpt_code, 5,1) else 'Critical Care' end) 'Var' 
    from SENT_PROCEDURE sp
      left outer join FACILITY_PROFESSIONAL fp on fp.FACILITY_PROF_ID=sp.PHYSICIAN_ID
      left outer join CHART_REPORTING_DATA crd on crd.SERVICE_AGREEMENT_ID = sp.service_agreement_id and crd.FACILITY_CHART_ID = sp.facility_chart_id
    where sp.facility_id = 417
      and dateadd(day, datediff(day, 0, sp.time_of_service), 0) between @m_StartDate and @m_EndDate
      and 417 in (select FACILITY_ID
                          from FACILITY_USER_AUTHORIZATION
   	          where USER_PROFILE_ID=@m_ReportUser)
      and sp.class in ('PL')
      and datediff(mi, crd.CHECK_IN_DATE, crd.CHECK_OUT_DATE) > 0
    group by case when sp.cpt_code not in ('99291', '99292') then substring(sp.cpt_code, 5,1) else 'Critical Care' end, fp.LAST_NAME + ', ' + fp.FIRST_NAME
    union select 'MATRIX-FILLER' Physician,
          '1' 'Level',
          null Qty,
          null AvgMin,
          null 'Var'
    union select 'MATRIX-FILLER' Physician,
          '2' 'Level',
          null Qty,
          null AvgMin,
          null 'Var'
    union select 'MATRIX-FILLER' Physician,
          '3' 'Level',
          null Qty,
          null AvgMin,
          null 'Var'
    union select 'MATRIX-FILLER' Physician,
          '4' 'Level',
          null Qty,
          null AvgMin,
          null 'Var'
    union select 'MATRIX-FILLER' Physician,
          '5' 'Level',
          null Qty,
          null AvgMin,
          null 'Var'
    union select 'MATRIX-FILLER' Physician,
          'Critical Care' 'Level',
          null Qty,
          null AvgMin,
          null 'Var')

  select upper([Physician]) Physician,
         [Level],
         [Qty],
         [AvgMin],
         [Var]
  from PhysicianLosSummary
  order by Physician, [Level]
END

GO
GRANT EXECUTE ON  [dbo].[rpt_CabellHuntington_PhysicianProductivity] TO [dbx_ExecuteReportProcs]
GO
