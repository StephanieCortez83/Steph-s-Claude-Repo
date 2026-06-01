SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 2/18/2014
-- Description:	SQL for the Dashboard Visit Totals by Facility report
-- =============================================
CREATE procedure [dbo].[rpt_DashboardVisitTotalsByFacility]
  @DosFrom date = null,
  @DosTo date = null,
  @ReceivedFrom date = null,
  @ReceivedTo date = null,
  @SentFrom date = null,
  @SentTo date = null,
  @Facilities varchar(max) = '-1',
  @ClinicID varchar(10) = null,
  @PatientClassID int = -1
as
begin
	set transaction isolation level read uncommitted;

	--declare
	--	@DosFrom date = '2023-03-15'       -- date
	--    ,@DosTo date = '2023-03-22'        -- date
	--    ,@ReceivedFrom date = '' -- date
	--    ,@ReceivedTo date = ''   -- date
	--    ,@SentFrom date = ''     -- date
	--    ,@SentTo date = ''       -- date
	--    ,@Facilities varchar(max) = '1782'             -- varchar(max)
	--    ,@ClinicID varchar(10) = ''               -- varchar(10)
	--    ,@PatientClassID int = 0          -- int


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  -- Insert statements for procedure here
  DECLARE @m_DosFrom DATE = @DosFrom;
  DECLARE @m_DosTo DATE = @DosTo;
  DECLARE @m_ReceivedFrom DATE = @ReceivedFrom;
  DECLARE @m_ReceivedTo DATE = @ReceivedTo;
  DECLARE @m_SentFrom DATE = @SentFrom;
  DECLARE @m_SentTo DATE = @SentTo;
  DECLARE @m_Facilities VARCHAR(MAX) = @Facilities;
  DECLARE @m_ClinicID VARCHAR(10) = @ClinicID;
  DECLARE @m_PatientClassID INT = @PatientClassID;

  DECLARE @m_SQLCommand VARCHAR(MAX);
  DECLARE @m_DateType INT = 1; -- Date Received

  -- Generate SQL for counts by Date Received
  EXEC [dbo].[sp_Get_DashboardReport_SQL] 
     @m_DateType
    ,@m_DosFrom
    ,@m_DosTo
    ,@m_ReceivedFrom
    ,@m_ReceivedTo
    ,@m_SentFrom
    ,@m_SentTo
    ,@m_Facilities
    ,@m_ClinicID
    ,@m_PatientClassID
    ,@m_SQLCommand OUTPUT

  DECLARE @ReceivedSQL VARCHAR(MAX) = @m_SQLCommand;
  SET @m_DateType = 0; -- Date of Service

  -- Generate SQL for counts by Date of Service
  EXEC [dbo].[sp_Get_DashboardReport_SQL] 
     @m_DateType
    ,@m_DosFrom
    ,@m_DosTo
    ,@m_ReceivedFrom
    ,@m_ReceivedTo
    ,@m_SentFrom
    ,@m_SentTo
    ,@m_Facilities
    ,@m_ClinicID
    ,@m_PatientClassID
    ,@m_SQLCommand OUTPUT

  DECLARE @DateOfServiceSQL VARCHAR(MAX) = @m_SQLCommand;
  SET @m_DateType = 3; -- Send Date

  -- Generate SQL for counts by Sent Date
  exec [dbo].[sp_Get_DashboardReport_SQL] 
     @m_DateType
    ,@m_DosFrom
    ,@m_DosTo
    ,@m_ReceivedFrom
    ,@m_ReceivedTo
    ,@m_SentFrom
    ,@m_SentTo
    ,@m_Facilities
    ,@m_ClinicID
    ,@m_PatientClassID
    ,@m_SQLCommand output

  declare @SentSQL varchar(max) = @m_SQLCommand;
  set @m_DateType = 4; -- Date of Discharge

  -- Generate SQL for counts by Date of Discharge
  exec [dbo].[sp_Get_DashboardReport_SQL] 
     @m_DateType
    ,@m_DosFrom
    ,@m_DosTo
    ,@m_ReceivedFrom
    ,@m_ReceivedTo
    ,@m_SentFrom
    ,@m_SentTo
    ,@m_Facilities
    ,@m_ClinicID
    ,@m_PatientClassID
    ,@m_SQLCommand output

  declare @DischargedSQL varchar(max) = @m_SQLCommand;

  -- Execute the SQL
  exec(@ReceivedSQL + ' 

    UNION 
    ' + @DateOfServiceSQL + ' 
  
    UNION
    ' + @DischargedSQL + ' 
  
    UNION
    ' + @SentSQL + '
    ORDER BY SortOrder, Facility, aDate
    ')
end


GO
GRANT EXECUTE ON  [dbo].[rpt_DashboardVisitTotalsByFacility] TO [dbx_ExecuteReportProcs]
GO
