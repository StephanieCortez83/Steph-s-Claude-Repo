SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE PROCEDURE [dbo].[rpt_CPT_Frequency_Summary_By_Facility_Original] 
  		 @CodeType         int            
		,@Code            varchar(max) 
		,@Organization    int 
		,@ReportUser      int           
		,@Facility        varchar(max)           
		,@StartDate       datetime      
		,@EndDate         datetime      
		,@Department      varchar(max) 
		,@Disposition     varchar(max)  
		,@DateType        int           
		,@Details         int  
		,@Clinic          varchar(max)


AS
BEGIN




    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SET NOCOUNT ON;

-- Test Parameters ****	
	--declare
	--	 @CodeType         int           = 1    -- 0 CPT, 1 Billing
	--	,@Code            varchar(max)  = '---Bypass Filter---'  -- ERM1732595 - 5, ERM1737338 - 430 , 'ERM1732595, ERM1737338'
	--	,@Organization    int           = 134   --197
	--	,@ReportUser      int           = 80
	--	,@Facility        varchar(max)  = '955'		 -- -1 All	
	--	,@StartDate       datetime      = '20250101'
	--	,@EndDate         datetime      = '20250131'
	--	,@Department      varchar(max) = '-1'  -- -1 All	
	--	,@Disposition     varchar(max)  = '-99'  -- -99 All
	--	,@DateType        int           = 0    -- 0 DOS, 1 Approved, 2 Sent
	--	,@Details         int           = 0   -- 0 Summary, 1 Details
	--	,@Clinic          varchar(max)  = '-1'   --DES, SES'   -- -1 All



declare @m_CodeType         int				= @CodeType;      
declare @m_Code            varchar(max)     = @Code;
declare @m_Organization    int				= @Organization;
declare @m_ReportUser      int				= @ReportUser;	      
declare	@m_Facility        varchar(max)     = @Facility;         
declare	@m_StartDate       datetime         = @StartDate;
declare	@m_EndDate         datetime         = @EndDate;
declare	@m_Department      varchar(max)     = @Department; 
declare	@m_Disposition     varchar(max)     = @Disposition;
declare	@m_DateType        int              = @DateType;
declare	@m_Details         int              = @Details;
declare	@m_Clinic          varchar(max)     = @Clinic;







      DECLARE @IncludeAllFacilities		  bit = IIF(@m_Facility LIKE '%-1%', 1, 0)
	  DECLARE @IncludeAllCodes		      bit = IIF(@m_Code LIKE '%---Bypass Filter---%', 1, 0)
	  DECLARE @IncludeAllDispositions	  bit = IIF(@m_Disposition LIKE '%-99%', 1, 0)
	  DECLARE @IncludeAllDepartments	  bit = IIF(@m_Department LIKE '%-1%', 1, 0)
	  DECLARE @IncludeAllClinics		  bit = IIF(@m_Clinic LIKE '%-1%', 1, 0)
	----------------------------------------------------------------------------------------------------------------------------------

	if datediff(day,@m_StartDate,@m_EndDate) > 90
	begin

		if @m_Details = 1
		begin

			select
				'ALL' as [AllData]
				,null as [FACILITY_ID]
				,null as [NAME]
				,null as [abbrev_name]
				,null as [DOS]
				,null as [DOS_Year]
				,null as [DOS_Month]
				,null as [Approved_Date]
				,null as [Sent_Date]
				,null as [Sent_Date_Year]
				,null as [Sent_Date_Month]
				,null as [CHART_ID]
				,null as [FACILITY_CHART_ID]
				,null as [PATIENT_NAME]
				,null as [PATIENT_DISPOSITION]
				,null as [FACILITY_PATIENT_DISPOSITION]
				,null as [CODE]
				,null as [UNITS]
				,null as [CHARGE]
				,null as [MEDICAL_RECORD_NUM]
				,null as [SERVICE_MODEL_CD]
				,null as [Coder]
				,null as [DEPT_ID]
				,null as [DEPT]

		end;
		else if @m_Details = 0
		begin

			select
				'ALL' as AllData
				,null as FACILITY_ID
				,null as NAME
				,null as abbrev_name
				,null as DOS
				,null as DOS_Year
				,null as DOS_Month
				,null as Approved_Date
				,null as Sent_Date
				,null as Sent_Date_Year
				,null as Sent_Date_Month
				,null as [CHART_ID]
				,null as FACILITY_CHART_ID
				,null as PATIENT_NAME
				,null as PATIENT_DISPOSITION
				,null as FACILITY_PATIENT_DISPOSITION
				,null as CODE
				,null as UNITS
				,null as CHARGE
				,null as MEDICAL_RECORD_NUM
				,null as SERVICE_MODEL_CD
				,null as Coder
				,null as DEPT_ID
				,null as DEPT

		end

	end
	else

begin

	----------------------------------------------------------------------------------------------------------------------------------
	-- 	Step 0 - Authorized Facilities

if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;

		SELECT *
	INTO #AuthorizedFacilities
	FROM (
	    SELECT DISTINCT fua.FACILITY_ID
		FROM FACILITY_USER_AUTHORIZATION fua,
		USER_PROFILE up,
		SERVICE_AGREEMENT sa
		WHERE 
		fua.user_profile_id = up.user_profile_id
		and fua.facility_id = sa.facility_id 
		and up.IS_ACTIVE = 'Y'						
		and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
		and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
		and sa.DEMO_TEST_SITE_IND = 0
		and fua.USER_PROFILE_ID = @m_ReportUser
		and    SA.COMPANY_ID in (SELECT * FROM SPLITSTRING(@m_Organization, ','))				
		and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_Facility, ','))
			   OR @IncludeAllFacilities = 1) 
		) 
		af;


	-- 	Step 1
	if object_id('TempDB..#chart1', 'U') is not null drop table #chart1;
	if object_id('TempDB..#chart2', 'U') is not null drop table #chart2;



	select
		 sp.chart_id
		,sp.cpt_code
		,sp.billing_code
		,sp.quantity
		,sp.charge_master_id
	into #chart1
	from
		SENT_PROCEDURE sp
		left join CHARGE_MASTER cm on sp.charge_master_id = cm.CHARGE_MASTER_ID
	where
		sp.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
		and
		(
			(
				@m_CodeType = 0
				and
				(
					sp.cpt_code in (SELECT * FROM SPLITSTRING(@m_Code, ','))
					OR @IncludeAllCodes = 1
				)
			)
			or
			(
				@m_CodeType = 1
				and
				(
					sp.billing_code in (SELECT * FROM SPLITSTRING(@m_Code, ','))
					OR @IncludeAllCodes = 1
				)
			)
			or
			(
				@m_CodeType = 2
				and
				(
					cm.ALIAS_BILLING_CODE in (SELECT * FROM SPLITSTRING(@m_Code, ','))
					OR @IncludeAllCodes = 1
				)
			)
		)
		and exists
	(
		select
			*
		from
			CHART c
		where
			c.CHART_ID = sp.chart_id
			and c.FACILITY_ID in ( select FACILITY_ID from #AuthorizedFacilities)
			and
			(
				(
					@m_DateType = 0
					and c.TIME_OF_SERVICE between @m_StartDate and dateadd(second, 86399, @m_EndDate)
				)
				or
				(
					@m_DateType = 1
					and c.APPROVED_DATE between @m_StartDate and dateadd(second, 86399, @m_EndDate)
				)
				or
				(
					@m_DateType = 2
					and c.SENT_DATE between @m_StartDate and dateadd(second, 86399, @m_EndDate)
				)
			)
	);


-- select * from #chart1



	alter table #chart1
	add
		 facility_id int
		,TIME_OF_SERVICE datetime
		,approved_date datetime
		,sent_date datetime
		,FACILITY_CHART_ID varchar(20)
		,PATIENT_LAST_NAME varchar(35)
		,PATIENT_FIRST_NAME varchar(25)
		,PATIENT_DISPOSITION_ID int
		,PATIENT_DISPOSITION_MAP_ID int
		,COMPLETED_BY_USER_PROFILE_ID int
		,MEDICAL_RECORD_NUM varchar(20)
		,SERVICE_AGREEMENT_ID int
		,SERVICE_MODEL_CD varchar(5)
		,CLINIC_ID		  varchar(10)
		,CLINIC		      varchar(100);

	update t
	set
		t.facility_id = c.FACILITY_ID
		,t.TIME_OF_SERVICE = c.TIME_OF_SERVICE
		,t.approved_date = c.APPROVED_DATE
		,t.sent_date = c.SENT_DATE
		,t.FACILITY_CHART_ID = c.FACILITY_CHART_ID
		,t.PATIENT_LAST_NAME = substring(c.patient_last_name, 1, 35)
		,t.PATIENT_FIRST_NAME = substring(c.patient_first_name, 1, 25)
		,t.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
		,t.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID
		,t.COMPLETED_BY_USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
		,t.MEDICAL_RECORD_NUM = c.medical_record_num
		,t.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		,t.CLINIC_ID            = c.clinic_id
		
	from
		#chart1 as t
		join CHART as c on t.chart_id = c.CHART_ID;


-- select * from #chart1

	update t
	set
		t.SERVICE_MODEL_CD = sa.SERVICE_MODEL_CD
	from
		#chart1 as t
		join SERVICE_AGREEMENT as sa on t.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID;

    update t
	set
		t.Clinic = sac.description
	from
		#chart1 as t
		join SERVICE_AGREEMENT_CLINIC as sac on t.SERVICE_AGREEMENT_ID = sac.SERVICE_AGREEMENT_ID
											 and t.clinic_id = sac.clinic_id;


	-- Step 2 
	select
		c.FACILITY_ID
		,f.NAME
		,case when f.ABBREVIATED_NAME <> '' then f.ABBREVIATED_NAME else f.NAME end as abbrev_name
		,convert(date, c.TIME_OF_SERVICE)                                           DOS
		,convert(date, c.approved_date)                                             Approved_Date
		,convert(date, c.sent_date)                                                 Sent_Date
		,c.CHART_ID
		,c.FACILITY_CHART_ID
		,c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME                          as PATIENT_NAME
		,pd.[DESCRIPTION]                                                           [PATIENT_DISPOSITION]
		,pdm.[FACILITY_PATIENT_DISPOSITION]
		,case @m_CodeType
			 when 0 then c.cpt_code
			 when 1 then c.billing_code
		 else cmas.ALIAS_BILLING_CODE end                                           as CODE
		,sum(c.quantity)                                                            UNITS
		,sum(isnull(cm.CHARGE_AMOUNT, 0) * c.quantity)                              CHARGE
		,c.MEDICAL_RECORD_NUM
		,c.SERVICE_MODEL_CD
		,upper(up.LAST_NAME) + ', ' + upper(up.FIRST_NAME)                          as Coder
		,cmd2.DEPT_ID
		,cmd2.DEPT
		,c.Clinic
	into #chart2
	from
		#chart1 c
		left join PATIENT_DISPOSITION         pd on pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
		left join PATIENT_DISPOSITION_MAP     pdm on pdm.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID
		left join USER_PROFILE                up on up.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
		left join CHARGE_MASTER_CHARGE_AMOUNT cm on cm.CHARGE_MASTER_ID = c.charge_master_id
													and cast(c.TIME_OF_SERVICE as date) between cm.EFFECTIVE_DATE and coalesce(cm.EXPIRATION_DATE,'12/31/9999')
		left join CHARGE_MASTER               cmas on c.charge_master_id = cmas.CHARGE_MASTER_ID
		left join CHARGE_MASTER_DEPARTMENT    cmd on cmas.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
	outer apply
	(
		select top 1
			cmd2.CHARGE_MASTER_DEPT_ID [DEPT_ID]
			,cmd2.[NAME]               [DEPT]
		from
			CHARGE_MASTER_DEPARTMENT cmd2
		where
			cmd2.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
	)                           cmd2
	left join FACILITY f on f.FACILITY_ID = c.FACILITY_ID
	where
		(
			@IncludeAllDepartments = 1
			or cmd.CHARGE_MASTER_DEPT_ID in (SELECT * FROM SPLITSTRING(@m_Department, ','))
			                                
		)
		and
		(
			@IncludeAllDispositions = 1
			or
			pd.PATIENT_DISPOSITION_ID in (SELECT * FROM SPLITSTRING(@m_Disposition, ','))
		)
		and  ( c.Clinic_ID in (SELECT * FROM SPLITSTRING(@m_Clinic, ','))
			   OR @IncludeAllClinics = 1) 
	group by
		c.FACILITY_ID
		,f.NAME
		,case when f.ABBREVIATED_NAME <> '' then f.ABBREVIATED_NAME else f.NAME end
		,convert(date, c.TIME_OF_SERVICE)
		,convert(date, approved_date)
		,convert(date, sent_date)
		,c.CHART_ID
		,c.FACILITY_CHART_ID
		,c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME
		,pd.[DESCRIPTION]
		,pdm.[FACILITY_PATIENT_DISPOSITION]
		,case @m_CodeType
			 when 0 then c.cpt_code
			 when 1 then c.billing_code
		 else cmas.ALIAS_BILLING_CODE end
		,c.MEDICAL_RECORD_NUM
		,c.SERVICE_MODEL_CD
		,upper(up.LAST_NAME) + ', ' + upper(up.FIRST_NAME)
		,cmd2.DEPT_ID
		,cmd2.DEPT
		,c.Clinic;


-- select * from #chart2
-- select * from  #chart_cnt

if object_id('TempDB..#chart_cnt', 'U') is not null drop table #chart_cnt;

create table #Chart_cnt
(			
	  
	  FACILITY_ID			int	
	, CLINIC				varchar(100)
	, PATIENT_DISPOSITION	varchar(50)
	, DEPT_ID				int
	, Count1				int
);	


INSERT INTO #chart_cnt
 select 
 facility_id, 
 isnull(clinic, '-1') as clinic,
 isnull(patient_disposition, '-99') as patient_disposition,
 dept_id, 
 cast(count(distinct(chart_id)) as int) as Count1 
 from #chart2 
 group by facility_id, clinic, patient_disposition, dept_id;



	-- Step 3
/*
	if @Details = 1
	begin
		
		select
			'ALL' as AllData
			,t1.FACILITY_ID
			,t1.NAME
			,t1.abbrev_name
			,cast(t1.DOS as date) DOS
			,year(t1.DOS) DOS_Year
			,left(datename(month,t1.DOS),3) DOS_Month
			,t1.Approved_Date
			,t1.Sent_Date
			,year(t1.Sent_Date) Sent_Date_Year
			,left(datename(month,t1.Sent_Date),3) Sent_Date_Month
			,t1.CHART_ID
			,t1.FACILITY_CHART_ID
			,t1.PATIENT_NAME
			,t1.PATIENT_DISPOSITION
			,t1.FACILITY_PATIENT_DISPOSITION
			,t1.CODE
			,t1.UNITS
			,t1.CHARGE
			,t1.MEDICAL_RECORD_NUM
			,t1.SERVICE_MODEL_CD
			,t1.Coder
			,t1.DEPT_ID
			,t1.DEPT
			,t1.Clinic
			,0 as ChartCount
		from
			#chart2 t1
		where
			exists
		(
			select
				*
			from
				FACILITY_USER_AUTHORIZATION FUA
				,USER_PROFILE UP
			where
				FUA.FACILITY_ID = t1.FACILITY_ID
				and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID
				and UP.IS_ACTIVE = 'Y'
				and getdate() between FUA.EFFECTIVE_DATE and FUA.EXPIRATION_DATE
				and FUA.USER_PROFILE_ID = @m_ReportUser
		)
			and t1.UNITS <> 0

			

		union all

		select 
			'ALL' as AllData
			,c.FACILITY_ID
			,c.[NAME]
			,c.abbrev_name
			,cast(cplos.DATE_OF_SERVICE as date) DATE_OF_SERVICE
			,year(cplos.DATE_OF_SERVICE)
			,left(datename(month,cplos.DATE_OF_SERVICE),3)
			,c.Approved_Date
			,c.Sent_Date
			,year(c.Sent_Date) Sent_Date_Year
			,left(datename(month,c.Sent_Date),3) Sent_Date_Month
			,cplos.CHART_ID
			,c.FACILITY_CHART_ID
			,c.PATIENT_NAME
			,null
			,null
			,case @CodeType
				 when 0 then psp.cpt_code
				 when 1 then psp.billing_code
			 else null end as [CODE]
			,1			
			,isnull(cm.CHARGE_AMOUNT, 0)
			,c.MEDICAL_RECORD_NUM
			,c.SERVICE_MODEL_CD
			,c.Coder
			,c.DEPT_ID
			,c.DEPT
			,c.Clinic
			,0 as ChartCount
		from
			#chart2 c
			inner join dbo.CHART_PHYSICIAN_LEVEL_OF_SERVICE cplos on c.chart_id = cplos.CHART_ID
			inner join dbo.PHYSICIAN_SERVICE_PROCEDURE psp
				on case when cplos.PHYSICIAN_SERVICE_PROC_ID = -1 then cplos.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID else cplos.PHYSICIAN_SERVICE_PROC_ID end = psp.PHYSICIAN_SERVICE_PROC_ID
			outer apply
				(	select cm.charge_master_id, cmca.CHARGE_AMOUNT
					from 
						charge_master cm 
						left join dbo.CHARGE_MASTER_CHARGE_AMOUNT cmca on cm.CHARGE_MASTER_ID = cmca.CHARGE_MASTER_ID
					where 
						cm.BILLING_CODE = psp.BILLING_CODE  
						and cm.CPT_CODE = psp.CPT_CODE
						and cm.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
						and cm.CHARGE_MASTER_USAGE_CODE = 4
						and cm.EFFECTIVE_DATE <= getdate()
						and cm.EXPIRATION_DATE >= getdate()
						and (cm.PATIENT_CLASS_ID = psp.PATIENT_CLASS_ID or cm.patient_class_id = -1)
				) cm
		where
			exists
		(
			select
				*
			from
				FACILITY_USER_AUTHORIZATION FUA
				,USER_PROFILE UP
			where
				FUA.FACILITY_ID = c.FACILITY_ID
				and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID
				and UP.IS_ACTIVE = 'Y'
				and getdate() between FUA.EFFECTIVE_DATE and FUA.EXPIRATION_DATE
				and FUA.USER_PROFILE_ID = @m_ReportUser
		)
			and c.UNITS <> 0
		
			
		order by DOS, CODE


	end;
	else if @Details = 0 -- Summary
	begin
*/
		select
			'ALL'                                                                                 as AllData
			,t1.FACILITY_ID
			,t1.NAME
			,t1.abbrev_name
			,concat(datepart(YYYY, t1.DOS), '-', right('00' + cast(datepart(month, t1.DOS) as varchar(2)),2), '-01')                     as DOS
			,year(concat(datepart(YYYY, t1.DOS), '-', right('00' + cast(datepart(month, t1.DOS) as varchar(2)),2), '-01')) DOS_Year
			,left(datename(month,concat(datepart(YYYY, t1.DOS), '-', right('00' + cast(datepart(month, t1.DOS) as varchar(2)),2), '-01')),3) DOS_Month
			,concat(datepart(YYYY, t1.Approved_Date), '-', right('00' + cast(datepart(mm, t1.Approved_Date) as varchar(2)),2), '-01') as Approved_Date
			,concat(datepart(YYYY, t1.Sent_Date), '-', right('00' + cast(datepart(mm, t1.Sent_Date) as varchar(2)),2), '-01')         as Sent_Date
			,year(concat(datepart(YYYY, t1.Sent_Date), '-', right('00' + cast(datepart(mm, t1.Sent_Date) as varchar(2)),2), '-01')) Sent_Date_Year
			,left(datename(month,concat(datepart(YYYY, t1.Sent_Date), '-', right('00' + cast(datepart(mm, t1.Sent_Date) as varchar(2)),2), '-01')),3) Sent_Date_Month
			,null																				  as [CHART_ID]
			,null                                                                                 as FACILITY_CHART_ID
			,null                                                                                 as PATIENT_NAME
			,t1.PATIENT_DISPOSITION			                                                      as PATIENT_DISPOSITION
			,null																				  as FACILITY_PATIENT_DISPOSITION
			,t1.CODE
			,sum(t1.UNITS)                                                                        as UNITS
			,sum(t1.CHARGE)                                                                       as CHARGE
			,null                                                                                 as MEDICAL_RECORD_NUM
			,null                                                                                 as SERVICE_MODEL_CD
			,null                                                                                 as Coder
			,null                                                                                 as DEPT_ID
			,t1.DEPT                                                                              as DEPT
			,t1.Clinic
			,(select (Count1) from #chart_cnt where facility_id = t1.facility_id 
			                                  and clinic = isnull(t1.clinic, '-1') 
			                                  and PATIENT_DISPOSITION = isnull(t1.PATIENT_DISPOSITION, '-99') 
											  and dept_id = t1.dept_id) as ChartCount
		from
			#chart2 t1
		where
			exists
		(
			select
				*
			from
				FACILITY_USER_AUTHORIZATION FUA
				,USER_PROFILE UP
			where
				FUA.FACILITY_ID = t1.FACILITY_ID
				and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID
				and UP.IS_ACTIVE = 'Y'
				and getdate() between FUA.EFFECTIVE_DATE and FUA.EXPIRATION_DATE
				and FUA.USER_PROFILE_ID = @m_ReportUser
		)
			and t1.UNITS <> 0
		group by
			 t1.FACILITY_ID
			,t1.NAME
			,t1.abbrev_name
			,concat(datepart(YYYY, t1.DOS), '-', right('00' + cast(datepart(month, t1.DOS) as varchar(2)),2), '-01')
			,concat(datepart(YYYY, t1.Approved_Date), '-', right('00' + cast(datepart(mm, t1.Approved_Date) as varchar(2)),2), '-01')
			,concat(datepart(YYYY, t1.Sent_Date), '-', right('00' + cast(datepart(mm, t1.Sent_Date) as varchar(2)),2), '-01')
			,t1.PATIENT_DISPOSITION						
			,t1.CODE
			,t1.DEPT
			,t1.dept_id
			,t1.Clinic
	
		order by
			concat(datepart(YYYY, t1.DOS), '-', right('00' + cast(datepart(month, t1.DOS) as varchar(2)),2), '-01')
			,t1.CODE;


end;

	--end;

		end;


GO
