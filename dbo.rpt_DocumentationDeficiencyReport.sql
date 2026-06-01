SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =============================================
-- Author:		Don Hutton
-- Create date: 9/15/2017
-- Description:	SQL for the Documentation Deficiency Report

-- Query was embedded in report, query tuned by David Sexton and placed into stored procedure, ACS-10504
-- Modifications:
--					20190128 - JHerrera - Added OBSERVATION_ATTENDING_PROVIDER
-- =============================================
CREATE PROCEDURE [dbo].[rpt_DocumentationDeficiencyReport]
  @StartDate datetime,
  @ThruDate datetime,
  @facility varchar(max)  

AS
BEGIN
	
	set transaction isolation level read uncommitted
	set NOCOUNT ON;

	--declare
	--	@StartDate datetime = '20180801'
	--	,@ThruDate datetime = '20180831'
	--	,@facility int      = 1117;


	DECLARE @m_StartDate datetime = @StartDate;
	DECLARE @m_ThruDate datetime = @ThruDate;
	DECLARE @m_facility varchar(max) = @facility;
  


	if object_id('TempDB..#Results', 'U') is not null drop table #Results
	select 
		   c.Chart_ID,
		   DocName = dt.Name,
		   f.NAME as 'Facility',
		c.FACILITY_CHART_ID as 'Patient ID',
		   Patient = cast(null as varchar(100)),
		   MRN = cast(null as varchar(50)),
		dt.NAME as 'Documentation Type',
		   time_of_service = cast(null as datetime),
		   Physician = cast(null as varchar(100)),
		   di.CODER_COMMENT 'DI Comments',
		   Nurse = cast(null as varchar(100)),
		   Disposition = cast(null as varchar(100)),
		   c.OBSERVATION_ATTENDING_PROVIDER_ID,
		   OBSERVATION_ATTENDING_PROVIDER = cast(null as varchar(100)),
		   c.LONG_PATIENT_ID2 [LONG_PATIENT_ID]
	  INTO #Results
	from chart c with(nolock), documentation_inequity di with(nolock), facility f with(nolock), documentation_item dt with(nolock)
	where di.CHART_ID = c.CHART_ID
		   and di.checked = 1
		   and f.FACILITY_ID = c.FACILITY_ID
		   and f.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_facility, ','))
		   and dt.DOCUMENTATION_ID = di.DOCUMENTATION_ID
		   and c.sent_date between @m_startDate and DateAdd(second, 86399, @m_ThruDate)   -- reduces logical reads 98% when removing convert on the sent_date column as was being done below
				  --and convert(varchar, @StartDate, 112) <= convert(varchar, c.sent_date, 112)     
				  --and convert(varchar, @ThruDate, 112) >= convert(varchar, c.sent_date, 112)


	UPDATE t
	SET 
		   t.Patient = c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME,
		   t.MRN = c.medical_record_num,
		   t.time_of_service = c.time_of_service,
		   t.Physician =  (select fp.LAST_NAME + ', ' + fp.FIRST_NAME 
											 from facility_professional fp with(nolock)
											 where fp.FACILITY_PROF_ID = case 
													when c.NURSE_PRACTITIONER_ID > 0 
														   and (c.PROVIDER_EVAL_PERFORMED_BY_IND is null or c.PROVIDER_EVAL_PERFORMED_BY_IND = 1) 
													then c.NURSE_PRACTITIONER_ID
													else c.PHYSICIAN_ID 
											 end),
		   t.Nurse = (select fp.LAST_NAME + ', ' + fp.FIRST_NAME from facility_professional fp with(nolock) where fp.FACILITY_PROF_ID = c.dis_nurse_id),
		   t.Disposition = (select pdm.DESCRIPTION from PATIENT_DISPOSITION_MAP pdm with(nolock) where pdm.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID)
	FROM #Results as t
		   join chart as c with(nolock) on t.chart_ID = c.chart_ID

	update r
	set
		OBSERVATION_ATTENDING_PROVIDER = fp.LAST_NAME + ', ' 
											+ fp.FIRST_NAME + case when fp.MIDDLE_NAME = '' then ' ' else + ' ' + fp.MIDDLE_NAME + ' ' end
											+ case when fp.NAME_SUFFIX = '' then '' else '[' + fp.NAME_SUFFIX + ']' end
	from
		#Results r
		inner join FACILITY_PROFESSIONAL fp on r.OBSERVATION_ATTENDING_PROVIDER_ID = fp.FACILITY_PROF_ID


	SELECT
		   Facility,
		   [Patient ID],
		   Patient,
		   MRN,
		   [Documentation Type],
		   DOS = convert(varchar, t.time_of_service, 110),
		   Physician,
		   c.coder_comment 'Coder Comments',
		   [DI Comments],
		   Nurse,
		   Disposition,
		   pc.[DESCRIPTION] PatientClass,
		   OBSERVATION_ATTENDING_PROVIDER,
		   LONG_PATIENT_ID
	FROM #Results as t 
		   join chart as c with(nolock) on t.chart_ID = c.chart_ID
		   join patient_class pc with(nolock) on c.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID
	ORDER BY Facility, DocName, convert(varchar, t.time_of_service, 110), [Patient ID]




END








GO
GRANT EXECUTE ON  [dbo].[rpt_DocumentationDeficiencyReport] TO [dbx_ExecuteReportProcs]
GO
