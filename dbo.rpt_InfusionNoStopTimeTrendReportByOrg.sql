SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Don Hutton
-- Create date: 02/07/2019
-- ACS-13441:	
--
-- Modified:
--			JHerrera | 07/27/2020 | Added DEPARTMENT to results
--			JHerrera | 01/08/2021 | AAR-581 | Add Facility parameter.
--			DHutton  | 12/15/2021 | AAR-1490 | Update CPT Codes used for charge amounts.
-- =============================================

CREATE PROCEDURE [dbo].[rpt_InfusionNoStopTimeTrendReportByOrg] 
    @DateType      int
    ,@StartDate    datetime
    ,@EndDate      datetime
    ,@Organization int
    ,@Facility     varchar(max)
    ,@ReportUser   int
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	set transaction isolation level read uncommitted	
	SET NOCOUNT ON;

	--declare 
	--	@DateType int = 0
	--	,@StartDate datetime = '20191201'
	--	,@EndDate datetime = '20191231'
	--	,@Organization int = '121'
	--	,@Facility int = 581

	DECLARE @m_DateType INT = @DateType;
	DECLARE @m_StartDate DATETIME = @StartDate;
	DECLARE @m_EndDate DATETIME = @EndDate;
	DECLARE @m_Organization INT = @Organization;
	declare @m_Facility varchar(max) = @Facility;
	
	if object_id('TempDB..#Charges', 'U') is not null DROP TABLE #Charges;

	select cm.cpt_Code, cm.service_agreement_ID, MaxChgAmt = max(ca.CHARGE_AMOUNT), 
		cm.Effective_Date, cm.Expiration_Date,
		EffDT_CM = isnull(cm.Effective_Date, '1/1/2000'), ExpDT_CM = isnull(cm.Expiration_Date, getdate()), 
		Effective_Date_CA = ca.Effective_Date, Expiration_Date_CA = ca.Expiration_Date,
		EffDT_CA = ca.EFFECTIVE_DATE, ExpDT_CA = isnull(ca.EXPIRATION_DATE, getdate())
		, cm.Charge_Master_Dept_ID 
		, cm.patient_class_ID 
	 INTO #Charges
	from
		CHARGE_MASTER cm with(nolock)
		join CHARGE_MASTER_CHARGE_AMOUNT ca with(nolock) on ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
	where CPT_CODE in ('96361', '96365', '96375', '96411', '96413', '96420', '96422' )
	group by cm.service_agreement_ID, cm.cpt_Code, 
		cm.Effective_Date, cm.Expiration_Date,
		isnull(cm.Effective_Date, '1/1/2000'), isnull(cm.Expiration_Date, getdate()), 
		ca.expiration_date,
		ca.EFFECTIVE_DATE, isnull(ca.EXPIRATION_DATE, getdate())
		, cm.Charge_Master_Dept_ID 
		, cm.patient_class_ID 
	order by cpt_Code, service_agreement_ID, EffDT_CM, ExpDT_CM, EffDT_CA, ExpDT_CA


	if object_id('TempDB..#Charts', 'U') is not null DROP TABLE #Charts;

	select 
		c.chart_ID, c.FACILITY_ID, c.SERVICE_AGREEMENT_ID, c.TIME_OF_SERVICE, c.chart_status_ID, 
		DOSMonth = CASE
			when @m_DateType = 0 then dateadd(month, datediff(month, 0, c.TIME_OF_SERVICE), 0)
			when @m_DateType = 1 then dateadd(month, datediff(month, 0, c.Sent_Date), 0)
		end,
		case when ci.NO_STOP_TIME = 1 then 1 else 0 end NoStop,
		it.APC_RATE,
		it.INFUSION_TYPE,
		charge_96361 = cast(null as decimal(7,2)), 
		charge_96365 = cast(null as decimal(7,2)), 
		charge_96375 = cast(null as decimal(7,2)), 
		charge_96411 = cast(null as decimal(7,2)), 
		charge_96413 = cast(null as decimal(7,2)),
		charge_96420 = cast(null as decimal(7,2)),
		charge_96422 = cast(null as decimal(7,2))
		, ci.Charge_Master_Dept_ID 
		, Patient_Class_ID = cast(null as int)	-- performs better if Patient_Class_ID is separately populated in subsequent step
	into #Charts
	from
		CHART c with(nolock)
		inner join CHART_INFUSION ci with(nolock) on ci.CHART_ID = c.CHART_ID
		inner join INFUSION_TYPE it with(nolock) on it.INFUSION_TYPE = ci.INFUSION_TYPE
		join service_agreement as sa with(nolock) on sa.service_agreement_ID = c.service_agreement_ID 
			and sa.company_ID = @m_Organization and (@m_Facility = '-99' or sa.FACILITY_ID in (select items from dbo.SplitString(@m_Facility,',')))
	where
		it.INJECTION = 0 
		and c.CHART_STATUS_ID = 5
		and (
				(@m_DateType = 0 and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between @m_StartDate and @m_EndDate)
				or
				(@m_DateType = 1 and dateadd(day, datediff(day, 0, c.SENT_DATE), 0) between @m_StartDate and @m_EndDate)
			)
		and exists
		(
			select
				*
			from
				FACILITY_USER_AUTHORIZATION FUA with (nolock)
				,USER_PROFILE UP with (nolock)
			where
				FUA.FACILITY_ID = sa.FACILITY_ID
				and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID
				and UP.IS_ACTIVE = 'Y'
				and getdate() between FUA.EFFECTIVE_DATE and FUA.EXPIRATION_DATE
				and FUA.USER_PROFILE_ID = @ReportUser
		)

	UPDATE t
	set t.Patient_Class_ID = c.patient_class_ID
	from #Charts as t
		join CHART as c with(nolock) on t.chart_ID = c.chart_ID

	update c
	set c.charge_96361 = cm.MaxChgAmt
	from #Charts as c
		join #Charges as cm on c.service_agreement_ID = cm.service_agreement_ID
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CM and cm.ExpDT_CM
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CA and cm.ExpDT_CA
			and cm.CPT_Code = '96361'
		and cm.CHARGE_MASTER_DEPT_ID = c.CHARGE_MASTER_DEPT_ID
		and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 

	update c
	set c.charge_96365 = cm.MaxChgAmt
	from #Charts as c
		join #Charges as cm on c.service_agreement_ID = cm.service_agreement_ID
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CM and cm.ExpDT_CM
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CA and cm.ExpDT_CA
			and cm.CPT_Code = '96365'
		and cm.CHARGE_MASTER_DEPT_ID = c.CHARGE_MASTER_DEPT_ID
		and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)

	update c
	set c.charge_96375 = cm.MaxChgAmt
	from #Charts as c
		join #Charges as cm on c.service_agreement_ID = cm.service_agreement_ID
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CM and cm.ExpDT_CM
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CA and cm.ExpDT_CA
			and cm.CPT_Code = '96375'
		and cm.CHARGE_MASTER_DEPT_ID = c.CHARGE_MASTER_DEPT_ID
		and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)

	update c
	set c.charge_96411 = cm.MaxChgAmt
	from #Charts as c
		join #Charges as cm on c.service_agreement_ID = cm.service_agreement_ID
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CM and cm.ExpDT_CM
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CA and cm.ExpDT_CA
			and cm.CPT_Code = '96411'
		and cm.CHARGE_MASTER_DEPT_ID = c.CHARGE_MASTER_DEPT_ID
		and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)

	update c
	set c.charge_96413 = cm.MaxChgAmt
	from #Charts as c
		join #Charges as cm on c.service_agreement_ID = cm.service_agreement_ID
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CM and cm.ExpDT_CM
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CA and cm.ExpDT_CA
			and cm.CPT_Code = '96413'
		and cm.CHARGE_MASTER_DEPT_ID = c.CHARGE_MASTER_DEPT_ID
		and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)

    update c
	set c.charge_96420 = cm.MaxChgAmt
	from #Charts as c
		join #Charges as cm on c.service_agreement_ID = cm.service_agreement_ID
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CM and cm.ExpDT_CM
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CA and cm.ExpDT_CA
			and cm.CPT_Code = '96420'
		and cm.CHARGE_MASTER_DEPT_ID = c.CHARGE_MASTER_DEPT_ID
		and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)

    update c
	set c.charge_96422 = cm.MaxChgAmt
	from #Charts as c
		join #Charges as cm on c.service_agreement_ID = cm.service_agreement_ID
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CM and cm.ExpDT_CM
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cm.EffDT_CA and cm.ExpDT_CA
			and cm.CPT_Code = '96422'
		and cm.CHARGE_MASTER_DEPT_ID = c.CHARGE_MASTER_DEPT_ID
		and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)

	;with REG1
	as
	(select
		 f.FACILITY_ID
		 ,f.NAME
		 ,sa.FACILITY_TYPE_CD
		 ,f.STATE
		 ,r.DESCRIPTION as REGION
	 from
		 FACILITY f
		 ,SERVICE_AGREEMENT sa
		 ,REGION r
	 where
		 f.FACILITY_ID = sa.FACILITY_ID and sa.COMPANY_ID = 29 and f.REGION_ID = r.REGION_ID
	)

	select
		y.COMPANY_ID
		,y.FACILITY_NAME
		,y.ABBREVIATED_NAME
		,y.FACILITY_TYPE
		,y.SERVICE_MODEL
		,REG1.REGION
		,y.DOSMonth as PERIOD
		,sum(y.Total) as TOTAL1
		,sum(y.NoStop) as NO_STOP
		,sum(y.NoStop) / (sum(y.Total) * 1.0) ErrorRate
		,sum(y.APC_AMOUNT) as APC_Total
		,sum(y.Facility_Rate) Facility_Rate
		,y.DEPARTMENT

-- drop table DBA..InfusionNoStop_Tuned
-- INTO DBA..InfusionNoStop_Tuned

	from
		REG1
		right join
			(
			select
				sa.COMPANY_ID
				,x.FACILITY_ID
				,f.NAME as FACILITY_NAME
				,f.ABBREVIATED_NAME
				,case
					 when FACILITY_TYPE_CD = 1 then 'ED'
					 when FACILITY_TYPE_CD = 2 then 'Clinic' end as FACILITY_TYPE
				,case
					 when SERVICE_MODEL_CD = 'ASP' then 'SaaS'
					 when SERVICE_MODEL_CD = 'SVC' then 'FS' end as SERVICE_MODEL
				,x.DOSMonth
				,sum(x.NoStop) NoStop
				,count(*) Total
				,x.APC_RATE
				,(count(*) * x.APC_RATE) as APC_AMOUNT
				,sum(case
						when x.INFUSION_TYPE = 6 then abs(x.charge_96375 - charge_96365)
						when x.INFUSION_TYPE = 7 then charge_96361
						when x.INFUSION_TYPE = 9 then abs(x.charge_96413 - x.charge_96411)
						when x.INFUSION_TYPE = 11 then abs(x.charge_96422 - x.charge_96420)
					else 0 end
					) as Facility_Rate
				,x.DEPARTMENT
			from
				FACILITY f 
				join SERVICE_AGREEMENT sa on sa.FACILITY_ID = f.FACILITY_ID
				join
					(
					select
						c.FACILITY_ID
						,c.SERVICE_AGREEMENT_ID
						,c.CHART_ID
						,c.DOSMonth
						, c.NoStop
						, c.APC_Rate
						, c.Infusion_Type
						, c.charge_96361
						, c.charge_96365
						, c.charge_96375
						, c.charge_96411
						, c.charge_96413
						, c.charge_96420
						, c.charge_96422
						,cmd.[NAME] [DEPARTMENT]
					from
						#Charts as c 
						left join CHARGE_MASTER_DEPARTMENT cmd on c.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID and c.SERVICE_AGREEMENT_ID = cmd.SERVICE_AGREEMENT_ID
					) x on x.FACILITY_ID = f.FACILITY_ID
			where
				sa.COMPANY_ID = @m_Organization and (@m_Facility = '-99' or sa.FACILITY_ID in (select items from dbo.SplitString(@m_Facility,',')))
			group by
				sa.COMPANY_ID
				,x.FACILITY_ID
				,f.NAME
				,f.ABBREVIATED_NAME
				,case
					 when FACILITY_TYPE_CD = 1 then 'ED'
					 when FACILITY_TYPE_CD = 2 then 'Clinic' end
				,case
					 when SERVICE_MODEL_CD = 'ASP' then 'SaaS'
					 when SERVICE_MODEL_CD = 'SVC' then 'FS' end
				,x.DOSMonth
				,x.APC_RATE
				,x.DEPARTMENT
			) y on REG1.FACILITY_ID = y.FACILITY_ID
	group by
		y.COMPANY_ID
		,y.FACILITY_NAME
		,y.ABBREVIATED_NAME
		,y.FACILITY_TYPE
		,y.SERVICE_MODEL
		,REG1.REGION
		,y.DOSMonth
		,y.DEPARTMENT
	order by
		y.FACILITY_NAME
		--, period	-- added by dsexton for testing
	
  OPTION (RECOMPILE);

END


GO
GRANT EXECUTE ON  [dbo].[rpt_InfusionNoStopTimeTrendReportByOrg] TO [dbx_ExecuteReportProcs]
GO
