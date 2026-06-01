SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE procedure [dbo].[rpt_Jackson_County_Memorial_Hospital_Expanse_Charge_Posting]
(
	 @ReportUser int
	,@Facility   varchar(max)
	,@DateType  int          
	,@StartDate datetime 
	,@EndDate   datetime 
	,@StartTime int 
	,@EndTime	int
	,@ExcludeCodes int 
)

as

begin



-- test parameters	 (dsexton, 5/22/2019)
	--declare
	--     @ReportUser int	  = 80	
	--	,@Facility   varchar(max) = 1643 -- Jackson County Memorial Hospital Expanse
	--	,@DateType  int          = 2		-- 1=Approved, 2=Sent
	--	,@StartDate datetime = '20230822'
	--	,@EndDate   datetime = '20230822'
	--    ,@StartTime int = 0
	--    ,@EndTime int = 23
	--	,@ExcludeCodes int		 = 1;       --  0=No, 1=Yes
		






    set transaction isolation level read uncommitted;
    set nocount on;
	set ansi_warnings off;	

	declare
	@m_ReportUser           int          = @ReportUser
   ,@m_Facility             varchar(max) = @Facility  
   ,@m_DateType             int          = @DateType
--   ,@m_StartDate            datetime     = @StartDate
--   ,@m_EndDate              datetime     = @EndDate
   ,@m_StartDateTime datetime = dateadd(hour, @StartTime, @StartDate)
   ,@m_EndDateTime datetime = dateadd(hour, @EndTime, dateadd(minute, 59, dateadd(second, 59, @EndDate)));   



----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

-- Part 1 - Create #SentProcedure table


	if object_id('TempDB..#NewlySentCharts', 'U') is not null DROP TABLE #NewlySentCharts;	
	



	select distinct ln.chart_ID into #NewlySentCharts  
	from log_note ln,
	chart c
	where 
	ln.chart_id = c.chart_id 
	and ln.category_ID = 4 
-- 	and ln.COMPLETION_DATE BETWEEN @m_StartDate AND DateAdd(second, 86399, @m_EndDate)
	and ln.COMPLETION_DATE BETWEEN @m_StartDateTime AND @m_EndDateTime
	and c.facility_id in (SELECT * FROM SPLITSTRING(@m_Facility, ','));
	                                               




----------------------------------------------------------------------------------------------------------


-- #TempFPE (Facility_Procedure_Evaluation)	
	-- tuning 10/25/2017: reads = 580K vs 4.8M; CPU = 50s vs. 59s; duration sec = 31/4 (cold/warm) vs. 374/9  (cold/warm)

    if object_id('TempDB..#TempFPE', 'U') is not null DROP TABLE #TempFPE;		
	select 
		c.chart_ID,
		fpe.FACILITY_PROCEDURE_ID, fpe.procedure_date, fpe.quantity
	 INTO #TempFPE	
	from facility_procedure_evaluation as fpe with(NOLOCK) 
		join #NewlySentCharts as c on fpe.chart_ID = c.chart_ID


	alter table #TempFPE		-- added 10/25/2017
	add 
	facility_chart_ID varchar(20),
	service_agreement_ID int,
	saEffDT datetime,
	time_of_service datetime,
	sent_date datetime,
	patient_disposition_ID int, 
	physician_ID int,
	facility_ID int,
	patient_class_ID int,
	facility_admin_chart_ID varchar(20)

	update t		-- added 10/25/2017
	set 
	t.facility_chart_ID = c.facility_chart_ID,
	t.service_agreement_ID = c.service_agreement_ID,
	t.time_of_service = c.time_of_service,
	t.sent_date = c.sent_date,
	t.patient_disposition_ID = c.patient_disposition_ID, 
	t.physician_ID = c.physician_ID,
	t.facility_ID = c.facility_ID,
	t.patient_class_ID = c.patient_class_ID,
	t.facility_admin_chart_ID = c.facility_admin_chart_ID
	from #TempFPE as t
		join Chart as c with(nolock, index(1)) on t.chart_ID = c.chart_ID

	update t		-- added 10/25/2017
	set t.saEffDT = sa.EFFECTIVE_DATE
	from #TempFPE as t
		join service_agreement as sa with(nolock) on t.service_agreement_ID = sa.service_agreement_ID


	delete from #TempFPE		-- added 10/25/2017		
	where isnull(time_of_service, '1/1/1900') < saEffDT


----------------------------------------------------------------------------------------------------------


-- #TempOER (Chart_Observation_Encounter_Result)
	-- (2016) Using this preprocessed table greatly improves performance (500K vs 21M reads)
    if object_id('TempDB..#TempOER', 'U') is not null DROP TABLE #TempOER;
	select 
		c.chart_ID,
		oer.CHART_OBSERVATION_ENCOUNTER_RESULT_ID, /*oer.chart_ID,*/ oer.CHARGE_MASTER_ID, oer.Units, oer.DATE_OF_SERVICE
	 INTO #TempOER	
	from CHART_OBSERVATION_ENCOUNTER_RESULT as oer with(NOLOCK) 
		join #NewlySentCharts as c on oer.chart_ID = c.chart_ID
	

	alter table #TempOER		-- added 10/25/2017
	add 
	facility_chart_ID varchar(20),
	service_agreement_ID int,
	saEffDT datetime,
	time_of_service datetime,
	sent_date datetime,
	patient_disposition_ID int, 
	physician_ID int,
	facility_ID int,
	patient_class_ID int,
	facility_admin_chart_ID varchar(20),
	evaluate_observation_departments bit

	update t		-- added 10/25/2017
	set 
		t.facility_chart_ID = c.facility_chart_ID,
		t.service_agreement_ID = c.service_agreement_ID,
		t.time_of_service = c.time_of_service,
		t.sent_date = c.sent_date,
		t.patient_disposition_ID = c.patient_disposition_ID, 
		t.physician_ID = c.physician_ID,
		t.facility_ID = c.facility_ID,
		t.patient_class_ID = c.patient_class_ID,
		t.facility_admin_chart_ID = c.facility_admin_chart_ID
	from #TempOER as t
		join Chart as c with(nolock, index(1)) on t.chart_ID = c.chart_ID
	
	update t
	set 
		t.saEffDT = sa.EFFECTIVE_DATE,
		t.evaluate_observation_departments = sa.evaluate_observation_departments
	from #TempOER as t
		join service_agreement as sa with(nolock) on t.service_agreement_ID = sa.service_agreement_ID

	
	delete from #TempOER		-- added 10/25/2017		
	where isnull(time_of_service, '1/1/1900') < saEffDT


----------------------------------------------------------------------------------------------------------




-- #TempCIR (Chart_Infusion_Result)
	-- (2016) Using this preprocessed table reduces LReads by about 50%, but duration is reduced much more (90 sec vs 6 min)
	-- tuning 10/25/2017: reads = 646K vs 5.1M; CPU = 145s vs. 453s; duration sec = 30/24 vs. 134/130 (cold/warm)
    if object_id('TempDB..#TempCIR', 'U') is not null DROP TABLE #TempCIR;		
	select 
		c.chart_ID,
		cir.chart_infusion_result_ID
	 INTO #TempCIR	
	from chart_infusion_result as cir with(NOLOCK) 
		join #NewlySentCharts as c on cir.chart_ID = c.chart_ID
	



	alter table #TempCIR		-- added 10/25/2017
	add 
	facility_chart_ID varchar(20),
	service_agreement_ID int,
	saEffDT datetime,
	time_of_service datetime,
	sent_date datetime,
	patient_disposition_ID int, 
	physician_ID int,
	facility_ID int,
	patient_class_ID int,
	facility_admin_chart_ID varchar(20),
	charge_master_ID int,
	Units int,
	date_of_service datetime,
	[mod] varchar(2)

	update t		-- added 10/25/2017
	set 
		t.facility_chart_ID = c.facility_chart_ID,
		t.service_agreement_ID = c.service_agreement_ID,
		t.time_of_service = c.time_of_service,
		t.sent_date = c.sent_date,
		t.patient_disposition_ID = c.patient_disposition_ID, 
		t.physician_ID = c.physician_ID,
		t.facility_ID = c.facility_ID,
		t.patient_class_ID = c.patient_class_ID,
		t.facility_admin_chart_ID = c.facility_admin_chart_ID
	from #TempCIR as t
		join Chart as c with(nolock, index(1)) on t.chart_ID = c.chart_ID
	
	update t
	set t.saEffDT = sa.EFFECTIVE_DATE
	from #TempCIR as t
		join service_agreement as sa with(nolock) on t.service_agreement_ID = sa.service_agreement_ID

	update t		-- added 10/25/2017
	set 
		t.charge_master_ID = cir.charge_master_ID,
		t.units = cir.Units,
		t.date_of_service = cir.date_of_service,
		t.[mod] = left(cir.modifiers, 2)
	from #TempCIR as t
		join chart_infusion_result as cir with(nolock) on t.chart_infusion_result_ID = cir.chart_infusion_result_ID

	-- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
		-- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
	delete from #TempCIR		-- added 10/25/2017		
	where isnull(time_of_service, '1/1/1900') < saEffDT


----------------------------------------------------------------------------------------------------------



-- #TempC (CHART, filtered on Facility_Level_ID and Override_Facility_Level_ID)
	-- (2016) Using this preprocessed table reduces logical reads to 1.4M vs 508M.  Duration = 1 min vs. 28 mins.
	-- tuning 10/25/2017: reads = 931K vs 4.8M; CPU = 173s vs. 201s; duration sec = 48/14 vs. 34/24 (cold/warm)
    if object_id('TempDB..#TempC', 'U') is not null DROP TABLE #TempC;
	select c.chart_ID
	 INTO #TempC	
	from 
		chart as c with(NOLOCK, index(1))
		join #NewlySentCharts as c2 on c2.chart_ID = c.chart_ID
	where 
			(
				c.OVERRIDE_FACILITY_LEVEL_ID <> -1		-- this uses another NC index on CHART (idx_Chart_sa_completiondate) when the index hint is not used
				or  
				c.FACILITY_LEVEL_ID <> -1
				)
	

	alter table #TempC		-- added 10/25/2017
	add 
	facility_chart_ID varchar(20),
	service_agreement_ID int,
	time_of_service datetime,
	sent_date datetime,
	patient_disposition_ID int, 
	physician_ID int,
	facility_ID int,
	patient_class_ID int,
	facility_admin_chart_ID varchar(20),
	facility_level_ID int,
	override_facility_level_ID int

	update t		-- added 10/25/2017
	set 
		t.facility_chart_ID = c.facility_chart_ID,
		t.service_agreement_ID = c.service_agreement_ID,
		t.time_of_service = c.time_of_service,
		t.sent_date = c.sent_date,
		t.patient_disposition_ID = c.patient_disposition_ID, 
		t.physician_ID = c.physician_ID,
		t.facility_ID = c.facility_ID,
		t.patient_class_ID = c.patient_class_ID,
		t.facility_admin_chart_ID = c.facility_admin_chart_ID,
		t.facility_level_ID = c.facility_level_ID,
		t.override_facility_level_ID = c.override_facility_level_ID
	from #TempC as t
		join Chart as c with(nolock, index(1)) on t.chart_ID = c.chart_ID

----------------------------------------------------------------------------------------------------------

-- #TempC2 (CHART, filtered on Physician_Service_Proc_ID and Override_Physician_Service_Proc_ID)
	-- (2016) Using this preprocessed table reduces logical reads to 1.3M vs 254M.  Duration = 1 min vs. 13 mins.
	-- tuning 10/18/2017: reads = 1.1M vs 4.7M; CPU = 92s vs. 112s; duration sec = 68/8 vs. 32/10 (cold/warm)
    if object_id('TempDB..#TempC2', 'U') is not null DROP TABLE #TempC2;
	select c.chart_ID
	 INTO #TempC2	
	from chart as c with(NOLOCK, index(1))  
		join #NewlySentCharts as c2 on c2.chart_ID = c.chart_ID
	where 
		-- earlier version had note that the criteria below was changed per John on 03/14/2013 (LDH).  Used to be:  and (c.NO_PHYSICIAN_SERVICES is null or c.NO_PHYSICIAN_SERVICES = 0)
		(c.PHYSICIAN_SERVICE_PROC_ID <> -1 or c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1)		-- when the index hint is not used, this criteria causes the usage of another NC index on CHART (_dta_index_CHART_5_1907537879__K2_K165_K49_K88_K55_K23_K1_K3_K57_4_17_48_51_52_54_64_153_214)

		

	alter table #TempC2		-- added 10/25/2017
	add 
	facility_chart_ID varchar(20),
	service_agreement_ID int,
	time_of_service datetime,
	sent_date datetime,
	patient_disposition_ID int, 
	physician_ID int,
	facility_ID int,
	patient_class_ID int,
	facility_admin_chart_ID varchar(20),
	physician_service_proc_ID int,
	override_physician_service_proc_ID int
		
	update t		-- added 10/25/2017
	set 
		t.facility_chart_ID = c.facility_chart_ID,
		t.service_agreement_ID = c.service_agreement_ID,
		t.time_of_service = c.time_of_service,
		t.sent_date = c.sent_date,
		t.patient_disposition_ID = c.patient_disposition_ID, 
		t.physician_ID = c.physician_ID,
		t.facility_ID = c.facility_ID,
		t.patient_class_ID = c.patient_class_ID,
		t.facility_admin_chart_ID = c.facility_admin_chart_ID,
		t.physician_service_proc_ID = c.physician_service_proc_ID,
		t.override_physician_service_proc_ID = c.override_physician_service_proc_ID
	from #TempC2 as t
		join Chart as c with(nolock, index(1)) on t.chart_ID = c.chart_ID

----------------------------------------------------------------------------------------------------------


-- #TempPPE (Physician_Procedure_Evaluation)
	-- tuning 10/25/2017 with #TempPPE vs. without: reads = 533K vs 51M/28M (warm/cold); CPU = 31s vs. 64s; duration sec = 3/2 vs. 414/35 (cold/warm)
    if object_id('TempDB..#TempPPE', 'U') is not null DROP TABLE #TempPPE;		-- added new section 10/25/2017 (was not previously using temp table for PPE)
	select 
		c.chart_ID,
		ppe.PHYSICIAN_PROCEDURE_ID, ppe.procedure_date, ppe.quantity, PhysicianID_PPE = ppe.physician_ID
	INTO #TempPPE	
	from physician_procedure_evaluation as ppe with(NOLOCK) 
		join #NewlySentCharts as c on ppe.chart_ID = c.chart_ID
	

	alter table #TempPPE
	add 
	facility_chart_ID varchar(20),
	service_agreement_ID int,
	saEffDT datetime,
	time_of_service datetime,
	sent_date datetime,
	patient_disposition_ID int, 
	physician_ID int,
	facility_ID int,
	patient_class_ID int,
	facility_admin_chart_ID varchar(20)

	update t
	set 
	t.facility_chart_ID = c.facility_chart_ID,
	t.service_agreement_ID = c.service_agreement_ID,
	t.time_of_service = c.time_of_service,
	t.sent_date = c.sent_date,
	t.patient_disposition_ID = c.patient_disposition_ID, 
	t.physician_ID = c.physician_ID,
	t.facility_ID = c.facility_ID,
	t.patient_class_ID = c.patient_class_ID,
	t.facility_admin_chart_ID = c.facility_admin_chart_ID
	from #TempPPE as t
		join Chart as c with(nolock, index(1)) on t.chart_ID = c.chart_ID

	update t
	set t.saEffDT = sa.EFFECTIVE_DATE
	from #TempPPE as t
		join service_agreement as sa with(nolock) on t.service_agreement_ID = sa.service_agreement_ID

	
	delete from #TempPPE	
	where isnull(time_of_service, '1/1/1900') < saEffDT

----------------------------------------------------------------------------------------------------------

-- #TempCPI (Chart_Package_Item)
	-- tuning 10/25/2017 with #TempCPI vs. without:
	if object_id('TempDB..#TempCPI', 'U') is not null DROP TABLE #TempCPI;		-- added new section 10/25/2017 (was not previously using temp table for CPI)
	select 
			c.CHART_ID,
			cpi.CHART_PACKAGE_ITEM_ID, cpi.UNITS, cpi.CHARGE_PACKAGE_ITEM_ID
	 INTO #TempCPI
	from   CHART_PACKAGE_ITEM cpi with (NOLOCK)
		join #NewlySentCharts as c on cpi.chart_ID = c.chart_ID
	

	alter table #TempCPI
	add 
	facility_chart_ID varchar(20),
	service_agreement_ID int,
	saEffDT datetime,
	time_of_service datetime,
	sent_date datetime,
	patient_disposition_ID int, 
	physician_ID int,
	facility_ID int,
	patient_class_ID int,
	facility_admin_chart_ID varchar(20)

	update t
	set 
	t.facility_chart_ID = c.facility_chart_ID,
	t.service_agreement_ID = c.service_agreement_ID,
	t.time_of_service = c.time_of_service,
	t.sent_date = c.sent_date,
	t.patient_disposition_ID = c.patient_disposition_ID, 
	t.physician_ID = c.physician_ID,
	t.facility_ID = c.facility_ID,
	t.patient_class_ID = c.patient_class_ID,
	t.facility_admin_chart_ID = c.facility_admin_chart_ID
	from #TempCPI as t
		join Chart as c with(nolock, index(1)) on t.chart_ID = c.chart_ID

	update t
	set t.saEffDT = sa.EFFECTIVE_DATE
	from #TempCPI as t
		join service_agreement as sa with(nolock) on t.service_agreement_ID = sa.service_agreement_ID

	-- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
		-- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
	delete from #TempCPI	
	where isnull(time_of_service, '1/1/1900') < saEffDT


----------------------------------------------------------------------------------------------------------



-- #TempCAP (Chart_Additional_Procedure)
	-- tuning 10/25/2017 with #TempCAP vs. without:
	if object_id('TempDB..#TempCAP', 'U') is not null DROP TABLE #TempCAP;		-- added new section 10/25/2017 (was not previously using temp table for CAP)
	select 
			c.CHART_ID,
			cap.Chart_Additional_Procedure_ID, cap.procedure_date, cap.Quantity, cap.Charge_master_ID, cap.class
	 INTO #TempCAP
	from CHART_ADDITIONAL_PROCEDURE as cap with (NOLOCK)
		join #NewlySentCharts as c on cap.chart_ID = c.chart_ID
	

	alter table #TempCAP
	add 
	facility_chart_ID varchar(20),
	service_agreement_ID int,
	saEffDT datetime,
	time_of_service datetime,
	sent_date datetime,
	patient_disposition_ID int, 
	physician_ID int,
	facility_ID int,
	patient_class_ID int,
	facility_admin_chart_ID varchar(20)

	update t
	set 
	t.facility_chart_ID = c.facility_chart_ID,
	t.service_agreement_ID = c.service_agreement_ID,
	t.time_of_service = c.time_of_service,
	t.sent_date = c.sent_date,
	t.patient_disposition_ID = c.patient_disposition_ID, 
	t.physician_ID = c.physician_ID,
	t.facility_ID = c.facility_ID,
	t.patient_class_ID = c.patient_class_ID,
	t.facility_admin_chart_ID = c.facility_admin_chart_ID
	from #TempCAP as t
		join Chart as c with(nolock, index(1)) on t.chart_ID = c.chart_ID

	update t
	set t.saEffDT = sa.EFFECTIVE_DATE
	from #TempCAP as t
		join service_agreement as sa with(nolock) on t.service_agreement_ID = sa.service_agreement_ID

	-- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
		-- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
	delete from #TempCAP		
	where isnull(time_of_service, '1/1/1900') < saEffDT


--------------------------------------

-- now run separate INSERT queries into #SentProcedure, all of which will refer to preprocessed tables populated above.
	-- Separating the INSERTs performs better than UNIONs in this case, and also makes it easier to analzye the performance of each step

	-- first create a temp table to gather preliminary results
    if object_id('TempDB..#SentProcedure', 'U') is not null DROP TABLE #SentProcedure;

	select CLASS, CHART_ID, FACILITY_CHART_ID, SERVICE_AGREEMENT_ID, TIME_OF_SERVICE, SENT_DATE, PATIENT_DISPOSITION_ID, 
	PHYSICIAN_ID, BILLING_CODE, CPT_CODE, QUANTITY, FACILITY_ID, PATIENT_CLASS_ID, ADJUSTMENT_IND, CHARGE_MASTER_ID, LEVEL_ID, 
	FACILITY_ADMIN_CHART_ID, SOURCE_ID, SOURCE_CD
	into #SentProcedure
	from RevCycleTransactionSnapshot..Sent_Procedure
	where 1 = 0


	INSERT INTO #SentProcedure
	select 'FP' as CLASS, 
			c.CHART_ID,
			c.FACILITY_CHART_ID,
			c.SERVICE_AGREEMENT_ID,
			coalesce(c.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
			c.SENT_DATE,
			c.PATIENT_DISPOSITION_ID,
			case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						end as PHYSICIAN_ID,
			ISNULL(NULLIF(cm.ALIAS_BILLING_CODE,''),cm.BILLING_CODE) BILLING_CODE,
			cm.CPT_CODE,
			c.QUANTITY,
			c.facility_id,
			case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
			'N' as ADJUSTMENT_IND,
			cm.CHARGE_MASTER_ID,
			0 as LEVEL_ID,
			c.FACILITY_ADMIN_CHART_ID,
			c.FACILITY_PROCEDURE_ID as source_id,
			'FP' as source_cd
	from #TempFPE as c
		join charge_master as cm with (NOLOCK) on cm.CHARGE_MASTER_ID = c.FACILITY_PROCEDURE_ID


	
	-- this INSERT was not using a preprocessed table, but now it does (#TempCPI) 10/25/2017
	INSERT INTO #SentProcedure
	select 'FP' as CLASS,   -- Package Items (e.g. generated supplies)
			c.CHART_ID,
			c.FACILITY_CHART_ID,
			c.SERVICE_AGREEMENT_ID,
			c.TIME_OF_SERVICE,
			c.SENT_DATE,
			c.PATIENT_DISPOSITION_ID,
			case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						end as PHYSICIAN_ID,
			ISNULL(NULLIF(cm.ALIAS_BILLING_CODE,''),cm.BILLING_CODE) BILLING_CODE,
			cm.CPT_CODE,
			c.UNITS Quantity,
			c.facility_id,
			case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
			'N' as ADJUSTMENT_IND,
			cm.CHARGE_MASTER_ID,
			0 as LEVEL_ID,
			c.FACILITY_ADMIN_CHART_ID,
			c.CHART_PACKAGE_ITEM_ID source_id,
			'PI' as source_cd
	from #TempCPI as c
		join CHARGE_PACKAGE_ITEM as ci with(nolock) on c.charge_package_item_ID = ci.charge_package_item_ID
		join CHARGE_MASTER as cm with(nolock) on cm.charge_master_ID = ci.charge_master_ID



	-- this INSERT was not efficiently using the preprocessed table, but now it does.
	INSERT INTO #SentProcedure
	select 'FP' as CLASS, 
			c.CHART_ID,
			c.FACILITY_CHART_ID,
			c.SERVICE_AGREEMENT_ID,
			coalesce(c.[DATE_OF_SERVICE], c.TIME_OF_SERVICE) TIME_OF_SERVICE,
			c.SENT_DATE,
			c.PATIENT_DISPOSITION_ID,
			case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						end as PHYSICIAN_ID,
			ISNULL(NULLIF(cm.ALIAS_BILLING_CODE,''),cm.BILLING_CODE) BILLING_CODE,
			cm.CPT_CODE,
			c.[UNITS],
			c.facility_id,
			case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
			'N' as ADJUSTMENT_IND,
			cm.CHARGE_MASTER_ID,
			0 as LEVEL_ID,
			c.FACILITY_ADMIN_CHART_ID,
			c.[CHART_OBSERVATION_ENCOUNTER_RESULT_ID] as source_id,
			'OP' as source_cd
	from #TempOER as c 	
		join charge_master as cm with (NOLOCK) on c.charge_master_id = cm.charge_master_id	
	where  
		c.PATIENT_DISPOSITION_ID = 5 -- Observation
		and c.EVALUATE_OBSERVATION_DEPARTMENTS = 1



	INSERT INTO #SentProcedure
	select 'IP' as CLASS, 
			c.CHART_ID,
			c.FACILITY_CHART_ID,
			c.SERVICE_AGREEMENT_ID,
			coalesce(c.DATE_OF_SERVICE,c.TIME_OF_SERVICE) TIME_OF_SERVICE,
			c.SENT_DATE,
			c.PATIENT_DISPOSITION_ID,
			case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						end as PHYSICIAN_ID,
			case when c.mod = '' then isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE)
            else isnull((select cmod.BILLING_CODE
                  from charge_master_modifier cmod with (NOLOCK)
                  where cmod.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
                  and cmod.SERVICE_AGREEMENT_ID = c.service_agreement_ID
                  and cmod.MODIFIER = c.mod
                  and len(cmod.BILLING_CODE) > 0), isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE))
                  end as BILLING_CODE,
			cm.CPT_CODE,
			c.UNITS Quantity,
			c.facility_id,
			case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK) 
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
			'N' as ADJUSTMENT_IND,
			cm.CHARGE_MASTER_ID,
			0 as LEVEL_ID,
			c.FACILITY_ADMIN_CHART_ID,
			c.CHART_INFUSION_RESULT_ID as source_id,
			'IP' as source_cd
	from #TempCIR as c
		join charge_master as cm with (NOLOCK) on cm.CHARGE_MASTER_ID = c.CHARGE_MASTER_ID



	-- this INSERT wasn't using a preprocessed table, but needed to badly (55M reads).  Now it does.  10/25/2017
	INSERT INTO #SentProcedure	
	select 'PP' as Class, 
			c.CHART_ID,
			c.FACILITY_CHART_ID,
			c.SERVICE_AGREEMENT_ID,
			coalesce(c.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,	
			c.SENT_DATE,
			c.PATIENT_DISPOSITION_ID,
			case when (c.PhysicianID_PPE = -1 or c.PhysicianID_PPE is null) then c.PHYSICIAN_ID
						else c.PhysicianID_PPE
					end as PHYSICIAN_ID,
			cm.BILLING_CODE,
			cm.CPT_CODE,
			c.QUANTITY,
			c.facility_id,
			case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK) 
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
			'N' as ADJUSTMENT_IND,
			cm.CHARGE_MASTER_ID,
			0 as LEVEL_ID,
			c.FACILITY_ADMIN_CHART_ID,
			c.PHYSICIAN_PROCEDURE_ID source_id,
			'PP' as source_cd
	from #TempPPE as c
		join charge_master as cm with (NOLOCK) on cm.CHARGE_MASTER_ID = c.PHYSICIAN_PROCEDURE_ID



	-- (2016) This next query was the most expensive step before tuning.
	INSERT INTO #SentProcedure
	select 'FL' as Class,
			c.CHART_ID,
			c.FACILITY_CHART_ID,
			c.SERVICE_AGREEMENT_ID,
			c.TIME_OF_SERVICE,
			c.SENT_DATE,
			patient_disposition_id = isNull(c.patient_disposition_ID, 1),		-- (2016) logic for populating patient_disposition_id has been moved to an UPDATE statement right after this INSERT (performs much better)
			case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						end as PHYSCISIAN_ID,
			fl.BILLING_CODE,
			fl.CPT_CODE,
			1 as QUANTITY,
			c.facility_id,
			case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
				(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
					where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
					and pc.DEFAULT_IND = 1) end as patient_class_id,  
			'N' as ADJUSTMENT_IND,
			coalesce((select max(cm.charge_master_id) 
						from charge_master cm with (nolock) 
						where 
						cm.BILLING_CODE = fl.BILLING_CODE  
						AND    cm.CPT_CODE = fl.CPT_CODE
						AND    cm.SERVICE_AGREEMENT_ID = fl.SERVICE_AGREEMENT_ID
						AND    cm.CHARGE_MASTER_USAGE_CODE = 2
						and    cm.EFFECTIVE_DATE <= getdate()
						and    cm.EXPIRATION_DATE >= getdate()
						and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID or cm.patient_class_id = -1)),null) as charge_master_id, 
		   (case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 then c.FACILITY_LEVEL_ID
				when c.OVERRIDE_FACILITY_LEVEL_ID = '' then c.FACILITY_LEVEL_ID
				else c.OVERRIDE_FACILITY_LEVEL_ID end) LEVEL_ID,
			c.FACILITY_ADMIN_CHART_ID,
			c.CHART_ID as source_id,
			'FL' as source_cd
	from #TempC as c, facility_level fl with (NOLOCK)
	where  
		(case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 then c.FACILITY_LEVEL_ID
				when c.OVERRIDE_FACILITY_LEVEL_ID = '' then c.FACILITY_LEVEL_ID
				else c.OVERRIDE_FACILITY_LEVEL_ID
				end) = fl.FACILITY_LEVEL_ID



	-- (2016) moved the logic here for populating patient_disposition_ID due to significant performance benefit
	update #SentProcedure
	set patient_disposition_ID = 4
	where 
		patient_disposition_ID in (-1, 0)
		and source_cd = 'FL'
		and 
		(
            chart_ID in
                (
                        select fse.chart_ID
                        from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE fs
                        where  fse.chart_ID = #SentProcedure.chart_ID
                                AND fse.FACILITY_SERVICE_ID IS NOT NULL 
                                AND fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID
                                and (left(fs.DESCRIPTION,9) = 'Admission' or left(fs.DESCRIPTION,5) = 'Admit')
                )
            or chart_ID in
                (
                        select fse.chart_ID
                        from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE_SCHEDULE_ITEM fssi
                        where  fse.chart_ID = #SentProcedure.chart_ID
                                AND fse.FACILITY_SERVICE_SCHEDULE_ID = fssi.FACILITY_SERVICE_SCHEDULE_ID 
                                AND fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fssi.FACILITY_SERVICE_SCHEDULE_ITEM_ID
                        and (left(fssi.DESCRIPTION,9) = 'Admission' or left(fssi.DESCRIPTION,5) = 'Admit' or left(fssi.DESCRIPTION,12) = 'Direct Admit')
                )
		)

 
	 -- (2016) clean up any remaining records where patient_disposition_ID in (-1, 0)
	update #SentProcedure
	set patient_disposition_ID = 1
	where patient_Disposition_ID in (-1, 0)
		and source_cd = 'FL'



	INSERT INTO #SentProcedure
	select  'PL' as Class,
		c.CHART_ID, 
		c.FACILITY_CHART_ID, 
		c.SERVICE_AGREEMENT_ID,
		c.TIME_OF_SERVICE,
		c.SENT_DATE,
		patient_disposition_id = isNull(c.patient_disposition_ID, 1),		-- (2016) logic for populating patient_disposition_id has been moved to an UPDATE statement right after this INSERT (performs much better)
		case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID end as PHYSICIAN_ID,
		(select psp.BILLING_CODE from physician_service_procedure psp with (NOLOCK)
		where psp.PHYSICIAN_SERVICE_PROC_ID = 
				(case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
					and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
					then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
					else c.PHYSICIAN_SERVICE_PROC_ID end)
		) as BILLING_CD,
		(select psp.CPT_CODE 
			from physician_service_procedure psp with (NOLOCK)
			where psp.PHYSICIAN_SERVICE_PROC_ID = 
				(case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
						and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
					then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
					else c.PHYSICIAN_SERVICE_PROC_ID end)
			) as CPT_CD,
		1 as Quantity,
		c.facility_id,
		case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
				(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK) 
					where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
					and pc.DEFAULT_IND = 1) end as patient_class_id,
		'N' as ADJUSTMENT_IND,
		coalesce((select max(cm.charge_master_id) 
					from charge_master cm with (nolock) 
					where 
					cm.BILLING_CODE = psp.BILLING_CODE  
					AND    cm.CPT_CODE = psp.CPT_CODE
					AND    cm.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
					AND    cm.CHARGE_MASTER_USAGE_CODE = 4
					and    cm.EFFECTIVE_DATE <= getdate()
					and    cm.EXPIRATION_DATE >= getdate()
					and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID or cm.patient_class_id = -1)),null) 
				as charge_master_id, 

		(select psp.PHYSICIAN_SERVICE_PROC_ID 
			from physician_service_procedure psp with (NOLOCK)
			where  psp.PHYSICIAN_SERVICE_PROC_ID = 
						(case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
								and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
								then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
								else c.PHYSICIAN_SERVICE_PROC_ID end)
					) as LEVEL_ID,
		c.FACILITY_ADMIN_CHART_ID,
		c.CHART_ID as source_id,
		'PL' as source_cd
	from #TempC2 as c, service_agreement sa with (NOLOCK), physician_service_procedure as psp with (NOLOCK)
	where       
		sa.service_agreement_id = c.service_agreement_id
		and sa.evaluate_physician_svc = 1
		and c.TIME_OF_SERVICE >= sa.EFFECTIVE_DATE
		and
			(case 
				when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
					and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
				then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
				else c.PHYSICIAN_SERVICE_PROC_ID end
			) = psp.PHYSICIAN_SERVICE_PROC_ID



	-- (2016) moved the logic here for populating patient_disposition_ID due to significant performance benefit
	update #SentProcedure
	set patient_disposition_ID = 4
	where 
		patient_disposition_ID in (-1, 0)
		and source_cd = 'PL'
		and 
		(
            chart_ID in
                (
                        select fse.chart_ID
                        from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE fs
                        where  fse.chart_ID = #SentProcedure.chart_ID
                                AND fse.FACILITY_SERVICE_ID IS NOT NULL 
                                AND fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID
                                and (left(fs.DESCRIPTION,9) = 'Admission' or left(fs.DESCRIPTION,5) = 'Admit')
                )
            or chart_ID in
                (
                        select fse.chart_ID
                        from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE_SCHEDULE_ITEM fssi
                        where  fse.chart_ID = #SentProcedure.chart_ID
                                AND fse.FACILITY_SERVICE_SCHEDULE_ID = fssi.FACILITY_SERVICE_SCHEDULE_ID 
                                AND fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fssi.FACILITY_SERVICE_SCHEDULE_ITEM_ID
                        and (left(fssi.DESCRIPTION,9) = 'Admission' or left(fssi.DESCRIPTION,5) = 'Admit' or left(fssi.DESCRIPTION,12) = 'Direct Admit')
                )
		)


	-- (2016) clean up any remaining records where patient_disposition_ID in (-1, 0)
	update #SentProcedure
	set patient_disposition_ID = 1
	where patient_Disposition_ID in (-1, 0)
		and source_cd = 'PL'



	-- this INSERT was not using a preprocessed table, but now it does (#TempCAP) 10/25/2017
	-- ACS-7351: CHART_ADDITIONAL_PROCEDURE
	INSERT INTO #SentProcedure
	select c.CLASS, 
			c.CHART_ID,
			c.FACILITY_CHART_ID,
			c.SERVICE_AGREEMENT_ID,
			coalesce(c.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
			c.SENT_DATE,
			c.PATIENT_DISPOSITION_ID,
			case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						end as PHYSICIAN_ID,
			ISNULL(NULLIF(cm.ALIAS_BILLING_CODE,''),cm.BILLING_CODE) BILLING_CODE,
			cm.CPT_CODE,
			c.QUANTITY,
			c.facility_id,
			case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
			'N' as ADJUSTMENT_IND,
			cm.CHARGE_MASTER_ID,
			0 as LEVEL_ID,
			c.FACILITY_ADMIN_CHART_ID,
			c.CHART_ADDITIONAL_PROCEDURE_ID as source_id,
			'AP' as source_cd
	from #TempCAP as c
		join CHARGE_MASTER as cm with(nolock) on c.charge_master_ID = cm.charge_master_ID




----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------


-- Part 2 - Charge Posting Report

	if object_id('TempDB..#chart1', 'U') is not null drop table #chart1;
	if object_id('TempDB..#sent_procedure1', 'U') is not null drop table #sent_procedure1;
	if object_id('TempDB..#Details1', 'U') is not null drop table #Details1;
	if object_id('TempDB..#Temp_Details1', 'U') is not null drop table #Temp_Details1;

--	declare @StartDateTime datetime = dateadd(hour, @StartTime, @StartDate);
--	declare @EndDateTime datetime = dateadd(hour, @EndTime, dateadd(minute, 59, dateadd(second, 59, @EndDate)));

-----------------------------------------------------------------------------

select
		SENT_DATE
		,CHART_ID
		,FACILITY_CHART_ID                             as Patient_ID
		,MEDICAL_RECORD_NUM                            as MRN
		,PATIENT_LAST_NAME + ', ' + PATIENT_FIRST_NAME as Patient_Name
		,TIME_OF_SERVICE                               as DOS
		,TIME_OF_DIS
		,FACILITY_ID
		,PATIENT_DISPOSITION_ID
		--(select Description from [dbo].[PATIENT_DISPOSITION] where PATIENT_DISPOSITION_ID = chart.PATIENT_DISPOSITION_ID) as ED_DISPOSITION,

		-- AAR-930 replace ACS disposition with Facility disposition
		,PATIENT_DISPOSITION_MAP_ID
		,(
			 select
				 -- DESCRIPTION
				 DESCRIPTION + ' (' + FACILITY_PATIENT_DISPOSITION +') '
			 from
				 [dbo].[PATIENT_DISPOSITION_MAP]
			 where
				 PATIENT_DISPOSITION_MAP_ID = CHART.PATIENT_DISPOSITION_MAP_ID
		 )                                             as ED_DISPOSITION
        ,PATIENT_DISPOSITION_DESTINATION_ID
		,(select DESCRIPTION from PATIENT_DISPOSITION_DESTINATION where 
		       PATIENT_DISPOSITION_DESTINATION_ID = CHART.PATIENT_DISPOSITION_DESTINATION_ID) as PATIENT_DESTINATION
		,PHYSICIAN_ID
		,NURSE_PRACTITIONER_ID
		,PROVIDER_EVAL_PERFORMED_BY_IND
		,case
			 when NURSE_PRACTITIONER_ID > 0
				  and
				  (
					  PROVIDER_EVAL_PERFORMED_BY_IND is null
					  or PROVIDER_EVAL_PERFORMED_BY_IND = 1
				  ) then NURSE_PRACTITIONER_ID
		 else PHYSICIAN_ID end                         as EVAL_PROVIDER
		,PHYSICIAN_SERVICE_MOD
		,case
			 when OVERRIDE_FACILITY_LEVEL_ID = -1 then FACILITY_LEVEL_ID
			 when OVERRIDE_FACILITY_LEVEL_ID = '' then FACILITY_LEVEL_ID
		 else OVERRIDE_FACILITY_LEVEL_ID end           FL_LEVEL_ID
		,CHART.SERVICE_AGREEMENT_ADMIT_TYPE_ID
		,saat.[DESCRIPTION] [ADMIT_TYPE]
		,CODER_COMMENT
		,DEPARTMENT
		,OBSERVATION_ATTENDING_PROVIDER_ID
	into
		#chart1
	from
		CHART
		left join dbo.SERVICE_AGREEMENT_ADMIT_TYPE saat on CHART.SERVICE_AGREEMENT_ID = saat.SERVICE_AGREEMENT_ID
															and CHART.SERVICE_AGREEMENT_ADMIT_TYPE_ID = saat.SERVICE_AGREEMENT_ADMIT_TYPE_ID
	where	
 	CHART.SERVICE_AGREEMENT_ID = 1459 -- Jackson County Memorial Hospital Expanse  ONLY ********************
	
	
        and 				   
				   ( 
				    (FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_Facility, ','))) 
				    OR (-1 in (SELECT * FROM SPLITSTRING(@m_Facility, ','))) 
					)	
				   
		and ((@m_DateType = 1 
				and (APPROVED_DATE between @m_StartDateTime and @m_EndDateTime))
				or
			 (@m_DateType = 2
				and (CHART_STATUS_ID = 5 and SENT_DATE between @m_StartDateTime and @m_EndDateTime))
			)



	-- Step 2  -- Sent Procedure Lookup

	

	select
		c.*
		,sp.class
		,sp.billing_code
		,sp.cpt_code
		,sp.quantity
		,sp.PHYSICIAN_ID          as sp_physician_id
		,sp.charge_master_id
		,sp.level_id
		,sp.time_of_service       as Perform_DOS
		,case
			 when sp.PHYSICIAN_ID is null then c.EVAL_PROVIDER
		 else sp.PHYSICIAN_ID end as Perform_Provider
	into
		#sent_procedure1
	from
		 #sentprocedure sp
		,#chart1 c
	where
		sp.CHART_ID = c.CHART_ID
		and class in ('PL', 'IP', 'FL');


--------------------------------------------------------------------------------

create table #Details1
	(
		chart_ID             int
		,Patient_ID          varchar(20)
		,MRN                 varchar(20)
		,Patient_Name        varchar(60)
		,DOS                 datetime
		,TIME_OF_DIS         datetime
		,sent_date           datetime
		,billing_code        varchar(20)
		,cpt_code            varchar(5)
		,CPT_Description     varchar(100)
		,quantity            int
		,facility_id         int
		,ED_DISPOSITION      varchar(75)
		,PATIENT_DESTINATION varchar(200)
		,modifiers           varchar(20)
		,provider_id         int
		,Provider            varchar(60)
		,perform_provider_id int
		,Perform_Provider    varchar(60)
		,Perform_DOS         datetime
		,icd_10_code         varchar(200)
		,PROCESS_ORDER       int
		,POSTING_ORDER       int
		,Code_Type           varchar(50)
		,Department			 varchar(50)
		,OBS_ATT_PROVIDER_ID int
		,OBS_ATT_PROVIDER	 varchar(60)
	);





	-- Insert Diagnosis Records ***

	if object_id('TempDB..#TempDetails1', 'U') is not null
		drop table #TempDetails1;

	select
		c.CHART_ID
		,c.Patient_ID
		,c.MRN
		,c.Patient_Name
		,c.DOS
		,c.TIME_OF_DIS
		,c.SENT_DATE
		,''              billing_code
		,''              cpt_code
		,''              CPT_Description
		,''              as quantity
		,c.FACILITY_ID
		,c.ED_DISPOSITION
		,c.PATIENT_DESTINATION
		,''              as modifiers
		,c.EVAL_PROVIDER as provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.EVAL_PROVIDER
		 )               as Provider
		,''              as perform_provider_id
		,''              as Perform_Provider
		,''              as Perform_DOS
		,icd10.ICD10_CODE
		,1               as Process_Order
		,icd10.DIAGNOSIS_TYPE_ID
		,icd10.IS_PRIMARY
		,icd10.POSTING_ORDER
		,case
			 when icd10.DIAGNOSIS_TYPE_ID = 1
				  and icd10.IS_PRIMARY = 1 then 'Chief Complaint '
			 when icd10.DIAGNOSIS_TYPE_ID = 1
				  and icd10.IS_PRIMARY = 0 then 'Secondary Complaint '
			 when icd10.DIAGNOSIS_TYPE_ID = 2
				  and icd10.IS_PRIMARY = 1 then 'Primary Dx '
			 when icd10.DIAGNOSIS_TYPE_ID = 2
				  and icd10.IS_PRIMARY = 0 then 'Secondary Dx '
			 when icd10.DIAGNOSIS_TYPE_ID = 3
				  and icd10.IS_PRIMARY = 1 then 'Chief Complaint and Primary Dx '
			 when icd10.DIAGNOSIS_TYPE_ID = 3
				  and icd10.IS_PRIMARY = 0 then 'Complaint and Secondary Dx'
			 when icd10.DIAGNOSIS_TYPE_ID = 5 then 'Chief Complaint and Secondary Dx'
		 else '' end     as Code_Type
		,c.OBSERVATION_ATTENDING_PROVIDER_ID
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.OBSERVATION_ATTENDING_PROVIDER_ID
		 )               as OBS_ATT_PROVIDER
	into
		#TempDetails1
	from
		#chart1 c
		,CHART_DIAGNOSIS_CODE_ICD10 icd10
	where
		c.CHART_ID = icd10.CHART_ID;



/*

AAR-1902  'Chief Complaint 'needs to be included for Tenet

	delete from
	#TempDetails1
	where
		(
			DIAGNOSIS_TYPE_ID = 1
			and IS_PRIMARY = 1
		);

*/


-- AAR-2032 DAH 07/13/22
IF @ExcludeCodes = 1 -- Removes Unspecified External Cause Codes ******* 
BEGIN	


delete from
	#TempDetails1
	where ICD10_CODE in ( 'Y92.9', 'Y93.9', 'Y99.9')
	;

END;


	insert into #Details1
	select
		t.CHART_ID
		,t.Patient_ID
		,t.MRN
		,t.Patient_Name
		,t.DOS
		,t.TIME_OF_DIS
		,t.SENT_DATE
		,t.billing_code
		,t.cpt_code
		,t.CPT_Description
		,t.quantity
		,t.FACILITY_ID
		,t.ED_DISPOSITION
		,t.PATIENT_DESTINATION
		,t.modifiers
		,t.provider_id
		,t.Provider
		,t.perform_provider_id
		,t.Perform_Provider
		,t.Perform_DOS
		,t.ICD10_CODE
		,t.Process_Order
		,t.POSTING_ORDER
		,t.Code_Type
		,null
		,t.OBSERVATION_ATTENDING_PROVIDER_ID
		,t.OBS_ATT_PROVIDER
	from
		#TempDetails1 t;


	-- insert PL data  

	insert into #Details1
	select
		sp.CHART_ID
		,sp.Patient_ID
		,sp.MRN
		,sp.Patient_Name
		,sp.DOS
		,sp.TIME_OF_DIS
		,sp.SENT_DATE
		,sp.BILLING_CODE
		,sp.CPT_CODE
		,cm.[DESCRIPTION]         as CPT_Description
		,sp.quantity
		,sp.FACILITY_ID
		,sp.ED_DISPOSITION
		,sp.PATIENT_DESTINATION
		,sp.PHYSICIAN_SERVICE_MOD as modifiers
		,sp.EVAL_PROVIDER         as provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = sp.EVAL_PROVIDER
		 )                        as Provider
		,sp.sp_physician_id       as perform_provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = sp.sp_physician_id
		 )                        as Perform_Provider
		,sp.Perform_DOS
		,''                       as [ICD10_Code]
		,2                        as PROCESS_ORDER
		,0                        as Posting_order
		,'P'                      as Code_Type
		,cmd.[NAME]				  as [DEPARTMENT]
		,sp.OBSERVATION_ATTENDING_PROVIDER_ID
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = sp.OBSERVATION_ATTENDING_PROVIDER_ID
		 )               as OBS_ATT_PROVIDER
	from
		#sent_procedure1 sp
	inner join
	CHARGE_MASTER        cm on sp.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
	left join dbo.CHARGE_MASTER_DEPARTMENT cmd on cm.SERVICE_AGREEMENT_ID = cmd.SERVICE_AGREEMENT_ID
														and cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
	where
		sp.class = 'PL';


	-- Insert Physician Procedure Data

	insert into #Details1
	select
		c.CHART_ID
		,c.Patient_ID
		,c.MRN
		,c.Patient_Name
		,c.DOS
		,c.TIME_OF_DIS
		,c.SENT_DATE
		,cm.BILLING_CODE
		,cm.CPT_CODE
		,cm.[DESCRIPTION]   as CPT_Description
		,ppe.QUANTITY
		,c.FACILITY_ID
		,c.ED_DISPOSITION
		,c.PATIENT_DESTINATION
		,ppe.MODIFIERS
		,c.EVAL_PROVIDER    as provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.EVAL_PROVIDER
		 )                  as Provider
		,ppe.PHYSICIAN_ID   as perform_provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = ppe.PHYSICIAN_ID
		 )                  as Perform_Provider
		,ppe.PROCEDURE_DATE as Perform_DOS
		,''                 as [ICD10_Code] --ppe.icd_10_code,
		,3                  as Process_Order
		,0                  as posting_order
		,'P'                as Code_Type
		,cmd.[NAME] [DEPARTMENT]
		,c.OBSERVATION_ATTENDING_PROVIDER_ID
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.OBSERVATION_ATTENDING_PROVIDER_ID
		 )               as OBS_ATT_PROVIDER
	from
		#chart1                    c
	left outer join
	PHYSICIAN_PROCEDURE_EVALUATION ppe on c.CHART_ID = ppe.CHART_ID
	inner join
	CHARGE_MASTER                  cm on cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
	left join dbo.CHARGE_MASTER_DEPARTMENT cmd on cm.SERVICE_AGREEMENT_ID = cmd.SERVICE_AGREEMENT_ID
														and cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
	union all
	select
		c.CHART_ID
		,c.Patient_ID
		,c.MRN
		,c.Patient_Name
		,c.DOS
		,c.TIME_OF_DIS
		,c.SENT_DATE
		,CM.BILLING_CODE
		,CM.CPT_CODE
		,CM.[DESCRIPTION]   as CPT_Description
		,cap.QUANTITY
		,c.FACILITY_ID
		,c.ED_DISPOSITION
		,c.PATIENT_DESTINATION
		,cap.MODIFIERS
		,c.EVAL_PROVIDER    as provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.EVAL_PROVIDER
		 )                  as Provider
		,cap.PHYSICIAN_ID   as perform_provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = cap.PHYSICIAN_ID
		 )                  as Perform_Provider
		,ppe.PROCEDURE_DATE as Perform_DOS
		,''                 as [ICD10_Code] --fpe.icd_10_code,
		,3                  as Process_Order
		,0                  as posting_order
		,'P'                as Code_Type
		,cmd.[NAME] [DEPARTMENT]
		,c.OBSERVATION_ATTENDING_PROVIDER_ID
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.OBSERVATION_ATTENDING_PROVIDER_ID
		 )               as OBS_ATT_PROVIDER
	from
		#chart1 c
		,CHARGE_MASTER             CM
	inner join
	CHART_ADDITIONAL_PROCEDURE     cap on CM.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID
	inner join
	PHYSICIAN_PROCEDURE_EVALUATION ppe on ppe.PHYSICIAN_PROCEDURE_ID = cap.CHARGE_MASTER_ID
	inner join
	CHARGE_MASTER_DEPARTMENT       cmd on CM.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
		,CHARGE_MASTER_CATEGORY CMC
	where
		CM.CHARGE_MASTER_CATEGORY_ID = CMC.CHARGE_MASTER_CATEGORY_ID
		and ppe.CHART_ID = cap.CHART_ID
		and cap.CLASS = 'PP'
		and cap.QUANTITY <> 0
		and CM.EFFECTIVE_DATE <= c.DOS
		and CM.EXPIRATION_DATE >= c.DOS
		and ppe.CHART_ID = c.CHART_ID;



	-- Facility Observation Records
	-- request data be summarized **




	insert into #Details1
	select
		c.CHART_ID
		,c.Patient_ID
		,c.MRN
		,c.Patient_Name
		,c.DOS
		,c.TIME_OF_DIS
		,c.SENT_DATE
		,isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE) BILLING_CODE
		,cm.CPT_CODE
		,cm.[DESCRIPTION]                                           as CPT_Description
		,sum(oer.[UNITS])                                           as quantity
		,c.FACILITY_ID
		,c.ED_DISPOSITION
		,c.PATIENT_DESTINATION
		,''                                                         modifiers
		,c.EVAL_PROVIDER                                            as provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.EVAL_PROVIDER
		 )                                                          as Provider
		,''                                                         as perform_provider_id
		,''                                                         as Perform_Provider
		,min(oer.DATE_OF_SERVICE)                                   as Perform_DOS
		,''                                                         as icd_10_code
		,6                                                          as Process_Order
		,0                                                          as posting_order
		,'F'                                                        as Code_Type
		,cmd.[NAME] [DEPARTMENT]
		,c.OBSERVATION_ATTENDING_PROVIDER_ID
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.OBSERVATION_ATTENDING_PROVIDER_ID
		 )               as OBS_ATT_PROVIDER
	from
		#chart1 c
		,CHART_OBSERVATION_ENCOUNTER_RESULT oer
		,CHARGE_MASTER cm
		,CHARGE_MASTER_DEPARTMENT cmd
	where
		c.CHART_ID = oer.CHART_ID
		and c.PATIENT_DISPOSITION_ID = 5 -- Observation	
		and oer.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
		and oer.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
		and upper(cm.CPT_CODE) like 'G%'
	group by
		c.CHART_ID
		,c.Patient_ID
		,c.MRN
		,c.Patient_Name
		,c.DOS
		,c.TIME_OF_DIS
		,c.SENT_DATE
		,isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE)
		,cm.CPT_CODE
		,cm.[DESCRIPTION]
		,c.FACILITY_ID
		,c.ED_DISPOSITION
		,c.PATIENT_DESTINATION
		,c.EVAL_PROVIDER
		,cmd.[NAME]
		,c.OBSERVATION_ATTENDING_PROVIDER_ID;





	-- insert FL data  

	insert into #Details1
	select
		sp.CHART_ID
		,sp.Patient_ID
		,sp.MRN
		,sp.Patient_Name
		,sp.DOS
		,sp.TIME_OF_DIS
		,sp.SENT_DATE
		,sp.BILLING_CODE
		,sp.CPT_CODE
		,cm.[DESCRIPTION]   as CPT_Description
		,sp.quantity
		,sp.FACILITY_ID
		,sp.ED_DISPOSITION
		,sp.PATIENT_DESTINATION
		,(
			 select
				 MODIFIER
			 from
				 FACILITY_LEVEL
			 where
				 FACILITY_LEVEL_ID = sp.FL_LEVEL_ID
		 )                  as modifiers
		,sp.EVAL_PROVIDER   as provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = sp.EVAL_PROVIDER
		 )                  as Provider
		,sp.sp_physician_id as perform_provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = sp.sp_physician_id
		 )                  as Perform_Provider
		,sp.Perform_DOS
		,''                 as [ICD10_Code]
		,4                  as PROCESS_ORDER
		,0                  as Posting_order
		,'F'                as Code_Type
		,cmd.[NAME] [DEPARTMENT]
		,sp.OBSERVATION_ATTENDING_PROVIDER_ID
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = sp.OBSERVATION_ATTENDING_PROVIDER_ID
		 )               as OBS_ATT_PROVIDER
	from
		#sent_procedure1 sp
	inner join
	CHARGE_MASTER        cm on sp.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
	left join dbo.CHARGE_MASTER_DEPARTMENT cmd on cm.SERVICE_AGREEMENT_ID = cmd.SERVICE_AGREEMENT_ID
														and cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
	where
		sp.class = 'FL';




	-- Facility Procedure





	insert into #Details1
	select
		c.CHART_ID
		,c.Patient_ID
		,c.MRN
		,c.Patient_Name
		,c.DOS
		,c.TIME_OF_DIS
		,c.SENT_DATE
		,CM.BILLING_CODE
		,CM.CPT_CODE
		,CM.[DESCRIPTION]   as CPT_Description
		,FPE.QUANTITY
		,c.FACILITY_ID
		,c.ED_DISPOSITION
		,c.PATIENT_DESTINATION
		,FPE.MODIFIERS
		,c.EVAL_PROVIDER    as provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.EVAL_PROVIDER
		 )                  as Provider
		,FPE.PHYSICIAN_ID   as perform_provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = FPE.PHYSICIAN_ID
		 )                  as Perform_Provider
		,FPE.PROCEDURE_DATE as Perform_DOS
		,''                 as [ICD10_Code] -- fpe.icd_10_code,
		,5                  as Process_Order
		,0                  as posting_order
		,'F'                as Code_Type
		,cmd.[NAME] [DEPARTMENT]
		,c.OBSERVATION_ATTENDING_PROVIDER_ID
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.OBSERVATION_ATTENDING_PROVIDER_ID
		 )               as OBS_ATT_PROVIDER
	from
		#chart1 c
		,CHARGE_MASTER            CM
	left outer join
	FACILITY_PROCEDURE_EVALUATION FPE on CM.CHARGE_MASTER_ID = FPE.FACILITY_PROCEDURE_ID
	inner join
	CHARGE_MASTER_DEPARTMENT      cmd on CM.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
		,CHARGE_MASTER_CATEGORY CMC
	where
		CM.CHARGE_MASTER_CATEGORY_ID = CMC.CHARGE_MASTER_CATEGORY_ID
		and (FPE.QUANTITY <> 0)
		and CM.EFFECTIVE_DATE <= c.DOS
		and CM.EXPIRATION_DATE >= c.DOS
		and FPE.CHART_ID = c.CHART_ID
	union all
	select
		c.CHART_ID
		,c.Patient_ID
		,c.MRN
		,c.Patient_Name
		,c.DOS
		,c.TIME_OF_DIS
		,c.SENT_DATE
		,CM.BILLING_CODE
		,CM.CPT_CODE
		,CM.[DESCRIPTION]   as CPT_Description
		,cap.QUANTITY
		,c.FACILITY_ID
		,c.ED_DISPOSITION
		,c.PATIENT_DESTINATION
		,cap.MODIFIERS
		,c.EVAL_PROVIDER    as provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.EVAL_PROVIDER
		 )                  as Provider
		,cap.PHYSICIAN_ID   as perform_provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = cap.PHYSICIAN_ID
		 )                  as Perform_Provider
		,fpe.PROCEDURE_DATE as Perform_DOS
		,''                 as [ICD10_Code] --fpe.icd_10_code,
		,5                  as Process_Order
		,0                  as posting_order
		,'F'                as Code_Type
		,cmd.[NAME] [DEPARTMENT]
		,c.OBSERVATION_ATTENDING_PROVIDER_ID
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.OBSERVATION_ATTENDING_PROVIDER_ID
		 )               as OBS_ATT_PROVIDER
	from
		#chart1 c
		,CHARGE_MASTER            CM
	inner join
	CHART_ADDITIONAL_PROCEDURE    cap on CM.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID
	inner join
	FACILITY_PROCEDURE_EVALUATION fpe on fpe.FACILITY_PROCEDURE_ID = cap.CHARGE_MASTER_ID
	inner join
	CHARGE_MASTER_DEPARTMENT      cmd on CM.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
		,CHARGE_MASTER_CATEGORY CMC
	where
		CM.CHARGE_MASTER_CATEGORY_ID = CMC.CHARGE_MASTER_CATEGORY_ID
		and fpe.CHART_ID = cap.CHART_ID
		and cap.CLASS = 'FP'
		and cap.QUANTITY <> 0
		and CM.EFFECTIVE_DATE <= c.DOS
		and CM.EXPIRATION_DATE >= c.DOS
		and fpe.CHART_ID = c.CHART_ID;






	---------------
	-- Insert  I/I

	insert into #Details1
	select
		c.CHART_ID
		,c.Patient_ID
		,c.MRN
		,c.Patient_Name
		,c.DOS
		,c.TIME_OF_DIS
		,c.SENT_DATE
		,cm.BILLING_CODE
		,cm.CPT_CODE
		,cm.[DESCRIPTION]    as CPT_Description
		,cir.UNITS           as quantity
		,c.FACILITY_ID
		,c.ED_DISPOSITION
		,c.PATIENT_DESTINATION
		,cir.MODIFIERS -- Modifiers where different in Sent_procedure table chart _id 65335059 as example
					   -- Lookup how Sent Procedure gathers Performing Physician for I/I, use this for now   **** 
		,c.EVAL_PROVIDER     as provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.EVAL_PROVIDER
		 )                   as Provider
		,(
			 select
				 max(Perform_Provider)
			 from
				 #sent_procedure1
			 where
				 class = 'IP'
				 and CHART_ID = c.CHART_ID
		 )                   as perform_provider_id
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID =
			 (
				 select
					 max(Perform_Provider)
				 from
					 #sent_procedure1
				 where
					 class = 'IP'
					 and CHART_ID = c.CHART_ID
			 )
		 )                   as Perform_Provider
		,cir.DATE_OF_SERVICE as Perform_DOS
		,''                  as [ICD10_Code]
		,7                   as Process_Order
		,0                   as posting_order
		,'F'                 as Code_Type
		,cmd.[NAME] [DEPARTMENT]
		,c.OBSERVATION_ATTENDING_PROVIDER_ID
		,(
			 select
				 LAST_NAME + ', ' + FIRST_NAME
			 from
				 FACILITY_PROFESSIONAL
			 where
				 FACILITY_PROF_ID = c.OBSERVATION_ATTENDING_PROVIDER_ID
		 )               as OBS_ATT_PROVIDER
	from
		#chart1 c
		,CHART_INFUSION_RESULT cir
		,CHARGE_MASTER cm
		left join dbo.CHARGE_MASTER_DEPARTMENT cmd on cm.SERVICE_AGREEMENT_ID = cmd.SERVICE_AGREEMENT_ID
														and cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
	where
		cir.CHART_ID = c.CHART_ID
		and cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID;







	-- Output 


	select
		Patient_ID
		,MRN                                                  as MRN_ID
		,Patient_Name
		,cast(DOS as date)                                    as DOS
		,cast(TIME_OF_DIS as datetime)                          as TIME_OF_DIS
		,case
			 when Perform_DOS <> ''
				  and cast(DOS as date) <> cast(Perform_DOS as date) then cast(Perform_DOS as date)
		 else null end                                        as Perform_DOS
		,ED_DISPOSITION
		,PATIENT_DESTINATION
		,''                                                   as OBS_DISPOSITION
		,case when Provider is null then '' else Provider end as Provider_Name
		,case
			 when perform_provider_id <> 0
				  and provider_id <> perform_provider_id then Perform_Provider
		 else null end                                        Perform_Provider
		,Code_Type
		,billing_code                                         as Bill_CD
		,quantity
		,cpt_code                                             as CPT
		,CPT_Description
		,modifiers
		,icd_10_code                                          as ICD_10_CM
		,(
			 select top 10
				 SHORT_DESCRIPTION
			 from
				 ICD_10_CM
			 where
				 ICD_10_CODE = replace(d.icd_10_code, '.', '')
		 )                                                    as DX_Description
		,facility_id
		,(
			 select
				 FACILITY.FACILITY_NUMBER
			 from
				 FACILITY
			 where
				 FACILITY.FACILITY_ID = d.facility_id
		 )                                                    as Tab_Name
         ,c.ADMIT_TYPE
         ,c.CODER_COMMENT
         ,d.Department
		 ,OBS_ATT_PROVIDER
		 ,dt.NAME as Documentation_Type -- RACS-2937 08/14/23 Add Documentation Deficiencies ****
	from
		#Details1 d
		outer apply (
					select c.CHART_ID, c.ADMIT_TYPE, c.CODER_COMMENT, c.DEPARTMENT
					from 
						#chart1 c
					where
						d.chart_ID = c.CHART_ID
					) c
left outer join documentation_inequity di on d.chart_id = di.chart_id
left outer join documentation_item dt on dt.DOCUMENTATION_ID = di.DOCUMENTATION_ID and di.checked = 1
where  
    EXISTS (								
		SELECT *						
		FROM FACILITY_USER_AUTHORIZATION  FUA WITH (NOLOCK),						
		USER_PROFILE UP	WITH (NOLOCK)					
		WHERE FUA.FACILITY_ID = d.FACILITY_ID						
		AND fua.user_profile_id = up.user_profile_id						
		AND UP.IS_ACTIVE = 'Y'						
		and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE						
		AND FUA.USER_PROFILE_ID = @ReportUser						
		)

	order by
		Patient_ID
		,PROCESS_ORDER
		,POSTING_ORDER
		,cpt_code asc;


end;







GO
