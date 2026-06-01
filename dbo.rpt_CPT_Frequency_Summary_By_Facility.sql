SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[rpt_CPT_Frequency_Summary_By_Facility] 
  		 @CodeType         int            
		,@Code            varchar(max)  
		,@ReportUser      int           
		,@Facility        varchar(max)           
		,@StartDate       datetime      
		,@EndDate         datetime      
		,@Department      varchar(max) 
		,@DispositionType int           
		,@Disposition     varchar(max)  
		,@DateType        int           
		,@Details         int           
		,@Class           int           





AS
BEGIN




    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SET NOCOUNT ON;


declare @m_CodeType         int				= @CodeType;      
declare @m_Code            varchar(max)     = @Code;
declare @m_ReportUser      int				= @ReportUser;	      
declare	@m_Facility        varchar(max)     = @Facility;         
declare	@m_StartDate       datetime         = @StartDate;
declare	@m_EndDate         datetime         = @EndDate;
declare	@m_Department      varchar(max)     = @Department; 
declare	@m_DispositionType int              = @DispositionType;
declare	@m_Disposition     varchar(max)     = @Disposition;
declare	@m_DateType        int              = @DateType;
declare	@m_Details         int              = @Details;
declare	@m_Class           int				= @Class;





/*
-- test db parameters *****
	declare
		@CodeType         int           = 0    -- 0 CPT, 1 Billing
		,@Code            varchar(max)  = '---Bypass Filter---'
		,@ReportUser      int           = 80
		,@Facility        int           = 1376 
		,@StartDate       datetime      = '20191101'
		,@EndDate         datetime      = '20191105'
		,@Department      varchar(1000) = '-1'
		,@DispositionType int           = 1
		,@Disposition     varchar(max)  = '-99'
		,@DateType        int           = 0    -- 0 DOS, 1 Approved, 2 Sent
		,@Details         int           = 1   -- 0 Summary, 1 Details
		,@Class           int           = -1; -- -1 All, 1 Facility, 2 Profee

*/



	-- 	Step 1
	if object_id('TempDB..#chart1', 'U') is not null drop table #chart1;
	if object_id('TempDB..#chart2', 'U') is not null drop table #chart2;



	select
		sp.chart_id
		,sp.cpt_code
		,sp.billing_code
		,sp.quantity
		,sp.charge_master_id
		,sp.class
	into #chart1
	from
		SENT_PROCEDURE sp
		left join CHARGE_MASTER cm on sp.charge_master_id = cm.CHARGE_MASTER_ID
	where
		sp.facility_id in (SELECT * FROM SPLITSTRING(@m_Facility, ','))
		and
		(
			(
				@m_CodeType = 0
				and
				(
					sp.cpt_code in (SELECT * FROM SPLITSTRING(@m_Code, ','))
					or '---Bypass Filter---' in (SELECT * FROM SPLITSTRING(@m_Code, ','))
				)
			)
			or
			(
				@m_CodeType = 1
				and
				(
					sp.billing_code in (SELECT * FROM SPLITSTRING(@m_Code, ','))
					or '---Bypass Filter---' in (SELECT * FROM SPLITSTRING(@m_Code, ','))
				)
			)
			or
			(
				@m_CodeType = 2
				and
				(
					cm.ALIAS_BILLING_CODE in (SELECT * FROM SPLITSTRING(@m_Code, ','))
					or '---Bypass Filter---' in (SELECT * FROM SPLITSTRING(@m_Code, ','))
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
			
			and c.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_Facility, ','))
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
and (
	  -1 in (@m_Class) -- All
	or 1 in (@m_Class) and sp.class in ( 'CA','IP','FL','FP') -- Facility
	or 2 in (@m_Class) and sp.class in ( 'PL','PP')	-- Profee
	)

	);




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
		,SERVICE_MODEL_CD varchar(5);

	update t
	set
		t.facility_id = c.FACILITY_ID
		,t.TIME_OF_SERVICE = c.TIME_OF_SERVICE
		,t.approved_date = c.APPROVED_DATE
		,t.sent_date = c.SENT_DATE
		,t.FACILITY_CHART_ID = c.FACILITY_CHART_ID
		,t.PATIENT_LAST_NAME = c.patient_last_name
		,t.PATIENT_FIRST_NAME = c.patient_first_name
		,t.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
		,t.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID
		,t.COMPLETED_BY_USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
		,t.MEDICAL_RECORD_NUM = c.medical_record_num
		,t.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
	from
		#chart1 as t
		join CHART as c on t.chart_id = c.CHART_ID;


	update t
	set
		t.SERVICE_MODEL_CD = sa.SERVICE_MODEL_CD
	from
		#chart1 as t
		join SERVICE_AGREEMENT as sa on t.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID;




	-- Step 2 
	select
		c.FACILITY_ID
		,f.NAME
		,case when f.ABBREVIATED_NAME <> '' then f.ABBREVIATED_NAME else f.NAME end as abbrev_name
		,convert(date, c.TIME_OF_SERVICE)                                           DOS
		,convert(date, c.approved_date)                                             Approved_Date
		,convert(date, c.sent_date)                                                 Sent_Date
		,c.CHART_ID
		,case when c.class in ('PL', 'PP') then 'Profee' else 'Facility' end as Class
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
			'-1' in (SELECT * FROM SPLITSTRING(@m_Department, ','))	
			or cmd.CHARGE_MASTER_DEPT_ID in (SELECT * FROM SPLITSTRING(@m_Department, ','))	
		)
		and
		(
			'-99' in (SELECT * FROM SPLITSTRING(@m_Disposition, ','))
			or
			(
				@m_DispositionType = 1
				and pd.PATIENT_DISPOSITION_ID in (SELECT * FROM SPLITSTRING(@m_Disposition, ','))
			)
			or
			(
				@m_DispositionType = 2
				and pdm.PATIENT_DISPOSITION_MAP_ID in (SELECT * FROM SPLITSTRING(@m_Disposition, ','))
			)
		)
	group by
		c.FACILITY_ID
		,f.NAME
		,case when f.ABBREVIATED_NAME <> '' then f.ABBREVIATED_NAME else f.NAME end
		,convert(date, c.TIME_OF_SERVICE)
		,convert(date, approved_date)
		,convert(date, sent_date)
		,c.CHART_ID
		,c.class
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
		,cmd2.DEPT;



		if object_id('TempDB..#chart2_D', 'U') is not null drop table #chart2_D;

select distinct
             c.chart_id
            ,c.FACILITY_ID
			,c.[NAME]
			,c.abbrev_name	
			,c.Approved_Date
		    ,c.Sent_Date
			,c.FACILITY_CHART_ID
			,c.PATIENT_NAME			
			,c.MEDICAL_RECORD_NUM
			,c.SERVICE_MODEL_CD
			,c.Coder
			,c.DEPT_ID
			,c.DEPT			
into #chart2_D
from #chart2 c



-- *******************************************************************************************
-- Step 3

	if @m_Details = 1
	begin
		
		select
			'ALL' as AllData
			,t1.FACILITY_ID
			,t1.NAME
			,t1.abbrev_name
			,t1.DOS
			,t1.Approved_Date
			,t1.Sent_Date
			,t1.CHART_ID
			,t1.Class as CLASS
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
			,cplos.DATE_OF_SERVICE as DOS
			,c.Approved_Date
		    ,c.Sent_Date			
			,cplos.CHART_ID
			,'Profee' as CLASS
			,c.FACILITY_CHART_ID
			,c.PATIENT_NAME
			,null
			,null
			,case @m_CodeType
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
		from
			#chart2_D c
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
		
		
			
		order by DOS, CODE


	end;
	else if @m_Details = 0
	begin

		select
			'ALL'                                                                                 as AllData
			,t1.FACILITY_ID
			,t1.NAME
			,t1.abbrev_name
			,concat(datepart(YYYY, t1.DOS), '-', datepart(mm, t1.DOS), '-01')                     as DOS
			,concat(datepart(YYYY, t1.Approved_Date), '-', datepart(mm, t1.Approved_Date), '-01') as Approved_Date
			,concat(datepart(YYYY, t1.Sent_Date), '-', datepart(mm, t1.Sent_Date), '-01')         as Sent_Date
			,t1.class																			  as CLASS	
			,null                                                                                 as FACILITY_CHART_ID
			,null                                                                                 as PATIENT_NAME
			,null                                                                                 as PATIENT_DISPOSITION
			,null                                                                                 as FACILITY_PATIENT_DISPOSITION
			,t1.CODE
			,sum(t1.UNITS)                                                                        as UNITS
			,sum(t1.CHARGE)                                                                       as CHARGE
			,null                                                                                 as MEDICAL_RECORD_NUM
			,null                                                                                 as SERVICE_MODEL_CD
			,null                                                                                 as Coder
			,null                                                                                 as DEPT_ID
			,null                                                                                 as DEPT
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
			,concat(datepart(YYYY, t1.DOS), '-', datepart(mm, t1.DOS), '-01')
			,concat(datepart(YYYY, t1.Approved_Date), '-', datepart(mm, t1.Approved_Date), '-01')
			,concat(datepart(YYYY, t1.Sent_Date), '-', datepart(mm, t1.Sent_Date), '-01')
			,t1.class
			,t1.CODE


union all




		select distinct 
			 'ALL' -- as AllData
			,c.FACILITY_ID
			,c.[NAME]
			,c.abbrev_name
			,concat(datepart(YYYY, cplos.DATE_OF_SERVICE), '-', datepart(mm, cplos.DATE_OF_SERVICE), '-01') as DOS
			,concat(datepart(YYYY, c.Approved_Date), '-', datepart(mm, c.Approved_Date), '-01') as Approved_Date
			,concat(datepart(YYYY, c.Sent_Date), '-', datepart(mm, c.Sent_Date), '-01') as Sent_date 
			,'Profee' as CLASS
			,null --c.FACILITY_CHART_ID
			,null --c.PATIENT_NAME
			,null
			,null

			
			,case @CodeType
				 when 0 then psp.cpt_code
				 when 1 then psp.billing_code
			 else null end as [CODE]
			,sum(1) as Units	
			,isnull(cm.CHARGE_AMOUNT, 0)

			,null --c.MEDICAL_RECORD_NUM
			,null --c.SERVICE_MODEL_CD
			,null -- c.Coder
			,null -- c.DEPT_ID
			,null -- c.DEPT			
		from
			#chart2_d c
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
				and FUA.USER_PROFILE_ID = @ReportUser
		)

group by

			 c.FACILITY_ID
			,c.[NAME]
			,c.abbrev_name
			,concat(datepart(YYYY, cplos.DATE_OF_SERVICE), '-', datepart(mm, cplos.DATE_OF_SERVICE), '-01') -- as DOS
			,concat(datepart(YYYY, c.Approved_Date), '-', datepart(mm, c.Approved_Date), '-01') -- as Approved_Date
			,concat(datepart(YYYY, c.Sent_Date), '-', datepart(mm, c.Sent_Date), '-01') -- as Sent_date 
			
					
			,case @CodeType
				 when 0 then psp.cpt_code
				 when 1 then psp.billing_code
			 else null end -- as code
			
			,isnull(cm.CHARGE_AMOUNT, 0)



		order by
			concat(datepart(YYYY, t1.DOS), '-', datepart(mm, t1.DOS), '-01')
			,t1.CODE;


	end;


   END               

   







GO
GRANT EXECUTE ON  [dbo].[rpt_CPT_Frequency_Summary_By_Facility] TO [dbx_ExecuteReportProcs]
GO
