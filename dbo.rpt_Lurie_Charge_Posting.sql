SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE procedure [dbo].[rpt_Lurie_Charge_Posting]
(
	 @ReportUser int
	,@Facility   varchar(max)
	,@StartDate datetime 
	,@EndDate   datetime 
	,@StartTime int = 0
	,@EndTime   int = 23
	,@concat int = 1
)

as

begin

    set transaction isolation level read uncommitted;
    set nocount on;
    set ansi_warnings off;


-- Test Parameters
  --  declare
  --       @ReportUser int          = 80
  --      ,@Facility  varchar(max) = '1539'
  --      ,@StartDate datetime     = '20250602'
  --      ,@EndDate   datetime     = '20250605' 
		--,@StartTime int = 0
	 --   ,@EndTime   int = 23
		--,@concat	int			 = 1;


	----------------------------------------------------------------------------------------------------------------------------------

	
    declare
         @m_ReportUser     int          = @ReportUser
        ,@m_Facility      varchar(max) = @Facility
        ,@m_StartDate            datetime     = @StartDate
        ,@m_EndDate              datetime     = @EndDate
        ,@m_StartDateTime datetime     = dateadd(hour, @StartTime, @StartDate)
        ,@m_EndDateTime   datetime     = dateadd(hour, @EndTime, dateadd(minute, 59, dateadd(second, 59, @EndDate)));

        

    ----------------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------------
	-- Part 1 - Create #SentProcedure table

	if object_id('TempDB..#NewlySentCharts', 'U') is not null drop table #NewlySentCharts;

    select distinct
        ln.CHART_ID
    into #NewlySentCharts
    from
        LOG_NOTE ln
        ,CHART c
    where
        ln.CHART_ID = c.CHART_ID
        and ln.CATEGORY_ID = 4 -- Chart sent
        -- 	and ln.COMPLETION_DATE BETWEEN @m_StartDate AND DateAdd(second, 86399, @m_EndDate)
        and ln.COMPLETION_DATE between @m_StartDateTime and @m_EndDateTime
        and c.FACILITY_ID in
            (
                select * from SplitString(@m_Facility, ',')
            )
			;


	----------------------------------------------------------------------------------------------------------------------------------
	-- #TempFPE (Facility_Procedure_Evaluation)	
    -- tuning 10/25/2017: reads = 580K vs 4.8M; CPU = 50s vs. 59s; duration sec = 31/4 (cold/warm) vs. 374/9  (cold/warm)

    if object_id('TempDB..#TempFPE', 'U') is not null drop table #TempFPE;
    
	select
        c.CHART_ID
        ,fpe.FACILITY_PROCEDURE_ID
        ,fpe.PROCEDURE_DATE
        ,fpe.QUANTITY
    into #TempFPE
    from
        FACILITY_PROCEDURE_EVALUATION as fpe with (nolock)
		join #NewlySentCharts                  as c on fpe.CHART_ID = c.CHART_ID;


    alter table #TempFPE -- added 10/25/2017
    add
        facility_chart_ID varchar(20)
        ,service_agreement_ID int
        ,saEffDT datetime
        ,time_of_service datetime
        ,sent_date datetime
        ,patient_disposition_ID int
        ,physician_ID int
        ,facility_ID int
        ,patient_class_ID int
        ,facility_admin_chart_ID varchar(20);

    update
        t -- added 10/25/2017
    set
        t.facility_chart_ID = c.FACILITY_CHART_ID
        ,t.service_agreement_ID = c.SERVICE_AGREEMENT_ID
        ,t.time_of_service = c.TIME_OF_SERVICE
        ,t.sent_date = c.SENT_DATE
        ,t.patient_disposition_ID = c.PATIENT_DISPOSITION_ID
        ,t.physician_ID = c.PHYSICIAN_ID
        ,t.facility_ID = c.FACILITY_ID
        ,t.patient_class_ID = c.PATIENT_CLASS_ID
        ,t.facility_admin_chart_ID = c.FACILITY_ADMIN_CHART_ID
    from
        #TempFPE as t
		join CHART        as c with (nolock, index(1)) on t.CHART_ID = c.CHART_ID;

    update
        t -- added 10/25/2017
    set
        t.saEffDT = sa.EFFECTIVE_DATE
    from
        #TempFPE      as t
		join SERVICE_AGREEMENT as sa with (nolock) on t.service_agreement_ID = sa.SERVICE_AGREEMENT_ID;


    delete from
    #TempFPE -- added 10/25/2017		
    where
        isnull(time_of_service, '1/1/1900') < saEffDT;


    ----------------------------------------------------------------------------------------------------------
	-- #TempOER (Chart_Observation_Encounter_Result)
    -- (2016) Using this preprocessed table greatly improves performance (500K vs 21M reads)
    
	if object_id('TempDB..#TempOER', 'U') is not null drop table #TempOER;
    
	select
        c.CHART_ID
        ,oer.CHART_OBSERVATION_ENCOUNTER_RESULT_ID
        ,/*oer.chart_ID,*/ oer.CHARGE_MASTER_ID
        ,oer.UNITS
        ,oer.DATE_OF_SERVICE
    into #TempOER
    from
        CHART_OBSERVATION_ENCOUNTER_RESULT as oer with (nolock)
		join #NewlySentCharts                       as c on oer.CHART_ID = c.CHART_ID;


    alter table #TempOER -- added 10/25/2017
    add
        facility_chart_ID varchar(20)
        ,service_agreement_ID int
        ,saEffDT datetime
        ,time_of_service datetime
        ,sent_date datetime
        ,patient_disposition_ID int
        ,physician_ID int
        ,facility_ID int
        ,patient_class_ID int
        ,facility_admin_chart_ID varchar(20)
        ,evaluate_observation_departments bit;

    update
        t -- added 10/25/2017
    set
        t.facility_chart_ID = c.FACILITY_CHART_ID
        ,t.service_agreement_ID = c.SERVICE_AGREEMENT_ID
        ,t.time_of_service = c.TIME_OF_SERVICE
        ,t.sent_date = c.SENT_DATE
        ,t.patient_disposition_ID = c.PATIENT_DISPOSITION_ID
        ,t.physician_ID = c.PHYSICIAN_ID
        ,t.facility_ID = c.FACILITY_ID
        ,t.patient_class_ID = c.PATIENT_CLASS_ID
        ,t.facility_admin_chart_ID = c.FACILITY_ADMIN_CHART_ID
    from
        #TempOER as t
		join CHART        as c with (nolock, index(1)) on t.CHART_ID = c.CHART_ID;

    update
        t
    set
        t.saEffDT = sa.EFFECTIVE_DATE
        ,t.evaluate_observation_departments = sa.EVALUATE_OBSERVATION_DEPARTMENTS
    from
        #TempOER      as t
		join SERVICE_AGREEMENT as sa with (nolock) on t.service_agreement_ID = sa.SERVICE_AGREEMENT_ID;


    delete from
    #TempOER -- added 10/25/2017		
    where
        isnull(time_of_service, '1/1/1900') < saEffDT;


    ----------------------------------------------------------------------------------------------------------
	-- #TempCIR (Chart_Infusion_Result)
    -- (2016) Using this preprocessed table reduces LReads by about 50%, but duration is reduced much more (90 sec vs 6 min)
    -- tuning 10/25/2017: reads = 646K vs 5.1M; CPU = 145s vs. 453s; duration sec = 30/24 vs. 134/130 (cold/warm)
    
	if object_id('TempDB..#TempCIR', 'U') is not null drop table #TempCIR;
    
	select
        c.CHART_ID
        ,cir.CHART_INFUSION_RESULT_ID
    into #TempCIR
    from
        CHART_INFUSION_RESULT as cir with (nolock)
		join #NewlySentCharts          as c on cir.CHART_ID = c.CHART_ID;
			   

    alter table #TempCIR -- added 10/25/2017
    add
        facility_chart_ID varchar(20)
        ,service_agreement_ID int
        ,saEffDT datetime
        ,time_of_service datetime
        ,sent_date datetime
        ,patient_disposition_ID int
        ,physician_ID int
        ,facility_ID int
        ,patient_class_ID int
        ,facility_admin_chart_ID varchar(20)
        ,charge_master_ID int
        ,Units int
        ,date_of_service datetime
        ,[mod] varchar(2);

    update
        t -- added 10/25/2017
    set
        t.facility_chart_ID = c.FACILITY_CHART_ID
        ,t.service_agreement_ID = c.SERVICE_AGREEMENT_ID
        ,t.time_of_service = c.TIME_OF_SERVICE
        ,t.sent_date = c.SENT_DATE
        ,t.patient_disposition_ID = c.PATIENT_DISPOSITION_ID
        ,t.physician_ID = c.PHYSICIAN_ID
        ,t.facility_ID = c.FACILITY_ID
        ,t.patient_class_ID = c.PATIENT_CLASS_ID
        ,t.facility_admin_chart_ID = c.FACILITY_ADMIN_CHART_ID
    from
        #TempCIR as t
		join CHART        as c with (nolock, index(1)) on t.CHART_ID = c.CHART_ID;

    update
        t
    set
        t.saEffDT = sa.EFFECTIVE_DATE
    from
        #TempCIR      as t
		join SERVICE_AGREEMENT as sa with (nolock) on t.service_agreement_ID = sa.SERVICE_AGREEMENT_ID;

    update
        t -- added 10/25/2017
    set
        t.charge_master_ID = cir.CHARGE_MASTER_ID
        ,t.units = cir.UNITS
        ,t.date_of_service = cir.DATE_OF_SERVICE
        ,t.[mod] = left(cir.MODIFIERS, 2)
    from
        #TempCIR          as t
		join CHART_INFUSION_RESULT as cir with (nolock) on t.CHART_INFUSION_RESULT_ID = cir.CHART_INFUSION_RESULT_ID;

    -- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
    -- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
    
	delete from
    #TempCIR -- added 10/25/2017		
    where
        isnull(time_of_service, '1/1/1900') < saEffDT;


    ----------------------------------------------------------------------------------------------------------
	-- #TempC (CHART, filtered on Facility_Level_ID and Override_Facility_Level_ID)
    -- (2016) Using this preprocessed table reduces logical reads to 1.4M vs 508M.  Duration = 1 min vs. 28 mins.
    -- tuning 10/25/2017: reads = 931K vs 4.8M; CPU = 173s vs. 201s; duration sec = 48/14 vs. 34/24 (cold/warm)
    
	if object_id('TempDB..#TempC', 'U') is not null drop table #TempC;
    
	select
        c.CHART_ID
    into #TempC
    from
        CHART        as c with (nolock, index(1))
		join #NewlySentCharts as c2 on c2.CHART_ID = c.CHART_ID
    where
        (
            c.OVERRIDE_FACILITY_LEVEL_ID <> -1 -- this uses another NC index on CHART (idx_Chart_sa_completiondate) when the index hint is not used
            or c.FACILITY_LEVEL_ID <> -1
        );


    alter table #TempC -- added 10/25/2017
    add
        facility_chart_ID varchar(20)
        ,service_agreement_ID int
        ,time_of_service datetime
        ,sent_date datetime
        ,patient_disposition_ID int
        ,physician_ID int
        ,facility_ID int
        ,patient_class_ID int
        ,facility_admin_chart_ID varchar(20)
        ,facility_level_ID int
        ,override_facility_level_ID int;

    update
        t -- added 10/25/2017
    set
        t.facility_chart_ID = c.FACILITY_CHART_ID
        ,t.service_agreement_ID = c.SERVICE_AGREEMENT_ID
        ,t.time_of_service = c.TIME_OF_SERVICE
        ,t.sent_date = c.SENT_DATE
        ,t.patient_disposition_ID = c.PATIENT_DISPOSITION_ID
        ,t.physician_ID = c.PHYSICIAN_ID
        ,t.facility_ID = c.FACILITY_ID
        ,t.patient_class_ID = c.PATIENT_CLASS_ID
        ,t.facility_admin_chart_ID = c.FACILITY_ADMIN_CHART_ID
        ,t.facility_level_ID = c.FACILITY_LEVEL_ID
        ,t.override_facility_level_ID = c.OVERRIDE_FACILITY_LEVEL_ID
    from
        #TempC as t
		join CHART      as c with (nolock, index(1)) on t.CHART_ID = c.CHART_ID;

    ----------------------------------------------------------------------------------------------------------
	-- #TempC2 (CHART, filtered on Physician_Service_Proc_ID and Override_Physician_Service_Proc_ID)
    -- (2016) Using this preprocessed table reduces logical reads to 1.3M vs 254M.  Duration = 1 min vs. 13 mins.
    -- tuning 10/18/2017: reads = 1.1M vs 4.7M; CPU = 92s vs. 112s; duration sec = 68/8 vs. 32/10 (cold/warm)
    
	if object_id('TempDB..#TempC2', 'U') is not null drop table #TempC2;
    
	select
        c.CHART_ID
    into #TempC2
    from
        CHART        as c with (nolock, index(1))
		join #NewlySentCharts as c2 on c2.CHART_ID = c.CHART_ID
    where
        -- earlier version had note that the criteria below was changed per John on 03/14/2013 (LDH).  Used to be:  and (c.NO_PHYSICIAN_SERVICES is null or c.NO_PHYSICIAN_SERVICES = 0)
        (
            c.PHYSICIAN_SERVICE_PROC_ID <> -1
            or c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
        ); -- when the index hint is not used, this criteria causes the usage of another NC index on CHART (_dta_index_CHART_5_1907537879__K2_K165_K49_K88_K55_K23_K1_K3_K57_4_17_48_51_52_54_64_153_214)



    alter table #TempC2 -- added 10/25/2017
    add
        facility_chart_ID varchar(20)
        ,service_agreement_ID int
        ,time_of_service datetime
        ,sent_date datetime
        ,patient_disposition_ID int
        ,physician_ID int
        ,facility_ID int
        ,patient_class_ID int
        ,facility_admin_chart_ID varchar(20)
        ,physician_service_proc_ID int
        ,override_physician_service_proc_ID int
		,PHYSICIAN_SERVICE_MOD    varchar(100)
		,CHART_STATUS_ID					int	
		;

    update
        t -- added 10/25/2017
    set
         t.facility_chart_ID = c.FACILITY_CHART_ID
        ,t.service_agreement_ID = c.SERVICE_AGREEMENT_ID
        ,t.time_of_service = c.TIME_OF_SERVICE
        ,t.sent_date = c.SENT_DATE
        ,t.patient_disposition_ID = c.PATIENT_DISPOSITION_ID
        ,t.physician_ID = c.PHYSICIAN_ID
        ,t.facility_ID = c.FACILITY_ID
        ,t.patient_class_ID = c.PATIENT_CLASS_ID
        ,t.facility_admin_chart_ID = c.FACILITY_ADMIN_CHART_ID
        ,t.physician_service_proc_ID = c.PHYSICIAN_SERVICE_PROC_ID
        ,t.override_physician_service_proc_ID = c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		,t.PHYSICIAN_SERVICE_MOD = c.PHYSICIAN_SERVICE_MOD
		,t.CHART_STATUS_ID		= c.CHART_STATUS_ID
    from
        #TempC2 as t
		join CHART       as c with (nolock, index(1)) on t.CHART_ID = c.CHART_ID;


   alter table #TempC2	
	add 
	SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EFFECTIVE_DATE  datetime,
	SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE datetime


	update x		
	set 
		x.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EFFECTIVE_DATE = sa.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EFFECTIVE_DATE,
		x.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE = sa.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE

	from #TempC2 as x
		join service_agreement as sa with(nolock, index(1)) on x.service_agreement_id = sa.service_agreement_id;

    ----------------------------------------------------------------------------------------------------------
	-- #TempPPE (Physician_Procedure_Evaluation)
    -- tuning 10/25/2017 with #TempPPE vs. without: reads = 533K vs 51M/28M (warm/cold); CPU = 31s vs. 64s; duration sec = 3/2 vs. 414/35 (cold/warm)
    
	if object_id('TempDB..#TempPPE', 'U') is not null drop table #TempPPE; -- added new section 10/25/2017 (was not previously using temp table for PPE)
    
	select
        c.CHART_ID
        ,ppe.PHYSICIAN_PROCEDURE_ID
        ,ppe.PROCEDURE_DATE
        ,ppe.QUANTITY
        ,PhysicianID_PPE = ppe.PHYSICIAN_ID
    into #TempPPE
    from
        PHYSICIAN_PROCEDURE_EVALUATION as ppe with (nolock)
		join #NewlySentCharts                   as c on ppe.CHART_ID = c.CHART_ID;


    alter table #TempPPE
    add
        facility_chart_ID varchar(20)
        ,service_agreement_ID int
        ,saEffDT datetime
        ,time_of_service datetime
        ,sent_date datetime
        ,patient_disposition_ID int
        ,physician_ID int
        ,facility_ID int
        ,patient_class_ID int
        ,facility_admin_chart_ID varchar(20);

    update
        t
    set
        t.facility_chart_ID = c.FACILITY_CHART_ID
        ,t.service_agreement_ID = c.SERVICE_AGREEMENT_ID
        ,t.time_of_service = c.TIME_OF_SERVICE
        ,t.sent_date = c.SENT_DATE
        ,t.patient_disposition_ID = c.PATIENT_DISPOSITION_ID
        ,t.physician_ID = c.PHYSICIAN_ID
        ,t.facility_ID = c.FACILITY_ID
        ,t.patient_class_ID = c.PATIENT_CLASS_ID
        ,t.facility_admin_chart_ID = c.FACILITY_ADMIN_CHART_ID
    from
        #TempPPE as t
		join CHART        as c with (nolock, index(1)) on t.CHART_ID = c.CHART_ID;

    update
        t
    set
        t.saEffDT = sa.EFFECTIVE_DATE
    from
        #TempPPE      as t
		join SERVICE_AGREEMENT as sa with (nolock) on t.service_agreement_ID = sa.SERVICE_AGREEMENT_ID;


    delete from
    #TempPPE
    where
        isnull(time_of_service, '1/1/1900') < saEffDT;

    ----------------------------------------------------------------------------------------------------------
	-- #TempCPI (Chart_Package_Item)
    -- tuning 10/25/2017 with #TempCPI vs. without:
    
	if object_id('TempDB..#TempCPI', 'U') is not null drop table #TempCPI; -- added new section 10/25/2017 (was not previously using temp table for CPI)
    
	select
        c.CHART_ID
        ,cpi.CHART_PACKAGE_ITEM_ID
        ,cpi.UNITS
        ,cpi.CHARGE_PACKAGE_ITEM_ID
    into #TempCPI
    from
        CHART_PACKAGE_ITEM cpi with (nolock)
		join #NewlySentCharts       as c on cpi.CHART_ID = c.CHART_ID;


    alter table #TempCPI
    add
        facility_chart_ID varchar(20)
        ,service_agreement_ID int
        ,saEffDT datetime
        ,time_of_service datetime
        ,sent_date datetime
        ,patient_disposition_ID int
        ,physician_ID int
        ,facility_ID int
        ,patient_class_ID int
        ,facility_admin_chart_ID varchar(20);

    update
        t
    set
        t.facility_chart_ID = c.FACILITY_CHART_ID
        ,t.service_agreement_ID = c.SERVICE_AGREEMENT_ID
        ,t.time_of_service = c.TIME_OF_SERVICE
        ,t.sent_date = c.SENT_DATE
        ,t.patient_disposition_ID = c.PATIENT_DISPOSITION_ID
        ,t.physician_ID = c.PHYSICIAN_ID
        ,t.facility_ID = c.FACILITY_ID
        ,t.patient_class_ID = c.PATIENT_CLASS_ID
        ,t.facility_admin_chart_ID = c.FACILITY_ADMIN_CHART_ID
    from
        #TempCPI as t
		join CHART        as c with (nolock, index(1)) on t.CHART_ID = c.CHART_ID;

    update
        t
    set
        t.saEffDT = sa.EFFECTIVE_DATE
    from
        #TempCPI      as t
		join SERVICE_AGREEMENT as sa with (nolock) on t.service_agreement_ID = sa.SERVICE_AGREEMENT_ID;

    -- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
    -- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
    delete from
    #TempCPI
    where
        isnull(time_of_service, '1/1/1900') < saEffDT;


    ----------------------------------------------------------------------------------------------------------
	-- #TempCAP (Chart_Additional_Procedure)
    -- tuning 10/25/2017 with #TempCAP vs. without:
    
	if object_id('TempDB..#TempCAP', 'U') is not null drop table #TempCAP; -- added new section 10/25/2017 (was not previously using temp table for CAP)
    
	select
        c.CHART_ID
        ,cap.CHART_ADDITIONAL_PROCEDURE_ID
        ,cap.PROCEDURE_DATE
        ,cap.QUANTITY
        ,cap.CHARGE_MASTER_ID
        ,cap.CLASS
    into #TempCAP
    from
        CHART_ADDITIONAL_PROCEDURE as cap with (nolock)
		join #NewlySentCharts               as c on cap.CHART_ID = c.CHART_ID;


    alter table #TempCAP
    add
        facility_chart_ID varchar(20)
        ,service_agreement_ID int
        ,saEffDT datetime
        ,time_of_service datetime
        ,sent_date datetime
        ,patient_disposition_ID int
        ,physician_ID int
        ,facility_ID int
        ,patient_class_ID int
        ,facility_admin_chart_ID varchar(20);

    update
        t
    set
        t.facility_chart_ID = c.FACILITY_CHART_ID
        ,t.service_agreement_ID = c.SERVICE_AGREEMENT_ID
        ,t.time_of_service = c.TIME_OF_SERVICE
        ,t.sent_date = c.SENT_DATE
        ,t.patient_disposition_ID = c.PATIENT_DISPOSITION_ID
        ,t.physician_ID = c.PHYSICIAN_ID
        ,t.facility_ID = c.FACILITY_ID
        ,t.patient_class_ID = c.PATIENT_CLASS_ID
        ,t.facility_admin_chart_ID = c.FACILITY_ADMIN_CHART_ID
    from
        #TempCAP as t
		join CHART        as c with (nolock, index(1)) on t.CHART_ID = c.CHART_ID;

    update
        t
    set
        t.saEffDT = sa.EFFECTIVE_DATE
    from
        #TempCAP      as t
		join SERVICE_AGREEMENT as sa with (nolock) on t.service_agreement_ID = sa.SERVICE_AGREEMENT_ID;

    -- Postponing the DELETE until this point (after populating saEffDT in separate step) avoids using any NC indexes on CHART except 
    -- idx_chart_sa_chtstatid_chartid which is used for initial population of the temp table.
    delete from
    #TempCAP
    where
        isnull(time_of_service, '1/1/1900') < saEffDT;


    ----------------------------------------------------------------------------------------------------------------------------------
	-- now run separate INSERT queries into #SentProcedure, all of which will refer to preprocessed tables populated above.
    -- Separating the INSERTs performs better than UNIONs in this case, and also makes it easier to analzye the performance of each step

    -- first create a temp table to gather preliminary results
    
	if object_id('TempDB..#SentProcedure', 'U') is not null drop table #SentProcedure;


	create table #SentProcedure		
(		
	     CLASS						varchar(2)
        ,CHART_ID					int
        ,FACILITY_CHART_ID			varchar(20)
        ,SERVICE_AGREEMENT_ID		int
        ,TIME_OF_SERVICE			datetime
        ,SENT_DATE					datetime
        ,PATIENT_DISPOSITION_ID		int
        ,PHYSICIAN_ID				int
        ,BILLING_CODE				varchar(20)
        ,CPT_CODE					varchar(5)
		,[MOD]						varchar(100)
        ,QUANTITY					int
        ,FACILITY_ID				int
        ,PATIENT_CLASS_ID			int
        ,ADJUSTMENT_IND				varchar(1)
        ,CHARGE_MASTER_ID			int
        ,LEVEL_ID					int
        ,FACILITY_ADMIN_CHART_ID	varchar(20)	
        ,SOURCE_ID					int
        ,SOURCE_CD					varchar(2)
)
    --into #SentProcedure
    --from
    --    RevCycleTransactionSnapshot..Sent_Procedure
    --where
    --    1 = 0;


    insert into #SentProcedure
    select
        'FP'                                                        as CLASS
        ,c.CHART_ID
        ,c.FACILITY_CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,coalesce(c.PROCEDURE_DATE, c.TIME_OF_SERVICE)              TIME_OF_SERVICE
        ,c.SENT_DATE
        ,c.PATIENT_DISPOSITION_ID
        ,case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID end     as PHYSICIAN_ID
        ,isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE) BILLING_CODE
        ,cm.CPT_CODE
		,NULL -- ***********
        ,c.QUANTITY
        ,c.facility_id
        ,case
             when c.PATIENT_CLASS_ID <> -1 then c.PATIENT_CLASS_ID
         else
         (
             select
                 max(pc.PATIENT_CLASS_ID)
             from
                 PATIENT_CLASS pc with (nolock)
             where
                 pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                 and pc.DEFAULT_IND = 1
         ) end                                                      as patient_class_id
        ,'N'                                                        as ADJUSTMENT_IND
        ,cm.CHARGE_MASTER_ID
        ,0                                                          as LEVEL_ID
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.FACILITY_PROCEDURE_ID                                    as source_id
        ,'FP'                                                       as source_cd
    from
        #TempFPE  as c
		join CHARGE_MASTER as cm with (nolock) on cm.CHARGE_MASTER_ID = c.FACILITY_PROCEDURE_ID;



    -- this INSERT was not using a preprocessed table, but now it does (#TempCPI) 10/25/2017
    insert into #SentProcedure
    select
        'FP'                                                        as CLASS -- Package Items (e.g. generated supplies)
        ,c.CHART_ID
        ,c.FACILITY_CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,c.TIME_OF_SERVICE
        ,c.SENT_DATE
        ,c.PATIENT_DISPOSITION_ID
        ,case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID end     as PHYSICIAN_ID
        ,isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE) BILLING_CODE
        ,cm.CPT_CODE
		,NULL -- **********
        ,c.UNITS                                                    Quantity
        ,c.facility_id
        ,case
             when c.PATIENT_CLASS_ID <> -1 then c.PATIENT_CLASS_ID
         else
         (
             select
                 max(pc.PATIENT_CLASS_ID)
             from
                 PATIENT_CLASS pc with (nolock)
             where
                 pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                 and pc.DEFAULT_IND = 1
         ) end                                                      as patient_class_id
        ,'N'                                                        as ADJUSTMENT_IND
        ,cm.CHARGE_MASTER_ID
        ,0                                                          as LEVEL_ID
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.CHART_PACKAGE_ITEM_ID                                    source_id
        ,'PI'                                                       as source_cd
    from
        #TempCPI        as c
		join CHARGE_PACKAGE_ITEM as ci with (nolock) on c.CHARGE_PACKAGE_ITEM_ID = ci.CHARGE_PACKAGE_ITEM_ID
		join CHARGE_MASTER       as cm with (nolock) on cm.CHARGE_MASTER_ID = ci.CHARGE_MASTER_ID;


    -- this INSERT was not efficiently using the preprocessed table, but now it does.
    insert into #SentProcedure
    select
        'FP'                                                        as CLASS
        ,c.CHART_ID
        ,c.FACILITY_CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,coalesce(c.[DATE_OF_SERVICE], c.TIME_OF_SERVICE)           TIME_OF_SERVICE
        ,c.SENT_DATE
        ,c.PATIENT_DISPOSITION_ID
        ,case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID end     as PHYSICIAN_ID
        ,isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE) BILLING_CODE
        ,cm.CPT_CODE
		,NULL --  ******
        ,c.[UNITS]
        ,c.facility_id
        ,case
             when c.PATIENT_CLASS_ID <> -1 then c.PATIENT_CLASS_ID
         else
         (
             select
                 max(pc.PATIENT_CLASS_ID)
             from
                 PATIENT_CLASS pc with (nolock)
             where
                 pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                 and pc.DEFAULT_IND = 1
         ) end                                                      as patient_class_id
        ,'N'                                                        as ADJUSTMENT_IND
        ,cm.CHARGE_MASTER_ID
        ,0                                                          as LEVEL_ID
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.[CHART_OBSERVATION_ENCOUNTER_RESULT_ID]                  as source_id
        ,'OP'                                                       as source_cd
    from
        #TempOER  as c
		join CHARGE_MASTER as cm with (nolock) on c.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
    where
        c.PATIENT_DISPOSITION_ID = 5 -- Observation
        and c.EVALUATE_OBSERVATION_DEPARTMENTS = 1;



    insert into #SentProcedure
    select
        'IP'                                                    as CLASS
        ,c.CHART_ID
        ,c.FACILITY_CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,coalesce(c.DATE_OF_SERVICE, c.TIME_OF_SERVICE)         TIME_OF_SERVICE
        ,c.SENT_DATE
        ,c.PATIENT_DISPOSITION_ID
        ,case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID end as PHYSICIAN_ID
        ,case
             when c.mod = '' then isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE)
         else
             isnull((
                        select
                            cmod.BILLING_CODE
                        from
                            charge_master_modifier cmod with (nolock)
                        where
                            cmod.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
                            and cmod.SERVICE_AGREEMENT_ID = c.service_agreement_ID
                            and cmod.MODIFIER = c.mod
                            and len(cmod.BILLING_CODE) > 0
                    )
                       ,isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE)
                   )end                                         as BILLING_CODE
        ,cm.CPT_CODE
		,NULL -- *****
        ,c.UNITS                                                Quantity
        ,c.facility_id
        ,case
             when c.PATIENT_CLASS_ID <> -1 then c.PATIENT_CLASS_ID
         else
         (
             select
                 max(pc.PATIENT_CLASS_ID)
             from
                 PATIENT_CLASS pc with (nolock)
             where
                 pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                 and pc.DEFAULT_IND = 1
         ) end                                                  as patient_class_id
        ,'N'                                                    as ADJUSTMENT_IND
        ,cm.CHARGE_MASTER_ID
        ,0                                                      as LEVEL_ID
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.CHART_INFUSION_RESULT_ID                             as source_id
        ,'IP'                                                   as source_cd
    from
        #TempCIR  as c
		join CHARGE_MASTER as cm with (nolock) on cm.CHARGE_MASTER_ID = c.CHARGE_MASTER_ID;



    -- this INSERT wasn't using a preprocessed table, but needed to badly (55M reads).  Now it does.  10/25/2017
    insert into #SentProcedure
    select
        'PP'                                           as Class
        ,c.CHART_ID
        ,c.FACILITY_CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,coalesce(c.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE
        ,c.SENT_DATE
        ,c.PATIENT_DISPOSITION_ID
        ,case
             when
             (
                 c.PhysicianID_PPE = -1
                 or c.PhysicianID_PPE is null
             ) then c.PHYSICIAN_ID
         else c.PhysicianID_PPE end                    as PHYSICIAN_ID
        ,cm.BILLING_CODE
        ,cm.CPT_CODE
		,NULL -- *****
        ,c.QUANTITY
        ,c.facility_id
        ,case
             when c.PATIENT_CLASS_ID <> -1 then c.PATIENT_CLASS_ID
         else
         (
             select
                 max(pc.PATIENT_CLASS_ID)
             from
                 PATIENT_CLASS pc with (nolock)
             where
                 pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                 and pc.DEFAULT_IND = 1
         ) end                                         as patient_class_id
        ,'N'                                           as ADJUSTMENT_IND
        ,cm.CHARGE_MASTER_ID
        ,0                                             as LEVEL_ID
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.PHYSICIAN_PROCEDURE_ID                      source_id
        ,'PP'                                          as source_cd
    from
        #TempPPE  as c
		join CHARGE_MASTER as cm with (nolock) on cm.CHARGE_MASTER_ID = c.PHYSICIAN_PROCEDURE_ID;



    -- (2016) This next query was the most expensive step before tuning.
    insert into #SentProcedure
    select
        'FL'                                                    as Class
        ,c.CHART_ID
        ,c.FACILITY_CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,c.TIME_OF_SERVICE
        ,c.SENT_DATE
        ,patient_disposition_id                                 = isnull(c.patient_disposition_ID, 1) -- (2016) logic for populating patient_disposition_id has been moved to an UPDATE statement right after this INSERT (performs much better)
        ,case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID end as PHYSCISIAN_ID
        ,fl.BILLING_CODE
        ,fl.CPT_CODE
		,NULL -- *******
        ,1                                                      as QUANTITY
        ,c.facility_id
        ,case
             when c.PATIENT_CLASS_ID <> -1 then c.PATIENT_CLASS_ID
         else
         (
             select
                 max(pc.PATIENT_CLASS_ID)
             from
                 PATIENT_CLASS pc with (nolock)
             where
                 pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                 and pc.DEFAULT_IND = 1
         ) end                                                  as patient_class_id
        ,'N'                                                    as ADJUSTMENT_IND
        ,coalesce((
                      select
                          max(cm.CHARGE_MASTER_ID)
                      from
                          CHARGE_MASTER cm with (nolock)
                      where
                          cm.BILLING_CODE = fl.BILLING_CODE
                          and cm.CPT_CODE = fl.CPT_CODE
                          and cm.SERVICE_AGREEMENT_ID = fl.SERVICE_AGREEMENT_ID
                          and cm.CHARGE_MASTER_USAGE_CODE = 2
                          and cm.EFFECTIVE_DATE <= getdate()
                          and cm.EXPIRATION_DATE >= getdate()
                          and
                          (
                              cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
                              or cm.PATIENT_CLASS_ID = -1
                          )
                  )
                     ,null
                 )                                              as charge_master_id
        ,(case
              when c.OVERRIDE_FACILITY_LEVEL_ID = -1 then c.FACILITY_LEVEL_ID
              when c.OVERRIDE_FACILITY_LEVEL_ID = '' then c.FACILITY_LEVEL_ID
          else c.OVERRIDE_FACILITY_LEVEL_ID end
         )                                                      LEVEL_ID
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.CHART_ID                                             as source_id
        ,'FL'                                                   as source_cd
    from
        #TempC as c
        ,FACILITY_LEVEL fl with (nolock)
    where
        (case
             when c.OVERRIDE_FACILITY_LEVEL_ID = -1 then c.FACILITY_LEVEL_ID
             when c.OVERRIDE_FACILITY_LEVEL_ID = '' then c.FACILITY_LEVEL_ID
         else c.OVERRIDE_FACILITY_LEVEL_ID end
        ) = fl.FACILITY_LEVEL_ID;



    -- (2016) moved the logic here for populating patient_disposition_ID due to significant performance benefit
    update
        #SentProcedure
    set
        patient_disposition_ID = 4
    where
        patient_disposition_ID in (-1, 0)
        and source_cd = 'FL'
        and
        (
            chart_ID in
            (
                select
                    fse.CHART_ID
                from
                    FACILITY_SERVICE_EVALUATION fse
                    ,FACILITY_SERVICE fs
                where
                    fse.CHART_ID = #SentProcedure.CHART_ID
                    and fse.FACILITY_SERVICE_ID is not null
                    and fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID
                    and
                    (
                        left(fs.DESCRIPTION, 9) = 'Admission'
                        or left(fs.DESCRIPTION, 5) = 'Admit'
                    )
            )
            or chart_ID in
               (
                   select
                       fse.CHART_ID
                   from
                       FACILITY_SERVICE_EVALUATION fse
                       ,FACILITY_SERVICE_SCHEDULE_ITEM fssi
                   where
                       fse.CHART_ID = #SentProcedure.CHART_ID
                       and fse.FACILITY_SERVICE_SCHEDULE_ID = fssi.FACILITY_SERVICE_SCHEDULE_ID
                       and fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fssi.FACILITY_SERVICE_SCHEDULE_ITEM_ID
                       and
                       (
                           left(fssi.DESCRIPTION, 9) = 'Admission'
                           or left(fssi.DESCRIPTION, 5) = 'Admit'
                           or left(fssi.DESCRIPTION, 12) = 'Direct Admit'
                       )
               )
        );


    -- (2016) clean up any remaining records where patient_disposition_ID in (-1, 0)
    update
        #SentProcedure
    set
        patient_disposition_ID = 1
    where
        patient_Disposition_ID in (-1, 0)
        and source_cd = 'FL';



    insert into #SentProcedure
    select
        'PL'                                                    as Class
        ,c.CHART_ID
        ,c.FACILITY_CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,c.TIME_OF_SERVICE
        ,c.SENT_DATE
        ,patient_disposition_id                                 = isnull(c.patient_disposition_ID, 1) -- (2016) logic for populating patient_disposition_id has been moved to an UPDATE statement right after this INSERT (performs much better)
        ,case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID end as PHYSICIAN_ID
        ,(
             select
                 psp.BILLING_CODE
             from
                 PHYSICIAN_SERVICE_PROCEDURE psp with (nolock)
             where
                 psp.PHYSICIAN_SERVICE_PROC_ID = (case
                                                      when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null
                                                           and c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1 then
                                                          c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                                                  else c.PHYSICIAN_SERVICE_PROC_ID end
                                                 )
         )                                                      as BILLING_CD
        ,(
             select
                 psp.CPT_CODE
             from
                 PHYSICIAN_SERVICE_PROCEDURE psp with (nolock)
             where
                 psp.PHYSICIAN_SERVICE_PROC_ID = (case
                                                      when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null
                                                           and c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1 then
                                                          c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                                                  else c.PHYSICIAN_SERVICE_PROC_ID end
                                                 )
         )                                                      as CPT_CD

,c.PHYSICIAN_SERVICE_MOD as [MOD]

        ,1                                                      as Quantity
        ,c.FACILITY_ID
        ,case
             when c.PATIENT_CLASS_ID <> -1 then c.PATIENT_CLASS_ID
         else
         (
             select
                 max(pc.PATIENT_CLASS_ID)
             from
                 PATIENT_CLASS pc with (nolock)
             where
                 pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                 and pc.DEFAULT_IND = 1
         ) end                                                  as patient_class_id
        ,'N'                                                    as ADJUSTMENT_IND
        ,coalesce((
                      select
                          max(cm.CHARGE_MASTER_ID)
                      from
                          CHARGE_MASTER cm with (nolock)
                      where
                          cm.BILLING_CODE = psp.BILLING_CODE
                          and cm.CPT_CODE = psp.CPT_CODE
                          and cm.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
                          and cm.CHARGE_MASTER_USAGE_CODE = 4
                          and cm.EFFECTIVE_DATE <= getdate()
                          and cm.EXPIRATION_DATE >= getdate()
                          and
                          (
                              cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
                              or cm.PATIENT_CLASS_ID = -1
                          )
                  )
                     ,null
                 )                                              as charge_master_id
        ,(
             select
                 psp.PHYSICIAN_SERVICE_PROC_ID
             from
                 PHYSICIAN_SERVICE_PROCEDURE psp with (nolock)
             where
                 psp.PHYSICIAN_SERVICE_PROC_ID = (case
                                                      when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null
                                                           and c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1 then
                                                          c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                                                  else c.PHYSICIAN_SERVICE_PROC_ID end
                                                 )
         )                                                      as LEVEL_ID
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.CHART_ID                                             as source_id
        ,'PL'                                                   as source_cd
    from
        #TempC2 as c
        ,SERVICE_AGREEMENT sa with (nolock)
        ,PHYSICIAN_SERVICE_PROCEDURE as psp with (nolock)
    where
        sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
        and sa.EVALUATE_PHYSICIAN_SVC = 1
        and c.TIME_OF_SERVICE >= sa.EFFECTIVE_DATE
        and (case
                 when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null
                      and c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1 then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
             else c.PHYSICIAN_SERVICE_PROC_ID end
            ) = psp.PHYSICIAN_SERVICE_PROC_ID;

-- *******
-- Additional Levels   

insert into #SentProcedure
select
		'PL'																			 as Class
		,c.CHART_ID
        ,c.FACILITY_CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,cplos2.Date_OF_SERVICE															as TIME_OF_SERVICE
        ,c.SENT_DATE
        ,patient_disposition_id  
		,cplos2.provider_id																as Provider_ID		
		,NULL																			as Billing_CD
		,psp3.cpt_code                                                                  as CPT_CD
		,NULL as MOD
		,1    as Quantity
		,c.FACILITY_ID
		,cplos2.PATIENT_CLASS_ID
		,'N'   as Adjustment_Ind
		,NULL  as Charge_Master_ID
		,NULL  as Level_ID
		,c.Facility_Admin_Chart_ID	
		,c.CHART_ID as Source_ID
		,'PL'as Source_CD
--		,psp2.cpt_code																 as Provider_Selected_E_M
--		,psp2.Modifier                                                               as Provider_Selected_Modifier

--		,psp.cpt_code                                                                as Physician_Service_CPT		--CH Selected E/M
--		,psp.Modifier                                                                as Physician_Service_MOD
		


	from
		#TempC2 c    		
		left outer join CHART_PHYSICIAN_LEVEL_OF_SERVICE cplos1 on c.chart_id = cplos1.chart_id
		left outer join PHYSICIAN_SERVICE_PROCEDURE psp on psp.PHYSICIAN_SERVICE_PROC_ID = cplos1.PHYSICIAN_SERVICE_PROC_ID
		left outer join CHART_PHYSICIAN_LEVEL_OF_SERVICE cplos2 on c.chart_id = cplos2.chart_id
		left outer join PHYSICIAN_SERVICE_PROCEDURE psp2 on cplos2.Provider_Specified_Los_Physician_Service_Proc_ID = psp2.PHYSICIAN_SERVICE_PROC_ID
        left outer join FACILITY_PROFESSIONAL fp on cplos2.provider_id = fp.FACILITY_PROF_ID
		left outer join PHYSICIAN_SERVICE_PROCEDURE psp3 on -- Override
															psp3.PHYSICIAN_SERVICE_PROC_ID = cplos2.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID

		--inner join FACILITY f on f.FACILITY_ID = c.FACILITY_ID
		
		where 
		
		cplos1.chart_id = cplos2.chart_id
		and cplos1.level_number = cplos2.level_number				
		and c.TIME_OF_SERVICE between isnull(c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EFFECTIVE_DATE,'01/01/1900') and isnull(c.SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE,'12/31/2099')
 		and c.CHART_STATUS_ID = 5 -- Sent  
		

-- select * from #TempC2


-- *******

    -- (2016) moved the logic here for populating patient_disposition_ID due to significant performance benefit
    update
        #SentProcedure
    set
        patient_disposition_ID = 4
    where
        patient_disposition_ID in (-1, 0)
        and source_cd = 'PL'
        and
        (
            chart_ID in
            (
                select
                    fse.CHART_ID
                from
                    FACILITY_SERVICE_EVALUATION fse
                    ,FACILITY_SERVICE fs
                where
                    fse.CHART_ID = #SentProcedure.CHART_ID
                    and fse.FACILITY_SERVICE_ID is not null
                    and fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID
                    and
                    (
                        left(fs.DESCRIPTION, 9) = 'Admission'
                        or left(fs.DESCRIPTION, 5) = 'Admit'
                    )
            )
            or chart_ID in
               (
                   select
                       fse.CHART_ID
                   from
                       FACILITY_SERVICE_EVALUATION fse
                       ,FACILITY_SERVICE_SCHEDULE_ITEM fssi
                   where
                       fse.CHART_ID = #SentProcedure.CHART_ID
                       and fse.FACILITY_SERVICE_SCHEDULE_ID = fssi.FACILITY_SERVICE_SCHEDULE_ID
                       and fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fssi.FACILITY_SERVICE_SCHEDULE_ITEM_ID
                       and
                       (
                           left(fssi.DESCRIPTION, 9) = 'Admission'
                           or left(fssi.DESCRIPTION, 5) = 'Admit'
                           or left(fssi.DESCRIPTION, 12) = 'Direct Admit'
                       )
               )
        );


    -- (2016) clean up any remaining records where patient_disposition_ID in (-1, 0)
    update
        #SentProcedure
    set
        patient_disposition_ID = 1
    where
        patient_Disposition_ID in (-1, 0)
        and source_cd = 'PL';



    -- this INSERT was not using a preprocessed table, but now it does (#TempCAP) 10/25/2017
    -- ACS-7351: CHART_ADDITIONAL_PROCEDURE
    insert into #SentProcedure
    select
        c.CLASS
        ,c.CHART_ID
        ,c.FACILITY_CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,coalesce(c.PROCEDURE_DATE, c.TIME_OF_SERVICE)              TIME_OF_SERVICE
        ,c.SENT_DATE
        ,c.PATIENT_DISPOSITION_ID
        ,case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID end     as PHYSICIAN_ID
        ,isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE) BILLING_CODE
        ,cm.CPT_CODE
        ,NULL -- *******
		,c.QUANTITY		
        ,c.facility_id
        ,case
             when c.PATIENT_CLASS_ID <> -1 then c.PATIENT_CLASS_ID
         else
         (
             select
                 max(pc.PATIENT_CLASS_ID)
             from
                 PATIENT_CLASS pc with (nolock)
             where
                 pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                 and pc.DEFAULT_IND = 1
         ) end                                                      as patient_class_id
        ,'N'                                                        as ADJUSTMENT_IND
        ,cm.CHARGE_MASTER_ID
        ,0                                                          as LEVEL_ID
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.CHART_ADDITIONAL_PROCEDURE_ID                            as source_id
        ,'AP'                                                       as source_cd
    from
        #TempCAP  as c
		join CHARGE_MASTER as cm with (nolock) on c.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID;


    ----------------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------------


-- Test parameters
--declare @Facility int = 1539;
--declare @StartDate date = '04/03/2025';
--declare @EndDate date =  '04/03/2025';




-- Step 1 Pull from chart table 

if object_id('TempDB..#chart1', 'U') is not null drop table #chart1;
 
 

select 
sent_date,
chart_id, 
facility_chart_id as Patient_ID,
medical_record_num as MRN,
patient_last_name + ', ' +patient_first_name as Patient_Name,
Patient_DOB,
time_of_service as DOS,
facility_id,
PHYSICIAN_ID,
NURSE_PRACTITIONER_ID,
PROVIDER_EVAL_PERFORMED_BY_IND,

case when NURSE_PRACTITIONER_ID > 0					
		AND (					
			PROVIDER_EVAL_PERFORMED_BY_IND IS NULL				
			OR PROVIDER_EVAL_PERFORMED_BY_IND = 1				
			)				
		THEN NURSE_PRACTITIONER_ID					
	ELSE PHYSICIAN_ID	end as EVAL_PHYSICIAN,

PHYSICIAN_SERVICE_MOD,
Coder_Comment
into #chart1
from chart
where 
facility_id in (@Facility) 
and chart_status_id = 5
and cast(sent_date as date) between @StartDate and  @EndDate
and service_agreement_id in ( 1487, 1490) -- restricts to 'Ann & Robert H. Lurie Children's Hosp of Chicago' only
;



-- Step 2  -- Sent Procedure Lookup

if object_id('TempDB..#sent_procedure1', 'U') is not null drop table #sent_procedure1;

select 
c.*, 
sp.class,
sp.billing_code, 
sp.cpt_code,
sp.quantity,
sp.physician_id as sp_physician_id,
sp.charge_master_id,
sp.level_id,
sp.MOD as [MOD],
sp.time_of_service,
case when sp.physician_id is null then c.EVAL_PHYSICIAN else sp.physician_id end as Provider
into #sent_procedure1
from 
#SentProcedure sp, 
#chart1 c
where sp.chart_id = c.chart_id
and class in ( 'PL', 'IP', 'FL' );     




-- Step 3  Create Detail Table



if object_ID('TempDB..#Details1', 'U') is not null DROP TABLE #Details1;							
create table #Details1
(							
	  chart_ID		int					
	, Patient_ID	varchar(20)					
	, MRN			varchar(20)
	, Patient_Name  varchar(60)
	, Patient_DOB   datetime				
	, DOS			datetime				
	, sent_date		datetime
	, billing_code	varchar(20)	
	, cpt_code		varchar(5)	
	, quantity		int
	, facility_id   int	
    , modifiers     varchar(20) 
    , p_id          int 
    , PerformingProvider2 varchar(60)
    , icd_10_code   varchar(200)
	, PROCESS_ORDER		int	
    , POSTING_ORDER int
	, CODER_COMMENT varchar(2000)
);							


-- insert PL data  

INSERT INTO #Details1
SELECT 		
sp.chart_id, sp.patient_id, sp.mrn, sp.patient_name, sp.Patient_DOB, sp.time_of_service, sp.sent_date, 
sp.billing_code, 
sp.cpt_code, 
sp.quantity, 
sp.facility_id,
sp.mod as modifiers, -- sp.PHYSICIAN_SERVICE_MOD as modifiers, 
sp.provider as p_id,
(select last_name + ', ' + first_name from Facility_Professional where facility_prof_ID = sp.provider) as PerformingProvider2,
'' as [ICD10_Code]	,  
1 as PROCESS_ORDER,
0 as Posting_order,
'' as CODER_COMMENT
from 
 #sent_procedure1 sp
 where 
 sp.class = 'PL'
 ;



-- insert FL data  

INSERT INTO #Details1
SELECT 		
sp.chart_id, sp.patient_id, sp.mrn, sp.patient_name, sp.Patient_DOB, sp.dos, sp.sent_date, 
sp.billing_code, 
sp.cpt_code, 
sp.quantity, 
sp.facility_id,
sp.PHYSICIAN_SERVICE_MOD as modifiers, 
sp.provider as p_id,
(select last_name + ', ' + first_name from Facility_Professional where facility_prof_ID = sp.provider) as PerformingProvider2,
'' as [ICD10_Code]	,  
2 as PROCESS_ORDER,
0 as Posting_order,
'' as CODER_COMMENT
from 
 #sent_procedure1 sp
 where 
 sp.class = 'FL';





 -- Step 4A  -- Insert ICD10/Diagnosis Codes

 if object_ID('TempDB..#Temp_Details1', 'U') is not null DROP TABLE #Temp_Details1;

 SELECT 		
c.chart_id, 
c.patient_id, c.mrn, c.patient_name, c.Patient_DOB, c.DOS, c.sent_date, 
'' billing_code , 
'' cpt_code, 
'' as quantity, 
c.facility_id,
'' as modifiers, 
c.eval_physician as p_id,
'' as PerformingProvider2,
icd10.icd10_code,
3 as Process_Order,
icd10.posting_order
,icd10.DIAGNOSIS_TYPE_ID 
,icd10.IS_PRIMARY
,c.Coder_Comment
into  #Temp_Details1
from 
#chart1 c,
 Chart_Diagnosis_Code_ICD10 icd10
  where c.chart_id = icd10.chart_id;



 

  
  
  delete from #Temp_Details1
  where  (DIAGNOSIS_TYPE_ID = 1 and IS_PRIMARY = 1 );


INSERT INTO #Details1
 SELECT 		
chart_id, 
patient_id, mrn, patient_name, Patient_DOB, DOS, sent_date, 
billing_code, 
cpt_code, 
'' as quantity, 
facility_id,
'' as modifiers, 
p_id,
(select last_name + ', ' + first_name from Facility_Professional where facility_prof_ID = #Temp_Details1.p_id) as PerformingProvider2,

icd10_code,
Process_Order,
posting_order,
coder_comment
from 
#Temp_Details1;
 
 
 



 -- Insert Facility Procedure Data



INSERT INTO #Details1
SELECT 		
c.chart_id, c.patient_id, c.mrn, c.patient_name, c.Patient_DOB, c.dos, c.sent_date, 
cm.billing_code, cm.cpt_code, 
fpe.quantity, 
c.facility_id,
fpe.modifiers, 
fpe.physician_id as p_id,
(select last_name + ', ' + first_name from Facility_Professional where facility_prof_ID = fpe.physician_id) as PerformingProvider2,
fpe.icd_10_code,
4 as Process_Order,
0 as posting_order,
c.coder_comment
from 
#chart1 c
left outer join FACILITY_PROCEDURE_EVALUATION fpe on c.chart_id = fpe.chart_id
inner join CHARGE_MASTER cm ON cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID;









-- Insert Physician Procedure Data

INSERT INTO #Details1
SELECT 		
c.chart_id, c.patient_id, c.mrn, c.patient_name, c.Patient_DOB, c.dos, c.sent_date, 
cm.billing_code, cm.cpt_code, 
ppe.quantity, 
c.facility_id,
ppe.modifiers, 
ppe.physician_id as p_id,
(select last_name + ', ' + first_name from Facility_Professional where facility_prof_ID = ppe.physician_id) as PerformingProvider2,
ppe.icd_10_code,
5 as Process_Order,
0 as posting_order,
c.coder_comment
from 
#chart1 c
left outer join PHYSICIAN_PROCEDURE_EVALUATION ppe on c.chart_id = ppe.chart_id
inner join CHARGE_MASTER cm ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID;








	  ---------------
-- Insert  I/I

	  INSERT INTO #Details1
 select 
					c.chart_id, c.patient_id, c.mrn, c.patient_name, c.Patient_DOB, c.dos, c.sent_date,
					cm.billing_code,
					cm.cpt_code,
					cir.units as quantity,
					c.facility_id,
					cir.modifiers,  -- Modifiers where different in Sent_procedure table chart _id 65335059 as example
									-- Lookup how Sent Procedure gathers Performing Physician for I/I, use this for now   **** 


 
(select max(provider) from #sent_procedure1 where class = 'IP' and chart_id = c.chart_id) as p_id, 
(select last_name + ', ' + first_name from Facility_Professional where facility_prof_ID = 
				(select max(provider) from #sent_procedure1 where class = 'IP' and chart_id = c.chart_id)) as PerformingProvider2,
				'' as[ICD10_Code],
				6 as Process_Order,
                0 as posting_order,
				c.Coder_Comment
					from 
					#chart1 c,
					CHART_INFUSION_RESULT cir,
					CHARGE_MASTER cm
					where cir.chart_id = c.chart_id
					and cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID;

	  





-- Output 

      select 
      Chart_ID, 
	  Patient_ID,
	  mrn as MRN_ID,
	  Patient_Name,
      case when facility_id = 1539 then NULL else cast(Patient_DOB as date) end DOB ,
	 cast( DOS as date) as DOS,
	  case when PerformingProvider2 IS NULL then '' else PerformingProvider2 end as Provider_Name,
	  billing_code as Bill_CD,
	  Quantity,
	  cpt_code as CPT,
	  Modifiers,
	  icd_10_code as [ICD-10_CM],
      facility_id,
	  Coder_Comment,
	  '' as Type_of_Injury,
	  '' as Date_of_Accident,
(select facility.name from facility where facility.facility_id = #Details1.facility_id) as Tab_Name
	  from #Details1
	  order by 
	  Patient_ID,
	  PROCESS_ORDER,
      POSTING_ORDER,
	  cpt_code asc;

end

GO
