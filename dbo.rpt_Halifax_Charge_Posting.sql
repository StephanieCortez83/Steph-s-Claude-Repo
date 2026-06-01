SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[rpt_Halifax_Charge_Posting]
(
	 @ReportUser int
	,@Facility   varchar(max)
	,@StartDate datetime 
	,@EndDate   datetime 
	,@StartTime int 
	,@EndTime	int 
	,@concat int = 1
)

as

begin

    set transaction isolation level read uncommitted;
    set nocount on;
    set ansi_warnings off;


  --  declare
  --      @ReportUser int          = 80
  --      ,@Facility  varchar(max) = '2014'
  --      ,@StartDate datetime     = '20230504'
  --      ,@EndDate   datetime     = '20230504'
  --      ,@StartTime int          = 0
  --      ,@EndTime   int          = 23
		--,@concat	int			 = 1;


	----------------------------------------------------------------------------------------------------------------------------------

    declare
        @m_ReportUser     int          = @ReportUser
        ,@m_Facility      varchar(max) = @Facility
        --   ,@m_StartDate            datetime     = @StartDate
        --   ,@m_EndDate              datetime     = @EndDate
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
            );


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
        ,override_physician_service_proc_ID int;

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
    from
        #TempC2 as t
		join CHART       as c with (nolock, index(1)) on t.CHART_ID = c.CHART_ID;

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

    select
        CLASS
        ,CHART_ID
        ,FACILITY_CHART_ID
        ,SERVICE_AGREEMENT_ID
        ,TIME_OF_SERVICE
        ,SENT_DATE
        ,PATIENT_DISPOSITION_ID
        ,PHYSICIAN_ID
        ,BILLING_CODE
        ,CPT_CODE
        ,QUANTITY
        ,FACILITY_ID
        ,PATIENT_CLASS_ID
        ,ADJUSTMENT_IND
        ,CHARGE_MASTER_ID
        ,LEVEL_ID
        ,FACILITY_ADMIN_CHART_ID
        ,SOURCE_ID
        ,SOURCE_CD
    into #SentProcedure
    from
        RevCycleTransactionSnapshot..Sent_Procedure
    where
        1 = 0;


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


    -- Part 2 - Charge Posting Report

    if object_id('TempDB..#chart1', 'U') is not null drop table #chart1;
    if object_id('TempDB..#sent_procedure1', 'U') is not null drop table #sent_procedure1;
    if object_id('TempDB..#Details1', 'U') is not null drop table #Details1;
    if object_id('TempDB..#Temp_Details1', 'U') is not null drop table #Temp_Details1;


    -----------------------------------------------------------------------------

    select
        SENT_DATE
        ,CHART_ID
        ,FACILITY_CHART_ID                             as Patient_ID
        ,medical_record_num                            as MRN
        ,patient_last_name + ', ' + patient_first_name as Patient_Name
        ,TIME_OF_SERVICE                               as DOS
        ,FACILITY_ID
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
         else PHYSICIAN_ID end                         as EVAL_PHYSICIAN
        ,PHYSICIAN_SERVICE_MOD
        ,FACILITY_LEVEL_ID

        --		,case when CODER_COMMENT like '%NDC%' then SUBSTRING(CODER_COMMENT, CHARINDEX('NDC', CODER_COMMENT), 2000) else '' end [CODER_COMMENTS]
        ,SERVICE_AGREEMENT_ID
        ,FACILITY_ADMIN_CHART_ID
        ,PATIENT_DOB
    into #chart1
    from
        CHART
    where
        FACILITY_ID in
        (
            select * from SplitString(@m_Facility, ',')
        )
        and CHART_STATUS_ID = 5 -- Sent		
        --and SENT_DATE BETWEEN @m_StartDate AND DateAdd(second, 86399, @m_EndDate)				
        and SENT_DATE between @m_StartDateTime and @m_EndDateTime
        --and SERVICE_AGREEMENT_ID = 1874 -- restricts to 'Halifax - Deltona Profee' only **********


    ------------------------------------------------------------------------------

    select
        c.*
        ,sp.class
        ,sp.billing_code
        ,sp.cpt_code
        ,sp.quantity
        ,sp.PHYSICIAN_ID          as sp_physician_id
        ,sp.charge_master_id
        ,sp.level_id
        ,case
             when sp.PHYSICIAN_ID is null then c.EVAL_PHYSICIAN
         else sp.PHYSICIAN_ID end as Provider
        ,sp.time_of_service
    into #sent_procedure1
    from
        #SentProcedure sp
        ,#chart1 c
    where
        sp.CHART_ID = c.CHART_ID
        and class in ('PL', 'IP', 'FL');


    --------------------------------------------------------------------------------

    create table #Details1
    (
        chart_ID                 int
        ,Patient_ID              varchar(20)
        ,MRN                     varchar(20)
        ,Patient_Name            varchar(60)
        ,DOS                     datetime
        ,sent_date               datetime
        ,billing_code            varchar(20)
        ,cpt_code                varchar(5)
        ,quantity                int
        ,facility_id             int
        ,modifiers               varchar(20)
        ,p_id                    int
        ,PerformingProvider2     varchar(60)
        ,icd_10_code             varchar(200)
        ,PROCESS_ORDER           int
        ,POSTING_ORDER           int
        ,TOS                     datetime
        ,Dx_Label                varchar(50)
        ,FACILITY_ADMIN_CHART_ID varchar(20)
        ,PATIENT_DOB             datetime
    --		,CODER_COMMENTS		 varchar(1000)
    );


    -- insert PL data  
    insert into #Details1
    select
        sp.CHART_ID
        ,sp.Patient_ID
        ,sp.MRN
        ,sp.Patient_Name
        ,sp.DOS
        ,sp.SENT_DATE
        ,sp.billing_code
        ,sp.cpt_code
        ,sp.quantity
        ,sp.FACILITY_ID
        ,sp.PHYSICIAN_SERVICE_MOD as modifiers
        ,sp.Provider              as p_id
        ,(
             select
                 LAST_NAME + ', ' + FIRST_NAME
             from
                 FACILITY_PROFESSIONAL
             where
                 FACILITY_PROF_ID = sp.Provider
         )                        as PerformingProvider2
        ,''                       as [ICD10_Code]
        ,1                        as PROCESS_ORDER
        ,0                        as Posting_order
        ,sp.time_of_service       as TOS
        ,''                       as Dx_Label
        ,sp.FACILITY_ADMIN_CHART_ID
        ,sp.PATIENT_DOB
    --		,CODER_COMMENTS
    from
        #sent_procedure1 sp
    where
        sp.class = 'PL';


    -------------------------------------------------------------------------------

    -- insert FL data  
    insert into #Details1
    select
        sp.CHART_ID
        ,sp.Patient_ID
        ,sp.MRN
        ,sp.Patient_Name
        ,sp.DOS
        ,sp.SENT_DATE
        ,sp.billing_code
        ,sp.cpt_code
        ,sp.quantity
        ,sp.FACILITY_ID
        ,(
             select
                 fl.MODIFIER
             from
                 FACILITY_LEVEL fl
             where
                 fl.FACILITY_LEVEL_ID = sp.FACILITY_LEVEL_ID
         )           as modifiers
        ,sp.Provider as p_id
        ,(
             select
                 LAST_NAME + ', ' + FIRST_NAME
             from
                 FACILITY_PROFESSIONAL
             where
                 FACILITY_PROF_ID = sp.Provider
         )           as PerformingProvider2
        ,''          as [ICD10_Code]
        ,2           as PROCESS_ORDER
        ,0           as Posting_order
        ,sp.time_of_service
        ,''          as Dx_Label
        ,sp.FACILITY_ADMIN_CHART_ID
        ,sp.PATIENT_DOB
    --		,CODER_COMMENTS
    from
        #sent_procedure1 sp
    where
        sp.class = 'FL';


    ----------------------------------------------------------------------------------

    -- Insert ICD10/Diagnosis Codes

    select
        c.CHART_ID
        ,c.Patient_ID
        ,c.MRN
        ,c.Patient_Name
        ,c.DOS
        ,c.SENT_DATE
        ,''               billing_code
        ,''               cpt_code
        ,''               as quantity
        ,c.FACILITY_ID
        ,''               as modifiers
        ,c.EVAL_PHYSICIAN as p_id
        ,''               as PerformingProvider2
        ,icd10.ICD10_CODE
        ,3                as Process_Order
        ,icd10.POSTING_ORDER
        ,icd10.DIAGNOSIS_TYPE_ID
        ,icd10.IS_PRIMARY
        ,c.DOS            as TOS
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.PATIENT_DOB
    --		,c.CODER_COMMENTS

    into #Temp_Details1
    from
        #chart1 c
        ,CHART_DIAGNOSIS_CODE_ICD10 icd10
    where
        c.CHART_ID = icd10.CHART_ID;

    /*
--  DIAGNOSIS_TYPE_ID = 1, IS_PRIMARY = 1 : Chief Complaint
	delete from #Temp_Details1
	where
		(
			DIAGNOSIS_TYPE_ID = 1
			and IS_PRIMARY = 1
		);

*/


    -- Exclude the following Dx codes
    --delete from #Temp_Details1
    --where icd10_code in
    --		(
    --		'Y92.9', 'Y93.9', 'Y99.9'	
    --		);


    insert into #Details1
    select
        CHART_ID
        ,Patient_ID
        ,MRN
        ,Patient_Name
        ,DOS
        ,SENT_DATE
        ,billing_code
        ,cpt_code
        ,''                     as quantity
        ,FACILITY_ID
        ,''                     as modifiers
        ,p_id
        ,(
             select
                 LAST_NAME + ', ' + FIRST_NAME
             from
                 FACILITY_PROFESSIONAL
             where
                 FACILITY_PROF_ID = #Temp_Details1.p_id
         )                      as PerformingProvider2
        ,ICD10_CODE
        ,Process_Order
        ,POSTING_ORDER
        ,TOS
        ,case
             when DIAGNOSIS_TYPE_ID = 1
                  and IS_PRIMARY = 1 then 'Chief Complaint'
             when DIAGNOSIS_TYPE_ID = 1
                  and IS_PRIMARY = 0 then 'Secondary Complaint'
             when DIAGNOSIS_TYPE_ID = 2
                  and IS_PRIMARY = 1 then 'Primary Dx'
             when DIAGNOSIS_TYPE_ID = 2
                  and IS_PRIMARY = 0 then 'Secondary Dx'
             when DIAGNOSIS_TYPE_ID = 3
                  and IS_PRIMARY = 1 then 'Chief Complaint and Primary Dx'
             when DIAGNOSIS_TYPE_ID = 3
                  and IS_PRIMARY = 0 then 'Complaint and Secondary Dx'
             when DIAGNOSIS_TYPE_ID = 5 then 'Chief Complaint and Secondary Dx'
         else '' end            as Dx_Label
        ,FACILITY_ADMIN_CHART_ID
        ,PATIENT_DOB
    --		,CODER_COMMENTS
    from
        #Temp_Details1;


    ----------------------------------------------------------------------------------

    -- Insert Facility Procedure Data

    insert into #Details1
    select
        c.CHART_ID
        ,c.Patient_ID
        ,c.MRN
        ,c.Patient_Name
        ,c.DOS
        ,c.SENT_DATE
        ,case
             when cmm.BILLING_CODE is null then cm.BILLING_CODE
         else cmm.BILLING_CODE end as BILLING_CODE
        ,cm.CPT_CODE
        ,fpe.QUANTITY
        ,c.FACILITY_ID
        ,fpe.MODIFIERS
        ,fpe.PHYSICIAN_ID          as p_id
        ,(
             select
                 LAST_NAME + ', ' + FIRST_NAME
             from
                 FACILITY_PROFESSIONAL
             where
                 FACILITY_PROF_ID = fpe.PHYSICIAN_ID
         )                         as PerformingProvider2
        ,fpe.ICD_10_CODE
        ,4                         as Process_Order
        ,0                         as posting_order
        ,fpe.PROCEDURE_DATE        as TOS
        ,''                        as Dx_Label
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.PATIENT_DOB
    --		,c.CODER_COMMENTS
    from
        #chart1                   c
		left outer join FACILITY_PROCEDURE_EVALUATION fpe on c.CHART_ID = fpe.CHART_ID
		inner join CHARGE_MASTER                 cm on cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID
		left outer join CHARGE_MASTER_MODIFIER        cmm on cm.CHARGE_MASTER_ID = cmm.CHARGE_MASTER_ID
											 and fpe.MODIFIERS = cmm.MODIFIER
											 and c.SERVICE_AGREEMENT_ID = cmm.SERVICE_AGREEMENT_ID;
    
	-------------------------------------------------------------------------------
	-- Insert Physician Procedure Data

    insert into #Details1
    select
        c.CHART_ID
        ,c.Patient_ID
        ,c.MRN
        ,c.Patient_Name
        ,c.DOS
        ,c.SENT_DATE
        ,cm.BILLING_CODE
        ,cm.CPT_CODE
        ,ppe.QUANTITY
        ,c.FACILITY_ID
        ,ppe.MODIFIERS
        ,ppe.PHYSICIAN_ID   as p_id
        ,(
             select
                 LAST_NAME + ', ' + FIRST_NAME
             from
                 FACILITY_PROFESSIONAL
             where
                 FACILITY_PROF_ID = ppe.PHYSICIAN_ID
         )                  as PerformingProvider2
        ,ppe.ICD_10_CODE
        ,5                  as Process_Order
        ,0                  as posting_order
        ,ppe.PROCEDURE_DATE as TOS
        ,''                 as Dx_Label
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.PATIENT_DOB
    --		,c.CODER_COMMENTS
    from
        #chart1                    c
		left outer join PHYSICIAN_PROCEDURE_EVALUATION ppe on c.CHART_ID = ppe.CHART_ID
		inner join CHARGE_MASTER                  cm on cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID;


    ---------------------------------------------------------------------------------

    -- Step 1 -- I/I

    if object_id('TempDB..#I_I_Details', 'U') is not null drop table #I_I_Details;


    select
        c.CHART_ID
        ,c.Patient_ID
        ,c.MRN
        ,c.Patient_Name
        ,c.DOS
        ,c.SENT_DATE
        ,cm.BILLING_CODE
        ,cm.CPT_CODE
        ,cir.UNITS           as quantity
        ,c.FACILITY_ID
        ,cir.MODIFIERS -- Modifiers where different in Sent_procedure table chart _id 65335059 as example
                       -- Lookup how Sent Procedure gathers Performing Physician for I/I, use this for now   **** 
        ,(
             select
                 max(Provider)
             from
                 #sent_procedure1
             where
                 class = 'IP'
                 and CHART_ID = c.CHART_ID
         )                   as p_id
        ,(
             select
                 LAST_NAME + ', ' + FIRST_NAME
             from
                 FACILITY_PROFESSIONAL
             where
                 FACILITY_PROF_ID =
             (
                 select
                     max(Provider)
                 from
                     #sent_procedure1
                 where
                     class = 'IP'
                     and CHART_ID = c.CHART_ID
             )
         )                   as PerformingProvider2
        ,''                  as [ICD10_Code]
        ,6                   as Process_Order
        ,0                   as posting_order
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.PATIENT_DOB
                       --		,c.CODER_COMMENTS
        ,cir.DATE_OF_SERVICE as TOS
        ,cm.CHARGE_MASTER_ID
        ,c.SERVICE_AGREEMENT_ID
    into #I_I_Details
    from
        #chart1 c
        ,CHART_INFUSION_RESULT cir
        ,CHARGE_MASTER cm
    where
        cir.CHART_ID = c.CHART_ID
        and cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID;





    -- Step 2 -- -- Insert  I/I

    insert into #Details1
    select
        c.CHART_ID
        ,c.Patient_ID
        ,c.MRN
        ,c.Patient_Name
        ,c.DOS
        ,c.SENT_DATE
        ,case
             when cmm.BILLING_CODE is null then c.BILLING_CODE
             when cmm.BILLING_CODE = '' then c.BILLING_CODE
         else cmm.BILLING_CODE end as BILLING_CODE
        ,c.CPT_CODE
        ,c.quantity
        ,c.FACILITY_ID
        ,c.MODIFIERS
        ,c.p_id
        ,c.PerformingProvider2
        ,c.[ICD10_Code]
        ,c.Process_Order
        ,c.posting_order
        ,c.TOS
        ,''                        as Dx_Label
        ,c.FACILITY_ADMIN_CHART_ID
        ,c.PATIENT_DOB
    --		,c.CODER_COMMENTS


    from
        #I_I_Details       c
		left join CHARGE_MASTER_MODIFIER cmm on c.CHARGE_MASTER_ID = cmm.CHARGE_MASTER_ID
                                  and c.MODIFIERS = cmm.MODIFIER
                                  and c.SERVICE_AGREEMENT_ID = cmm.SERVICE_AGREEMENT_ID;


    -----------------------------------------------------------------------------
    -- Output 

	if object_id('TempDB..#final_results', 'U') is not null drop table #final_results;
	if object_id('TempDB..#Dx_pivot', 'U') is not null drop table #Dx_pivot;

    select
        sent_date
        ,Patient_ID
        ,MRN                                                                        as MRN_ID
        ,Patient_Name
        ,cast(DOS as date)                                                          as DOS
        ,case when PerformingProvider2 is null then '' else PerformingProvider2 end as Provider_Name
        ,billing_code                                                               as Bill_CD
        ,quantity
        ,cpt_code                                                                   as CPT
        ,modifiers
        ,icd_10_code                                                                as [ICD-10_CM]
        ,facility_id
        ,(
             select
                 FACILITY_NUMBER
             from
                 FACILITY
             where
                 FACILITY.FACILITY_ID = #Details1.facility_id
         )                                                                          as Tab_Name
        ,TOS                                                                        as Procedure_Date
        ,Dx_Label
		,case when Dx_Label = 'Chief Complaint and Primary Dx' then 1
				when Dx_Label = 'Chief Complaint' then 2
				when Dx_Label = 'Primary Dx' then 3
				--when Dx_Label = 'Secondary Dx' then 4
			else 4 end Dx_Label_Ord
        ,FACILITY_ADMIN_CHART_ID
        ,PATIENT_DOB
    -- 		,CODER_COMMENTS
		,(select c.CHART_STATUS_ID
			from
				dbo.CHART c
			where
				#Details1.CHART_ID = c.CHART_ID
			) CHART_STATUS_ID
    into #final_results
	from
        #Details1
    where
        exists
		(   -- FUA Check *****
			select
				*
			from
				FACILITY_USER_AUTHORIZATION FUA with (nolock)
				,USER_PROFILE UP with (nolock)
			where
				FUA.FACILITY_ID = #Details1.facility_id
				and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID
				and UP.IS_ACTIVE = 'Y'
				and getdate() between FUA.EFFECTIVE_DATE and FUA.EXPIRATION_DATE
				and FUA.USER_PROFILE_ID = @m_ReportUser
		)

		--and Patient_ID = 'W00000640870'
    order by
        sent_date
        ,Patient_ID
        -- ,PROCESS_ORDER
        -- ,POSTING_ORDER
        -- ,cpt_code asc
		,Procedure_Date
        ,Dx_Label
        ,icd_10_code;


	select 
		Patient_ID
		,max([Chief Complaint and Primary Dx]) [Chief Complaint and Primary Dx]
		,max([Primary Dx]) [Primary Dx]
		,max([Chief Complaint ]) [Chief Complaint]
		,max([Secondary Dx]) [Secondary Dx]
	into #Dx_pivot
	from
	(select 
		fr.Patient_ID, fr.[ICD-10_CM], fr.Dx_Label, fr.Dx_Label_Ord
	from
		#final_results fr
	) p
	pivot
	(
	max([ICD-10_CM])
	for Dx_Label in
	( [Chief Complaint and Primary Dx], [Primary Dx], [Chief Complaint ], [Secondary Dx] )
	) as pvt
	group by Patient_ID


	----------------------------------------------------------------------------------------------------------------------------------

	if @concat = 1
	begin

		select distinct
			fr.sent_date
			,fr.Patient_ID
			,fr.MRN_ID
			,fr.Patient_Name
			,fr.DOS
			--,fr.Provider_Name
			,stuff(
					(
					select
						',' + convert(varchar(max),fr2.Provider_Name)
					from
						#final_results fr2
					where
						fr.Patient_ID = fr2.Patient_ID
						and isnull(fr2.Provider_Name,'') <> ''
					for xml path('')
					)
					,1
					,1
					,''
						) as [Provider_Name]
			--,fr.Bill_CD
			,stuff(
					(
					select
						',' + convert(varchar(max),fr2.Bill_CD)
					from
						#final_results fr2
					where
						fr.Patient_ID = fr2.Patient_ID
						and isnull(fr2.Bill_CD,'') <> ''
					for xml path('')
					)
					,1
					,1
					,''
					) as [Bill_CD]
			--,fr.quantity
			,stuff(
					(
					select
						',' + convert(varchar(max),fr2.quantity)
					from
						#final_results fr2
					where
						fr.Patient_ID = fr2.Patient_ID
					for xml path('')
					)
					,1
					,1
					,''
					) as [quantity]
			--,fr.CPT
			,stuff(
					(
					select 
						',' + convert(varchar(max),fr2.CPT)
					from
						#final_results fr2
					where
						fr.Patient_ID = fr2.Patient_ID
						and isnull(fr2.CPT,'') <> ''
					for xml path('')
					)
					,1
					,1
					,''
					) as [CPT]
			--,fr.modifiers
			,stuff(
					(
					select
						',' + convert(varchar(max),fr2.modifiers)
					from
						#final_results fr2
					where
						fr.Patient_ID = fr2.Patient_ID
						and isnull(fr2.modifiers,'') <> ''
					for xml path('')
					)
					,1
					,1
					,''
					) as [modifiers]
			,null as [ICD-10_CM]
			,fr.facility_id
			,fr.Tab_Name
			--,fr.Procedure_Date
			,stuff(
					(
					select
						'; ' + convert(varchar(8),fr2.Procedure_Date,10)
					from
						#final_results fr2
					where
						fr.Patient_ID = fr2.Patient_ID
						and isnull(fr2.Procedure_Date,'') <> ''
					for xml path('')
					)
					,1
					,1
					,''
						) as [Procedure_Date]
			,null as Dx_Label
			,fr.FACILITY_ADMIN_CHART_ID
			,fr.PATIENT_DOB
			,dx.[Chief Complaint and Primary Dx] [Chief_Complaint_and_Primary_Dx]
			,dx.[Chief Complaint] [Chief_Complaint]
			,dx.[Primary Dx] [Primary_Dx]
			,dx.[Secondary Dx] [Secondary_Dx]
			,cs.[DESCRIPTION] [CHART_STATUS]
			,f.[NAME] Facility
		from
			#final_results fr
			inner join dbo.FACILITY f on fr.FACILITY_ID = f.FACILITY_ID
			left join #Dx_pivot dx on fr.Patient_ID = dx.Patient_ID
			left join dbo.CHART_STATUS cs on fr.CHART_STATUS_ID = cs.CHART_STATUS_ID

	end

	else 

	select 
		fr.sent_date
		,fr.Patient_ID
		,fr.MRN_ID
		,fr.Patient_Name
		,fr.DOS
		,fr.Provider_Name
		,fr.Bill_CD
		,fr.quantity
		,fr.CPT
		,fr.modifiers
		,fr.[ICD-10_CM]
		,fr.facility_id
		,fr.Tab_Name
		,fr.Procedure_Date
		,fr.Dx_Label
		,fr.FACILITY_ADMIN_CHART_ID
		,fr.PATIENT_DOB
		,null [Chief Complaint and Primary Dx]
		,null [Chief Complaint]
		,null [Primary Dx]
		,null [Secondary Dx]
		,cs.[DESCRIPTION] [CHART_STATUS]
	from 
		#final_results fr
		left join dbo.CHART_STATUS cs on fr.CHART_STATUS_ID = cs.CHART_STATUS_ID



end;
GO
GRANT EXECUTE ON  [dbo].[rpt_Halifax_Charge_Posting] TO [dbx_ExecuteReportProcs]
GO
