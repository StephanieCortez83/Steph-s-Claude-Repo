SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[rpt_UnbilledChartsWithPhysician]
@Facility varchar(MAX), @StartDate date, @EndDate date, @ReportUser int
WITH EXEC AS CALLER
AS
select c.TIME_OF_SERVICE ServiceDate,
	     c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME + ' ' + isnull(c.PATIENT_MIDDLE_NAME, '') PatientName,
	     c.FACILITY_CHART_ID Account#,
	     c.MEDICAL_RECORD_NUM MedRec#,
       c.FACILITY_ADMIN_CHART_ID SecAccount#,
	     cs.[DESCRIPTION] CodingStatus,
	     pdm.FACILITY_PATIENT_DISPOSITION DispCode,
	     p.LAST_NAME + ', ' + p.FIRST_NAME + ' ' + isnull(p.MIDDLE_NAME, '') PhysicianName,
       case c.LOCATION_CODE
        when NULL
        then ''
        else mcl.[DESCRIPTION]
        end Location
from CHART c with (nolock)
  join CHART_STATUS cs with (nolock) on cs.CHART_STATUS_ID = c.CHART_STATUS_ID
  left outer join PATIENT_DISPOSITION_MAP pdm with (nolock) on pdm.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID
  left outer join MEDSTAR_CLINIC_LOCATION mcl with (nolock) on mcl.LOCATION_CODE = c.LOCATION_CODE
  left outer join FACILITY_PROFESSIONAL p with (nolock) on p.FACILITY_PROF_ID = c.PHYSICIAN_ID
where c.FACILITY_ID IN (SELECT * FROM SPLITSTRING(@Facility, ','))
  and c.CHART_STATUS_ID IN (1,2,3,4) and dateadd(dd, datediff(d, 0, c.TIME_OF_SERVICE), 0) between @StartDate and @EndDate
  --and @Facility in (select FACILITY_ID
  --                    from FACILITY_USER_AUTHORIZATION
	--      where USER_PROFILE_ID = @ReportUser)
order by p.LAST_NAME + ', ' + p.FIRST_NAME + ' ' + isnull(p.MIDDLE_NAME, ''),
         CONVERT(VARCHAR, c.TIME_OF_SERVICE, 110),
	       c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME + ' ' + isnull(c.PATIENT_MIDDLE_NAME, ''),
	       c.FACILITY_CHART_ID,
	       cs.[DESCRIPTION]
GO
GRANT EXECUTE ON  [dbo].[rpt_UnbilledChartsWithPhysician] TO [dbx_ExecuteReportProcs]
GO
