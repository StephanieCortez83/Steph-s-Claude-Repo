SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[Refresh_Daily_Snapshot_SENT_PROCEDURE]
WITH EXEC AS CALLER
AS


-- IMPORTANT - after the project of index reduction on CHART is complete, consider removing the query hints in the form of "index(1)" from this stored proc.
	-- Index(1) forces the query to use the clustered index.

/*
Tuning from 10/25/2017 can be summarized as using a bookmark process to identify the relatively small subset of chart_IDs which need to be processed each time (usually 
between 30K-50K rows).

Additional tuning comes from modifying the preprocessing steps so that only chart_ID is initially pulled from CHART, along with needed columns from
the various child tables (Facility_Procedure_Evaluation, Chart_Infusion_Result, etc.).  Subsequent steps populate the additional columns needed from CHART by joining
the temp tables (with the subset of Chart_IDs) to CHART. A final step for each temp table deletes any rows having sent_date < effective_date of the service agreement.

This modified approach reduces logical reads by more than 90% (2M vs. 70M), and also reduces CPU and duration to a similar degree.  It also 
minimizes the usage of CHART indexes which may help in our effort to reduce the overall number of indexes retained on CHART.
*/

----------------------------------------------------------------------------------------------------------

declare @HadError bit = 0

-- beginning of new section added 3/4/2022, dsexton. --------------------------------------------------------------------------------
/* 
This tracking table (RefreshSnapshot_ChartAdjustment_Status0) will be used to keep track of rows in CHART_ADJUSTMENT which had Status_ID = 0 and may have fallen behind the bookmark. 
When they are updated in CHART_ADJUSTMENT to Status_ID = 1 they will be flagged (date stamped) as StatusID 1 in the tracking table, inserted into #TempCA, and deleted from the tracking table 30 days after being flagged as StatusID 1.
*/

/*  -- one-time execution for creating the new tracking table
create table RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0
(
	Chart_Adjustment_ID int not null, 
	Current_Status_ID int not null, 
	RowInsertedDT datetime not null, 
	LastAuditDT datetime not null, 
	StatusID1_DT datetime, 
	PostedDT datetime
)

ALTER TABLE RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0 
	add CONSTRAINT [PK_RefreshSnapshot_ChartAdjustment_Status0] PRIMARY KEY CLUSTERED (Chart_Adjustment_ID)

CREATE NONCLUSTERED INDEX ix_RefreshSnapshotCAStatus0_StatusID1DT 
	ON RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0 (StatusID1_DT)
	INCLUDE (Current_Status_ID, PostedDT)

Create index ix_ChartAdjustment_StatusID on CHART_ADJUSTMENT (Status_ID)		-- postpone until maintenance window
*/

	-- Remove orphaned rows if any from the tracking table
	delete 
	from RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0 
	where chart_Adjustment_ID not in (select Chart_Adjustment_ID from CHART_ADJUSTMENT)
		and PostedDT is null


	-- insert new rows into the tracking table which don't already exist there
	insert into RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0 (Chart_Adjustment_ID, Current_Status_ID, RowInsertedDT, LastAuditDT, StatusID1_DT, PostedDT)
	select Chart_Adjustment_ID, 
		Current_Status_ID = Status_ID, 
		RowInsertedDT = getdate(), 
		LastAuditDT = getdate(), 
		StatusID1_DT = null, 
		PostedDT = null 
	from CHART_ADJUSTMENT as CA 
	where Status_ID = 0 
		and Chart_Adjustment_ID not in (select Chart_Adjustment_ID from RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0)
		and Creation_Date_Time > '3/1/2022'		-- do not include records prior to when these changes were implemented. Such old records are typically for practice charts or expired service agreements.


	-- update Current_Status_ID in the tracking table (based on Status_ID in CHART_ADJUSTMENT) for rows which have not already been flagged as StatusID 1 
	update t
	set 
		t.Current_Status_ID = CA.Status_ID,
		t.LastAuditDT = getdate()
	from RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0 as t
		join CHART_ADJUSTMENT as CA on t.Chart_Adjustment_ID = CA.Chart_Adjustment_ID
	where t.StatusID1_DT is null


	-- date stamp any rows in the tracking table that are now StatusID 1.  These will be inserted to #TempCA in a subsequent step.
	update RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0 
	set StatusID1_DT = getdate()
	where Current_Status_ID = 1
		and StatusID1_DT is null


	-- delete rows from the tracking table 30 days after being date stamped in StatusID_DT and PostedDT
	delete from RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0 
	where 
		Current_Status_ID = 1
		and StatusID1_DT is not null
		and PostedDT < GetDate()-30

-- end of new section added 3/4/2022, dsexton.  -------------------------------------------------------------------------------------


-- capture bookmark IDs for current execution which will be used in subsequent execution
	insert into RevCycleTransactionSnapshot.dbo.RefreshSnapshot_SP_Bookmarks (CurrentMax_LogNoteID_Sent, CurrentMax_ChartAdjustmentID, RowInsertedDT, RefreshCompletedDT)
	select 
		CurrentMax_LogNoteID_Sent = (select max(Log_Note_ID) from LOG_NOTE where category_ID = 4),
		CurrentMax_ChartAdjustmentID = (select max(Chart_Adjustment_ID) from CHART_ADJUSTMENT),
		RowInsertedDT = getdate(),
		RefreshCompletedDT = NULL;

	declare @BookmarkDT datetime;	-- will be used at the end to update RefreshSnapshot_SP_Bookmarks
	select TOP 1 @BookmarkDT = RowInsertedDT from RevCycleTransactionSnapshot.dbo.RefreshSnapshot_SP_Bookmarks order by RowInsertedDT desc;	

	declare
		@LN_Bookmark int,
		@CA_Bookmark int

	select TOP 1 @LN_Bookmark = CurrentMax_LogNoteID_Sent from RevCycleTransactionSnapshot.dbo.RefreshSnapshot_SP_Bookmarks Order By RefreshCompletedDT desc;
	select TOP 1 @CA_Bookmark = CurrentMax_ChartAdjustmentID from RevCycleTransactionSnapshot.dbo.RefreshSnapshot_SP_Bookmarks Order By RefreshCompletedDT desc;		-- where RefreshCompletedDT is not null

	if object_id('TempDB..#NewlySentCharts', 'U') is not null DROP TABLE #NewlySentCharts;	
	if object_id('TempDB..#NewlyAdjusted', 'U') is not null DROP TABLE #NewlyAdjusted;	

	select distinct chart_ID into #NewlySentCharts from log_note with(nolock) where category_ID = 4 and log_note_ID >= @LN_Bookmark option(recompile);
	select distinct chart_ID into #NewlyAdjusted from chart_adjustment with(nolock) where chart_adjustment_id >= @CA_Bookmark;


-- #TempFPE (Facility_Procedure_Evaluation)	
	-- tuning 10/25/2017: reads = 580K vs 4.8M; CPU = 50s vs. 59s; duration sec = 31/4 (cold/warm) vs. 374/9  (cold/warm)
    if object_id('TempDB..#TempFPE', 'U') is not null DROP TABLE #TempFPE;		
	select 
		c.chart_ID,
		fpe.FACILITY_PROCEDURE_ID, fpe.procedure_date, fpe.quantity
	 INTO #TempFPE	
	from facility_procedure_evaluation as fpe with(NOLOCK) 
		join #NewlySentCharts as c on fpe.chart_ID = c.chart_ID
	where not exists
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where sp.source_id = fpe.FACILITY_PROCEDURE_ID and sp.chart_ID = fpe.chart_ID and sp.source_cd = 'FP')

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

	-- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
		-- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
	delete from #TempFPE		-- added 10/25/2017		
	where isnull(time_of_service, '1/1/1900') < saEffDT


-- #TempOER (Chart_Observation_Encounter_Result)
	-- (2016) Using this preprocessed table greatly improves performance (500K vs 21M reads)
    if object_id('TempDB..#TempOER', 'U') is not null DROP TABLE #TempOER;
	select 
		c.chart_ID,
		oer.CHART_OBSERVATION_ENCOUNTER_RESULT_ID, /*oer.chart_ID,*/ oer.CHARGE_MASTER_ID, oer.Units, oer.DATE_OF_SERVICE
	 INTO #TempOER	
	from CHART_OBSERVATION_ENCOUNTER_RESULT as oer with(NOLOCK) 
		join #NewlySentCharts as c on oer.chart_ID = c.chart_ID
	where not exists
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where sp.source_id = oer.CHART_OBSERVATION_ENCOUNTER_RESULT_ID and sp.chart_ID = oer.chart_ID and sp.source_cd = 'OP')

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

	-- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
		-- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
	delete from #TempOER		-- added 10/25/2017		
	where isnull(time_of_service, '1/1/1900') < saEffDT


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
	where not exists
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where sp.source_id = cir.chart_infusion_result_ID and sp.chart_ID = cir.chart_ID and sp.source_cd = 'IP')

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
	--
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
		and not exists		-- 11/14/2017, dsexton: changed this filter to use c2.chart_ID instead of c.chart_ID in the join to sp.source_id.  This avoids a double join on c.chart_ID which was sometimes causing horrible performance (300M reads, 100 minutes).
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where sp.source_id = c2.chart_ID and sp.chart_ID = c.chart_ID and sp.source_cd = 'FL')

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

		and not exists		-- 11/14/2017, dsexton: changed this filter to use c2.chart_ID instead of c.chart_ID in the join to sp.source_id.  This avoids a double join on c.chart_ID which was sometimes causing horrible performance (300M reads, 100 minutes).
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where sp.source_id = c2.chart_ID and sp.chart_ID = c.chart_ID and sp.source_cd = 'PL')

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


-- #TempPPE (Physician_Procedure_Evaluation)
	-- tuning 10/25/2017 with #TempPPE vs. without: reads = 533K vs 51M/28M (warm/cold); CPU = 31s vs. 64s; duration sec = 3/2 vs. 414/35 (cold/warm)
    if object_id('TempDB..#TempPPE', 'U') is not null DROP TABLE #TempPPE;		-- added new section 10/25/2017 (was not previously using temp table for PPE)
	select 
		c.chart_ID,
		ppe.PHYSICIAN_PROCEDURE_ID, ppe.procedure_date, ppe.quantity, PhysicianID_PPE = ppe.physician_ID
	 INTO #TempPPE	
	from physician_procedure_evaluation as ppe with(NOLOCK) 
		join #NewlySentCharts as c on ppe.chart_ID = c.chart_ID
	where not exists
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where sp.source_id = ppe.PHYSICIAN_PROCEDURE_ID and sp.chart_ID = ppe.chart_ID and sp.source_cd = 'PP')

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

	-- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
		-- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
	delete from #TempPPE	
	where isnull(time_of_service, '1/1/1900') < saEffDT


-- #TempCPI (Chart_Package_Item)
	-- tuning 10/25/2017 with #TempCPI vs. without:
	if object_id('TempDB..#TempCPI', 'U') is not null DROP TABLE #TempCPI;		-- added new section 10/25/2017 (was not previously using temp table for CPI)
	select 
			c.CHART_ID,
			cpi.CHART_PACKAGE_ITEM_ID, cpi.UNITS, cpi.CHARGE_PACKAGE_ITEM_ID
	 INTO #TempCPI
	from   CHART_PACKAGE_ITEM cpi with (NOLOCK)
		join #NewlySentCharts as c on cpi.chart_ID = c.chart_ID
	where not exists
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where sp.source_id = cpi.CHART_PACKAGE_ITEM_ID 
				and sp.chart_ID = cpi.chart_ID and sp.source_cd = 'PI')

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



-- #TempCAS (Chart_Additional_Supplies)
	-- tuning 10/25/2017 with #TempCAS vs. without:
	if object_id('TempDB..#TempCAS', 'U') is not null DROP TABLE #TempCAS;		-- added new section 10/25/2017 (was not previously using temp table for CAS)
	select 
			c.CHART_ID,
			cas.Chart_Additional_Supplies_ID, cas.Units, cas.Charge_master_ID
	 INTO #TempCAS
	from CHART_ADDITIONAL_SUPPLIES as cas with (NOLOCK)
		join #NewlySentCharts as c on cas.chart_ID = c.chart_ID
	where not exists
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where cas.CHART_ID = sp.chart_id
			  and cas.CHART_ADDITIONAL_SUPPLIES_ID = sp.source_id
			  and sp.source_cd = 'AS')

	alter table #TempCAS
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
	from #TempCAS as t
		join Chart as c with(nolock, index(1)) on t.chart_ID = c.chart_ID

	update t
	set t.saEffDT = sa.EFFECTIVE_DATE
	from #TempCAS as t
		join service_agreement as sa with(nolock) on t.service_agreement_ID = sa.service_agreement_ID

	-- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
		-- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
	delete from #TempCAS	
	where isnull(time_of_service, '1/1/1900') < saEffDT



-- #TempCA (Chart_Adjustment)
	-- tuning 10/25/2017 with #TempCA vs. without:
	if object_id('TempDB..#TempCA', 'U') is not null DROP TABLE #TempCA;		-- added new section 10/25/2017 (was not previously using temp table for CA)
	select 
			c.CHART_ID,
			ca.Chart_Adjustment_ID, ca.charge_master_ID, ca.revised_date_of_service, ca.Quantity, ca.sent_date
	 INTO #TempCA
	from CHART_ADJUSTMENT as ca with (NOLOCK)
		--join #NewlySentCharts as c on ca.chart_ID = c.chart_ID		-- can't use this because many entries in log_note for category_ID 4 (for all recent adjustments) are older than the cutoff for #NewlySentCharts.
		join #NewlyAdjusted as c on ca.chart_ID = c.chart_ID
	where not exists
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where ca.CHART_ID = sp.chart_id
			  and ca.Chart_Adjustment_ID = sp.source_id
			  and sp.source_cd = 'CA')
		and CA.Status_ID = 1			-- added 3/4/2022, dsexton


-- begin new section added 3/4/2022, dsexton  ----------------------------------

	-- insert additional rows into #TempCA from the tracking table for any adjustments that may have fallen behind the bookmark before Status_ID changed from 0 to 1.
	insert into #TempCA  (CHART_ID, Chart_Adjustment_ID, charge_master_ID, revised_date_of_service, Quantity, sent_date)
	select ca.CHART_ID, ca.Chart_Adjustment_ID, ca.charge_master_ID, ca.revised_date_of_service, ca.Quantity, ca.sent_date
	from CHART_ADJUSTMENT as ca with (NOLOCK)
		join RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0 as t 
			on ca.Chart_Adjustment_ID = t.chart_Adjustment_ID
			and t.StatusID1_DT is not null
			and t.PostedDT is null
			and t.Chart_Adjustment_ID not in (Select Chart_Adjustment_ID from #TempCA)
	where not exists
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where ca.CHART_ID = sp.chart_id
			  and ca.Chart_Adjustment_ID = sp.source_id
			  and sp.source_cd = 'CA')
		and CA.Status_ID = 1	

	-- flag rows in the tracking table that are about to be posted to SENT_PROCEDURE
	update RevCycleTransactionSnapshot.dbo.RefreshSnapshot_ChartAdjustment_Status0
	set PostedDT = getdate()
	where Chart_Adjustment_ID in (select Chart_Adjustment_ID from #TempCA)

-- end new section added 3/4/2022, dsexton  ------------------------------------


	alter table #TempCA
	add 
	facility_chart_ID varchar(20),
	service_agreement_ID int,
	saEffDT datetime,
	time_of_service datetime,
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
	t.sent_date = case when t.sent_date is NULL then c.sent_date else t.sent_date end,
	t.patient_disposition_ID = c.patient_disposition_ID, 
	t.physician_ID = c.physician_ID,
	t.facility_ID = c.facility_ID,
	t.patient_class_ID = c.patient_class_ID,
	t.facility_admin_chart_ID = c.facility_admin_chart_ID
	from #TempCA as t
		join Chart as c with(nolock, index(1)) on t.chart_ID = c.chart_ID

	update t
	set t.saEffDT = sa.EFFECTIVE_DATE
	from #TempCA as t
		join service_agreement as sa with(nolock) on t.service_agreement_ID = sa.service_agreement_ID

	-- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
		-- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
	delete from #TempCA	
	where isnull(time_of_service, '1/1/1900') < saEffDT


-- #TempCAP (Chart_Additional_Procedure)
	-- tuning 10/25/2017 with #TempCAP vs. without:
	if object_id('TempDB..#TempCAP', 'U') is not null DROP TABLE #TempCAP;		-- added new section 10/25/2017 (was not previously using temp table for CAP)
	select 
			c.CHART_ID,
			cap.Chart_Additional_Procedure_ID, cap.procedure_date, cap.Quantity, cap.Charge_master_ID, cap.class
	 INTO #TempCAP
	from CHART_ADDITIONAL_PROCEDURE as cap with (NOLOCK)
		join #NewlySentCharts as c on cap.chart_ID = c.chart_ID
	where not exists
		(select 1 from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE as sp with(NOLOCK)
			where cap.CHART_ID = sp.chart_id
			  and cap.chart_additional_procedure_ID = sp.source_id
			  and sp.source_cd = 'AP')

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
	if @@Error <> 0 SET @HadError = 1

	
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
	if @@Error <> 0 SET @HadError = 1


	-- this INSERT was not using a preprocessed table, but now it does (#TempCAS)	-- 10/25/2017
	INSERT INTO #SentProcedure
	select 'FP' as CLASS,   -- Additional Supplies
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
			c.CHART_ADDITIONAL_SUPPLIES_ID as source_id,
			'AS' as source_cd
	from #TempCAS as c 
		join CHARGE_MASTER as cm with(nolock) on c.charge_master_ID = cm.charge_master_ID
	if @@Error <> 0 SET @HadError = 1


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
	if @@Error <> 0 SET @HadError = 1


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
	if @@Error <> 0 SET @HadError = 1


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
	if @@Error <> 0 SET @HadError = 1	


	-- this INSERT was not using a preprocessed table, but now it does (#TempCA) 10/25/2017
	INSERT INTO #SentProcedure
	select case when cm.CHARGE_MASTER_USAGE_CODE = 2 then 'FL' 
				when cm.CHARGE_MASTER_USAGE_CODE = 3 then 'FP' 
				when cm.CHARGE_MASTER_USAGE_CODE = 4 then 'PL'
				when cm.CHARGE_MASTER_USAGE_CODE = 5 then 'PP'
			 else 'CA' end  as Class,
			c.CHART_ID,
			c.FACILITY_CHART_ID,
			c.SERVICE_AGREEMENT_ID,
			coalesce(c.REVISED_DATE_OF_SERVICE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
			c.SENT_DATE,
		   (case when c.PATIENT_DISPOSITION_ID in (-1, 0) then 
				  coalesce((select distinct 4 
				   from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE fs, FACILITY_SERVICE_SCHEDULE_ITEM fssi
				   where fse.CHART_ID = c.chart_id
				   and   ((fse.FACILITY_SERVICE_ID IS NOT NULL AND fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID) OR
						 (fse.FACILITY_SERVICE_SCHEDULE_ID = fssi.FACILITY_SERVICE_SCHEDULE_ID AND
						   fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fssi.FACILITY_SERVICE_SCHEDULE_ITEM_ID))
				   and   (left(fs.DESCRIPTION,9) = 'Admission' or left(fs.DESCRIPTION,5) = 'Admit')),1)
				 when c.PATIENT_DISPOSITION_ID is null then 1
					 else c.PATIENT_DISPOSITION_ID end)  PATIENT_DISPOSITION_ID,
							case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
										end as PHYSCISIAN_ID,
			cm.BILLING_CODE,
			cm.CPT_CODE,
			c.QUANTITY,
			c.facility_id,
			case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK) 
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
			'Y' as ADJUSTMENT_IND,
			cm.CHARGE_MASTER_ID,
			case when cm.CHARGE_MASTER_USAGE_CODE = 2 then (select max(fl.FACILITY_LEVEL_ID) from FACILITY_LEVEL fl
				  where fl.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID
				  and   fl.BILLING_CODE = cm.BILLING_CODE)
				 when cm.CHARGE_MASTER_USAGE_CODE = 4 and cm.cpt_code not in ('99291', '99292') then 
				   (select max(psp.PHYSICIAN_SERVICE_PROC_ID) from PHYSICIAN_SERVICE_PROCEDURE psp with (NOLOCK)
					where psp.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID
					and   psp.BILLING_CODE = cm.BILLING_CODE)
				 when cm.CHARGE_MASTER_USAGE_CODE = 4 and cm.cpt_code in ('99291', '99292') then -1  --Critical Care
				 else 0 end as LEVEL_ID,
		   c.FACILITY_ADMIN_CHART_ID,
		   c.CHART_ADJUSTMENT_ID as source_id,
		   'CA' as source_cd
	from #TempCA as c
		join CHARGE_MASTER as cm with(nolock) on c.charge_master_ID = cm.charge_master_ID
	if @@Error <> 0 SET @HadError = 1


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
	if @@Error <> 0 SET @HadError = 1


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
	if @@Error <> 0 SET @HadError = 1
 
	 -- (2016) clean up any remaining records where patient_disposition_ID in (-1, 0)
	update #SentProcedure
	set patient_disposition_ID = 1
	where patient_Disposition_ID in (-1, 0)
		and source_cd = 'FL'
	if @@Error <> 0 SET @HadError = 1


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
	if @@Error <> 0 SET @HadError = 1


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
	if @@Error <> 0 SET @HadError = 1

	-- (2016) clean up any remaining records where patient_disposition_ID in (-1, 0)
	update #SentProcedure
	set patient_disposition_ID = 1
	where patient_Disposition_ID in (-1, 0)
		and source_cd = 'PL'
	if @@Error <> 0 SET @HadError = 1


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
	if @@Error <> 0 SET @HadError = 1

-----------------------------------------------------------------------------------------------------


-- insert results to SENT_PROCEDURE	
	insert into [RevCycleTransactionSnapshot].[DBO].SENT_PROCEDURE
		(CLASS, CHART_ID, FACILITY_CHART_ID, SERVICE_AGREEMENT_ID, TIME_OF_SERVICE, SENT_DATE, PATIENT_DISPOSITION_ID, 
		PHYSICIAN_ID, BILLING_CODE, CPT_CODE, QUANTITY, FACILITY_ID, PATIENT_CLASS_ID, ADJUSTMENT_IND, CHARGE_MASTER_ID, LEVEL_ID, 
		FACILITY_ADMIN_CHART_ID, SOURCE_ID, SOURCE_CD)
	select *
	from #SentProcedure
	if @@Error <> 0 SET @HadError = 1

-- update the bookmark history
	IF @HadError = 0
	BEGIN
		UPDATE RevCycleTransactionSnapshot.dbo.RefreshSnapshot_SP_Bookmarks
		set 
			HadError = 0,
			RefreshCompletedDT = getdate(),
			BookmarkIDUsed_LN = @LN_Bookmark,
			BookmarkIDUsed_CA = @CA_Bookmark
		where RowInsertedDT = @BookmarkDT
			and RefreshCompletedDT is null;
	END;
	ELSE
	BEGIN
		UPDATE RevCycleTransactionSnapshot.dbo.RefreshSnapshot_SP_Bookmarks
		set 
			HadError = 1,
			RefreshCompletedDT = NULL,			-- ensure this column will still show as NULL
			BookmarkIDUsed_LN = @LN_Bookmark,
			BookmarkIDUsed_CA = @CA_Bookmark
		where RowInsertedDT = @BookmarkDT;
	END;
GO
