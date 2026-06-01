SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Preprocess data for subscription "Coder QA Detail With Observation"

CREATE PROCEDURE [dbo].[rpt_Preprocess_CoderQADetailWithObservation]
as
BEGIN

set nocount on
set transaction isolation level read uncommitted

--declare @StartDate date  = cast(getdate()-1 as date);
--declare @EndDate date = cast(getdate()-1 as date);
declare @StartDate datetime  = cast(getdate()-1 as date);	-- performance improvement for populating #CAR by using the native data type for the Approved_Date column	dsexton, 3/2022
declare @EndDate datetime = cast(getdate()-1 as date);		-- performance improvement for populating #CAR by using the native data type for the Approved_Date column	dsexton, 3/2022
declare @ReportUser int = 80;
declare @FACILITY_ID int = -1;
declare @AUID int = 0;
--declare @CUID int = 6734;		-- the SSRS subscription will provide @CUID when it queries the table holding the current day's results of this query.

declare @ReportUserClass int = (select user_class_cd from user_profile where user_profile_id = @ReportUser)


if object_id('TempDB..#CAR', 'U') is not null DROP TABLE #CAR		-- using #CAR reduces LReads of the big query by 50% (300K vs 600K)
select Seq into #CAR from chart_audit_result as car 
--where convert(varchar, car.APPROVED_DATE, 112) BETWEEN convert(varchar, @StartDate, 112) AND convert(varchar, @EndDate, 112)
where car.Approved_Date between @StartDate and dateadd(second, 86399, @EndDate)	-- big improvement (200 Lreads vs 65K)


if object_id('TempDB..#Facility', 'U') is not null drop table #Facility
if object_id('TempDB..#Audit', 'U') is not null drop table #Audit

select * 
into #Facility
from
(
select distinct sa.facility_id
from SERVICE_AGREEMENT sa  WITH (NOLOCK),								
FACILITY f  WITH (NOLOCK)								
where 								
f.facility_id = sa.facility_ID
and sa.DEMO_TEST_SITE_IND = 0								
and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE								
and EXISTS (								
		SELECT *						
		FROM FACILITY_USER_AUTHORIZATION  FUA WITH (NOLOCK),						
		USER_PROFILE UP	WITH (NOLOCK)					
		WHERE FUA.FACILITY_ID = f.FACILITY_ID						
		AND fua.user_profile_id = up.user_profile_id						
		AND UP.IS_ACTIVE = 'Y'						
		and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE						
		AND FUA.USER_PROFILE_ID = @ReportUser
                                and   ((fua.FACILITY_ID = @FACILITY_ID) or (@FACILITY_ID = -1))	
		)	
)t1;


select * 
into #Audit
from
(
select up.USER_PROFILE_ID AUID
from user_profile up WITH (NOLOCK)
where 
up.IS_ACTIVE = 'Y'
and (up.user_profile_id = @AUID or 0 = @AUID)

UNION					
					
SELECT 0					
where 0 = @AUID
) t2;



if object_id('TempDB..#POST_BILL1', 'U') is not null drop table #POST_BILL1;
-- Keep as is below. Testing showed no performance improvement by first pulling a subset of Chart_IDs into a table like #Charts	-- dsexton, 3/31/2022

select * 								
into #POST_BILL1							
from								
(

SELECT 
	   NULL Coder, 
	   NULL CUID,  

	   UP_AUDIT.last_name + ' ' + UP_AUDIT.first_name  as Auditor,
	   c2.post_bill_audit_completed_by_user_id,
	   c2.post_bill_audit_completed ,
		
	   c2.FACILITY_ID,
       f.NAME  as Facility,
       c2.FACILITY_CHART_ID ,
	   cpbar.CHART_ID, 
		               
			CASE WHEN FACILITY_SVC_ERROR IS NULL THEN 0 ELSE 1 END AS FA ,
			 CASE when FACILITY_SVC_ERROR = 1 then 0 
	               when FACILITY_SVC_ERROR is null then 0
	               else 1 end as FLOSE ,
            cpbar.FACILITY_SVC_COMMENT,

			CASE WHEN INFUSION_ERROR IS NULL THEN 0 ELSE 1 END AS FIA ,
            CASE when INFUSION_ERROR = 1 then 0 
	               when INFUSION_ERROR is null then 0
	               else 1 end as FINJE ,  
            cpbar.INFUSION_COMMENT,

			CASE WHEN FACILITY_PROCEDURE_ERROR IS NULL THEN 0 ELSE 1 END AS FPA,
			  CASE when FACILITY_PROCEDURE_ERROR = 1 then 0 
	               when FACILITY_PROCEDURE_ERROR is null then 0
	               else 1 end as FPROCE ,
            cpbar.FACILITY_PROCEDURE_COMMENT,

              CASE WHEN PHYSICIAN_SVC_ERROR IS NULL THEN 0 ELSE 1 END AS PA,
			   CASE when PHYSICIAN_SVC_ERROR = 1 then 0 
	               when PHYSICIAN_SVC_ERROR is null then 0
	               else 1 end as PLOSE ,
             cpbar.PHYSICIAN_SVC_COMMENT,

			  CASE WHEN PHYSICIAN_PROCEDURE_ERROR IS NULL THEN 0 ELSE 1 END AS PPA,
			    CASE when PHYSICIAN_PROCEDURE_ERROR = 1 then 0 
	               when PHYSICIAN_PROCEDURE_ERROR is null then 0
	               else 1 end as PPROCE , 
              cpbar.PHYSICIAN_PROCEDURE_COMMENT ,

			  CASE WHEN DIAGNOSIS_ICD10_ERROR IS NULL THEN 0 ELSE 1 END AS DA,	
			  CASE when DIAGNOSIS_ICD10_ERROR = 1 then 0 
	               when DIAGNOSIS_ICD10_ERROR is null then 0
	               else 1 end as DE ,
               cpbar.DIAGNOSIS_ICD10_COMMENT ,
			   NULL as obsUID , 
	           NULL as Obs_Coder,
               c2.observation_auditor_review_feedback ,
				CASE WHEN OBSERVATION_HOURS_ERROR IS NULL THEN 0 ELSE 1 END AS OHA ,
				CASE when OBSERVATION_HOURS_ERROR = 1 then 0 
	               when OBSERVATION_HOURS_ERROR is null then 0
	               else 1 end as OHE ,
				CASE WHEN OBSERVATION_INFUSIONS_ERROR IS NULL THEN 0 ELSE 1 END AS OIA ,
                CASE when OBSERVATION_INFUSIONS_ERROR = 1 then 0 
	               when OBSERVATION_INFUSIONS_ERROR is null then 0
	               else 1 end  as OIE ,
                cpbar.OBSERVATION_INFUSIONS_COMMENT ,
				CASE WHEN OBSERVATION_PROCEDURES_ERROR IS NULL THEN 0 ELSE 1 END AS OPA,
                CASE when OBSERVATION_PROCEDURES_ERROR = 1 then 0 
	               when OBSERVATION_PROCEDURES_ERROR is null then 0
	               else 1 end as OPE ,

	       cpbar.OBSERVATION_PROCEDURES_COMMENT ,
     	   c2.auditor_review_feedback,
	       c2.patient_disposition_id, 
           sa.EVALUATE_OBSERVATION_DEPARTMENTS,

	      CASE WHEN DEMOGRAPHIC_ERROR IS NULL THEN 0 ELSE 1 END AS DEMA ,
		  CASE when DEMOGRAPHIC_ERROR = 1 then 0 
               when DEMOGRAPHIC_ERROR is null then 0
               else 1 end as DEME ,
           cpbar.DEMOGRAPHIC_COMMENT 
           
      FROM [dbo].[CHART_POST_BILL_AUDIT_REVIEW] cpbar WITH (NOLOCK),
          	  user_profile up_audit WITH (NOLOCK),
              service_agreement sa WITH (NOLOCK),
              FACILITY f WITH (NOLOCK),
			  chart c2 WITH (NOLOCK)

      WHERE 
	  	  
		  cast(c2.POST_BILL_AUDIT_COMPLETED as date)BETWEEN @StartDate AND @EndDate
              and cpbar.chart_id = c2.chart_id
              and sa.service_agreement_id = c2.service_agreement_id
              and f.FACILITY_ID = c2.FACILITY_ID
			  and c2.POST_BILL_AUDIT_COMPLETED is not null
              and up_audit.USER_PROFILE_ID = c2.post_bill_audit_completed_by_user_id
and exists ( select * from #Facility where c2.facility_id = #Facility.facility_ID )  
)t1


	update x
	set x.CUID = ln.Completed_By_User_ID
	from
		#POST_BILL1 as x
			join
		(
			select chart_ID, MinLogNoteID = min(LOG_NOTE_ID) 
			from log_note with (NOLOCK) 
			where CATEGORY_ID = 2
			group by chart_ID
		) as t
				on x.chart_ID = t.chart_ID
			join
		log_note as ln with (nolock)
				on t.MinLogNoteID = ln.log_note_ID


  	update x
	set x.obsUID = ln.Completed_By_User_ID
	from
		#POST_BILL1  as x
			join
		(
			select chart_ID, MinLogNoteID = min(LOG_NOTE_ID) 
			from log_note with (NOLOCK) 
			where CATEGORY_ID = 26
			group by chart_ID
		) as t
				on x.chart_ID = t.chart_ID
			join
		log_note as ln with (nolock)
				on t.MinLogNoteID = ln.log_note_ID



-- delete old records
TRUNCATE TABLE Rpts_CoderQADetailWithObservation

INSERT INTO Rpts_CoderQADetailWithObservation		-- Subscriptions will query against this table.  For example, SELECT * FROM Rpts_CoderQADetailWithObservation WHERE CUID = @CUID
select *
from 
(
	select 
	'1LA' as Cat,
	@ReportUserClass as ReportUserClass,
	car.CNAME Coder,
		 car.CUID,
		 car.ANAME 'Approved by',
					 car.AUID,
	(select user_class_cd from user_profile where user_profile_id = car.AUID) as AUID_UserClass, 
		 car.APPROVED_DATE 'Date Approved',
		 car.FACILITY_ID 'Facility ID',
					 car.FNAME 'Facility',
		 car.FACILITY_CHART_ID 'Patient ID',
					 car.CHART_ID,
		 car.FA + car.FPA + car.FIA + car.PA + car.PPA + car.DA + car.oha + car.opa + car.oia + car.dema 'Total Pts',
		 car.FLOSE + car.FPROCE + car.FINJE + car.PLOSE + car.PPROCE + car.DE + car.ohe + car.ope + car.oie + car.deme 'Total Earned',
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
		 car.obsUID 'Obs Coder ID',
		 car.obsNAME 'Obs Coder',
		 car.observation_auditor_review_feedback 'Obs Review Feedback',
		 car.oha 'Obs Hours Avail',
		 car.ohe 'Obs Hours Earned',
		 car.oia 'Obs Inf/Inj Avail',
		 car.oie 'Obs Inf/Inj Earned',
		 car.oinj_comment 'Obs Inf/Inj Comment',
		 car.opa 'Obs Proc Avail',
		 car.ope 'Obs Proc Earned',
		 car.oproc_comment 'Obs Proc Comment',
     		 c.auditor_review_feedback,
		 c.patient_disposition_id, 
		 sa.EVALUATE_OBSERVATION_DEPARTMENTS,
		 car.dema 'Demo Pts',
		 car.deme 'Demo Earned',
		 car.DEMO_COMMENT 'Demo Comment'

		 , RowInsertedDT = getdate()		-- added 3/31/2022, dsexton

	from  chart_audit_result car with (NOLOCK), chart c with (NOLOCK), service_agreement sa with (NOLOCK)
	--where  convert(varchar, car.APPROVED_DATE, 112) BETWEEN convert(varchar, @StartDate, 112) AND convert(varchar, @EndDate, 112)		-- replaced by usage of #CAR
	where car.seq in (select seq from #CAR)
	and    car.chart_id = c.chart_id
	and    c.service_agreement_id = sa.service_agreement_id
	--and    (car.CUID = @CUID or car.ObsUID = @CUID)		-- do not filter on CUID for preprocessing to support the SSRS subscription

	and ( exists ( select * from #Audit
				 where car.auid = #Audit.auid ) or @AUID = 0 	  )

	and exists ( select * from #Facility where car.facility_id = #Facility.facility_ID )  
	-- and car.auid not in (2, 4, 5)         -- ACS-12638 DAH 8/10/2018			-- already commented out before 3/31/2022 


	union all

	-- Post Bill
	select 
	'PBA' as Cat,
	@ReportUserClass as ReportUserClass,
	(select LAST_NAME + ', ' + FIRST_NAME from  user_profile where 
	  USER_PROFILE_ID = CUID) as Coder,
	CUID,
	Auditor as 'Approved by',
	post_bill_audit_completed_by_user_id as AUID,
	(select user_class_cd from user_profile where user_profile_id = post_bill_audit_completed_by_user_id) as AUID_UserClass, 

	post_bill_audit_completed as 'Date Approved',
	FACILITY_ID as 'Facility ID',
	Facility,
	FACILITY_CHART_ID as 'Patient ID',
	CHART_ID, 

	FA + FPA + FIA + PA + PPA + DA + oha + opa + oia + dema as 'Total Pts',
	FLOSE + FPROCE + FINJE + PLOSE + PPROCE + DE + ohe + ope + oie + deme as 'Total Earned',	

                      
	FA as 'Fac LOS Avail',
	FLOSE as 'Fac LOS Earned',
	FACILITY_SVC_COMMENT as 'Fac LOS Comment',

	FIA as 'Fac Inf/Inj Avail',
	FINJE as 'Fac Inf/Inj Earned',  
	INFUSION_COMMENT as 'Fac Inf/Inj Comment',

	FPA as 'Fac Proc Avail',
	FPROCE as'Fac Proc Earned',
	FACILITY_PROCEDURE_COMMENT as 'Fac Proc Comment',

	PA as 'Phys E&M Avail',
	PLOSE as 'Phys LOS Earned' ,
	PHYSICIAN_SVC_COMMENT as 'Phys LOS Comment',

	PPA as 'Phys Proc Avail',
	PPROCE as 'Phys Proc Earned', 
	PHYSICIAN_PROCEDURE_COMMENT as 'Phys Proc Comment',

	DA as 'Diag Pts',	
	DE as 'Diag Earned',
	DIAGNOSIS_ICD10_COMMENT as 'Diag Comment',
	obsUID as 'Obs Coder ID',   
	(select LAST_NAME + ', ' + FIRST_NAME from  user_profile where 
	  USER_PROFILE_ID = obsUID)  as 'Obs Coder',
	observation_auditor_review_feedback as 'Obs Review Feedback',

	OHA as 'Obs Hours Avail',
	OHE as 'Obs Hours Earned',
	OIA as 'Obs Inf/Inj Avail',
	OIE as 'Obs Inf/Inj Earned',
	OBSERVATION_INFUSIONS_COMMENT as 'Obs Inf/Inj Comment',
	OPA as 'Obs Proc Avail',
	OPE as 'Obs Proc Earned',
	OBSERVATION_PROCEDURES_COMMENT as 'Obs Proc Comment',
	auditor_review_feedback,
	patient_disposition_id, 
	EVALUATE_OBSERVATION_DEPARTMENTS,

	DEMA as 'Demo Pts',
	DEME as 'Demo Earned',
	DEMOGRAPHIC_COMMENT as 'Demo Comment'

	, RowInsertedDT = getdate()			-- added 3/31/2022, dsexton
       
	from #POST_BILL1 pb1	
	where 
	--    pb1.post_bill_audit_completed_by_user_id not in (2, 4, 5)	-- ACS-12638 DAH 8/10/2018		-- already commented out before 3/31/2022
		 -- (pb1.CUID = @CUID or pb1.obsUID = @CUID)		-- do not filter on CUID for preprocessing to support the SSRS subscription		-- dsexton, 3/31/2022
		--and 
		( exists ( select * from #Audit
				 where pb1.post_bill_audit_completed_by_user_id = #Audit.auid ) or @AUID = 0  )
) as t

END
GO
