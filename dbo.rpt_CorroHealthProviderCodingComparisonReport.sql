SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









	
CREATE proc [dbo].[rpt_CorroHealthProviderCodingComparisonReport]
(
 @ReportUser     int
,@DateType       int      
,@StartDate      datetime 
,@EndDate        datetime 
,@Company        varchar(max)
,@FACILITY_ID    varchar(max)
,@Provider       varchar(max)
,@PatientClassId varchar(max)
,@Provided_Selected_E_M varchar(max)
,@Physician_Service_CPT varchar(max)
,@Procedure_CPT varchar(5)
,@Clinic		varchar(max)  
)
as
begin



	set transaction isolation level read uncommitted;

	---- Test Parameters

	 --  declare
		-- @ReportUser      int      = 80
	 --   ,@DateType       int	  = 3					-- 0 Approved, 1 Completion, 2 Sent, 3 TimeOfService	
		--,@StartDate      datetime = '04/03/2025'
		--,@EndDate        datetime = '04/03/2025'
		--,@Company        varchar(max)      = '70' 	-- All '-1'
		--,@FACILITY_ID    varchar(max)      = '2492' -- All '-1'
		--,@Provider       varchar(max)      = '-1' -- '1938305' -- Feldman, Amy -- All '-1'
		--,@PatientClassId varchar(max)      = '-1'
		
		--,@Provided_Selected_E_M varchar(max) = '-1'
		--,@Physician_Service_CPT varchar(max) = '-1'
		--,@Procedure_CPT varchar(5) = '-1' -- '36415'
	 --   ,@Clinic		varchar(max)      = '-1'   -- All '-1'




	    DECLARE @m_Provider varchar(max) = @Provider;


	

	if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;

	if object_id('TempDB..#Chart1', 'U') is not null drop table #Chart1;
	if object_id('TempDB..#Chart2', 'U') is not null drop table #Chart2;
	if object_id('TempDB..#Chart3', 'U') is not null drop table #Chart3;
	if object_id('TempDB..#Chart4', 'U') is not null drop table #Chart4;
	if object_id('TempDB..#Chart5', 'U') is not null drop table #Chart5;
	if object_id('TempDB..#Chart6', 'U') is not null drop table #Chart6;
	if object_id('TempDB..#Chart7', 'U') is not null drop table #Chart7;
	if object_id('TempDB..#Provider1', 'U') is not null drop table #Provider1;
	if object_id('TempDB..#CPT1', 'U') is not null drop table #CPT1;
	if object_id('TempDB..#NEXT_LEVEL_MIN', 'U') is not null drop table #NEXT_LEVEL_MIN;

	if object_id('TempDB..#adjustments', 'U') is not null drop table #adjustments;



print 'Section: 00 ' + convert(varchar, getdate(), 121)

-- *********************************************************



	select
		t1.*
	into #CPT1
	from
	(
		select
			'99202' as CPT
		union
		select
			'99203' as CPT
		union
		select
			'99204' as CPT
		union
		select
			'99205' as CPT
		union
		select
			'99211' as CPT
		union
		select
			'99212' as CPT
		union
		select
			'99213' as CPT
		union
		select
			'99214' as CPT
		union
		select
			'99215' as CPT
		union
		select
			'99217' as CPT
		union
		select
			'99218' as CPT
		union
		select
			'99219' as CPT
		union
		select
			'99220' as CPT
		union
		select
			'99221' as CPT
		union
		select
			'99222' as CPT
		union
		select
			'99223' as CPT
		union
		select
			'99224' as CPT
		union
		select
			'99225' as CPT
		union
		select
			'99226' as CPT
		union
		select
			'99231' as CPT
		union
		select
			'99232' as CPT
		union
		select
			'99234' as CPT
		union
		select
			'99235' as CPT
		union
		select
			'99236' as CPT
		union
		select
			'99238' as CPT
		union
		select
			'99239' as CPT
		
		-- Added codes below RACS-2658 JHerrera
		union
		select
			'99202' as [CPT]
		union
		select
			'99203'
		union
		select
			'99204'
		union
		select
			'99205'
		union
		select
			'99211'
		union
		select
			'99212'
		union
		select
			'99213'
		union
		select
			'99214'
		union
		select
			'99215'
		union
		select
			'99281'
		union
		select
			'99282'
		union
		select
			'99283'
		union
		select
			'99284'
		union
		select
			'99285'
		union
		select
			'99291'
		union
		select
			'99292'
		union
		select
			'99221'
		union
		select
			'99222'
		union
		select
			'99223'
		union
		select
			'99224'
		union
		select
			'99225'
		union
		select
			'99226'
		union
		select
			'99231'
		union
		select
			'99232'
		union
		select
			'99233'
		union
		select
			'99234'
		union
		select
			'99235'
		union
		select
			'99239'
		union
		select
			'99241'
		union
		select
			'99242'
		union
		select
			'99243'
		union
		select
			'99244'
		union
		select
			'99245'
		union
		select
			'99251'
		union
		select
			'99252'
		union
		select
			'99253'
		union
		select
			'99254'
		union
		select
			'99255'
		union
		select
			'99304'
		union
		select
			'99305'
		union
		select
			'99306'
		union
		select
			'99307'
		union
		select
			'99308'
		union
		select
			'99309'
		union
		select
			'99310'
		union
		select
			'99315'
		union
		select
			'99316'
		union
		select
			'99318'
		union
		select
			'99358'
		union
		select
			'99381'
		union
		select
			'99382'
		union
		select
			'99383'
		union
		select
			'99384'
		union
		select
			'99385'
		union
		select
			'99386'
		union
		select
			'99387'
		union
		select
			'99391'
		union
		select
			'99392'
		union
		select
			'99393'
		union
		select
			'99394'
		union
		select
			'99395'
		union
		select
			'99396'
		union
		select
			'99397'
		union
		select
			'99406'
		union
		select
			'99417'
		union
		select
			'99442'
		union
		select
			'99460'
		union
		select
			'99462'
		union
		select
			'99463'
		union
		select
			'99468'
		union
		select
			'99469'
		union
		select
			'99472'
		union
		select
			'99477'
		union
		select
			'99478'
		union
		select
			'99479'
		union
		select
			'99480'
		union
		select
			'99495'
		union
		select
			'99496'
	) t1;

	create nonclustered index idx_CPT on #CPT1 (CPT);

	
	----------------------------------------------------------------------------------------------------------------------------------

	select
		t2.*
	into #NEXT_LEVEL_MIN
	from
	(
		select
			'99202' as CPT
			,30     as MIN
		union
		select
			'99203' as CPT
			,44     as MIN
		union
		select
			'99204' as CPT
			,60     as MIN
		union
		select
			'99205' as CPT
			,0      as MIN
		union
		select
			'99212' as CPT
			,20     as MIN
		union
		select
			'99213' as CPT
			,30     as MIN
		union
		select
			'99214' as CPT
			,40     as MIN
		union
		select
			'99215' as CPT
			,0      as MIN
		union
		select
			'99217' as CPT
			,0      as MIN
		union
		select
			'99218' as CPT
			,30     as MIN
		union
		select
			'99219' as CPT
			,50     as MIN
		union
		select
			'99220' as CPT
			,70     as MIN
		union
		select
			'99221' as CPT
			,15     as MIN
		union
		select
			'99222' as CPT
			,15     as MIN
		union
		select
			'99223' as CPT
			,15     as MIN
		union
		select
			'99224' as CPT
			,15     as MIN
		union
		select
			'99225' as CPT
			,25     as MIN
		union
		select
			'99226' as CPT
			,35     as MIN
		union
		select
			'99231' as CPT
			,25     as MIN
		union
		select
			'99232' as CPT
			,35     as MIN
		union
		select
			'99234' as CPT
			,45     as MIN
		union
		select
			'99235' as CPT
			,70     as MIN
		union
		select
			'99236' as CPT
			,85     as MIN
		union
		select
			'99238' as CPT
			,0      as MIN
		union
		select
			'99239' as CPT
			,0      as MIN
		
		-- Added codes below RACS-2658 JHerrera
		union
		select
			'99202' as [CPT]
			,30     as MIN
		union
		select
			'99203'
			,44 
		union
		select
			'99204'
			,60 
		union
		select
			'99205'
			,0 
		union
		select
			'99211'
			,0 
		union
		select
			'99212'
			,20 
		union
		select
			'99213'
			,30 
		union
		select
			'99214'
			,40 
		union
		select
			'99215'
			,0 
		union
		select
			'99281'
			,0 
		union
		select
			'99282'
			,0 
		union
		select
			'99283'
			,0 
		union
		select
			'99284'
			,0 
		union
		select
			'99285'
			,0 
		union
		select
			'99291'
			,0 
		union
		select
			'99292'
			,0 		
		union
		select
			'99233'
			,0 
		union
		select
			'99239'
			,0 
		union
		select
			'99241'
			,0 
		union
		select
			'99242'
			,0 
		union
		select
			'99243'
			,0 
		union
		select
			'99244'
			,0 
		union
		select
			'99245'
			,0 
		union
		select
			'99251'
			,0 
		union
		select
			'99252'
			,0 
		union
		select
			'99253'
			,0 
		union
		select
			'99254'
			,0 
		union
		select
			'99255'
			,0 
		union
		select
			'99304'
			,0 
		union
		select
			'99305'
			,0 
		union
		select
			'99306'
			,0 
		union
		select
			'99307'
			,0 
		union
		select
			'99308'
			,0 
		union
		select
			'99309'
			,0 
		union
		select
			'99310'
			,0 
		union
		select
			'99315'
			,0 
		union
		select
			'99316'
			,0 
		union
		select
			'99318'
			,0 
		union
		select
			'99358'
			,0 
		union
		select
			'99381'
			,0 
		union
		select
			'99382'
			,0 
		union
		select
			'99383'
			,0 
		union
		select
			'99384'
			,0 
		union
		select
			'99385'
			,0 
		union
		select
			'99386'
			,0 
		union
		select
			'99387'
			,0 
		union
		select
			'99391'
			,0 
		union
		select
			'99392'
			,0 
		union
		select
			'99393'
			,0 
		union
		select
			'99394'
			,0 
		union
		select
			'99395'
			,0 
		union
		select
			'99396'
			,0 
		union
		select
			'99397'
			,0 
		union
		select
			'99406'
			,0 
		union
		select
			'99417'
			,0 
		union
		select
			'99442'
			,0 
		union
		select
			'99460'
			,0 
		union
		select
			'99462'
			,0 
		union
		select
			'99463'
			,0 
		union
		select
			'99468'
			,0 
		union
		select
			'99469'
			,0 
		union
		select
			'99472'
			,0 
		union
		select
			'99477'
			,0 
		union
		select
			'99478'
			,0 
		union
		select
			'99479'
			,0 
		union
		select
			'99480'
			,0 
		union
		select
			'99495'
			,0 
		union
		select
			'99496'
			,0 
	) t2;

	create nonclustered index idx_CPT on #NEXT_LEVEL_MIN (CPT);
	

print 'Section: 01 ' + convert(varchar, getdate(), 121)

-- *********************************************************
	


-- Providers

				select
				FACILITY_PROF_ID					
                into #Provider1
				from
					FACILITY_PROFESSIONAL
				where
				(FACILITY_ID in (SELECT * FROM SPLITSTRING(@FACILITY_ID, ','))
		          OR '-1' in (SELECT * FROM SPLITSTRING(@FACILITY_ID, ',')) 
				 )
	            
				AND (FACILITY_PROF_ID in (SELECT * FROM SPLITSTRING(@m_Provider, ','))
				     OR '-1' in (SELECT * FROM SPLITSTRING(@m_Provider, ','))  )

	

print 'Section: 02 ' + convert(varchar, getdate(), 121)

-- *********************************************************

-- AuthorizedFacilities


	select
		*
	into #AuthorizedFacilities
	from
	(
		select distinct
			fua.FACILITY_ID
		from
			FACILITY_USER_AUTHORIZATION fua
			,USER_PROFILE up
			,SERVICE_AGREEMENT sa
		where
			fua.USER_PROFILE_ID = up.USER_PROFILE_ID
			and fua.FACILITY_ID = sa.FACILITY_ID
			and up.IS_ACTIVE = 'Y'
			and getdate() between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
			and getdate() between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
			and sa.DEMO_TEST_SITE_IND = 0
			and fua.USER_PROFILE_ID = @ReportUser
			and
			(
				'-1' in (SELECT * FROM SPLITSTRING(@Company, ','))
				or sa.COMPANY_ID in (SELECT * FROM SPLITSTRING(@Company, ','))
			)
			and EVALUATE_PHYSICIAN_SVC = 1 -- Physician Services
			and sa.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN = 1
			and
			(
				sa.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE is null
				or sa.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE > getdate()
			)			
			and
			(
				'-1' in (SELECT * FROM SPLITSTRING(@FACILITY_ID, ','))
				or fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@FACILITY_ID, ','))
			)
	) fa;


	-- 		select * from #AuthorizedFacilities

print 'Section: 03 ' + convert(varchar, getdate(), 121)

-- *********************************************************
	
-- Chart data pull
-- Based on Facility and Date Range

	select
		c.CHART_ID
	into #Chart1
	from
		CHART c
	where
		c.FACILITY_ID in
		(
			select FACILITY_ID from #AuthorizedFacilities
		)
		and cast(c.TIME_OF_SERVICE as date) >= '1/1/2021'

	    and		
		(
		(@DateType = 3 and c.TIME_OF_SERVICE between @StartDate and  DateAdd(second, 86399, @EndDate) )
		or
		(@DateType = 0 and convert(date, c.APPROVED_DATE) between convert(date, @StartDate) and convert(date, @EndDate) )
		or 
		(@DateType = 2 and convert(date, c.SENT_DATE) between convert(date, @StartDate) and convert(date, @EndDate) )
		or 
		(@DateType = 1 and convert(date, c.COMPLETION_DATE) between convert(date, @StartDate) and convert(date, @EndDate) )
		)
		;


-- select * from 	#Chart1 
		
print 'Section: 04 ' + convert(varchar, getdate(), 121)

-- *********************************************************
	
-- Chart fields data pull 
	

	select
		 c.CHART_ID
		,c.FACILITY_ID
		,c.FACILITY_CHART_ID
		,c.medical_record_num
		,c.CLINIC_ID
		,c.FINANCIAL_CLASS_CD
		,c.PATIENT_CLASS_ID
		,c.TIME_OF_SERVICE
		,c.SENT_DATE
		,c.CHART_STATUS_ID
		,c.SERVICE_AGREEMENT_ID
		,c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES
		,c.CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE
		,c.PHYSICIAN_SERVICE_PROC_ID
		,c.CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE
		,case
			 when c.CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE >= c.CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE then
				 'Based on MDM'
			 when c.CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE is null
				  and c.CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE is null then ''
		 else 'Based on Time' end                            as MDM_TIME_Basis
		,case
			 when c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES is null then -1
		 else c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES end as TIME_BASED_ENCOUNTER_MINUTES
		,c.PROVIDER_SPECIFIED_LOS_PHYSICIAN_SERVICE_PROC_ID
		,c.PROVIDER_SPECIFIED_LOS_MODIFIER
		,c.PROVIDER_EVAL_PERFORMED_BY_IND
		,c.PHYSICIAN_ID
		,c.NURSE_PRACTITIONER_ID
		,c.No_Physician_Services
		,c.PHYSICIAN_SERVICE_MOD
		,c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		
	into #Chart2
	from
		CHART c
	where
		CHART_ID in
		(
			select CHART_ID from #Chart1
		);


	-- select * from #Chart2

print 'Section: 05 ' + convert(varchar, getdate(), 121)

-- *********************************************************
	
	-- Step 4 Service Agreement fields data pull 

	select
		c.*
		,sa.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN
		,sa.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EFFECTIVE_DATE
		,sa.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE
		,sa.PHYSICIAN_SERVICE_PLAN_ID
	into #Chart3
	from
		#Chart2 c
		,SERVICE_AGREEMENT sa
	where
		c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID;

-- select * from #Chart3



print 'Section: 06 ' + convert(varchar, getdate(), 121)

-- *********************************************************


	
-- E_M

	select
		 c.CHART_ID
		,c.FACILITY_ID
		,f.NAME                                                                         as facility_name
		,f.ABBREVIATED_NAME                                                             as facility_abbr_name
		,1																				as Level_Number
		,case
			 when c.PROVIDER_EVAL_PERFORMED_BY_IND is null
				  or c.PROVIDER_EVAL_PERFORMED_BY_IND = 0 then c.PHYSICIAN_ID
			 when c.PROVIDER_EVAL_PERFORMED_BY_IND = 1 then c.NURSE_PRACTITIONER_ID end as Provider_ID
		,fp.LAST_NAME + ', ' + fp.FIRST_NAME                                            as Provider
		,fp.UPIR_ID as Provider_NPI
		,c.FACILITY_CHART_ID
		,c.SERVICE_AGREEMENT_ID
		,c.CLINIC_ID
		,c.PATIENT_CLASS_ID
		,c.medical_record_num
		,c.TIME_OF_SERVICE
		,c.SENT_DATE
		,c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES
		,c.MDM_TIME_Basis
		,c.TIME_BASED_ENCOUNTER_MINUTES
		,case
			 when c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN = 1
				  and c.TIME_OF_SERVICE between c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EFFECTIVE_DATE 
				                            and isnull(	c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE,'12/31/2099'  ) 
			then  psp1.CPT_CODE
		    else null end as Provider_Selected_E_M
		,case
			 when c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN = 1
				  and c.TIME_OF_SERVICE between c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EFFECTIVE_DATE 
				                           and isnull( c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE,'12/31/2099' ) 
		     then c.PROVIDER_SPECIFIED_LOS_MODIFIER
			 else null end                                                              as Provider_Selected_Modifier

		,psp2.CPT_CODE                                                                  as Physician_Service_CPT		--CH Selected E/M
		,c.PHYSICIAN_SERVICE_MOD                                                        as Physician_Service_MOD
		,psp3.CPT_CODE		                                                            as Override_LOS

 	into #Chart4
	from
		#Chart3                    c
		left outer join PHYSICIAN_SERVICE_PROCEDURE    psp1 on psp1.PHYSICIAN_SERVICE_PROC_ID = c.PROVIDER_SPECIFIED_LOS_PHYSICIAN_SERVICE_PROC_ID
		left outer join PHYSICIAN_SERVICE_PROCEDURE    psp2 on psp2.PHYSICIAN_SERVICE_PROC_ID = c.PHYSICIAN_SERVICE_PROC_ID
		left outer join PHYSICIAN_SERVICE_PROCEDURE    psp3 on -- Override
											psp3.PHYSICIAN_SERVICE_PROC_ID = c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID

		inner join FACILITY                       f on f.FACILITY_ID = c.FACILITY_ID
		inner join PATIENT_CLASS                  pc on pc.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
		left outer join FACILITY_PROFESSIONAL          fp on (case
												  when c.PROVIDER_EVAL_PERFORMED_BY_IND is null
													   or c.PROVIDER_EVAL_PERFORMED_BY_IND = 0 then c.PHYSICIAN_ID
												  when c.PROVIDER_EVAL_PERFORMED_BY_IND = 1 then c.NURSE_PRACTITIONER_ID end
											 ) = fp.FACILITY_PROF_ID

	where
		c.TIME_OF_SERVICE between c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EFFECTIVE_DATE and isnull(c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE,'12/31/2099')
 		and c.CHART_STATUS_ID = 5 
		and ('-1' in (SELECT * FROM SPLITSTRING(@PatientClassId, ',')) or c.PATIENT_CLASS_ID in (SELECT * FROM SPLITSTRING(@PatientClassId, ',')))


-- select * from #Chart4


print 'Section: 07 ' + convert(varchar, getdate(), 121)

-- *********************************************************

-- Additional Levels

INSERT INTO #Chart4
select
		 c.CHART_ID
		,c.FACILITY_ID
		,f.NAME                                                                         as facility_name
		,f.ABBREVIATED_NAME                                                             as facility_abbr_name
		,cplos2.level_number																as Level_Number
		,cplos2.provider_id																as Provider_ID		
		,fp.LAST_NAME + ', ' + fp.FIRST_NAME                                            as Provider
		,fp.UPIR_ID as Provider_NPI
		,c.FACILITY_CHART_ID
		,c.SERVICE_AGREEMENT_ID
		,c.CLINIC_ID
		,cplos2.PATIENT_CLASS_ID
		,c.medical_record_num
		,cplos2.Date_OF_SERVICE															as TIME_OF_SERVICE
		,c.SENT_DATE
		,c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES
		,c.MDM_TIME_Basis
		,c.TIME_BASED_ENCOUNTER_MINUTES
		
		,psp2.cpt_code																 as Provider_Selected_E_M
		,psp2.Modifier                                                               as Provider_Selected_Modifier

		,psp.cpt_code                                                                as Physician_Service_CPT		--CH Selected E/M
		,psp.Modifier                                                                as Physician_Service_MOD
		,psp3.cpt_code                                                               as Override_LOS


	from
		#Chart3 c    		
		left outer join CHART_PHYSICIAN_LEVEL_OF_SERVICE cplos1 on c.chart_id = cplos1.chart_id
		left outer join PHYSICIAN_SERVICE_PROCEDURE psp on psp.PHYSICIAN_SERVICE_PROC_ID = cplos1.PHYSICIAN_SERVICE_PROC_ID
		left outer join CHART_PHYSICIAN_LEVEL_OF_SERVICE cplos2 on c.chart_id = cplos2.chart_id
		left outer join PHYSICIAN_SERVICE_PROCEDURE psp2 on cplos2.Provider_Specified_Los_Physician_Service_Proc_ID = psp2.PHYSICIAN_SERVICE_PROC_ID
        left outer join FACILITY_PROFESSIONAL fp on cplos2.provider_id = fp.FACILITY_PROF_ID
		left outer join PHYSICIAN_SERVICE_PROCEDURE psp3 on -- Override
															psp3.PHYSICIAN_SERVICE_PROC_ID = cplos2.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID

		inner join FACILITY f on f.FACILITY_ID = c.FACILITY_ID
		
		where cplos1.chart_id = cplos2.chart_id
		and cplos1.level_number = cplos2.level_number		
		
		and c.TIME_OF_SERVICE between c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EFFECTIVE_DATE and isnull(c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE,'12/31/2099')
 		and c.CHART_STATUS_ID = 5 -- Sent  
		and ('-1' in (SELECT * FROM SPLITSTRING(@PatientClassId, ',')) or c.PATIENT_CLASS_ID in (SELECT * FROM SPLITSTRING(@PatientClassId, ',')))




print 'Section: 07.1 ' + convert(varchar, getdate(), 121)

-- *********************************************************



if object_id('TempDB..#Provider_Specified_Procedure_1', 'U') is not null drop table #Provider_Specified_Procedure_1;

select 
 c.chart_id 	
,cpsp.CPT_CODE		as Provider_Specified_Procedure_CPT_Code
,cpsp.Modifiers		as Provider_Specified_Procedure_Modifiers
,cpsp.Quantity		as Provider_Specified_Procedure_Quantity

,case
             when cpsp.CPT_CODE is null then null
			 when len(cpsp.Modifiers) > 0 then
				  concat(cpsp.CPT_CODE, '-', cpsp.Modifiers, '(', cpsp.Quantity,')' )
		     else concat(cpsp.CPT_CODE, '(', cpsp.Quantity,')' ) end as [Provider_Specified_Procedure_Combined]

into #Provider_Specified_Procedure_1
from
#Chart3  c
left outer join CHART_PHYSICIAN_SPECIFIED_PROCEDURE cpsp on c.chart_id = cpsp.chart_id


-- select * from #Provider_Specified_Procedure_1



print 'Section: 07.2 ' + convert(varchar, getdate(), 121)

-- *********************************************************

if object_id('TempDB..#Procedure_CPT_1', 'U') is not null drop table #Procedure_CPT_1;

select
 c.chart_id 
,cm.CPT_CODE        as Procedure_CPT_CPT
,ppe.MODIFIERS      as Procedure_CPT_Mod
,ppe.QUANTITY       as Procedure_CPT_Qty

,case
			 when cm.CPT_CODE is null then null
			 when len(ppe.MODIFIERS) > 0 then
				  concat(cm.CPT_CODE, '-', ppe.MODIFIERS, '(', ppe.QUANTITY,')' )
		     else concat(cm.CPT_CODE, '(', ppe.QUANTITY,')' ) end as [Procedure_CPT_Combined]



into #Procedure_CPT_1
from
#Chart3 c 
left outer join PHYSICIAN_PROCEDURE_EVALUATION ppe on ppe.CHART_ID = c.CHART_ID
		left outer join CHARGE_MASTER                  cm on cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID 


-- select * from #Chart3
--    select * from #Procedure_CPT_1







IF @Procedure_CPT <> '-1'
BEGIN

delete from #Procedure_CPT_1
where isnull(Procedure_CPT_CPT,'-9999') not in (SELECT * FROM SPLITSTRING(@Procedure_CPT, ','))

End




print 'Section: 07.3 ' + convert(varchar, getdate(), 121)

-- *********************************************************





	select 
		 ca.CHART_ID
		,ca.CHARGE_MASTER_ID
		,cm.CPT_CODE
		,ca.QUANTITY
	into #adjustments
	from
		dbo.CHART_ADJUSTMENT ca
		left join dbo.CHARGE_MASTER cm on ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
	where
		ca.CHART_ID in (select distinct CHART_ID from #Chart4)

	
 --select * from #adjustments


print 'Section: 08 ' + convert(varchar, getdate(), 121)

-- *********************************************************



-- MDM


if object_id('TempDB..#Chart5', 'U') is not null drop table #Chart5;

	select distinct
		c.CHART_ID
		,c.FACILITY_ID
		,c.facility_name
		,c.facility_abbr_name
		,c.Level_Number
		,c.Provider_ID
		,c.[Provider]
		,c.Provider_NPI
		,c.FACILITY_CHART_ID
		,c.medical_record_num
		,c.SERVICE_AGREEMENT_ID
		,c.CLINIC_ID
		,c.PATIENT_CLASS_ID
		,c.TIME_OF_SERVICE
		,c.SENT_DATE
		,c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES
		,c.MDM_TIME_Basis
		,c.TIME_BASED_ENCOUNTER_MINUTES
		,c.Provider_Selected_E_M
		,c.Provider_Selected_Modifier
		,case -- Level Of Service Override 
			 when c.Override_LOS is not null then c.Override_LOS
		 else c.Physician_Service_CPT end  as Physician_Service_CPT
		,c.Physician_Service_MOD
		,c.Override_LOS

 	into #Chart5
	from
		#Chart4 c;



-- select * from #Chart4
-- select * from #Chart5


print 'Section: 09 ' + convert(varchar, getdate(), 121)

-- *********************************************************



-- Adjustment Update ******

-- Note: not sure how multi level may impact this, added a condition of Level 1 only 
	update #Chart5
	set Physician_Service_CPT = CPT_CODE 
	from
		#Chart5 c
		inner join #adjustments a on c.CHART_ID = a.CHART_ID
	where
		a.QUANTITY > 0
		and c.Level_Number = 1


print 'Section: 10 ' + convert(varchar, getdate(), 121)

-- *********************************************************


	


if object_id('TempDB..#Chart6', 'U') is not null drop table #Chart6;

	select distinct
		1                              as All_Data
		,c.CHART_ID
		,c.FACILITY_ID
		,case
		 when c.facility_abbr_name is null then c.facility_name
		 when c.facility_abbr_name = '' then c.facility_name
		 else c.facility_abbr_name end as Facility
        ,c.Level_Number
		,c.Provider_ID
		,c.[Provider]
		,c.Provider_NPI
		,c.FACILITY_CHART_ID
		,c.medical_record_num
		,c.SERVICE_AGREEMENT_ID
		,c.CLINIC_ID
		,c.PATIENT_CLASS_ID
		,c.TIME_OF_SERVICE
		,c.SENT_DATE
		,c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES
		,c.MDM_TIME_Basis
		,c.TIME_BASED_ENCOUNTER_MINUTES

		,c.Provider_Selected_E_M
		,c.Provider_Selected_Modifier
	
		,case
			 when len(c.Provider_Selected_Modifier) > 0 then
				  concat(c.Provider_Selected_E_M, '-', c.Provider_Selected_Modifier)
		     else c.Provider_Selected_E_M end as Provider_Specified_LOS_Combined
	
	
		,c.Physician_Service_CPT
		,c.Physician_Service_MOD

		,case
			 when len(c.Physician_Service_MOD) > 0 then
				  concat(c.Physician_Service_CPT, '-', c.Physician_Service_MOD)
		     else c.Physician_Service_CPT end as Physician_Service_CPT_Combined


		,c.Override_LOS

 		,case when @Procedure_CPT = '-1' then '-1'
		else 
		(select Procedure_CPT_CPT from #Procedure_CPT_1 c5 where c5.CHART_ID = c.CHART_ID) 
		end as Procedure_CPT_CPT

/*
		,ltrim(stuff((
						 select
							 '/ ' + c5.Procedure_CPT_Combined -- Physician_Procedure_Combined
						 from
							 #Procedure_CPT_1 c5
						 where
							 c5.CHART_ID = c.CHART_ID
						 for xml path(''), type
					 ).value('.', 'VARCHAR(MAX)')
						,1
						,1
						,''
					)
			  )              as Procedure_CPT -- old name Physician_Procedure ****



		,ltrim(stuff((
						 select
							 '/ ' + c6.Provider_Specified_Procedure_Combined
						 from
							 #Provider_Specified_Procedure_1 c6
						 where
							 c6.CHART_ID = c.CHART_ID
						 for xml path(''), type
					 ).value('.', 'VARCHAR(MAX)')
						,1
						,1
						,''
					)
			  )                as Provider_Specified_Procedure
*/

,(SELECT 	
ltrim(STUFF((SELECT '/ ' + Procedure_CPT_Combined
  from (	
select 
c5.Procedure_CPT_CPT,
c5.Procedure_CPT_Combined
from  #Procedure_CPT_1 c5
where 	
c5.CHART_ID = c.CHART_ID

) x	
   ORDER BY  Procedure_CPT_CPT
      FOR XML PATH('')) , 1, 1, '')
)	   
)	  as Procedure_CPT



,(SELECT 	
ltrim(STUFF((SELECT '/ ' + Provider_Specified_Procedure_Combined
  from (	
select 
c6.Provider_Specified_Procedure_CPT_Code,
c6.Provider_Specified_Procedure_Combined	
from  #Provider_Specified_Procedure_1 c6
where 	
c6.CHART_ID = c.CHART_ID

) x	
   ORDER BY  Provider_Specified_Procedure_CPT_Code
      FOR XML PATH('')) , 1, 1, '') 
)
)	  as Provider_Specified_Procedure




		,(
			 select (MIN - case
							   when c.Physician_Service_CPT = '99205' then 0
							   when c.Physician_Service_CPT = '99215' then 0
							   when c.Physician_Service_CPT = '99217' then 0
							   when c.Physician_Service_CPT = '99238' then 0
							   when c.Physician_Service_CPT = '99239' then 0
							   when c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES is null then 0
							   when c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES = -1 then 0
						   else c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES end
					)
			 from
				 #NEXT_LEVEL_MIN
			 where
				 CPT = c.Physician_Service_CPT
		 )                             as NextLevelMinutes
		,case
			 when substring(isnull(Provider_Selected_E_M, 0), 1, 5) = substring(isnull(Physician_Service_CPT, 0), 1, 5) then
				 1
		 else 0 end                    EM_Check
		
		,case
			 when (
					  c.Provider_Selected_E_M is not null
					  or c.Physician_Service_CPT is not null
				  )
				  and substring(Provider_Selected_E_M, 1, 4) = substring(Physician_Service_CPT, 1, 4) then 'Y'
		 else 'N' end                  CH_Check
		,case
			 when substring(isnull(Provider_Selected_E_M, ''), 1, 4) <> substring(isnull(Physician_Service_CPT, ''), 1, 4) then
				 1
		 else 0 end                    CH_Visit
		,case
			 when substring(Provider_Selected_Modifier, 1, len(Provider_Selected_Modifier)) = substring(
																										   Physician_Service_MOD
																										   ,1
																										   ,len(Physician_Service_MOD)
																									   ) then 0
		 else 1 end                    CH_MOD
		
		

	into #Chart6
	from
		#Chart5 c
	where
		(
			Provider_ID in
			(
				select FACILITY_PROF_ID from #Provider1
			)
			or '-1' in
			   (
				   select FACILITY_PROF_ID from #Provider1
			   )
		);


--select * from #Chart5 
--select * from #Chart6 


print 'Section: 11 ' + convert(varchar, getdate(), 121)

-- *********************************************************

	
--  CPT checks

	select distinct
		c.*
		,(
			 select distinct
				 'Y'
			 from
				 #Chart6 c1
			 where
				 exists
			 (
				 select CPT from #CPT1 where CPT = c1.Provider_Selected_E_M
			 )
				 and c1.CHART_ID = c.CHART_ID
		 ) as CPT1_Check
		,(
			 select distinct
				 'Y'
			 from
				 #Chart6 c2
			 where
				 exists
			 (
				 select CPT from #CPT1 where CPT = c2.Physician_Service_CPT
			 )
				 and c2.CHART_ID = c.CHART_ID
		 ) as CPT2_Check
	into #Chart7
	from
		#Chart6 c;


print 'Section: 12 ' + convert(varchar, getdate(), 121)

-- *********************************************************
	
-- Output
	


	select -- distinct
		 c.All_Data
		,c.CHART_ID
		,c.FACILITY_ID
		,c.facility
		,c.Level_Number
		,c.Provider_ID
		,c.[Provider]
		,c.Provider_NPI
		,c.FACILITY_CHART_ID
		,c.medical_record_num
		,c.CLINIC_ID
        ,(Select description from SERVICE_AGREEMENT_CLINIC where service_agreement_id = c.service_agreement_id and  CLINIC_ID = c.CLINIC_ID) as Clinic
		,c.PATIENT_CLASS_ID
		,(select description from PATIENT_CLASS where service_agreement_id = c.service_agreement_id and  PATIENT_CLASS_ID = c.PATIENT_CLASS_ID) as PatientClass
		,c.TIME_OF_SERVICE
		,c.SENT_DATE
		,c.CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES
		,c.MDM_TIME_Basis
		,c.TIME_BASED_ENCOUNTER_MINUTES


		,c.Provider_Specified_LOS_Combined as Provider_Specified_LOS			--Provider Selected E/M
	
		,(select top 1 cm.DESCRIPTION
			from
				dbo.CHARGE_MASTER cm
				,dbo.SERVICE_AGREEMENT sa
			where
				cm.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
				and sa.FACILITY_ID = c.FACILITY_ID
				and cm.CPT_CODE = c.Provider_Selected_E_M
			order by cm.EFFECTIVE_DATE desc
			) Provider_Specified_LOS_Desc





		, c.Physician_Service_CPT_Combined as  Physician_Service_CPT			--CH Selected E/M
		,(select top 1 cm.DESCRIPTION
			from
				dbo.CHARGE_MASTER cm
				,dbo.SERVICE_AGREEMENT sa
			where
				cm.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
				and sa.FACILITY_ID = c.FACILITY_ID
				and cm.CPT_CODE = c.Physician_Service_CPT
			order by cm.EFFECTIVE_DATE desc
			) Physician_Service_CPT_Desc

		
		,c.CH_Check
		
		
		,case
			 when (
					  c.Provider_Selected_E_M is null
					  or c.Physician_Service_CPT is null
				  ) then 0
			when substring(Provider_Selected_E_M, 1, 5) = substring(Physician_Service_CPT, 1, 5) then 1
		 else 0 end                    EM_Check_N
		,case
			 when (
					  c.Provider_Selected_E_M is null
					  or c.Physician_Service_CPT is null
				  ) then 0
		 else 1 end                    EM_Check_D
		,case
			 when substring(isnull(Provider_Selected_E_M, 0), 1, 5) = substring(isnull(Physician_Service_CPT, 0), 1, 5) then
				 1
		 else 0 end                  CH_Check_N
		,1 as CH_Check_D
		

		
		,c.NextLevelMinutes
		,ltrim(stuff((
						 select
							 ', ' + replace(replace(DESCRIPTION,'<i><strong>',''),'</strong></i>','')
						 from
							 PHYSICIAN_SERVICE
						 where
							 PHYSICIAN_SERVICE_ID in
							 (
								 select
									 PHYSICIAN_SERVICE_ID
								 from
									 PHYSICIAN_SERVICE_EVAL
								 where
									 CHART_ID = c.CHART_ID
							 )
							 and CATEGORY_ID = 3
							 and SUBCATEGORY_ID = 1
							 and MINOR_CATEGORY in (4, 5, 6, 7)
						 order by
							 PHYSICIAN_SERVICE_ID
						 for xml path(''), type
					 ).value('.', 'VARCHAR(MAX)')
						,1
						,1
						,''
					)
			  )     [W]
		,ltrim(stuff(
						(
							select
								', ' + ps.DESCRIPTION + ': '
								+ cast((
										   select
											   pse.QUANTITY
										   from
											   PHYSICIAN_SERVICE_EVAL pse
										   where
											   pse.CHART_ID = c.CHART_ID
											   and pse.PHYSICIAN_SERVICE_ID = ps.PHYSICIAN_SERVICE_ID
									   ) as varchar)
							from
								PHYSICIAN_SERVICE ps
							where
								ps.PHYSICIAN_SERVICE_ID in
								(
									select
										pse1.PHYSICIAN_SERVICE_ID
									from
										PHYSICIAN_SERVICE_EVAL pse1
									where
										pse1.CHART_ID = c.CHART_ID
								)
								and ps.CATEGORY_ID = 3
								and ps.SUBCATEGORY_ID = 2
							order by
								ps.PHYSICIAN_SERVICE_ID
							for xml path(''), type
						).value('.', 'VARCHAR(MAX)')
						,1
						,1
						,''
					)
			  )     [X]
		,ltrim(stuff((
						 select
							 ', ' + replace(replace(left(ps.DESCRIPTION, charindex('</b>', ps.DESCRIPTION, 0) + 3),'<b>',''),'</b>','')
						 from
							 PHYSICIAN_SERVICE ps
						 where
							 ps.PHYSICIAN_SERVICE_ID in
							 (
								 select
									 pse1.PHYSICIAN_SERVICE_ID
								 from
									 PHYSICIAN_SERVICE_EVAL pse1
								 where
									 pse1.CHART_ID = c.CHART_ID
							 ) -- = 66064117 )
							 and ps.CATEGORY_ID = 3
							 and ps.SUBCATEGORY_ID = 3
						 order by
							 ps.PHYSICIAN_SERVICE_ID
						 for xml path(''), type
					 ).value('.', 'VARCHAR(MAX)')
						,1
						,1
						,''
					)
			  )     [Y]

		,case
			 when substring(Provider_Selected_E_M, 1, 4) = substring(Physician_Service_CPT, 1, 4)
				  and c.CPT1_Check = 'Y'
				  and c.CPT2_Check = 'Y'
				  and cast(substring(Physician_Service_CPT, 5, 1) as int)
					  - cast(substring(Provider_Selected_E_M, 5, 1) as int) > 0 then 1
		 else 0 end as CH_Up
		,case
			 when substring(Provider_Selected_E_M, 1, 4) = substring(Physician_Service_CPT, 1, 4)
				  and c.CPT1_Check = 'Y'
				  and c.CPT2_Check = 'Y'
				  and cast(substring(Physician_Service_CPT, 5, 1) as int)
					  - cast(substring(Provider_Selected_E_M, 5, 1) as int) < 0 then 1
		 else 0 end as CH_Down
		,c.CH_Visit
		,c.CH_MOD
		,c.Override_LOS
        ,case when isnull(c.Provider_Selected_E_M, '') = isnull(c.Physician_Service_CPT, '') then 0 else 1 end as ColumnCompare

		
		
		
        ,c.Procedure_CPT_CPT

		,c.Procedure_CPT
	    ,c.Provider_Specified_Procedure
	from
		#Chart7 c
	where
		('-1' in (SELECT * FROM SPLITSTRING(@Provided_Selected_E_M, ',')) or isnull(c.Provider_Selected_E_M,'-9999') in (SELECT * FROM SPLITSTRING(@Provided_Selected_E_M, ',')))
	and ('-1' in (SELECT * FROM SPLITSTRING(@Physician_Service_CPT, ',')) or isnull(c.Physician_Service_CPT,'-9999') in (SELECT * FROM SPLITSTRING(@Physician_Service_CPT, ',')))
    and ('-1' = (@Procedure_CPT)	or isnull(c.Procedure_CPT_CPT,'-9999') = (@Procedure_CPT))
	and ('-1' in (SELECT * FROM SPLITSTRING(@Clinic, ',')) or c.CLINIC_ID in (SELECT * FROM SPLITSTRING(@Clinic, ',')))




-- order by c.chart_id		
		

	

end





GO
