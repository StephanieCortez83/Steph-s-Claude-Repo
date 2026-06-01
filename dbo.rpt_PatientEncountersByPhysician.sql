SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE procedure [dbo].[rpt_PatientEncountersByPhysician]
    @Facility           varchar(max)
    ,@Physician         varchar(max)
    ,@Code              bit = 0
    ,@StartDate         date
    ,@EndDate           date
    ,@ConsultantOnly    int
    ,@CODES             varchar(max)
    ,@PatientClass      varchar(max)
    ,@DateType          int
    ,@Override          varchar(max)
    ,@DisplayNoOverride int
    ,@ReportUser        int
    ,@SharedVisitsOnly  int
	,@PatientAgeGroup	varchar(max)
as
begin

    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.

    set transaction isolation level read uncommitted;
    set nocount on;

    ----TEST PARMS
   -- 	declare
   -- 		@Facility           varchar(max) = '1122'
   -- 		,@Physician         varchar(max) = '-1'  -- 1 All 
   -- 		,@Code              bit          = 0   -- 0 CPT,  1 Billing
   -- 		,@StartDate         date		 = '20240101'
   -- 		,@EndDate           date		 = '20240107'
   -- 		,@ConsultantOnly    int			 = 2     -- All Records
   -- 		,@CODES             varchar(max) = '99285'
   -- 		,@PatientClass      varchar(max) = '2895'
   -- 		,@DateType          int			 = 0  -- DOS
   -- 		,@Override          varchar(max) = 'No Override' --'99214 - LEVEL 4 UCC w/ proc' --'99024 - Postop follow-up visit'
   -- 		,@DisplayNoOverride int			 = 0  --0 false
   -- 		,@ReportUser		int			 = 80
   -- 		,@SharedVisitsOnly	int			 = 0	-- 0 False
   --       ,@PatientAgeGroup   varchar(max) = 5	-- -1 All



		--if object_id('TempDB..#CODES_tmp', 'U') is not null drop table #CODES_tmp;
		--select DISTINCT CASE @Code
		--		WHEN 1
		--			THEN BILLING_CODE
		--		ELSE CPT_CODE
		--		END CODE
		--into #CODES_tmp
		--FROM CHARGE_MASTER  WITH (NOLOCK)
		--WHERE SERVICE_AGREEMENT_ID IN (
		--		SELECT SERVICE_AGREEMENT_ID
		--		FROM SERVICE_AGREEMENT WITH (NOLOCK)
		--		WHERE FACILITY_ID IN (@Facility)
		--			AND GETDATE() BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
		--		)
		--	AND GETDATE() BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
		----ORDER BY CODE

		--set @CODES = 
		--( select
		--	substring(
		--		(
		--			SELECT ','+CODE  AS [text()]
		--			FROM #CODES_tmp
		--			ORDER BY CODE
		--			FOR XML PATH (''), TYPE
		--		).value('text()[1]','varchar(max)'), 2, 1000) )
    ----TEST PARMS

    -- Insert statements for procedure here
    declare
        @m_Facility           varchar(max)
        = @Facility
        ,@m_Physician         varchar(max) = @Physician
        ,@m_Code              bit          = @Code
        ,@m_StartDate         datetime     = @StartDate
        ,@m_EndDate           datetime     = @EndDate -- needs to be datetime data type to use function DateAdd(second, 86399, @m_EndDate)
        ,@m_Consultant        int          = @ConsultantOnly
        ,@m_CODES             varchar(max) = @CODES
        ,@m_PatientClass      varchar(max) = @PatientClass
        ,@m_DateType          int          = @DateType
        ,@m_Override          varchar(max) = @Override
        ,@m_DisplayNoOverride int          = @DisplayNoOverride
		,@m_PatientAgeGroup   varchar(max) = @PatientAgeGroup;
    --@m_CODES_CNT int = 0



    if object_id('TempDB..#Provider1', 'U') is not null
        drop table #Provider1;
    if object_id('TempDB..#Data1', 'U') is not null
        drop table #Data1;
    if object_id('TempDB..#Override1', 'U') is not null
        drop table #Override1;
    if object_id('TempDB..#ICD10CM', 'U') is not null
        drop table #ICD10CM;
    if object_id('TempDB..#Charts', 'U') is not null
        drop table #Charts;

    if object_id('TempDB..#SentProcedure', 'U') is not null
        drop table #SentProcedure;
    if object_id('TempDB..#ChartConsultingPhysician', 'U') is not null
        drop table #ChartConsultingPhysician;
    if object_id('TempDB..#ChartDiagnoses', 'U') is not null
        drop table #ChartDiagnoses;
    if object_id('TempDB..#ChartICD9Desc', 'U') is not null
        drop table #ChartICD9Desc;
    if object_id('TempDB..#ChartDiagnoses10', 'U') is not null
        drop table #ChartDiagnoses10;
    if object_id('TempDB..#ProcedureClassCodes', 'U') is not null
        drop table #ProcedureClassCodes;
    if object_id('TempDB..#ChartMaxAdjIndFL', 'U') is not null
        drop table #ChartMaxAdjIndFL;
    if object_id('TempDB..#ChartFacilityLevel', 'U') is not null
        drop table #ChartFacilityLevel;
    if object_id('TempDB..#ChartFP', 'U') is not null
        drop table #ChartFP;
    if object_id('TempDB..#ChartMaxAdjIndPL', 'U') is not null
        drop table #ChartMaxAdjIndPL;
    if object_id('TempDB..#ChartPhysicianLevel', 'U') is not null
        drop table #ChartPhysicianLevel;
    if object_id('TempDB..#ChartPP', 'U') is not null
        drop table #ChartPP;
    if object_id('TempDB..#ChartIP', 'U') is not null
        drop table #ChartIP;
    if object_id('TempDB..#ChartFacilityLevelDesc', 'U') is not null
        drop table #ChartFacilityLevelDesc;
    if object_id('TempDB..#ChartPhysicianLevelDesc', 'U') is not null
        drop table #ChartPhysicianLevelDesc;
    if object_id('TempDB..#ChartOverride', 'U') is not null
        drop table #ChartOverride;


	--print 'Section: 00 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    create table #Charts
    (
        chart_ID int
    );

    select
        *
    into
        #Provider1
    from
    (
        select distinct
            FACILITY_PROF_ID
        from
            FACILITY_PROFESSIONAL FP with (nolock)
        inner join
        (
            select
                LAST_NAME
                ,FIRST_NAME
            from
                FACILITY_PROFESSIONAL with (nolock)
            where
                (
                    FACILITY_PROF_ID in
                    (
                        select * from SplitString(@m_Physician, ',')
                    )
                    or -1 in
                       (
                           select * from SplitString(@m_Physician, ',')
                       )
                )
        )                         T1 on T1.LAST_NAME = FP.LAST_NAME
                                        and T1.FIRST_NAME = FP.FIRST_NAME
        where
            (
                FACILITY_PROF_ID in
                (
                    select * from SplitString(@m_Physician, ',')
                )
                or -1 in
                   (
                       select * from SplitString(@m_Physician, ',')
                   )
            )
            and FACILITY_ID in
                (
                    select * from SplitString(@m_Facility, ',')
                )
    ) T2;


	--print 'Section: 01 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------

    if @m_DateType = 0
    begin -- in this case, peformance is better like this instead of using CASE @m_DateType in a WHERE statement
        insert into #Charts
        (
        chart_ID
        )
        select
            c.CHART_ID
        from
            CHART as c with (nolock)
        where
            c.FACILITY_ID in
            (
                select * from SplitString(@m_Facility, ',')
            )
            and c.TIME_OF_SERVICE between @m_StartDate and dateadd(second, 86399, @m_EndDate); -- performance can be improved in some cases by using functions only on params (not on table columns).
    --and c.patient_class_id in (SELECT * FROM SPLITSTRING(@m_PatientClass, ','))	-- edited 12/5/2017 - move to subsequent step for big performance improvement in some situations (1M reads vs. 75M reads)
    end;
    else
    begin
        insert into #Charts
        (
        chart_ID
        )
        select
            c.CHART_ID
        from
            CHART as c with (nolock)
        where
            c.FACILITY_ID in
            (
                select * from SplitString(@m_Facility, ',')
            )
            and c.SENT_DATE between @m_StartDate and dateadd(second, 86399, @m_EndDate);
    --and c.patient_class_id in (SELECT * FROM SPLITSTRING(@m_PatientClass, ','))	-- edited 12/5/2017 - move to subsequent step for big performance improvement in some situations (1M reads vs. 75M reads)
    end;

    create clustered index ix_cls_CHARTS_ChartID on #Charts (chart_ID); -- added index 12/12/2017


	--print 'Section: 02 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    -- added section 12/5/2017 to improve performance
    alter table #Charts add Patient_Class_ID int;

    update
        t
    set
        t.patient_class_ID = c.PATIENT_CLASS_ID
    from
        #Charts as t
    join
    CHART       as c with (nolock, index(1)) on t.chart_ID = c.CHART_ID;

    delete from
    #Charts
    where
        patient_class_ID not in
        (
            select * from SplitString(@m_PatientClass, ',')
        );
    --------------------------------------------------
    -- new 


	--print 'Section: 03 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------

    -- Places selected CODES into Temp Table
    if object_id('TempDB..#CODES1', 'U') is not null
        drop table #CODES1;

    select
        *
    into
        #CODES1
    from
    (select items as CODE from SplitString(@m_CODES, ',') ) t1;



    --create nonclustered index idx_CODE on #CODES1 (CODE);



    -- This Counts all possible CODES for a selected facility
    declare @m_CODES_CNT int = 0;

    --set @m_CODES_CNT = (SELECT count(DISTINCT CASE @m_Code WHEN 1
    --			THEN BILLING_CODE
    --		    ELSE CPT_CODE
    --		END) as CNT
    --FROM CHARGE_MASTER
    --WHERE SERVICE_AGREEMENT_ID IN 
    --				(
    --				SELECT SERVICE_AGREEMENT_ID
    --				FROM SERVICE_AGREEMENT
    --				WHERE FACILITY_ID IN (@m_Facility)
    --				AND GETDATE() BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
    --				)
    --AND GETDATE() BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
    --);


	--print 'Section: 04 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    if @m_Code = 1
    begin

        set @m_CODES_CNT =
        (
            select
                count(distinct BILLING_CODE) as CNT
            from
                CHARGE_MASTER
            where
                SERVICE_AGREEMENT_ID in
                (
                    select
                        SERVICE_AGREEMENT_ID
                    from
                        SERVICE_AGREEMENT
                    where
                        FACILITY_ID in
                        (
                            select * from SplitString(@m_Facility, ',')
                        ) --(@m_Facility)
                        and getdate() between EFFECTIVE_DATE and EXPIRATION_DATE
                )
                and getdate() between EFFECTIVE_DATE and EXPIRATION_DATE
                and BILLING_CODE <> ''
        );
    end;

    else
    begin
        set @m_CODES_CNT =
        (
            select
                count(distinct CPT_CODE) as CNT
            from
                CHARGE_MASTER
            where
                SERVICE_AGREEMENT_ID in
                (
                    select
                        SERVICE_AGREEMENT_ID
                    from
                        SERVICE_AGREEMENT
                    where
                        FACILITY_ID in
                        (
                            select * from SplitString(@m_Facility, ',')
                        ) --(@m_Facility)
                        and getdate() between EFFECTIVE_DATE and EXPIRATION_DATE
                )
                and getdate() between EFFECTIVE_DATE and EXPIRATION_DATE
                and CPT_CODE <> ''
        );
    end;


    --print 'Section: 05 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    alter table #Charts
    add
        provider_eval_performed_by_ind bit
        ,physician_ID int
        ,nurse_practitioner_ID int
        ,chart_status_ID int
        ,sent_date datetime
                                        --patient_class_ID int,				-- edited 12/5/2017 - this column is now added in previous step
        ,facility_Chart_ID varchar(20)
        ,patient_last_name varchar(35)
        ,patient_first_name varchar(25)
        ,facility_admin_chart_ID varchar(20)
        ,time_of_service datetime
        ,facility_ID int
        ,location_code varchar(10)
        ,no_physician_services bit
        ,service_agreement_ID int
        ,evaluate_physician_svc int
        ,evaluate_physician_procedures int
        ,evaluate_facility_svc int
        ,evaluate_facility_procedures int
        ,infusion_injection_method_ID int
        ,perform_diagnosis_coding int
        ,collect_consulting_physicians varchar(1)
        ,COLLECT_ANESTHESIA varchar(1)
        ,[Physician Name] varchar(80)
        ,facility_prof_ID int
        ,CUID int
        ,ProcedureProvider varchar(50)  --ACS 12534 JHerrera
        ,PATIENT_DOB datetime           --ACS-13061 DHutton
        ,Financial_Class_Cd varchar(10) --ACS-13061 DHutton

        ,Attending varchar(150)
        ,Midlevel varchar(150)
        ,RESIDENT_PHYS_PRESENT varchar(5)
        ,FacilityProcedureProvider varchar(150);

    update
        t
    set
        t.chart_status_ID = c.CHART_STATUS_ID
        ,t.sent_date = c.SENT_DATE
    --t.patient_class_ID = c.patient_class_ID		-- edited 12/5/2017 - this column is now populated in previous step
    from
        #Charts as t
    join
    CHART       as c with (nolock) on t.chart_ID = c.CHART_ID;

    delete from
    #Charts
    where
        chart_status_ID <> 5
        or sent_date >= dateadd(day, -1, getdate());

    update
        t
    set
        t.provider_eval_performed_by_ind = c.PROVIDER_EVAL_PERFORMED_BY_IND
        ,t.physician_ID = c.PHYSICIAN_ID
        ,t.nurse_practitioner_ID = c.NURSE_PRACTITIONER_ID
        ,t.facility_Chart_ID = c.FACILITY_CHART_ID
        ,t.patient_last_name = c.PATIENT_LAST_NAME
        ,t.patient_first_name = c.PATIENT_FIRST_NAME
        ,t.facility_admin_chart_ID = c.FACILITY_ADMIN_CHART_ID
        ,t.time_of_service = c.TIME_OF_SERVICE
        ,t.facility_ID = c.FACILITY_ID
        --,t.location_code = c.LOCATION_CODE
        ,t.no_physician_services = c.NO_PHYSICIAN_SERVICES
        ,t.service_agreement_ID = c.SERVICE_AGREEMENT_ID
        ,t.PATIENT_DOB = c.PATIENT_DOB
        ,t.Financial_Class_Cd = c.FINANCIAL_CLASS_CD
    from
        #Charts as t
    join
    CHART       as c with (nolock) on t.chart_ID = c.CHART_ID;

    update
        t
    set
        t.evaluate_physician_svc = cast(sa.EVALUATE_PHYSICIAN_SVC as int)
        ,t.evaluate_physician_procedures = cast(sa.EVALUATE_PHYSICIAN_PROCEDURES as int)
        ,t.evaluate_facility_svc = cast(sa.EVALUATE_FACILITY_SVC as int)
        ,t.evaluate_facility_procedures = cast(sa.EVALUATE_FACILITY_PROCEDURES as int)
        ,t.infusion_injection_method_ID = sa.INFUSION_INJECTION_METHOD_ID
        ,t.perform_diagnosis_coding = cast(sa.PERFORM_DIAGNOSIS_CODING as int)
        ,t.collect_consulting_physicians = sa.COLLECT_CONSULTING_PHYSICIANS
        ,t.COLLECT_ANESTHESIA = sa.COLLECT_ANESTHESIA
    from
        #Charts       as t
    join
    SERVICE_AGREEMENT as sa with (nolock) on t.service_agreement_ID = sa.SERVICE_AGREEMENT_ID;

    update
        c
    set
        c.facility_prof_ID = fp.FACILITY_PROF_ID
        ,[Physician Name] = fp.LAST_NAME + ', ' + fp.FIRST_NAME
        ,Attending = att.LAST_NAME + ', ' + att.FIRST_NAME
        ,Midlevel = mlp.LAST_NAME + ', ' + mlp.FIRST_NAME
        --,RESIDENT_PHYS_PRESENT = case
        --                             when sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE = 'R' then
        --                                 case t.RESIDENT_PARTICIPATED_IN_CARE
        --                                     when 1 then 'Yes'
        --                                     when 0 then 'No'
        --                                 else '' end
        --                         else null end
    from
        #Charts           as c
    join
    CHART                 as t with (nolock) on t.CHART_ID = c.chart_ID
    join
    SERVICE_AGREEMENT     sa on t.FACILITY_ID = sa.FACILITY_ID
                                and t.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
    inner join
    FACILITY_PROFESSIONAL fp with (nolock) on (case
                                                   when c.PROVIDER_EVAL_PERFORMED_BY_IND is null
                                                        or c.PROVIDER_EVAL_PERFORMED_BY_IND = 0 then c.PHYSICIAN_ID
                                                   when c.PROVIDER_EVAL_PERFORMED_BY_IND = 1 then
                                                       c.nurse_practitioner_id end
                                              ) = fp.FACILITY_PROF_ID
    left join
    FACILITY_PROFESSIONAL att on att.FACILITY_PROF_ID = c.PHYSICIAN_ID
    left join
    FACILITY_PROFESSIONAL mlp on mlp.FACILITY_PROF_ID = c.NURSE_PRACTITIONER_ID;

    update
        c
    set
        FacilityProcedureProvider = fp.LAST_NAME + ', ' + fp.FIRST_NAME
    from
        #Charts c
    outer apply
    (
        select top 1
            *
        from
            FACILITY_PROCEDURE_EVALUATION fpe
        where
            c.CHART_ID = fpe.CHART_ID
        order by
            fpe.FACILITY_PROCEDURE_ID desc
    )           fpe
    left join
    FACILITY_PROFESSIONAL fp on fpe.PHYSICIAN_ID = fp.FACILITY_PROF_ID;


    delete from
    #Charts
    where
        facility_prof_ID not in
        (
            select FACILITY_PROF_ID from #Provider1
        );


    update
        t
    set
        CUID = COMPLETED_BY_USER_PROFILE_ID		       

    from
        #Charts t
    inner join
    CHART       c with (nolock) on t.chart_ID = c.CHART_ID;



	--print 'Section: 06 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    select
        *
    into
        #Override1
    from
    (
        select distinct
            case @m_Code when 0 then psp.CPT_CODE else psp.BILLING_CODE end as Code
        from
            PHYSICIAN_SERVICE_PROCEDURE psp with (nolock)
            ,SERVICE_AGREEMENT sa with (nolock)
        where
            psp.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
            and sa.FACILITY_ID in
                (
                    select * from SplitString(@m_Facility, ',')
                )
            and psp.PATIENT_CLASS_ID in
                (
                    select * from SplitString(@m_PatientClass, ',')
                )
            and
            (
                psp.CPT_CODE in
                (
                    select CODE from #CODES1
                )
                or psp.BILLING_CODE in
                   (
                       select CODE from #CODES1
                   )
            )
            and OVERRIDE_ONLY_IND = 1
        union
        select distinct
            case @m_Code when 0 then fl.CPT_CODE else fl.BILLING_CODE end as Code
        from
            FACILITY_LEVEL fl with (nolock)
            ,SERVICE_AGREEMENT sa with (nolock)
        where
            fl.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
            and sa.FACILITY_ID in
                (
                    select * from SplitString(@m_Facility, ',')
                )
            and fl.PATIENT_CLASS_ID in
                (
                    select * from SplitString(@m_PatientClass, ',')
                )
            and
            (
                fl.CPT_CODE in
                (
                    select CODE from #CODES1
                )
                or fl.BILLING_CODE in
                   (
                       select CODE from #CODES1
                   )
            )
            and fl.OVERRIDE_LIST_IND = 1
    ) T4;


	--print 'Section: 07 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------

    -- populate subset of Sent_Procedure (tuning step added 12/5/2017)
    select
        sp.seq
        ,sp.chart_ID
        ,sp.source_ID
        ,sp.source_CD
    into
        #SentProcedure
    from
        SENT_PROCEDURE as sp with (nolock)
    join
    #Charts            as c on sp.chart_ID = c.chart_ID;

    create clustered index ix_cls_SentProcedure_Seq on #SentProcedure (SEQ);

    alter table #SentProcedure
    add
        Class varchar(2)
        ,Adjustment_Ind varchar(1)
        ,Quantity int
        ,CPT_Code varchar(5)
        ,Billing_Code varchar(20)
        ,Service_Agreement_ID int
        ,Level_ID int
		,CHARGE_MASTER_ID int;

    update
        t
    set
        t.class = sp.class
        ,t.Adjustment_Ind = sp.Adjustment_Ind
        ,t.Quantity = sp.quantity
        ,t.cpt_code = sp.cpt_code
        ,t.billing_code = sp.billing_code
        ,t.service_agreement_ID = sp.service_agreement_ID
        ,t.level_ID = sp.level_ID
		,t.CHARGE_MASTER_ID = sp.charge_master_id
    from
        #SentProcedure as t
    join
    SENT_PROCEDURE     as sp with (nolock) on t.seq = sp.seq;


    update
        c
    set
        ProcedureProvider = case
                                when fp.FACILITY_PROF_ID is null then 'UNKNOWN'
                            else upper(fp.LAST_NAME + ', ' + fp.FIRST_NAME)end
    from
        #Charts c
        ,PHYSICIAN_PROCEDURE_EVALUATION ppe
        ,FACILITY_PROFESSIONAL fp
    where
        c.chart_ID = ppe.CHART_ID
        and ppe.PHYSICIAN_ID = fp.FACILITY_PROF_ID;


	--print 'Section: 08 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    select
        *
    into
        #Data1
    from
    (
        select
            c.chart_ID
            ,c.FACILITY_CHART_ID                               [Account]
            ,c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME [Patient Name]
            ,c.FACILITY_ADMIN_CHART_ID                         [EMPI]
            ,c.TIME_OF_SERVICE                                 [DOS]
            ,c.SENT_DATE                                       [Sent Date]
            ,c.[Physician Name]
            ,c.Attending
            ,c.Midlevel
            ,c.RESIDENT_PHYS_PRESENT
            ,c.FacilityProcedureProvider
            ,c.EVALUATE_PHYSICIAN_SVC                          [Profee Level On]
            ,c.EVALUATE_PHYSICIAN_PROCEDURES                   [Profee Procs On]
            ,c.EVALUATE_FACILITY_SVC                           [Facility Level On]
            ,c.EVALUATE_FACILITY_PROCEDURES                    [Facility Procs On]
            ,c.INFUSION_INJECTION_METHOD_ID                    [Inf-Inj On]
            ,c.PERFORM_DIAGNOSIS_CODING                        [Dx Coding On]
            ,c.COLLECT_CONSULTING_PHYSICIANS
            ,c.COLLECT_ANESTHESIA
            ,c.NO_PHYSICIAN_SERVICES
            -- replace subquery below with left join to FACILITY which is cleaner and might also perform better
            /*(select name from facility with (nolock) where facility_id = c.FACILITY_ID ) as FacilityName ,*/
            ,FacilityName                                      = f.NAME
            -- replace subquery below with left join to MEDSTAR_CLINIC_LOCATION which is cleaner and might also perform better
            /*(SELECT [DESCRIPTION] FROM MEDSTAR_CLINIC_LOCATION with (nolock) WHERE LOCATION_CODE = c.LOCATION_CODE) [Location Code],*/
            ,[Location Code]                                   = mcl.DESCRIPTION
            -- replace subquery below with left join to PATIENT_CLASS which is cleaner and might also perform better
            --(select Description from PATIENT_CLASS with (nolock) where patient_class_id = c.patient_class_id ) as Patient_Class
            ,Patient_Class                                     = pc.DESCRIPTION
            -- With large data sets, cold buffer performance is about twice as good from having moved the next five subqueries to subsequent steps, but warm performance is not as good.  Probably worth the trade-off.
            -- Small data sets have equitable performance here of old vs new version.
            -- moved FOR XML population of Consulting_Physician_Name to subsequent step to guard against potential poor performance of subqueries in some situations
            -- moved FOR XML population of Diagnoses to subsequent step to guard against potential poor performance of subqueries in some situations
            -- moved FOR XML population of ICD9_Diagnoses_Desc to subsequent step to guard against potential poor performance of subqueries in some situations
            -- moved FOR XML population of ICD10_Diagnoses to subsequent step to guard against potential poor performance of subqueries in some situations
            -- moved FOR XML population of ICD10_Diagnoses_Desc to subsequent step to guard against potential poor performance of subqueries in some situations

            -- moved FOR XML population of [Facility Level] to subsequent step which reduced logical reads by 400K
            -- moved FOR XML population of [Facility Procedure] to subsequent step which reduced logical reads by 500K
            -- moved FOR XML population of [Physician Level] to subsequent step which reduced logical reads by 400K
            -- moved FOR XML population of [Physician Procedure] to subsequent step which reduced logical reads by 500K
            -- moved FOR XML population of [Infusion/Injection] to subsequent step which reduced logical reads by 500K

            -- moved population of FacilityLevelDesc to subsequent step which reduced logical reads by 750K
            -- moved population of PhysicianLevelDesc to subsequent step which reduced logical reads by 700K
            -- moved population of OverRide to subsequent step which reduced logical reads by 1.5M
            ,c.CUID
            ,up.LAST_NAME + ', ' + up.FIRST_NAME               [Coder]
            ,up.USER_CLASS_CD
            ,c.physician_ID
            ,c.ProcedureProvider
            ,c.PATIENT_DOB
            ,c.SERVICE_AGREEMENT_ID
            ,c.Financial_Class_Cd
        from
            #Charts             as c
        left join
        FACILITY                as f with (nolock) on c.FACILITY_ID = f.FACILITY_ID -- added 12/12/2017
        left join
        PATIENT_CLASS           as pc with (nolock) on c.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID -- added 12/12/2017
        left join
        MEDSTAR_CLINIC_LOCATION as mcl with (nolock) on c.LOCATION_CODE = mcl.LOCATION_CODE -- added 12/12/2017
        left join
        USER_PROFILE            up with (nolock) on c.CUID = up.USER_PROFILE_ID -- added 05/02/2018 jherrera
    ) T3;

    create clustered index ix_cls_Data1_ChartID on #Data1 (chart_ID); -- added index 12/12/2017

    -- add columns to #Data1 for subsequent population of FOR XML data - 12/12/2017
    alter table #Data1
    add
        Consulting_Physician_Name varchar(max)
        ,Diagnoses varchar(max)
        ,ICD9_Diagnoses_Desc varchar(max)
        ,ICD10_Diagnoses varchar(max)
        ,ICD10_Diagnoses_Desc varchar(max)
        ,[Facility Level] varchar(max)
        ,[Facility Procedure] varchar(max)
        ,[Facility Procedure Description] varchar(max)
        ,[Physician Level] varchar(max)
        ,[Physician Procedure] varchar(max)
        ,[Physician Procedure Description] varchar(max)
        ,[Infusion/Injection] varchar(max)
        ,FacilityLevelDesc varchar(1000)
        ,PhysicianLevelDesc varchar(1000)
        ,Override varchar(10)
        ,Financial_Class varchar(100)
        ,Anesthesia_Codes varchar(100)
        ,Surgical_Procedures varchar(100);


	--print 'Section: 09 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    -- populate Consulting_Physician_Name
    select
        c.chart_ID
        ,Consulting_Physician_Name = fp2.LAST_NAME + ', ' + fp2.FIRST_NAME
    into
        #ChartConsultingPhysician
    from
        CHART_CONSULTING_PHYSICIAN as cpp with (nolock)
    join
    #Charts                        as c on cpp.CHART_ID = c.chart_ID
    join
    FACILITY_PROFESSIONAL          as fp2 with (nolock) on fp2.FACILITY_PROF_ID = cpp.FACILITY_PROFESSIONAL_ID;

    update
        c
    set
        c.Consulting_Physician_Name = ltrim(stuff((
                                                      select
                                                          ', ' + Consulting_Physician_Name
                                                      from
                                                          #ChartConsultingPhysician as t
                                                      where
                                                          t.CHART_ID = c.CHART_ID
                                                      order by
                                                          Consulting_Physician_Name
                                                      for xml path(''), type
                                                  ).value('.', 'VARCHAR(MAX)')
                                                     ,1
                                                     ,1
                                                     ,''
                                                 )
                                           )
    from
        #Data1 as c;



	--print 'Section: 10 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    -- populate Diagnoses 
    select
        c.chart_ID
        ,cdc.ICD9_CODE
    into
        #ChartDiagnoses
    from
        CHART_DIAGNOSIS_CODE as cdc with (nolock)
    join
    #Charts                  as c on cdc.CHART_ID = c.chart_ID;

    update
        c
    set
        c.Diagnoses = ltrim(stuff((
                                      select
                                          ', ' + ICD9_CODE
                                      from
                                          #ChartDiagnoses as t
                                      where
                                          t.CHART_ID = c.CHART_ID
                                      order by
                                          ICD9_CODE
                                      for xml path(''), type
                                  ).value('.', 'VARCHAR(MAX)')
                                     ,1
                                     ,1
                                     ,''
                                 )
                           )
    from
        #Data1 as c;



	--print 'Section: 11 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    -- populate ICD9_Diagnoses_Desc 
    select
        c.chart_ID
        ,cm9.icd9_code
        ,cm9.short_description
    into
        #ChartICD9Desc
    from
        CHART_DIAGNOSIS_CODE as cdc with (nolock)
    join
    #Charts                  as c on cdc.CHART_ID = c.chart_ID
    join
    ICD_9_CM                 as cm9 with (nolock) on cm9.icd9_code = cdc.ICD9_CODE
                                                     and getdate() between cm9.effective_date and cm9.expiration_date;

    update
        c
    set
        c.ICD9_Diagnoses_Desc = ltrim(stuff((
                                                select
                                                    ', ' + short_description
                                                from
                                                    #ChartICD9Desc as t
                                                where
                                                    t.CHART_ID = c.CHART_ID
                                                order by
                                                    ICD9_CODE
                                                for xml path(''), type
                                            ).value('.', 'VARCHAR(MAX)')
                                               ,1
                                               ,1
                                               ,''
                                           )
                                     )
    from
        #Data1 as c;


	--print 'Section: 12 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    -- populate ICD10_Diagnoses 
    select
        c.chart_ID
        ,cdc10.ICD10_CODE
    into
        #ChartDiagnoses10
    from
        CHART_DIAGNOSIS_CODE_ICD10 as cdc10 with (nolock)
    join
    #Charts                        as c on cdc10.CHART_ID = c.chart_ID;

    update
        c
    set
        c.ICD10_Diagnoses = ltrim(stuff((
                                            select
                                                ', ' + ICD10_CODE
                                            from
                                                #ChartDiagnoses10 as t
                                            where
                                                t.CHART_ID = c.CHART_ID
                                            order by
                                                ICD10_CODE
                                            for xml path(''), type
                                        ).value('.', 'VARCHAR(MAX)')
                                           ,1
                                           ,1
                                           ,''
                                       )
                                 )
    from
        #Data1 as c;



	--print 'Section: 13 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------

    -- derive CaseCode for all records in #SentProcedure with applicable Class value
    select
        chart_ID
        ,Class
        ,CPT_Code
        ,CaseCode = case @m_Code when 0 then CPT_CODE else BILLING_CODE end
		,CHARGE_MASTER_ID
    into
        #ProcedureClassCodes
    from
        #SentProcedure
    where
        class in ('FP', 'PP', 'IP');



	--print 'Section: 14 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------

    -- populate [Facility Level]
    -- Delaying population of [Facility Level] reduced reads by 400K for this section during testing.
    select
        chart_ID
        ,Adjustment_Ind = max(Adjustment_Ind)
    into
        #ChartMaxAdjIndFL
    from
        #SentProcedure
    where
        class = 'FL'
    group by
        chart_ID;

    select
        sp.chart_ID
        ,FacilityLevel = case
                             when @m_Code = 0
                                  and
                                  (
                                      sp.Adjustment_Ind <> 'Y'
                                      or sp.QUANTITY > 0
                                  ) -- Handle adjustment where the level is removed
        then                     sp.CPT_CODE
                             when @m_Code = 1
                                  and
                                  (
                                      sp.Adjustment_Ind <> 'Y'
                                      or sp.QUANTITY > 0
                                  ) then sp.BILLING_CODE
                         else null end
    into
        #ChartFacilityLevel
    from
        #SentProcedure as sp
    join
    #ChartMaxAdjIndFL  as a on sp.chart_ID = a.chart_ID
                               and sp.Adjustment_Ind = a.Adjustment_Ind
    where
        sp.class = 'FL';

    update
        t1
    set
        t1.[Facility Level] = t2.FacilityLevel
    from
        #Data1          as t1
    join
    #ChartFacilityLevel as t2 on t1.chart_ID = t2.chart_ID;


	--print 'Section: 15 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------
	
    -- populate [Facility Procedure]
    -- Delaying population of [Facility Procedure] reduced reads by 500K for this section during testing.
    select
        *
    into
        #ChartFP
    from
        #ProcedureClassCodes
    where
        class = 'FP';

    update
        c
    set
        c.[Facility Procedure] = ltrim(stuff((
                                                 select
                                                     ', ' + CaseCode
                                                 from
                                                     #ChartFP as t
                                                 where
                                                     t.CHART_ID = c.chart_id
                                                 order by
                                                     CPT_Code
                                                 for xml path(''), type
                                             ).value('.', 'VARCHAR(MAX)')
                                                ,1
                                                ,1
                                                ,''
                                            )
                                      )
    from
        #Data1 as c;


	update c 
	set
		c.[Facility Procedure Description] = cm.[DESCRIPTION]
	from
		#Data1 c
		inner join #ChartFP fp on c.chart_ID = fp.chart_id
		left join dbo.CHARGE_MASTER cm on fp.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID


	--print 'Section: 16 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------

    -- populate [Physician Level]
    -- Delaying population of [Physician Level] reduced reads by 400K for this section during testing.
    select
        chart_ID
        ,Adjustment_Ind = max(Adjustment_Ind)
    into
        #ChartMaxAdjIndPL
    from
        #SentProcedure
    where
        class = 'PL'
    group by
        chart_ID;

    select
        sp.chart_ID
        ,PhysicianLevel = case
                              when @m_Code = 0
                                   and
                                   (
                                       sp.Adjustment_Ind <> 'Y'
                                       or sp.QUANTITY > 0
                                   ) -- Handle adjustment where the level is removed
        then                      sp.CPT_CODE
                              when @m_Code = 1
                                   and
                                   (
                                       sp.Adjustment_Ind <> 'Y'
                                       or sp.QUANTITY > 0
                                   ) then sp.BILLING_CODE
                          else null end
    into
        #ChartPhysicianLevel
    from
        #SentProcedure as sp
    join
    #ChartMaxAdjIndPL  as a on sp.chart_ID = a.chart_ID
                               and sp.Adjustment_Ind = a.Adjustment_Ind
    where
        sp.class = 'PL';

    update
        t1
    set
        t1.[Physician Level] = t2.PhysicianLevel
    from
        #Data1           as t1
    join
    #ChartPhysicianLevel as t2 on t1.chart_ID = t2.chart_ID;


	--print 'Section: 17 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------
	
    -- populate [Physician Procedure]
    -- Delaying population of [Physician Procedure] reduced reads by 500K for this section during testing.
    select
        *
    into
        #ChartPP
    from
        #ProcedureClassCodes
    where
        class = 'PP';

    update
        c
    set
        c.[Physician Procedure] = ltrim(stuff((
                                                  select
                                                      ', ' + CaseCode
                                                  from
                                                      #ChartPP as t
                                                  where
                                                      t.CHART_ID = c.chart_id
                                                  order by
                                                      CPT_Code
                                                  for xml path(''), type
                                              ).value('.', 'VARCHAR(MAX)')
                                                 ,1
                                                 ,1
                                                 ,''
                                             )
                                       )
    from
        #Data1 as c;


	update c 
	set
		c.[Physician Procedure Description] = cm.[DESCRIPTION]
	from
		#Data1 c
		inner join #ChartPP pp on c.chart_ID = pp.chart_id
		left join dbo.CHARGE_MASTER cm on pp.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID


	--print 'Section: 18 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------

    -- populate [Infusion/Injection]
    -- Delaying population of [Infusion/Injection] reduced reads by 500K for this section during testing.
    select
        *
    into
        #ChartIP
    from
        #ProcedureClassCodes
    where
        class = 'IP';

    update
        c
    set
        c.[Infusion/Injection] = ltrim(stuff((
                                                 select
                                                     ', ' + CaseCode
                                                 from
                                                     #ChartIP as t
                                                 where
                                                     t.CHART_ID = c.chart_id
                                                 order by
                                                     CPT_Code
                                                 for xml path(''), type
                                             ).value('.', 'VARCHAR(MAX)')
                                                ,1
                                                ,1
                                                ,''
                                            )
                                      )
    from
        #Data1 as c;


	--print 'Section: 19 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    -- populate FacilityLevelDesc
    -- Delaying population of FacilityLevelDesc reduced reads by 750K for this section during testing.
    select
        sp.chart_ID
        ,fl.DESCRIPTION
    into
        #ChartFacilityLevelDesc
    from
        #SentProcedure as sp
    join
    FACILITY_LEVEL     as fl with (nolock) on sp.level_ID = fl.FACILITY_LEVEL_ID
                                              and sp.SERVICE_AGREEMENT_ID = fl.SERVICE_AGREEMENT_ID
    where
        sp.CLASS = 'FL';

    update
        t1
    set
        t1.FacilityLevelDesc = t2.DESCRIPTION
    from
        #Data1              as t1
    join
    #ChartFacilityLevelDesc as t2 on t1.chart_ID = t2.chart_ID;



	--print 'Section: 20 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------

    -- populate PhysicianLevelDesc
    -- Delaying population of PhysicianLevelDesc reduced reads by 700K for this section during testing.
    select
        sp.chart_ID
        ,psp.DESCRIPTION
    into
        #ChartPhysicianLevelDesc
    from
        #SentProcedure          as sp
    join
    PHYSICIAN_SERVICE_PROCEDURE as psp with (nolock) on sp.level_ID = psp.PHYSICIAN_SERVICE_PROC_ID
                                                        and sp.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
    where
        sp.CLASS = 'PL'
        and sp.source_cd = 'PL';

    update
        t1
    set
        t1.PhysicianLevelDesc = t2.DESCRIPTION
    from
        #Data1               as t1
    join
    #ChartPhysicianLevelDesc as t2 on t1.chart_ID = t2.chart_ID;


	--print 'Section: 21 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------


    -- populate Override
    -- Delaying population of Override reduced reads by 1.5M for this section during testing.
    select
        chart_ID
    into
        #ChartOverride
    from
        #SentProcedure as sp
    where
        CLASS in ('FL', 'FP', 'PL', 'PP', 'IP')
        and exists
    (
        select
            1
        from
            #Override1
        where
            case @m_Code when 0 then sp.CPT_CODE else sp.BILLING_CODE end = #Override1.Code
    );

    update
        #Data1
    set
        Override = 'Y'
    where
        chart_ID in
        (
            select chart_ID from #ChartOverride
        );


	--print 'Section: 22 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------

		
    -- populate ICD10_Diagnoses_Desc 
    select
        c.chart_ID
        ,Short_Description = cast(null as varchar(150))/*cm10.SHORT_DESCRIPTION*/
        ,icd10.ICD10_CODE                              --icd10.posting_order
    into
        #ICD10CM
    from
        #Data1                 as c
    join
    CHART_DIAGNOSIS_CODE_ICD10 as icd10 with (nolock) on icd10.CHART_ID = c.chart_ID;

    update
        t -- broke out this REPLACE join to a separate step 12/12/2017 to avoid unpredictable poor performance (in one test, prior version took 10 minutes on this step)
    set
        t.Short_Description = cm10.SHORT_DESCRIPTION
    from
        #ICD10CM as t
    join
    ICD_10_CM    as cm10 with (nolock) on cm10.ICD_10_CODE = replace(t.ICD10_CODE, '.', '')
                                          and getdate() between cm10.EFFECTIVE_DATE and cm10.EXPIRATION_DATE;

    update
        c -- note that some Chart_IDs in CHART_DIAGNOSIS_CODE_ICD10 have duplicate values for Posting_Order which will produce random results in the ordering here
    set
        c.ICD10_Diagnoses_Desc = ltrim(stuff((
                                                 select
                                                     ', ' + Short_Description
                                                 from
                                                     #ICD10CM as t
                                                 where
                                                     t.chart_ID = c.chart_ID
                                                 order by
                                                     ICD10_CODE --POSTING_ORDER				
                                                 for xml path(''), type
                                             ).value('.', 'VARCHAR(MAX)')
                                                ,1
                                                ,1
                                                ,''
                                            )
                                      )
    from
        #Data1 as c;


    update
        #Data1
    set
        [OverRide] = 'N'
    where
        [OverRide] is null;


    -- This is to prevent Clients from seeing other Coder Names.
    update
        #Data1
    set
        Coder = null
    where
        USER_CLASS_CD <> 4
        and exists
    (
        select
            *
        from
            USER_PROFILE with (nolock)
        where
            USER_PROFILE_ID = @ReportUser
            and IS_ACTIVE = 'Y'
            and USER_CLASS_CD = 4
    );



    -- populate Financial_Class 
    update
        c
    set
        c.Financial_Class = fc.DESCRIPTION
    from
        #Data1               as c
    join
    FACILITY_FINANCIAL_CLASS as fc on c.SERVICE_AGREEMENT_ID = fc.SERVICE_AGREEMENT_ID
                                      and c.financial_class_cd = fc.FINANCIAL_CLASS_CD;



    -- populate Anesthesia_Codes

    --update
    --    d
    --set
    --    d.Anesthesia_Codes = ltrim(stuff((
    --                                         select
    --                                             ', ' + ANESTHESIA_CODE
    --                                         from
    --                                             CHART_ANESTHESIA_CODE as cac
    --                                         where
    --                                             cac.CHART_ID = d.CHART_ID
    --                                         order by
    --                                             ANESTHESIA_CODE
    --                                         for xml path(''), type
    --                                     ).value('.', 'VARCHAR(MAX)')
    --                                        ,1
    --                                        ,1
    --                                        ,''
    --                                    )
    --                              )
    --from
    --    #Data1 as d;


    -- populate Surgical_Procedures

    --update
    --    d
    --set
    --    d.Surgical_Procedures = ltrim(stuff((
    --                                            select
    --                                                ', ' + SURGICAL_PROCEDURE_CODE
    --                                            from
    --                                                CHART_ANESTHESIA_SURGICAL_PROCEDURE as casp
    --                                            where
    --                                                casp.CHART_ID = d.CHART_ID
    --                                            order by
    --                                                SURGICAL_PROCEDURE_CODE
    --                                            for xml path(''), type
    --                                        ).value('.', 'VARCHAR(MAX)')
    --                                           ,1
    --                                           ,1
    --                                           ,''
    --                                       )
    --                                 )
    --from
    --    #Data1 as d;




	--print 'Section: 23 ' + convert(varchar, getdate(), 121)
    ----------------------------------------------------------------------------------------------------




    if object_id('TempDB..#Output1', 'U') is not null
        drop table #Output1;

    create table #Output1
    (
        chart_id                       int
        ,Account                       varchar(20)
        ,[Patient Name]                varchar(65)
        ,[EMPI]                        varchar(20)
        ,[DOS]                         datetime
        ,[Sent Date]                   datetime
        ,[Physician Name]              varchar(65)
        ,Attending                     varchar(150)
        ,Midlevel                      varchar(150)
        ,RESIDENT_PHYS_PRESENT         varchar(5)
        ,FacilityProcedureProvider     varchar(150)
        ,No_Physician_Services         int
        ,FacilityName                  varchar(65)
        ,[Location Code]               varchar(65)
        ,Patient_Class                 varchar(65)
        ,CUID                          int
        ,Coder                         varchar(65)
        ,USER_CLASS_CD                 int
        ,physician_ID                  int
        ,ProcedureProvider             varchar(65)
        ,Patient_DOB                   datetime
		,Patient_Age				   int
		,Patient_Age_Group			   int 	
        ,Service_Agreement_ID          int
        ,Financial_Class_CD            varchar(65)
        ,Consulting_Physician_Name     varchar(max)
        ,Diagnoses                     varchar(max)
        ,ICD9_Diagnoses_Desc           varchar(max)
        ,ICD10_Diagnoses               varchar(max)
        ,ICD10_Diagnoses_Desc          varchar(max)
        ,[Facility Level]              varchar(max)
        ,[Facility Procedure]          varchar(max)
        ,[Facility Procedure Description]          varchar(max)
        ,[Physician Level]             varchar(max)
        ,[Physician Procedure]         varchar(max)
        ,[Physician Procedure Description]         varchar(max)
        ,[Infusion/Injection]          varchar(max)
        ,FacilityLevelDesc             varchar(1000)
        ,PhysicianLevelDesc            varchar(1000)
        ,[Override]                    varchar(10)
        ,Financial_Class               varchar(100)
        ,Anesthesia_Codes              varchar(100)
        ,Surgical_Procedures           varchar(100)
        ,Profee_Level_On               int
        ,Profee_Procs_On               int
        ,Facility_Level_On             int
        ,Facility_Procs_On             int
        ,Inf_Inj_On                    int
        --[Dx Coding On]					int,
        ,COLLECT_CONSULTING_PHYSICIANS varchar(10)
        ,COLLECT_ANESTHESIA            int
    );





    -- If all CODES for the facility are selected, no loop.

    if @m_CODES_CNT =
    (
        select count(*)from #CODES1
    ) --(SELECT count(items) FROM SPLITSTRING(@m_CODES, ','))
    begin
        insert into #Output1
        select
            chart_ID
            ,Account
            ,[Patient Name]
            ,[EMPI]
            ,[DOS]
            ,[Sent Date]
            ,[Physician Name]
            ,Attending
            ,Midlevel
            ,RESIDENT_PHYS_PRESENT
            ,FacilityProcedureProvider
            ,No_Physician_Services
            ,FacilityName
            ,[Location Code]
            ,Patient_Class
            ,CUID
            ,Coder
            ,USER_CLASS_CD
            ,physician_ID
            ,ProcedureProvider
            ,Patient_DOB
			,PATIENT_Age = (DATEDIFF(day, PATIENT_DOB, getdate() )/365) -- RAP-230 Patient_AGE
			,Patient_Age_Group = NULL
            ,SERVICE_AGREEMENT_ID
            ,Financial_Class_CD
            ,Consulting_Physician_Name
            ,Diagnoses
            ,ICD9_Diagnoses_Desc
            ,ICD10_Diagnoses
            ,ICD10_Diagnoses_Desc
            ,[Facility Level]
            ,[Facility Procedure]
            ,[Facility Procedure Description]
            ,[Physician Level]
            ,[Physician Procedure]
            ,[Physician Procedure Description]
            ,[Infusion/Injection]
            ,FacilityLevelDesc
            ,PhysicianLevelDesc
            ,[Override]
            ,Financial_Class
            ,Anesthesia_Codes
            ,Surgical_Procedures
            ,[Profee Level On]
            ,[Profee Procs On]
            ,[Facility Level On]
            ,[Facility Procs On]
            ,[Inf-Inj On]
            --[Dx Coding On]					,
            ,COLLECT_CONSULTING_PHYSICIANS
            ,case
                 when COLLECT_ANESTHESIA = 'O' then 0
                 when COLLECT_ANESTHESIA = 'R' then 0
             else 1 end COLLECT_ANESTHESIA
        from
            #Data1;


			
    end;
    else -- loop through selected CODES


    declare @minCode varchar(150)

    declare @i int;
    set @i = 0;
    while @i < (select count(*)from #CODES1)
    begin


        set @minCode = (select top 1 CODE from #CODES1 order by CODE)

        begin
            insert into #Output1
            select
                chart_ID
                ,Account
                ,[Patient Name]
                ,[EMPI]
                ,[DOS]
                ,[Sent Date]
                ,[Physician Name]
                ,Attending
                ,Midlevel
                ,RESIDENT_PHYS_PRESENT
                ,FacilityProcedureProvider
                ,No_Physician_Services
                ,FacilityName
                ,[Location Code]
                ,Patient_Class
                ,CUID
                ,Coder
                ,USER_CLASS_CD
                ,physician_ID
                ,ProcedureProvider
                ,Patient_DOB
				,PATIENT_Age = (DATEDIFF(day, PATIENT_DOB, getdate() )/365) -- RAP-230 Patient_AGE
				,Patient_Age_Group = NULL
                ,SERVICE_AGREEMENT_ID
                ,Financial_Class_CD
                ,Consulting_Physician_Name
                ,Diagnoses
                ,ICD9_Diagnoses_Desc
                ,ICD10_Diagnoses
                ,ICD10_Diagnoses_Desc
                ,[Facility Level]
                ,[Facility Procedure]
                ,[Facility Procedure Description]
                ,[Physician Level]
                ,[Physician Procedure]
                ,[Physician Procedure Description]
                ,[Infusion/Injection]
                ,FacilityLevelDesc
                ,PhysicianLevelDesc
                ,[Override]
                ,Financial_Class
                ,Anesthesia_Codes
                ,Surgical_Procedures
                ,[Profee Level On]
                ,[Profee Procs On]
                ,[Facility Level On]
                ,[Facility Procs On]
                ,[Inf-Inj On]
                --[Dx Coding On]				,
                ,COLLECT_CONSULTING_PHYSICIANS
                ,case
                     when COLLECT_ANESTHESIA = 'O' then 0
                     when COLLECT_ANESTHESIA = 'R' then 0
                 else 1 end COLLECT_ANESTHESIA
            from
                #Data1
            where
                (
                    [Facility Level] = @minCode
                    or [Facility Procedure] = @minCode
                    or [Physician Level] = @minCode
                    or [Physician Procedure] = @minCode
                    or [Infusion/Injection] = @minCode
                    or [Anesthesia_Codes] = @minCode
                    or [Surgical_Procedures] = @minCode
                )
				and not exists
				(
					select o.* from #Output1 o where o.chart_id = #Data1.chart_ID
				); -- used to avoid duplicate records inserted into temp table

        end;



        --delete from
        --#CODES1
        --where
        --    CODE =
        --(
        --    select min(CODE)from #CODES1
        --);


		delete from #CODES1
		where CODE = @minCode

    end;





    update
        t
    set
        Patient_Age_Group = Case when PATIENT_Age = 0 then 1
								 when PATIENT_Age between 1 and 4 then 2
								 when PATIENT_Age between 5 and 11 then 3
								 when PATIENT_Age between 12 and 17 then 4
								 when PATIENT_Age between 18 and 39 then 5
								 when PATIENT_Age between 40 and 64 then 6
								 when PATIENT_Age >= 65 then 7
								 end 
    from
        #Output1 t;

  



	--print 'Section: 24 ' + convert(varchar, getdate(), 121)
    -- *********************************************************************************************************





    select
        *
        ,case
             when No_Physician_Services = 1
                  and [Override] = 'N' then 'Y'
         else 'N' end as Override_Ind
        ,'ALL'        as AllData
        ,case
             when isnull([Physician Name], '') = isnull([ProcedureProvider], '') then 0
         else 1 end   [SharedVisit]
    from
        #Output1
    where
        case
            when @m_Consultant = 1
                 and Consulting_Physician_Name is not null then 1
            when @m_Consultant = 2 then 1
        else 0 end = 1
        and case
                when @m_DisplayNoOverride = 1
                     and No_Physician_Services = 1
                     and [Override] = 'N' then 1
                when @m_DisplayNoOverride = 0 then 1 end = 1
        --and @m_Override in ('-1')
		and ('No Override' in ( select * from dbo.SplitString(@m_Override, ',') ))
        and
        (
            @SharedVisitsOnly = 0
            or case
                   when isnull([ProcedureProvider], '') = '' then 0
                   when isnull([Physician Name], '') = isnull([ProcedureProvider], '') then 0
               else 1 end = 1
        )

		and ( Patient_Age_Group in (select * from SplitString(@m_PatientAgeGroup, ',')) OR -1 in (select * from SplitString(@m_PatientAgeGroup, ',')) )
    union
	-- Facility Level
    select
        *
        ,case
             when No_Physician_Services = 1
                  and [Override] = 'N' then 'Y'
         else 'N' end as Override_Ind
        ,'ALL'        as AllData
        ,case
             when isnull([Physician Name], '') = isnull([ProcedureProvider], '') then 0
         else 1 end   [SharedVisit]
    from
        #Output1
    where
        case
            when @m_Consultant = 1
                 and Consulting_Physician_Name is not null then 1
            when @m_Consultant = 2 then 1
        else 0 end = 1
        and case
                when @m_DisplayNoOverride = 1
                     and No_Physician_Services = 1
                     and [Override] = 'N' then 1
                when @m_DisplayNoOverride = 0 then 1 end = 1
        --and @m_Override not in ('-1')
		and (([Facility Level] + ' - ' + FacilityLevelDesc) in ( select * from dbo.SplitString(@m_Override, ',') ))
        and
        (
            @SharedVisitsOnly = 0
            or case
                   when isnull([ProcedureProvider], '') = '' then 0
                   when isnull([Physician Name], '') = isnull([ProcedureProvider], '') then 0
               else 1 end = 1
        )
		and ( Patient_Age_Group in (select * from SplitString(@m_PatientAgeGroup, ',')) OR -1 in (select * from SplitString(@m_PatientAgeGroup, ',')) )
    union
	-- Physician Level
    select
        *
        ,case
             when No_Physician_Services = 1
                  and [Override] = 'N' then 'Y'
         else 'N' end as Override_Ind
        ,'ALL'        as AllData
        ,case
             when isnull([Physician Name], '') = isnull([ProcedureProvider], '') then 0
         else 1 end   [SharedVisit]
    from
        #Output1
    where
        case
            when @m_Consultant = 1
                 and Consulting_Physician_Name is not null then 1
            when @m_Consultant = 2 then 1
        else 0 end = 1
        and case
                when @m_DisplayNoOverride = 1
                     and No_Physician_Services = 1
                     and [Override] = 'N' then 1
                when @m_DisplayNoOverride = 0 then 1 end = 1
        --and @m_Override not in ('-1')
		and (([Physician Level] + ' - ' + PhysicianLevelDesc) in ( select * from dbo.SplitString(@m_Override, ',') ))
			
        and
        (
            @SharedVisitsOnly = 0
            or case
                   when isnull([ProcedureProvider], '') = '' then 0
                   when isnull([Physician Name], '') = isnull([ProcedureProvider], '') then 0
               else 1 end = 1
        ) 
		and ( Patient_Age_Group in (select * from SplitString(@m_PatientAgeGroup, ',')) OR -1 in (select * from SplitString(@m_PatientAgeGroup, ',')) )
    order by
        [Physician Name]
        ,[Location Code]
        ,[DOS]
        ,[Patient Name];


	--print 'Section: 25 ' + convert(varchar, getdate(), 121)

end;











GO
GRANT EXECUTE ON  [dbo].[rpt_PatientEncountersByPhysician] TO [dbx_ExecuteReportProcs]
GO
