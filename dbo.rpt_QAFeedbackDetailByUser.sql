SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[rpt_QAFeedbackDetailByUser] 
	@StartDate DATETIME,
	@EndDate DATETIME,
	@CUID int
AS
BEGIN

-- Coder QA Detail
select 
     car.CHART_ID,
	 car.CUID,
	 car.CNAME Coder,
     car.AUID,
	 car.ANAME 'AuditorName',
	 car.APPROVED_DATE, 
	 car.FACILITY_ID,
     car.FNAME 'Facility',
	 car.FACILITY_CHART_ID,
	 car.FA + car.FPA + car.FIA + car.PA + car.PPA + car.DA + car.DEMA 'Total Pts',
	 car.FLOSE + car.FPROCE + car.FINJE + car.PLOSE + car.PPROCE + car.DE + car.DEME 'Total Earned',
	 car.FA 'Fac LOS Avail',
	 car.FLOSE 'Fac LOS Earned',
	 car.FLOS_COMMENT 'Fac LOS Comment',
     car.FIA 'Fac Inf/Inj Avail',
     car.FINJE 'Fac Inf/Inj Earned',
     car.FINJ_COMMENT 'Fac Inf/Inj Comment',
     car.FPA 'Fac Proc Avail',
	 car.FPROCE 'Fac Proc Earned',
	 car.FPROC_COMMENT 'Fac Proc Comment',
	 car.PA 'Phys E&M Avail',
	 car.PLOSE 'Phys LOS Earned',
	 car.PLOS_COMMENT 'Phys LOS Comment',
     car.PPA 'Phys Proc Avail',
	 car.PPROCE 'Phys Proc Earned',
	 car.PPROC_COMMENT 'Phys Proc Comment',
	 car.DA 'Diag Pts',
	 car.DE 'Diag Earned',
	 car.DIAG_COMMENT 'Diag Comment',
	 car.DEMA 'Demo Pts',
	 car.DEME 'Demo Earned',
	 car.DEMO_COMMENT 'Demo Comment',
	 	 c.auditor_review_feedback
from  chart_audit_result car with (NOLOCK),
	  chart c with (NOLOCK), user_profile up with (NOLOCK)
where  convert(varchar, car.APPROVED_DATE, 112) BETWEEN convert(varchar, @StartDate, 112) AND convert(varchar, @EndDate, 112)
and    up.USER_PROFILE_ID = car.CUID
and    car.chart_id = c.chart_id
and    car.CUID = @CUID
and   car.CUID in (select car2.cuid from chart_audit_result car2 with (NOLOCK)
			 where car.cuid = car2.cuid
			 and (car.FA + car.FPA + car.FIA + car.PA + car.PPA + car.DA + car.DEMA) <> ( car.FLOSE + car.FPROCE + car.FINJE + car.PLOSE + car.PPROCE + car.DE + car.DEME)
			 and   convert(varchar, car2.APPROVED_DATE, 112) >= convert(varchar, @StartDate, 112)
			 and   convert(varchar, car2.APPROVED_DATE, 112) <= convert(varchar, @EndDate, 112)
			 and   car2.auid not in (2, 4, 5))
order by car.FNAME, car.APPROVED_DATE, car.CHART_ID

END


GO
