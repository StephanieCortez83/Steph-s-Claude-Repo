SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[rpt_Provider_RVU_Detail]
(
	 @ReportUser    INT 
    ,@DateType      INT 
    ,@StartDate     DATETIME
    ,@EndDate       DATETIME
    ,@Organization  int
    ,@Facility      int
)

as

begin

    set transaction isolation level read uncommitted;
    set nocount on;
    set ansi_warnings off;


-- Test parameters

 -- declare
 --    @ReportUser    INT = 80
 --   ,@DateType      INT =  1-- 1 DOS, 2 Sent 
 --   ,@StartDate     DATETIME = '04/07/2025'            
 --   ,@EndDate       DATETIME = '04/09/2025'
 --   ,@Organization  int  = 213 -- 213 -- Rochester Regional Health	
	--,@Facility      int = -1  -- '-1' All
 --   ;

    ----------------------------------------------------------------------------------------------------------
	


if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;

SELECT *
INTO #AuthorizedFacilities
FROM (
  SELECT DISTINCT fua.FACILITY_ID, 
                  sa.service_agreement_id, 
                  sa.description as name
                FROM FACILITY_USER_AUTHORIZATION fua,
                USER_PROFILE up,
                SERVICE_AGREEMENT sa
                WHERE 
                fua.user_profile_id = up.user_profile_id
                and fua.facility_id = sa.facility_id 
                and ( up.CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR up.IS_ACTIVE = 'Y' )                                    
                and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
                and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
                and sa.company_id = (@Organization) 
                and sa.DEMO_TEST_SITE_IND = 0
                and fua.USER_PROFILE_ID = @ReportUser
				and (@Facility = -1 or fua.FACILITY_ID in (@Facility))
				and
				(
				EVALUATE_PHYSICIAN_PROCEDURES = 1
				or 
				EVALUATE_PHYSICIAN_SVC = 1
				or 
				EVALUATE_PHYSICIAN_OBSERVATION = 1
				)
				)af
				;


-- select * from #AuthorizedFacilities




IF OBJECT_ID('TempDB..#chartsubset', 'U') IS NOT NULL DROP TABLE #chartsubset;
SELECT
    (SELECT NAME FROM FACILITY WHERE FACILITY_ID = C.FACILITY_ID) AS Facility,
    C.chart_id AS ACS_Chart_ID,
    C.facility_chart_ID AS Chart_Identifier,
	C.FACILITY_ADMIN_CHART_ID AS ED_PACE_ACCT_NUMBER,
    (SELECT DESCRIPTION FROM PATIENT_CLASS 
     WHERE service_agreement_id = C.service_agreement_id 
     AND patient_class_id = C.patient_class_id) AS DepartmentName,
    C.[MEDICAL_RECORD_NUM] AS MRN,
    C.[PATIENT_LAST_NAME] + ',' + C.[PATIENT_FIRST_NAME] AS PatientName,
    C.[PATIENT_DOB],
    DATEDIFF(YEAR, C.[PATIENT_DOB], GETDATE()) AS PatientAge,
    C.TIME_OF_SERVICE ,
    CAST(C.[TIME_OF_SERVICE] AS DATE) AS DOS,
    CAST(C.[TIME_OF_SERVICE] AS TIME) AS Arrival_Time,
   -- C.[ARRIVAL_DATE_TIME],
    CASE 
        WHEN C.provider_eval_performed_by_ind = 0 
        AND C.NURSE_PRACTITIONER_ID > 0 
        THEN 'Yes' 
        ELSE 'No' 
    END AS Shared_Visit,
    (SELECT DESCRIPTION FROM PATIENT_DISPOSITION_MAP 
     WHERE service_agreement_id = C.service_agreement_id
     AND PATIENT_DISPOSITION_MAP_ID = C.PATIENT_DISPOSITION_MAP_ID
     AND C.[TIME_OF_SERVICE] BETWEEN effective_date AND expiration_date ) AS FacilityDisposition,
    C.CHART_ID,
    C.SERVICE_AGREEMENT_ID,
c.NURSE_PRACTITIONER_ID,
c.provider_eval_performed_by_ind,
c.PHYSICIAN_ID,
    C.FACILITY_ID,
    C.facility_chart_ID,
    C.resident_id,
	c.FINANCIAL_CLASS_CD,
    c.TIME_OF_PHYS_DIS as FirstDispoSelectedTime,
	c.COMPLETED_BY_USER_PROFILE_ID,
	c.LONG_PATIENT_ID1
			  
INTO #chartsubset
FROM CHART C WITH (NOLOCK)
JOIN SERVICE_AGREEMENT SA ON SA.SERVICE_AGREEMENT_ID = C.SERVICE_AGREEMENT_ID
WHERE 
 C.FACILITY_ID in ( select FACILITY_ID from #AuthorizedFacilities )
and c.chart_status_id not in (6) -- Removed
and                        (                                                                                                                                                                            
                                (@DateType = 1 and c.TIME_OF_SERVICE between @StartDate and DateAdd(second, 86399, @EndDate) )                                                                                                                                      
                                or                                                                                                                                            
                                (@DateType = 2 and c.sent_date between @StartDate and  DateAdd(second, 86399, @EndDate) )
                                ) 

;


-- select * from #chartsubset


    ----------------------------------------------------------------------------------------------------------
	-- Part 1 - ReCreate Sent_Procedure table
	
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
		join #chartsubset as c on cir.CHART_ID = c.CHART_ID;
			   

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


 -- select * from #TempCIR

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
		join #chartsubset as c2 on c2.CHART_ID = c.CHART_ID
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
		join #chartsubset as c on ppe.CHART_ID = c.CHART_ID;


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
        ,cap.PHYSICIAN_ID
	into #TempCAP
    from
        CHART_ADDITIONAL_PROCEDURE as cap with (nolock)
		join #chartsubset as c on cap.CHART_ID = c.CHART_ID;


    alter table #TempCAP
    add
        facility_chart_ID varchar(20)
        ,service_agreement_ID int
        ,saEffDT datetime
        ,time_of_service datetime
        ,sent_date datetime
        ,patient_disposition_ID int
 --       ,physician_ID int
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
--        ,t.physician_ID = c.PHYSICIAN_ID
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
	-- insert into Temp #SentProcedure

	-- now run separate INSERT queries into #SentProcedure, all of which will refer to preprocessed tables populated above.
    -- Separating the INSERTs performs better than UNIONs in this case, and also makes it easier to analzye the performance of each step

    -- first create a temp table to gather preliminary results
    
	if object_id('TempDB..#SentProcedure', 'U') is not null drop table #SentProcedure;

create table #SentProcedure
(
    
         CLASS					varchar(2)
        ,CHART_ID				int
        ,FACILITY_CHART_ID		varchar(20)
        ,SERVICE_AGREEMENT_ID	int
        ,TIME_OF_SERVICE		datetime
        ,SENT_DATE				datetime
        ,PATIENT_DISPOSITION_ID	int
        ,PHYSICIAN_ID			int
        ,BILLING_CODE			varchar(20)
        ,CPT_CODE				varchar(5)
		,CPT_DESCRIPTION		varchar(100)
		,CHARGE_MASTER_USAGE_CODE	int
        ,QUANTITY				int
        ,FACILITY_ID			int
        ,PATIENT_CLASS_ID		int
        ,ADJUSTMENT_IND			varchar(1)
        ,CHARGE_MASTER_ID		int
        ,LEVEL_ID				int
        ,FACILITY_ADMIN_CHART_ID	varchar(20)
        ,SOURCE_ID				int
        ,SOURCE_CD				varchar(2)
		,WORK_RVU				decimal(11,2)
		
   )

-- select * from #SentProcedure




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
		,cm.description as CPT_DESCRIPTION		
		,cm.CHARGE_MASTER_USAGE_CODE
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
		,NULL
	
    from
        #TempCIR  as c
		join CHARGE_MASTER as cm with (nolock) on cm.CHARGE_MASTER_ID = c.CHARGE_MASTER_ID;


		    update
        #SentProcedure
    set
        WORK_RVU = RVU.WORK_RVU
    from #SentProcedure sp
	 	join CMS_PHYSICIAN_RVU rvu 
    on   sp.cpt_code = rvu.hcpcs
    and  sp.TIME_OF_SERVICE between rvu.effective_dt and expiration_dt
	where source_cd = 'IP'




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
		,cm.description as CPT_DESCRIPTION		
		,cm.CHARGE_MASTER_USAGE_CODE
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
		,NULL as WORK_RVU

    from
        #TempPPE  as c
		join CHARGE_MASTER as cm with (nolock) on cm.CHARGE_MASTER_ID = c.PHYSICIAN_PROCEDURE_ID;		
		


		  update
        #SentProcedure
		set
        WORK_RVU = RVU.WORK_RVU
		from #SentProcedure sp
	 	join CMS_PHYSICIAN_RVU rvu 
		on   sp.cpt_code = rvu.hcpcs
		and  sp.TIME_OF_SERVICE between rvu.effective_dt and expiration_dt
		where source_cd = 'PP';





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
		
		,NULL as CPT_DESCRIPTION		
		,NULL as CHARGE_MASTER_USAGE_CODE
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
		,NULL as WORK_RVU

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

	update
        #SentProcedure
    set
	   CPT_Description = CM.DESCRIPTION,
	   CHARGE_MASTER_USAGE_CODE = CM.CHARGE_MASTER_USAGE_CODE 
	from #SentProcedure sp
	join charge_master cm 
     on cm.charge_master_id = sp.charge_master_id
     and cm.SERVICE_AGREEMENT_ID = sp.SERVICE_AGREEMENT_ID;


    update
        #SentProcedure
    set
        WORK_RVU = RVU.WORK_RVU
    from #SentProcedure sp
	 	join CMS_PHYSICIAN_RVU rvu 
    on   sp.cpt_code = rvu.hcpcs
    and  sp.TIME_OF_SERVICE between rvu.effective_dt and expiration_dt
	where source_cd = 'PL';


	
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
		
		,case when c.PHYSICIAN_ID = -1 or c.PHYSICIAN_ID is null 
		then ( select c2.PHYSICIAN_ID from #chartsubset c2 where c2.chart_id = c.chart_id )
		else c.PHYSICIAN_ID end PHYSICIAN_ID		

        ,isnull(nullif(cm.ALIAS_BILLING_CODE, ''), cm.BILLING_CODE) BILLING_CODE
        ,cm.CPT_CODE
		,cm.description as CPT_DESCRIPTION		
		,cm.CHARGE_MASTER_USAGE_CODE
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
        ,'AP'														as source_cd
  	    , NULL as WORK_RVU

    from
        #TempCAP  as c
		join CHARGE_MASTER as cm with (nolock) on c.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID;


    update
        #SentProcedure
    set
        WORK_RVU = RVU.WORK_RVU
    from #SentProcedure sp
	 	join CMS_PHYSICIAN_RVU rvu 
    on   sp.cpt_code = rvu.hcpcs
    and  sp.TIME_OF_SERVICE between rvu.effective_dt and expiration_dt
	where source_cd = 'AP'; 

-- ***********************************************************************



--  Temp OUTPUT1 -- *************

IF OBJECT_ID('TempDB..#PayorDetails', 'U') IS NOT NULL DROP TABLE #PayorDetails;
SELECT  
    FFC.SERVICE_AGREEMENT_ID,
    FFC.FINANCIAL_CLASS_CD, 
    FFC.DESCRIPTION AS Payor, 
    UP.[LAST_NAME] + ',' + UP.[FIRST_NAME] AS UserName, 
    UP.user_profile_id AS Coder_ID
INTO #PayorDetails
FROM [dbo].[FACILITY_FINANCIAL_CLASS] FFC
JOIN SERVICE_AGREEMENT SA ON SA.SERVICE_AGREEMENT_ID = FFC.SERVICE_AGREEMENT_ID
JOIN USER_PROFILE UP ON UP.user_profile_id = FFC.changing_user_profile_id
WHERE 
FFC.SERVICE_AGREEMENT_ID in ( select SERVICE_AGREEMENT_ID from #AuthorizedFacilities );


IF OBJECT_ID('TempDB..#NURSE_PRACTITIONER', 'U') IS NOT NULL DROP TABLE #NURSE_PRACTITIONER;
SELECT distinct 
    NP.LAST_NAME + ', ' + NP.FIRST_NAME AS NURSE_PRACTITIONER_NAME
    ,C.NURSE_PRACTITIONER_ID
	,np.Facility_ID
INTO #NURSE_PRACTITIONER  
FROM #chartsubset C
LEFT JOIN FACILITY_PROFESSIONAL NP ON NP.FACILITY_PROF_ID = C.NURSE_PRACTITIONER_ID
								   and np.facility_id = c.facility_id	
where 
c.NURSE_PRACTITIONER_ID > 0 and
c.FACILITY_ID in ( select FACILITY_ID from #AuthorizedFacilities ) and
c.shared_visit = 'Yes'
;


IF OBJECT_ID('TempDB..#Resident', 'U') IS NOT NULL DROP TABLE #Resident;
SELECT distinct 
RES.LAST_NAME + ', ' + RES.FIRST_NAME AS Resident
,C.RESIDENT_ID
,RES.Facility_ID
INTO #Resident  
FROM #chartsubset C
LEFT JOIN FACILITY_PROFESSIONAL RES ON RES.FACILITY_PROF_ID = C.resident_id
									and RES.facility_id = c.facility_id	
where 
res.FACILITY_ID in ( select FACILITY_ID from #AuthorizedFacilities )
;





if object_id('TempDB..#Output1', 'U') is not null drop table #Output1;


SELECT 

sp.CHART_ID,
c.FINANCIAL_CLASS_CD,
c.Facility,
c.ED_PACE_ACCT_NUMBER as "ED PACE Acct Number" ,
'' AS CSN_Dot,
C.DepartmentName,
'' AS Notes,
sp.physician_id as Proc_Physician_id, -- Performing Procedure Provider
c.provider_eval_performed_by_ind,
c.PHYSICIAN_ID,
c.NURSE_PRACTITIONER_ID,
C.MRN,
C.PatientName,
DATEDIFF(YEAR, C.[PATIENT_DOB], GETDATE()) AS PatientAge,
CAST(sp.[TIME_OF_SERVICE] AS DATE) AS DOS,
c.Arrival_Time,
c. FirstDispoSelectedTime as "First Dispo Selected Time",   
C.LONG_PATIENT_ID1 as "ED Dispo Group", 
sp.CPT_CODE,
sp.CPT_Description,
(
select
-- 3 Facility Procedure, 4 Physician Service, 5 Physician Procedure
CASE 
        WHEN sp.CHARGE_MASTER_USAGE_CODE = 4 THEN 'E&M'
        WHEN sp.CHARGE_MASTER_USAGE_CODE = 5 THEN 'PROC'
		WHEN sp.CHARGE_MASTER_USAGE_CODE = 3 THEN 'PROC'
	    ELSE CMUC.[DESCRIPTION]
END AS CDM_Usage
FROM [RevCycleDB].[dbo].[CHARGE_MASTER_USAGE_CODE] CMUC 
WHERE CMUC.CHARGE_MASTER_USAGE_CODE IN (4,5,3)
and sp.CHARGE_MASTER_USAGE_CODE = CMUC.CHARGE_MASTER_USAGE_CODE
) as "E&M vs Proc",
      
ROUND(sp.quantity * sp.WORK_RVU, 2) AS WorkRVU,	 

sp.charge_master_id,

'' AS CPT_Edit_Past_Due,
'' AS Task_Name,
'' AS "D/E/N",
'' AS Site,
'' AS Prod_vs_NonProd,
'' AS Interpreter_Services_Used,
C.Shared_Visit,
NP.NURSE_PRACTITIONER_NAME as  "APP Name on Shared Visit", 
RES.Resident AS "Resident/Med Student",
'' AS "Resident/Med Student Name",
'' AS Note_Compliance,
'' AS Patients_Last_ED_Bed,
'' AS Plan_Name,    
PD.Payor,   
c.COMPLETED_BY_USER_PROFILE_ID as CODER
into #Output1
from #SentProcedure sp
left outer join #chartsubset c on sp.chart_id = c.chart_id
left join #Resident res WITH (NOLOCK) 
     on res.resident_id = c.resident_id  
left join #PayorDetails pd WITH (NOLOCK) 
     on c.SERVICE_AGREEMENT_ID = pd.SERVICE_AGREEMENT_ID
     and c.FINANCIAL_CLASS_CD = pd.FINANCIAL_CLASS_CD
left join #NURSE_PRACTITIONER np 
     on np.NURSE_PRACTITIONER_ID = c.NURSE_PRACTITIONER_ID

-- select * from #Output1 where chart_id = 139427735


-- *********************************************************


IF OBJECT_ID('TempDB..#Role', 'U') IS NOT NULL DROP TABLE #Role;
SELECT DISTINCT  
    FPR.FACILITY_PROF_ROLE_ID,
    CASE 
        WHEN FPR.FACILITY_PROF_ROLE_ID IN (1, 3, 6, 7, 9) THEN 'APP'
        WHEN FPR.FACILITY_PROF_ROLE_ID IN (2, 4, 8) THEN 'DOC'
        ELSE FPR.DESCRIPTION
    END AS Role
INTO #Role
FROM FACILITY_PROFESSIONAL FP
JOIN FACILITY_PROFESSIONAL_ROLE FPR ON FP.ROLE_ID = FPR.FACILITY_PROF_ROLE_ID
WHERE FPR.FACILITY_PROF_ROLE_ID != 5;


if object_id('TempDB..#Output2', 'U') is not null drop table #Output2;

-- step 1 - PROC


	
SELECT 
c.CHART_ID,
c.FINANCIAL_CLASS_CD,
C.Facility,
C."ED PACE Acct Number" ,
C.CSN_Dot,
C.DepartmentName,

FP.SECONDARY_EMPLOYEE_ID AS Provider_Naming_Convention,

c.Notes,
FP.Title,
c.Proc_Physician_id, -- Performing Procedure Provider
	c.provider_eval_performed_by_ind,
    c.PHYSICIAN_ID,
	c.NURSE_PRACTITIONER_ID,
FP2.LAST_NAME + ', ' + FP2.FIRST_NAME AS Provider,

R.Role as "Doc v APP Grouping" ,
FP.UPIR_ID AS NPI#,    
C.MRN,
C.PatientName,
C.PatientAge,
C.DOS,
C.Arrival_Time,
C."First Dispo Selected Time",   
C."ED Dispo Group", 
C.CPT_CODE,
C.CPT_Description,
c."E&M vs Proc",
c.WorkRVU,
c.charge_master_id,
c.CPT_Edit_Past_Due,
c.Task_Name,
c."D/E/N",
c.Site,
c.Prod_vs_NonProd,
c.Interpreter_Services_Used,
C.Shared_Visit,
C."APP Name on Shared Visit", 
c."Resident/Med Student",
C."Resident/Med Student Name",
C.Note_Compliance,
c.Patients_Last_ED_Bed,
c.Plan_Name,    
c.Payor,
c.CODER
INTO #Output2	
from #Output1 c

left join FACILITY_PROFESSIONAL fp2 WITH (NOLOCK) -- Attending Provider
     on c.physician_id = fp2.FACILITY_PROF_ID 

left join FACILITY_PROFESSIONAL fp WITH (NOLOCK) -- FP.SECONDARY_EMPLOYEE_ID AS Provider_Naming_Convention
		  on c.Proc_Physician_id = fp.FACILITY_PROF_ID
left join #Role r WITH (NOLOCK)
          on fp.role_id = r.FACILITY_PROF_ROLE_ID		    
where [E&M vs Proc] = 'PROC'
 






-- step 2 - E&M

INSERT INTO #Output2

SELECT 
c.CHART_ID,
c.FINANCIAL_CLASS_CD,
C.Facility,
C."ED PACE Acct Number" ,
C.CSN_Dot,
C.DepartmentName,

FP.SECONDARY_EMPLOYEE_ID AS Provider_Naming_Convention,


c.Notes,

FP.Title,
c.Proc_Physician_id, -- Performing Procedure Provider
	c.provider_eval_performed_by_ind,
    c.PHYSICIAN_ID,
	c.NURSE_PRACTITIONER_ID,
FP2.LAST_NAME + ', ' + FP2.FIRST_NAME AS Provider,

R.Role as "Doc v APP Grouping" ,

    
FP.UPIR_ID AS NPI#,

    
C.MRN,
C.PatientName,
C.PatientAge,
C.DOS,
C.Arrival_Time,
C."First Dispo Selected Time",   
C."ED Dispo Group", 
C.CPT_CODE,
C.CPT_Description,
c."E&M vs Proc",
c.WorkRVU,
c.charge_master_id,
c.CPT_Edit_Past_Due,
c.Task_Name,
c."D/E/N",
c.Site,
c.Prod_vs_NonProd,
c.Interpreter_Services_Used,
C.Shared_Visit,
C."APP Name on Shared Visit", 
c."Resident/Med Student",
C."Resident/Med Student Name",
C.Note_Compliance,
c.Patients_Last_ED_Bed,
c.Plan_Name,    
c.Payor,
c.CODER

from #Output1 c

left join FACILITY_PROFESSIONAL fp2 WITH (NOLOCK) -- Attending Provider
     on c.physician_id = fp2.FACILITY_PROF_ID 

left join FACILITY_PROFESSIONAL fp WITH (NOLOCK) -- FP.SECONDARY_EMPLOYEE_ID AS Provider_Naming_Convention
		 on  	case 	
		when c.provider_eval_performed_by_ind = 0 then c.PHYSICIAN_ID -- 0 Attending, 1 Midlevel
		when c.provider_eval_performed_by_ind = 1 and c.NURSE_PRACTITIONER_ID > 0 then c.NURSE_PRACTITIONER_ID
		else c.PHYSICIAN_ID 
		end = fp.FACILITY_PROF_ID 
left join #Role r WITH (NOLOCK)
          on fp.role_id = r.FACILITY_PROF_ROLE_ID		    		 

where [E&M vs Proc] = 'E&M'


-- select * from #Output2


--  Final Output table-- *************



SELECT 
c.CHART_ID,
c.FINANCIAL_CLASS_CD,
C.Facility,
C.[ED PACE Acct Number] ,
c.CSN_Dot,
C.DepartmentName,
C.Provider_Naming_Convention,
C.Notes,
C.Title,
C.Provider,
C.[Doc v APP Grouping] ,    
C.[NPI#],
C.MRN,
C.PatientName,
C.PatientAge,
C.DOS,
C.Arrival_Time,
C.[First Dispo Selected Time],
C.[ED Dispo Group], 
C.CPT_CODE,
C.CPT_Description,
C.[E&M vs Proc],
C.WorkRVU,
C.CHARGE_MASTER_ID,
C.CPT_Edit_Past_Due,
C.Task_Name,
C.[D/E/N],
C.Site,
C.Prod_vs_NonProd,
C.Interpreter_Services_Used,

case when C.[E&M vs Proc] = 'PROC' then NULL
else C.Shared_Visit
end as Shared_Visit,

case when C.[E&M vs Proc] = 'E&M' and C.Shared_Visit = 'Yes' then C.[APP Name on Shared Visit]										 
else NULL 
end as [APP Name on Shared Visit], 

C.[Resident/Med Student],
C.[Resident/Med Student Name],
C.Note_Compliance,
C.Patients_Last_ED_Bed,
C.Plan_Name,
C.Payor,
C.CODER
from #Output2 c




end 

GO
