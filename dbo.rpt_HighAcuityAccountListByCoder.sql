SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











-- =============================================
-- Author:		Don Hutton
-- Create date: 12/20/2018
-- ACS-13441:	
-- =============================================

CREATE PROCEDURE [dbo].[rpt_HighAcuityAccountListByCoder] 
    @StartDate DATETIME,
	@EndDate DATETIME,
	@UserGroup VARCHAR(MAX),
	@ReportUser INT,
	@Coder VARCHAR(MAX),
	@ColumnGroup varchar(20)
	
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	set transaction isolation level read uncommitted	
	SET NOCOUNT ON;

	DECLARE @m_StartDate DATETIME = @StartDate;
	DECLARE @m_EndDate DATETIME = @EndDate;
	DECLARE @m_ReportUser INT = @ReportUser;
	DECLARE @m_Coder VARCHAR(MAX) = @Coder;
	DECLARE @m_UserGroup VARCHAR(MAX) = @UserGroup;	
	DECLARE @m_ColumnGroup varchar(20) = @ColumnGroup;
	


if object_id('TempDB..#coder', 'U') is not null drop table #coder




create table #coder
	(
		CUID int		
	);
	

insert into #coder
select distinct x.user_profile_id 
from  
            ( SELECT user_profile_id							
			  FROM USER_PROFILE 			
			  WHERE 
			  USER_GROUP_ID in (select items from revcycledb.dbo.SplitString(@UserGroup,','))	
			  -- USER_GROUP_ID in (@UserGroup)	
			  and is_active = 'Y'				
			  			  UNION				
			  SELECT ugup.user_profile_id				
			  FROM USER_GROUP_TO_USER_PROFILE ugup ,				
			  user_profile up				
			  where up.user_profile_id = ugup.user_profile_id				
			  and up.is_active = 'Y'				
			  AND ugup.USER_GROUP_ID in (select items from revcycledb.dbo.SplitString(@UserGroup,','))	
			  -- AND ugup.USER_GROUP_ID in (@UserGroup)	
			  
			)x
where
 (@Coder = '-1' or x.USER_PROFILE_ID in (select items from revcycledb.dbo.SplitString(@Coder,',')))			 				
 -- (@Coder = '-1' or x.USER_PROFILE_ID in (@Coder))			 				
and 1 = (													
	SELECT 1 													
	FROM USER_PROFILE													
	WHERE USER_PROFILE_ID = @m_ReportUser													
	and is_active = 'Y'												
	and USER_GROUP_ID in (1,116) 													
													
	UNION													
													
	SELECT 1													
	FROM USER_GROUP_TO_USER_PROFILE ugup,													
	user_profile up													
	where up.user_profile_id = ugup.user_profile_id													
	and up.is_active = 'Y'													
	and ugup.USER_PROFILE_ID = @m_ReportUser													
	AND ugup.USER_GROUP_ID in (1,116)												
	)	



create nonclustered index idx_CUID on #coder (CUID)


print 'Section: 00 ' + convert(varchar, getdate(), 121)	
	----------------------------------------------------------------------------------------------------



-- Facility Level CC



if object_id('TempDB..#CC_FACILITY_LEVEL', 'U') is not null drop table #CC_FACILITY_LEVEL

select facility_level_id, service_agreement_id, description     
into #CC_FACILITY_LEVEL
from FACILITY_LEVEL where critical_care = 1
and service_agreement_id in ( 
			select service_agreement_id 
			from service_agreement sa
			where  	
			    sa.COMPANY_ID <> 140  -- Test/Demo					
			and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE					
			and sa.DEMO_TEST_SITE_IND = 0					
			)

create nonclustered index idx_facility_level_id on #CC_FACILITY_LEVEL (facility_level_id)


print 'Section: 01 ' + convert(varchar, getdate(), 121)	
	----------------------------------------------------------------------------------------------------


-- Patient Class Trauma
if object_id('TempDB..#PatientClassTrauma', 'U') is not null drop table #PatientClassTrauma

select Patient_Class_ID, Service_Agreement_ID, Description 
into #PatientClassTrauma
from [dbo].[PATIENT_CLASS] 
where description like '%trauma%'
and getdate () between EFFECTIVE_DATE and isnull(expiration_date, '12/31/2099')
and service_agreement_id in ( 
			select service_agreement_id 
			from service_agreement sa
			where  	
			    sa.COMPANY_ID <> 140  -- Test/Demo					
			and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE					
			and sa.DEMO_TEST_SITE_IND = 0					
			)

create nonclustered index idx_Patient_Class_ID on #PatientClassTrauma (Patient_Class_ID)



print 'Section: 02 ' + convert(varchar, getdate(), 121)	
	----------------------------------------------------------------------------------------------------

if object_id('TempDB..#billing_code', 'U') is not null drop table #billing_code


create table #billing_code
	(
	CHARGE_MASTER_ID	 int,
	SERVICE_AGREEMENT_ID int,
	DESCRIPTION	varchar(100),
    CPT_CODE    varchar(5),
    BILLING_CODE varchar(20)
	);
	
-- Facility Level Billing Code Trauma
insert into #billing_code
select 				
cm.charge_master_id, 
cm.service_agreement_id, 
cm.description,
cm.cpt_code,
cm.billing_code				
from charge_master cm,				
service_agreement sa  				
where 				
sa.service_agreement_id = cm.service_agreement_id				
				and cm.description like '%trauma%'
				and cm.cpt_code <> 'SUPLY'
				AND    cm.CHARGE_MASTER_USAGE_CODE = 2
				and getdate() between cm.effective_date and cm.expiration_date
				and getdate() between sa.effective_date and sa.expiration_date
				and sa.DEMO_TEST_SITE_IND = 0
				and sa.COMPANY_ID <> 140;  -- Test/Demo



-- Facility Procedure Billing Code Trauma 


insert into #billing_code
select 				
cm.charge_master_id, 
cm.service_agreement_id, 
cm.description,
cm.cpt_code,
cm.billing_code				
from charge_master cm,				
service_agreement sa  				
where 				
sa.service_agreement_id = cm.service_agreement_id				
				and cm.description like '%trauma%'
				and cm.cpt_code <> 'SUPLY'
				AND    cm.CHARGE_MASTER_USAGE_CODE = 3
				and getdate() between cm.effective_date and cm.expiration_date
				and getdate() between sa.effective_date and sa.expiration_date
				and sa.DEMO_TEST_SITE_IND = 0
				and sa.COMPANY_ID <> 140  -- Test/Demo
				and (substring(cpt_code,1,1) in ( '0','9', 'G', 'N', 'T') or cm.CHARGE_MASTER_ID = 407671798)
				and cm.CHARGE_MASTER_ID not in (407361078, 407361079, 407356227);


-- Physician Service Billing Code Trauma
insert into #billing_code
select 				
cm.charge_master_id, 
cm.service_agreement_id, 
cm.description,
cm.cpt_code,
cm.billing_code				
from charge_master cm,				
service_agreement sa  				
where 				
sa.service_agreement_id = cm.service_agreement_id				
				and cm.description like '%trauma%'
				and cm.cpt_code <> 'SUPLY'
				AND    cm.CHARGE_MASTER_USAGE_CODE = 4 -- Physician Service
				and getdate() between cm.effective_date and cm.expiration_date
				and getdate() between sa.effective_date and sa.expiration_date
				and sa.DEMO_TEST_SITE_IND = 0
				and sa.COMPANY_ID <> 140;  -- Test/Demo



-- Physician Procedure Billing Code Trauma
insert into #billing_code
select 				
cm.charge_master_id, 
cm.service_agreement_id, 
cm.description,
cm.cpt_code,
cm.billing_code				
from charge_master cm,				
service_agreement sa  				
where 				
sa.service_agreement_id = cm.service_agreement_id				
				and cm.description like '%trauma%'
				and cm.cpt_code <> 'SUPLY'
				AND    cm.CHARGE_MASTER_USAGE_CODE = 5 -- Physician Procedure
				and getdate() between cm.effective_date and cm.expiration_date
				and getdate() between sa.effective_date and sa.expiration_date
				and sa.DEMO_TEST_SITE_IND = 0
				and sa.COMPANY_ID <> 140  -- Test/Demo
				and cpt_code in ('99291', 'G0390');

				


create nonclustered index idx_Charge_Master_ID on #billing_code (Charge_Master_ID);



print 'Section: 03 ' + convert(varchar, getdate(), 121)	;
	----------------------------------------------------------------------------------------------------





if object_id('TempDB..#data_1', 'U') is not null drop table #data_1


create table #data_1
	(
	chart_id			int,
	SentDate			date,
	DOS					date,
	patient_class_id	int,
	level_id			int,
	charge_master_id	int,
	Physician_Critical_Care int ,
    Facility_Critical_Care	int
	);

	
----------------------------------------------------------------------------------------------------

-- 1 Facility Level CC

	if object_id('TempDB..#sent_procedure_2', 'U') is not null drop table #sent_procedure_2;
		
		select sp.chart_id, cast(sp.SENT_DATE as date) as SentDate, 
		cast(sp.TIME_OF_SERVICE as date) as DOS, 
		sp.patient_class_id,  sp.level_id, sp.charge_master_id,
		NULL as Physician_Critical_Care,
		NULL as Facility_Critical_Care		
		into #sent_procedure_2
		from sent_procedure sp
		where exists ( select fl.FACILITY_LEVEL_ID from #CC_FACILITY_LEVEL fl where fl.FACILITY_LEVEL_ID = sp.level_id)	
        and cast(sp.SENT_DATE as date) between @m_StartDate and @m_EndDate
	    and sp.class = 'FL';


       create nonclustered index idx_Chart_id on #sent_procedure_2 (Chart_id);




		insert into #data_1
		select c.chart_id, sp.SentDate, sp.DOS, 
		NULL as patient_class_id,  sp.level_id, NULL as charge_master_id,
		NULL as Physician_Critical_Care,
		NULL as Facility_Critical_Care      
      from
	  CHART c,
	  #sent_procedure_2 sp
	  where 		
		sp.chart_id = c.chart_id 
		and exists ( select CUID from #coder where CUID = c.COMPLETED_BY_USER_PROFILE_ID); -- better performance


print 'Section: 04 ' + convert(varchar, getdate(), 121);	
	----------------------------------------------------------------------------------------------------



-- 2 New Patient Class *****



if object_id('TempDB..#sent_procedure_1', 'U') is not null drop table #sent_procedure_1;

		select sp.chart_id, cast(sp.SENT_DATE as date) as SentDate, 
		cast(sp.TIME_OF_SERVICE as date) as DOS, 
		sp.patient_class_id,  sp.level_id, sp.charge_master_id,
		NULL as Physician_Critical_Care,
		NULL as Facility_Critical_Care
		into #sent_procedure_1
		from sent_procedure sp
		where exists ( select pc.patient_class_id from #PatientClassTrauma pc where pc.patient_class_id = sp.patient_class_id)		
		and cast(sp.SENT_DATE as date) between @m_StartDate and @m_EndDate
       create nonclustered index idx_Chart_id on #sent_procedure_1 (Chart_id);


insert into #data_1
select c.chart_id, sp.SentDate, sp.DOS, 
		sp.patient_class_id,  NULL as level_id, NULL as charge_master_id,
		NULL as Physician_Critical_Care,
		NULL as Facility_Critical_Care
from
			CHART c,
			#sent_procedure_1 sp
	where 		
		sp.chart_id = c.chart_id 
		and exists ( select CUID from #coder where CUID = c.COMPLETED_BY_USER_PROFILE_ID); -- better performance


print 'Section: 05 ' + convert(varchar, getdate(), 121);	
	----------------------------------------------------------------------------------------------------




-- 3 New Charge Master *****


	if object_id('TempDB..#sent_procedure_3', 'U') is not null drop table #sent_procedure_3;

		select 
		sp.chart_id, cast(sp.SENT_DATE as date) as SentDate, 
		cast(sp.TIME_OF_SERVICE as date) as DOS, 
		sp.patient_class_id,  sp.level_id, sp.charge_master_id,
		NULL as Physician_Critical_Care,
		NULL as Facility_Critical_Care
		into #sent_procedure_3
		from sent_procedure sp
		where exists ( select bc.charge_master_id from #billing_code bc where bc.charge_master_id = sp.charge_master_id)		
		and cast(sp.SENT_DATE as date) between @m_StartDate and @m_EndDate

       create nonclustered index idx_Chart_id on #sent_procedure_3 (Chart_id);


		insert into #data_1
		select 
		 c.chart_id, sp.SentDate, sp.DOS, 
		NULL as patient_class_id,  NULL as level_id, sp.charge_master_id, 
		NULL as Physician_Critical_Care,
		NULL as Facility_Critical_Care
      from
	  CHART c,
	  #sent_procedure_3 sp
	  where 		
		sp.chart_id = c.chart_id 
		and exists ( select CUID from #coder where CUID = c.COMPLETED_BY_USER_PROFILE_ID); -- better performance


print 'Section: 06 ' + convert(varchar, getdate(), 121);	
	----------------------------------------------------------------------------------------------------

-- Critical Care section based on CPT_Code 99291	

		if object_id('TempDB..#sent_procedure_4', 'U') is not null drop table #sent_procedure_4;

		select 
		sp.chart_id, cast(sp.SENT_DATE as date) as SentDate, 
		cast(sp.TIME_OF_SERVICE as date) as DOS, 
		sp.patient_class_id,  sp.level_id, sp.charge_master_id, 
		case when sp.class ='PL' then 1 end Physician_Critical_Care,
		case when sp.class ='FL' then 1 end Facility_Critical_Care
		into #sent_procedure_4
		from sent_procedure sp
		where sp.class in ('PL', 'FL') 
		and sp.cpt_code = '99291'		
        and cast(sp.SENT_DATE as date) between @m_StartDate and @m_EndDate

       create nonclustered index idx_Chart_id on #sent_procedure_4 (Chart_id);


	   insert into #data_1
		select 
		 c.chart_id, sp.SentDate, sp.DOS, 
		NULL as patient_class_id,  NULL as level_id, NULL as charge_master_id, 
		sp.Physician_Critical_Care,
		sp.Facility_Critical_Care
      from
	  CHART c,
	  #sent_procedure_4 sp
	  where 		
		sp.chart_id = c.chart_id 
		and exists ( select CUID from #coder where CUID = c.COMPLETED_BY_USER_PROFILE_ID); -- better performance

		
print 'Section: 06A ' + convert(varchar, getdate(), 121);	
----------------------------------------------------------------------------------------------------


-- update time_of_service,  sent_procedure can have multiple time_of_service values for a chart, ie.. chart_id in ( 56329529, 56274197)
   UPDATE d1 SET d1.DOS = c.time_of_service FROM #data_1 as d1 join chart c on d1.chart_id = c.chart_id ;



if object_id('TempDB..#data_2', 'U') is not null drop table #data_2;


select 
chart_id,
SentDate, 
DOS,
max(patient_class_id) as patient_class_id,
max(level_id) as level_id,
max(charge_master_id) as charge_master_id,
max(Physician_Critical_Care) as Physician_Critical_Care,
max(Facility_Critical_Care) as Facility_Critical_Care
into #data_2
from #data_1
group by 
chart_id,
SentDate, 
DOS

print 'Section: 06B ' + convert(varchar, getdate(), 121);	
----------------------------------------------------------------------------------------------------

alter table #data_2
add	
	[FACILITY_CHART_ID]		varchar(20),
	FACILITY_ID				int,
    MEDICAL_RECORD_NUM		varchar(20),
    FACILITY_ADMIN_CHART_ID varchar(20),    
	CUID					int,
	SERVICE_AGREEMENT_ID    int,
    CHART_STATUS_ID         int, 
    APPROVED_DATE           datetime,
    APPROVED_BY_USER_PROFILE_ID		int,
	SECOND_LEVEL_QA_APPROVED_DATETIME datetime,
    SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID int,
    COMPLETED_BY_USER_PROFILE_ID    int,
	COMPLETION_DATE	        datetime,
	NO_FACILITY_SERVICES    int;




update d
set 
d.FACILITY_CHART_ID = c.FACILITY_CHART_ID,
d.FACILITY_ID = c.FACILITY_ID,				
d.MEDICAL_RECORD_NUM = 	c.MEDICAL_RECORD_NUM,	
d.FACILITY_ADMIN_CHART_ID = c.FACILITY_ADMIN_CHART_ID,
d.CUID	= c.COMPLETED_BY_USER_PROFILE_ID,					
d.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID,    
d.CHART_STATUS_ID = c.CHART_STATUS_ID,         
d.APPROVED_DATE = c.APPROVED_DATE,           
d.APPROVED_BY_USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID,
d.SECOND_LEVEL_QA_APPROVED_DATETIME = c.SECOND_LEVEL_QA_APPROVED_DATETIME, 
d.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID = c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID, 
d.COMPLETED_BY_USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID,
d.COMPLETION_DATE = c.COMPLETION_DATE,    
d.NO_FACILITY_SERVICES = c.NO_FACILITY_SERVICES  	
from
 #data_2 d	join CHART as c with(NOLOCK) on d.chart_ID = c.chart_ID;


 alter table #data_2
add
	Facility_Level_Descr    varchar(100),
	Patient_Class_Descr     varchar(100),
	Billling_Code_Descr     varchar(100),
	G0390                   varchar(5);
	

	


-- update facility level descr		
	UPDATE t1 SET t1.Facility_Level_Descr = fl.Description FROM #data_2 as t1 join #CC_FACILITY_LEVEL as fl on t1.level_ID = fl.facility_level_ID;

-- update patient class descr
	UPDATE t1 SET t1.Patient_Class_Descr = pc.Description FROM #data_2 as t1 join #PatientClassTrauma as pc on t1.patient_class_id = pc.patient_class_id;

-- update billing code descr
	UPDATE t1 SET t1.Billling_Code_Descr = bc.Description FROM #data_2 as t1 join #billing_code as bc on t1.charge_master_id = bc.charge_master_id;
	
-- update G0390
   UPDATE t1 SET t1.G0390 = 'Yes' FROM #data_2 as t1 join #billing_code bc on t1.charge_master_id = bc.charge_master_id and bc.cpt_code = 'G0390';
	

print 'Section: 07 ' + convert(varchar, getdate(), 121);	
	----------------------------------------------------------------------------------------------------


if object_id('TempDB..#POINTS', 'U') is not null drop table #POINTS

	select 
t1.CHART_ID,
t1.POINTS 
into #POINTS
from (
SELECT 
c.CHART_ID,
fs.description as POINTS
FROM #data_2 c 
JOIN [dbo].[FACILITY_SERVICE_EVALUATION] fse WITH (NOLOCK) ON fse.CHART_ID = c.CHART_ID
JOIN [dbo].[FACILITY_SERVICE] fs WITH (NOLOCK) ON fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID
left join sent_procedure sp with (NOLOCK) on c.chart_id = sp.chart_id 
     and sp.CLASS = 'FL'
join FACILITY_LEVEL fl (NOLOCK) on fl.FACILITY_LEVEL_ID = sp.LEVEL_ID
WHERE c.CHART_STATUS_ID = 5
AND sp.CLASS = 'FL'
AND c.Physician_Critical_Care = 1



UNION

SELECT 
c.CHART_ID,
fssi.description as POINTS
FROM #data_2 c 
JOIN [dbo].[FACILITY_SERVICE_EVALUATION] fse WITH (NOLOCK) ON fse.CHART_ID = c.CHART_ID
JOIN [dbo].[FACILITY_SERVICE_SCHEDULE_ITEM] fssi WITH (NOLOCK) ON fssi.FACILITY_SERVICE_SCHEDULE_ID = fse.FACILITY_SERVICE_SCHEDULE_ID
  AND fssi.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID
 left join sent_procedure sp with (NOLOCK) on c.chart_id = sp.chart_id
   and sp.CLASS = 'FL'
 left join FACILITY_LEVEL fl (NOLOCK) on fl.FACILITY_LEVEL_ID = sp.LEVEL_ID
WHERE c.CHART_STATUS_ID = 5
AND c.Physician_Critical_Care = 1


union

SELECT 
c.CHART_ID,
'' as POINTS
FROM #data_2 c 
WHERE c.CHART_STATUS_ID = 5
and c.NO_FACILITY_SERVICES = 1    
) T1


print 'Section: 08' + convert(varchar, getdate(), 121)	


	----------------------------------------------------------------------------------------------------

if object_id('TempDB..#LogNote1', 'U') is not null drop table #LogNote1;
if object_id('TempDB..#LogNote2A', 'U') is not null drop table #LogNote2A;
if object_id('TempDB..#LogNote2B', 'U') is not null drop table #LogNote2B;
if object_id('TempDB..#LogNote3', 'U') is not null drop table #LogNote3;
if object_id('TempDB..#LogNote4', 'U') is not null drop table #LogNote4;
if object_id('TempDB..#LogNote5', 'U') is not null drop table #LogNote5;


SELECT *    
INTO #LogNote1
FROM (
select 
  ln.chart_id,
  ln.completion_date ,
  ln.completed_by_user_id ,
  ln.category_id,
  ln.Summary as SUMMARY

from LOG_NOTE LN WITH (NOLOCK) 
where 
ln.category_id in (3,9)     
and exists ( select chart_id from #data_2 c1
			where c1.chart_id = ln.chart_id )
)t2;






SELECT *    
INTO #LogNote2A
FROM (
select ln1.chart_id,ln1.completion_date ,
  ln1.completed_by_user_id ,
  ln1.category_id,
  ln1.Summary as SUMMARY
 from #LogNote1 ln1
where ln1.category_id = 9
and ln1.completion_date =  ( select max(completion_date) from #LogNote1 
								where ln1.chart_id = chart_id 
								and category_id = 9	)
)T2a;




select *    
INTO #LogNote2B
from (
select
ln1.chart_id as CHART_ID,
max(ln1.completion_date) as COMPLETION_DATE, 

max(case when LN1A.completed_by_user_id = LN1.completed_by_user_id then LN1.completed_by_user_id
else LN1.completed_by_user_id end ) as completed_by_user_id, 
 
max(ln1.category_id) as category_id,  
max(ln1.Summary) as SUMMARY
 from #LogNote1 ln1,
      #LogNote2a ln1a 
  


where 
      ln1.chart_id = ln1a.chart_id 
  and ln1.category_id = 3   
  and ln1.summary = 'Chart approved.'
  and ln1.completion_date = ( select max(completion_date) from #LogNote1 
								where ln1.chart_id = chart_id 
								and category_id = 3
								and summary = 'Chart approved.'
							 )
group by ln1.chart_id
)t2b;






SELECT *    
INTO #LogNote3
FROM (	
select distinct
  c1.chart_id as CHART_ID, 
  c1.facility_id as FACILITY_ID,
  c1.service_agreement_id as SERVICE_AGREEMENT_ID,
  c1.chart_status_id as CHART_STATUS_ID,
  c1.APPROVED_DATE as APPROVED_DATE,
  c1.APPROVED_BY_USER_PROFILE_ID,
  c1.COMPLETED_BY_USER_PROFILE_ID,

  LN1A.COMPLETION_DATE as CAT9_COMP_DATE,
  LN1A.completed_by_user_id as CAT9_USER_ID,
  LN1A.SUMMARY as CAT9_SUMMARY,

(LN1B.COMPLETION_DATE) as CAT3_COMP_DATE, 

(case when LN1A.completed_by_user_id = LN1B.completed_by_user_id then LN1B.completed_by_user_id
		 when LN1A.completed_by_user_id is null and LN1B.completed_by_user_id is null then NULL
		 when LN1A.completed_by_user_id is null and LN1B.completed_by_user_id = 2 then LN1B.completed_by_user_id
         when LN1B.SUMMARY = 'Chart approved.' then LN1B.completed_by_user_id
		 else c1.APPROVED_BY_USER_PROFILE_ID end)	as CAT3_USER_ID,
 LN1B.SUMMARY as CAT3_SUMMARY	


from #data_2 c1	
left outer join #LogNote2A LN1A ON c1.chart_id = LN1A.chart_id								
left outer join #LogNote2B LN1B ON c1.chart_id = LN1B.chart_id


	
) T3;	



			


SELECT *    
INTO #LogNote4
FROM (
select 
 c.chart_id as CHART_ID, 
 c.facility_id as FACILITY_ID,
 c.service_agreement_id as SERVICE_AGREEMENT_ID,
 c.chart_status_id as CHART_STATUS_ID,
 c.SECOND_LEVEL_QA_APPROVED_DATETIME ,
 c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID ,
 c.COMPLETED_BY_USER_PROFILE_ID,	

  ln.completion_date ,
  ln.completed_by_user_id ,
  ln.category_id,
  ln.Summary as SUMMARY

from #data_2 c
left outer join LOG_NOTE LN WITH (NOLOCK) ON LN.chart_id = c.chart_id
and (ln.category_id in (28,31) 
or 
(ln.category_id = 3 and ln.summary = 'Chart status changed from Second Audit to Approved by System to meet SLA.')    )
)t6;


				

SELECT *    
INTO #LogNote5
FROM (
 select 
 distinct 
  ln4.chart_id as CHART_ID, 
  ln4.facility_id as FACILITY_ID,
  ln4.service_agreement_id as SERVICE_AGREEMENT_ID,
  ln4.chart_status_id as CHART_STATUS_ID,
  ln4.SECOND_LEVEL_QA_APPROVED_DATETIME,
  ln4.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID,
  ln4.COMPLETED_BY_USER_PROFILE_ID,

 (select max(completion_date) from #LogNote4 
								where ln4.chart_id = chart_id 
								and category_id = 28	)
								as CAT28_COMP_DATE,

( select completed_by_user_id from #LogNote4 
								where ln4.chart_id = chart_id 
								and category_id = 28	
								and completion_date =  (select max(completion_date) from #LogNote4
														where ln4.chart_id = chart_id 
														and category_id = 28	) )
								as CAT28_USER_ID,

 ( Select SUMMARY from #LogNote4 
								where ln4.chart_id = chart_id 
								and category_id = 28	
								and completion_date =  (select max(completion_date) from #LogNote4 
														where ln4.chart_id = chart_id 
														and category_id = 28	) )
								as CAT28_SUMMARY,

 ( select max(completion_date) from #LogNote4
								where ln4.chart_id = chart_id 
								and ( category_id = 31
								or (category_id = 3 and summary =  'Chart status changed from Second Audit to Approved by System to meet SLA.' ))
								) as CAT31_COMP_DATE,

 ( select completed_by_user_id from #LogNote4
								where ln4.chart_id = chart_id 
								and ( category_id = 31
								or (category_id = 3 and summary =  'Chart status changed from Second Audit to Approved by System to meet SLA.' ))
								and completion_date =  (select max(completion_date) from #LogNote4 
														where ln4.chart_id = chart_id 
														and ( category_id = 31
								                        or (category_id = 3 
														and summary =  'Chart status changed from Second Audit to Approved by System to meet SLA.' ))
														) 
								) as CAT31_USER_ID,
( Select SUMMARY from #LogNote4 
								where ln4.chart_id = chart_id 
								and ( category_id = 31
								or (category_id = 3 and summary =  'Chart status changed from Second Audit to Approved by System to meet SLA.' ))
								and completion_date =  (select max(completion_date) from #LogNote4 
														where ln4.chart_id = chart_id 
														and ( category_id = 31
								                        or (category_id = 3 
														and summary =  'Chart status changed from Second Audit to Approved by System to meet SLA.' ))
														) 
								) as CAT31_SUMMARY

from #LogNote4 ln4
) T7;



print 'Section: 09' + convert(varchar, getdate(), 121)	
	----------------------------------------------------------------------------------------------------

	

select 
(select name from facility where facility_id = c.Facility_ID) as Facility,
c.Facility_ID, 
c.Facility_Chart_ID,
c.Medical_Record_Num,
c.Facility_Admin_Chart_ID,
c.COMPLETION_DATE,
c.DOS as TIME_OF_SERVICE,
c.SentDate as SENT_DATE,
c.COMPLETED_BY_USER_PROFILE_ID,
(select LAST_NAME + ', ' + FIRST_NAME from user_profile where user_profile_id = c.COMPLETED_BY_USER_PROFILE_ID) as Coder,
(select description from PATIENT_CLASS where patient_class_id = c.Patient_Class_ID) as Patient_Class,
c.Patient_Class_ID, 
c.level_id as Facility_Level, 
c.Charge_Master_ID, 
c.Facility_Level_Descr,
c.Patient_Class_Descr, 
c.Billling_Code_Descr,
case when c.Facility_Critical_Care = 1 then 'Yes' else NULL end as Facility_Critical_Care,
case when c.Physician_Critical_Care = 1 then 'Yes' else NULL end as Physician_Critical_Care,
p.POINTS,
c.G0390,
(select LAST_NAME + ', ' + FIRST_NAME from user_profile where user_profile_id = ln.cat3_user_id) as Auditor,
ln.cat3_user_id, 
cast(ln.cat3_comp_date as date) as Audit_Comp_Date,
(select LAST_NAME + ', ' + FIRST_NAME from user_profile where user_profile_id = ln2.cat31_user_id) as Auditor2,
ln2.cat31_user_id, 
cast(ln2.cat31_comp_date as date) as Audit2_Comp_Date
 from #data_2 c 
 left join #LogNote3 ln on c.chart_id = ln.chart_id
 left join #LogNote5 ln2 on c.chart_id = ln2.chart_id
 left join #POINTS p on c.chart_id = p.chart_id
where 
   (1 in (select items from revcycledb.dbo.SplitString(@ColumnGroup,',')) and c.Patient_Class_Descr IS NOT NULL)
or (2 in (select items from revcycledb.dbo.SplitString(@ColumnGroup,',')) and c.Billling_Code_Descr IS NOT NULL)
or (3 in (select items from revcycledb.dbo.SplitString(@ColumnGroup,',')) and c.Facility_Critical_Care = 1)
or (4 in (select items from revcycledb.dbo.SplitString(@ColumnGroup,',')) and c.Physician_Critical_Care = 1)
or (5 in (select items from revcycledb.dbo.SplitString(@ColumnGroup,',')) and c.G0390 = 'Yes')



  OPTION (RECOMPILE);


END









GO
GRANT EXECUTE ON  [dbo].[rpt_HighAcuityAccountListByCoder] TO [dbx_ExecuteReportProcs]
GO
