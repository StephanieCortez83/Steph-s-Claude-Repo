SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[rpt_QAFeedbackDetailByUser_withObs_EF] 
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
	 car.FA + car.FPA + car.FIA + car.PA + car.PPA + car.DA + car.DEMA  + car.oha + car.opa + car.oia  'Total Pts',
	 car.FLOSE + car.FPROCE + car.FINJE + car.PLOSE + car.PPROCE + car.DE + car.DEME + car.ohe + car.ope + car.oie 'Total Earned',
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
 	 c.auditor_review_feedback,
	 car.oha 'Obs Hours Avail',
	 car.ohe 'Obs Hours Earned',
	 car.observation_auditor_review_feedback 'Obs Review Feedback',
	 car.oia 'Obs Inf/Inj Avail',
	 car.oie 'Obs Inf/Inj Earned',
	 car.oinj_comment 'Obs Inf/Inj Comment',
	 car.opa 'Obs Proc Avail',
	 car.ope 'Obs Proc Earned',
	 car.oproc_comment 'Obs Proc Comment',
	 car.obsUID 'Obs Coder ID',
	 car.obsNAME 'Obs Coder'

from  chart_audit_result car with (NOLOCK),
	  chart c with (NOLOCK), user_profile up with (NOLOCK)
where  convert(varchar, car.APPROVED_DATE, 112) BETWEEN convert(varchar, @StartDate, 112) AND convert(varchar, @EndDate, 112)
and    up.USER_PROFILE_ID = car.CUID
and    car.chart_id = c.chart_id
and    (car.CUID = @CUID or car.ObsUID = @CUID)
and   car.CUID in (select car2.cuid from chart_audit_result car2 with (NOLOCK)
			 where car.cuid = car2.cuid
			 and (car.FA + car.FPA + car.FIA + car.PA + car.PPA + car.DA + car.DEMA + car.OHA + car.OIA + car.OPA) 
					<> ( car.FLOSE + car.FPROCE + car.FINJE + car.PLOSE + car.PPROCE + car.DE + car.DEME + car.OHE + car.OIE + car.OPE)
			 and   convert(varchar, car2.APPROVED_DATE, 112) >= convert(varchar, @StartDate, 112)
			 and   convert(varchar, car2.APPROVED_DATE, 112) <= convert(varchar, @EndDate, 112)
			 and   car2.auid not in (2, 4, 5))

UNION 
select 
x.CHART_ID, x.cuid, x.CoderName, x.AUID, x.AuditorName, x.ApprovedDate, x.Facility_ID, x.FNAME, x.FACILITY_CHART_ID, 
(x.FA + x.FIA + x.FPA + x.PA + x.PPA + x.DA + x.DEMA + x.OHA + x.OIA + x.OPA) as TotalPts, 
(x.FLOSE + x.FINJE + x.FPROCE + x.PLOSE + x.PPROCE + x.DE + x.DEME + x.OHE + x.OIE + x.OPE) as TotalEarned, 
x.FA, x.FLOSE, x.FacLOSComment, x.FIA, x.FINJE, x.FacInfComment, x.FPA, x.FPROCE, x.FacProcComment,
x.PA, x.PLOSE, x.PhysLOSComment, x.PPA, x.PPROCE, x.PhysProcComment, x.DA, x.DE, x.DiagComment, x.DEMA, x.DEME, x.DemoComment, x.auditor_review_feedback,
x.OHA, x.OHE, x.ObsReviewFeedback, x.OIA, x.OIE, x.ObsInfInjComment, x.OPA, x.OPE, x.ObsProcComment, x.obsUID, x.ObsCoder
FROM 
   (select 
     car.CHART_ID  Chart_ID,
	 c2.completed_by_user_profile_id  cuid,
	 up1.LAST_NAME + ', ' + up1.FIRST_NAME  CoderName,
     c2.post_bill_audit_completed_by_user_id  AUID,
	 up2.LAST_NAME + ', ' + up2.FIRST_NAME + ' (Post Bill Audit)' AuditorName,
	 c2.POST_BILL_AUDIT_COMPLETED  ApprovedDate, 
	 c2.FACILITY_ID  Facility_ID,
     f.[NAME]  FNAME,
	 c2.FACILITY_CHART_ID  Facility_Chart_ID,
	 0 TotalPts  ,
	 0 TotalEarned ,
	 CASE WHEN car.FACILITY_SVC_ERROR IS NULL THEN 0 ELSE 1 END AS FA,
	 CASE when FACILITY_SVC_ERROR = 1 then 0 
	      when FACILITY_SVC_ERROR is null then 0
	      else 1 end as FLOSE ,
	 car.FACILITY_SVC_COMMENT as FacLOSComment,
     CASE WHEN car.INFUSION_ERROR IS NULL THEN 0 ELSE 1 END AS FIA,
     CASE when INFUSION_ERROR = 1 then 0 
	      when INFUSION_ERROR is null then 0
	      else 1 end as FINJE ,
     car.INFUSION_COMMENT as FacInfComment,
     CASE WHEN FACILITY_PROCEDURE_ERROR IS NULL THEN 0 ELSE 1 END AS FPA,
	 CASE when FACILITY_PROCEDURE_ERROR = 1 then 0 
	      when FACILITY_PROCEDURE_ERROR is null then 0
	      else 1 end as FPROCE ,
	 car.FACILITY_PROCEDURE_COMMENT as FacProcComment,
     CASE WHEN PHYSICIAN_SVC_ERROR IS NULL THEN 0 ELSE 1 END AS PA,
	 CASE when PHYSICIAN_SVC_ERROR = 1 then 0 
	      when PHYSICIAN_SVC_ERROR is null then 0
	      else 1 end as PLOSE ,
	 car.PHYSICIAN_SVC_COMMENT as PhysLOSComment,
	 CASE WHEN PHYSICIAN_PROCEDURE_ERROR IS NULL THEN 0 ELSE 1 END AS PPA,
	 CASE when PHYSICIAN_PROCEDURE_ERROR = 1 then 0 
	      when PHYSICIAN_PROCEDURE_ERROR is null then 0
	      else 1 end as PPROCE , 
	 car.PHYSICIAN_PROCEDURE_COMMENT as PhysProcComment,
     CASE WHEN DIAGNOSIS_ICD10_ERROR IS NULL THEN 0 ELSE 1 END AS DA,	
	 CASE when DIAGNOSIS_ICD10_ERROR = 1 then 0 
	      when DIAGNOSIS_ICD10_ERROR is null then 0
	      else 1 end as DE ,
	 car.DIAGNOSIS_ICD10_COMMENT as DiagComment,
	 CASE WHEN DEMOGRAPHIC_ERROR IS NULL THEN 0 ELSE 1 END AS DEMA ,
	 CASE when DEMOGRAPHIC_ERROR = 1 then 0 
          when DEMOGRAPHIC_ERROR is null then 0
          else 1 end as DEME ,
	 car.DEMOGRAPHIC_COMMENT as DemoComment,
 	 c2.auditor_review_feedback,
	 CASE WHEN OBSERVATION_HOURS_ERROR IS NULL THEN 0 ELSE 1 END AS OHA ,
  	 CASE when OBSERVATION_HOURS_ERROR = 1 then 0 
	      when OBSERVATION_HOURS_ERROR is null then 0
	      else 1 end as OHE ,
	 car.OBSERVATION_HOURS_COMMENT as ObsReviewFeedback,
	 CASE WHEN OBSERVATION_INFUSIONS_ERROR IS NULL THEN 0 ELSE 1 END AS OIA ,
     CASE when OBSERVATION_INFUSIONS_ERROR = 1 then 0 
	      when OBSERVATION_INFUSIONS_ERROR is null then 0
	      else 1 end  as OIE ,
	 car.OBSERVATION_INFUSIONS_COMMENT as ObsInfInjComment,
	 CASE WHEN OBSERVATION_PROCEDURES_ERROR IS NULL THEN 0 ELSE 1 END AS OPA,
     CASE when OBSERVATION_PROCEDURES_ERROR = 1 then 0 
	      when OBSERVATION_PROCEDURES_ERROR is null then 0
	      else 1 end as OPE ,
	 car.OBSERVATION_PROCEDURES_COMMENT as ObsProcComment,
	 null obsUID,
	 null obsCoder

FROM [dbo].[CHART_POST_BILL_AUDIT_REVIEW] car  with (NOLOCK),
	  CHART c2  with (NOLOCK),
	  USER_PROFILE up1 with (NOLOCK), USER_PROFILE up2 with (NOLOCK), FACILITY f with (NOLOCK), FACILITY_USER_AUTHORIZATION fua with (NOLOCK)
	  WHERE car.CHART_ID = c2.CHART_ID
	  AND  c2.FACILITY_ID = f.FACILITY_ID
	  AND  c2.completed_by_user_profile_id = @CUID
	  and  c2.post_bill_audit_completed_by_user_id = up2.user_profile_id
	  and  c2.completed_by_user_profile_id = up1.user_profile_id
	  and  c2.POST_BILL_AUDIT_COMPLETED is not null
	  and  cast(c2.POST_BILL_AUDIT_COMPLETED as date) BETWEEN @StartDate AND @EndDate
	  and  fua.user_profile_id = @CUID
	  and  fua.facility_id = c2.FACILITY_ID
	  and  cast(c2.POST_BILL_AUDIT_COMPLETED as date) BETWEEN fua.EFFECTIVE_DATE AND fua.EXPIRATION_DATE
	  and (FACILITY_SVC_ERROR = 1 or INFUSION_ERROR = 1 or FACILITY_PROCEDURE_ERROR = 1 or PHYSICIAN_SVC_ERROR =1 or PHYSICIAN_PROCEDURE_ERROR = 1 or DIAGNOSIS_ICD10_ERROR =1 
			or DEMOGRAPHIC_ERROR =1 or OBSERVATION_HOURS_ERROR = 1 or OBSERVATION_INFUSIONS_ERROR = 1 or OBSERVATION_PROCEDURES_ERROR = 1)
	) x


order by FNAME, APPROVED_DATE, CHART_ID

END


GO
