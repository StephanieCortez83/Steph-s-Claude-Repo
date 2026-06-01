SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 5/8/2013
-- Description:	Coder Productivity by Facility Report
-- =============================================
CREATE PROCEDURE [dbo].[rptCoderProductivityByFacilityReport]
	@StartDate date = null,
  @EndDate date = null,
  @ReportUser int,
  @Organization int = -1,
  @TimeZone varchar(50) = 'Central Daylight Time',
  @Facility int = -1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  -- Set the default date range to the previous week if not supplied
  IF @StartDate is null
  SET @StartDate = getdate()-7;
  IF @EndDate is null
  SET @EndDate = getdate();

  declare @m_StartDate date = @StartDate;
  declare @m_EndDate date = @EndDate;
  declare @m_ReportUser int = @ReportUser;
  declare @m_Organization int = @Organization;
  declare @m_TimeZone varchar(25) = @TimeZone;
  declare @m_Facility int = @Facility;

  declare @CTOffSet VARCHAR(9) = (select CT_OFFSET from TIME_ZONE where DESCRIPTION=@m_TimeZone);
  declare @Operator varchar(1) = substring(@CTOffSet, 1, 1);
  declare @hms varchar(8) = substring(@CTOffSet, 2, LEN(@CTOffSet)-1) 
  declare @hours decimal(10,2) = datepart(hour, @hms)
  declare @minutes decimal(10,2) = datepart(minute, @hms)
  declare @HrsOffSet decimal(10,2) = cast(@Operator + convert(varchar, datepart(hour, @hms)) as decimal(10,2))
  declare @MinOffSet decimal(10,2) = cast(@Operator + convert(varchar, datepart(minute, @hms)) as decimal(10,2))

  ;with Productivity as 
  (
    select dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0) ADate,
           f.[NAME] Facility,
           f.FACILITY_ID FacilityID,
           coder.LAST_NAME + ', ' + coder.FIRST_NAME Coder, 
           coder.USER_PROFILE_ID UserID,
           sum(case when c.COMPLETED_BY_USER_PROFILE_ID=coder.USER_PROFILE_ID THEN 1 ELSE 0 end) Completed,
           sum(case when c.APPROVED_BY_USER_PROFILE_ID=coder.USER_PROFILE_ID THEN 1 ELSE 0 end) Audited
    from chart c with(nolock)
      join SERVICE_AGREEMENT sa with(nolock) on sa.FACILITY_ID = c.FACILITY_ID
      join FACILITY f with(nolock) on f.FACILITY_ID = c.FACILITY_ID
      left join USER_PROFILE coder with(nolock) on coder.USER_PROFILE_ID=c.COMPLETED_BY_USER_PROFILE_ID
    where c.chart_status_id in (3, 4, 5)
      and sa.DEMO_TEST_SITE_IND <> 1
      and @m_StartDate between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
      and @m_Organization in (-1, sa.COMPANY_ID)
      and @m_Facility in (-1, c.FACILITY_ID)
      and dateadd(day, datediff(day, 0, dateadd(hour, @HrsOffSet, dateadd(minute, @MinOffSet, c.COMPLETION_DATE))), 0) between @m_StartDate and @m_EndDate
    group by dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0), f.[NAME], f.FACILITY_ID, coder.USER_PROFILE_ID, coder.LAST_NAME + ', ' + coder.FIRST_NAME
    union
    select dateadd(day, datediff(day, 0, c.APPROVED_DATE), 0) ADate,
           f.[NAME] Facility,
           f.FACILITY_ID FacilityID,
           auditor.LAST_NAME + ', ' + auditor.FIRST_NAME Coder,
           auditor.USER_PROFILE_ID UserID,
           sum(case when c.COMPLETED_BY_USER_PROFILE_ID=auditor.USER_PROFILE_ID THEN 1 ELSE 0 end) Completed,
           sum(case when c.APPROVED_BY_USER_PROFILE_ID=auditor.USER_PROFILE_ID THEN 1 ELSE 0 end) Audited
    from chart c with(nolock)
      join SERVICE_AGREEMENT sa with(nolock) on sa.FACILITY_ID = c.FACILITY_ID
      join FACILITY f with(nolock) on f.FACILITY_ID = c.FACILITY_ID
      join USER_PROFILE auditor with(nolock) on auditor.USER_PROFILE_ID=c.APPROVED_BY_USER_PROFILE_ID
    where c.chart_status_id in (3, 4, 5)
      and sa.DEMO_TEST_SITE_IND <> 1
      and @m_StartDate between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
      and @m_Organization in (-1, sa.COMPANY_ID)
      and @m_Facility in (-1, c.FACILITY_ID)
      and dateadd(day, datediff(day, 0, dateadd(hour, @HrsOffSet, dateadd(minute, @MinOffSet, c.COMPLETION_DATE))), 0) between @m_StartDate and @m_EndDate
    group by dateadd(day, datediff(day, 0, c.APPROVED_DATE), 0), f.[NAME], f.FACILITY_ID, auditor.USER_PROFILE_ID, auditor.LAST_NAME + ', ' + auditor.FIRST_NAME
  )

  select ADate,
         Coder,
         UserID,
         Facility,
         FacilityID,
         Completed,
         Audited,
         Completed + Audited Total
  from Productivity
  where UserID <> 2
    and FacilityID in (select FACILITY_ID
                       from FACILITY_USER_AUTHORIZATION with(nolock)
                       where USER_PROFILE_ID=@m_ReportUser)
  order by Coder, Facility
END
GO
