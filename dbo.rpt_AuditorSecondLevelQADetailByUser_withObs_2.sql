SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[rpt_AuditorSecondLevelQADetailByUser_withObs_2] 
	@StartDate DATETIME,
	@EndDate DATETIME,
	@AUID int
AS
BEGIN

-- Auditor 2nd Level QA Detail
select 
     car.CHART_ID,
     car.AUID,
	 car.ANAME 'AuditorName',
	 car.SECOND_AUID,
	 car.SECOND_ANAME 'Second Auditor',
	 car.APPROVED_DATE, 
	 car.FACILITY_ID,
     car.FNAME 'Facility',
	 car.FACILITY_CHART_ID,

	 car.FA + car.FPA + car.FIA + car.PA + car.PPA + car.DA + car.DEMA 'Total Pts',
	 car.AUDITOR_FLOSE + car.AUDITOR_FPROCE + car.AUDITOR_FINJE + car.AUDITOR_PLOSE + car.AUDITOR_PPROCE + car.AUDITOR_DE + car.AUDITOR_DEME 'Total Earned',
	 car.FA 'Fac LOS Avail',
	 car.AUDITOR_FLOSE 'Fac LOS Earned',
	 car.FLOS_COMMENT 'Fac LOS Comment',
     car.FIA 'Fac Inf/Inj Avail',
     car.AUDITOR_FINJE 'Fac Inf/Inj Earned',
     car.FINJ_COMMENT 'Fac Inf/Inj Comment',
     car.FPA 'Fac Proc Avail',
	 car.AUDITOR_FPROCE 'Fac Proc Earned',
	 car.FPROC_COMMENT 'Fac Proc Comment',
	 car.PA 'Phys E&M Avail',
	 car.AUDITOR_PLOSE 'Phys LOS Earned',
	 car.PLOS_COMMENT 'Phys LOS Comment',
     car.PPA 'Phys Proc Avail',
	 car.AUDITOR_PPROCE 'Phys Proc Earned',
	 car.PPROC_COMMENT 'Phys Proc Comment',
	 car.DA 'Diag Pts',
	 car.AUDITOR_DE 'Diag Earned',
	 car.DIAG_COMMENT 'Diag Comment',
     car.DEMA 'Demo Pts',
     car.AUDITOR_DEME 'Demo Earned',
     car.DEMO_COMMENT 'Demo Comment',
	 c.auditor_review_feedback,
	 car.oha 'Obs Hours Avail',
	 car.ohe 'Obs Hours Earned',
	 car.observation_auditor_review_feedback 'Obs Review Feedback',
	 car.oia 'Obs Inf/Inj Avail',
	 car.oie 'Obs Inf/Inj Earned',
	 car.oinj_comment 'Obs Inf/Inj Comment',
	 car.opa 'Obs Proc Avail',
	 car.ope 'Obs Proc Earned',
	 car.oproc_comment 'Obs Proc Comment'
from  chart_second_level_audit_result car with (NOLOCK),
	  chart c with (NOLOCK), user_profile up with (NOLOCK)
where  
	  convert(varchar, car.SECOND_APPROVED_DATE, 112) >= convert(varchar, @StartDate, 112)
and   convert(varchar, car.SECOND_APPROVED_DATE, 112) <= convert(varchar, @EndDate, 112)
	--convert(varchar, car.SECOND_APPROVED_DATE, 112) BETWEEN convert(varchar, @StartDate, 112) AND convert(varchar, @EndDate, 112)
and    up.USER_PROFILE_ID = car.AUID
and    car.AUID <> car.SECOND_AUID
and    car.chart_id = c.chart_id
and    car.AUID = @AUID
and   car.AUID in (select car2.Auid from chart_second_level_audit_result car2 with (NOLOCK)
			 where car.Auid = car2.Auid
			 and (car.FA + car.FPA + car.FIA + car.PA + car.PPA + car.DA + car.DEMA) <> (car.AUDITOR_FLOSE + car.AUDITOR_FPROCE + car.AUDITOR_FINJE + car.AUDITOR_PLOSE + car.AUDITOR_PPROCE + car.AUDITOR_DE + car.AUDITOR_DEME)
			 and   convert(varchar, car2.SECOND_APPROVED_DATE, 112) >= convert(varchar, @StartDate, 112)
			 and   convert(varchar, car2.SECOND_APPROVED_DATE, 112) <= convert(varchar, @EndDate, 112)
			 and   car2.auid not in (2, 4, 5))
order by car.FNAME, car.SECOND_APPROVED_DATE, car.CHART_ID

END




GO
