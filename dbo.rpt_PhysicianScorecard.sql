SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE procedure [dbo].[rpt_PhysicianScorecard]
 (
	@Facility           varchar(max) 
	,@Physician         varchar(max) 
	,@DateType			int
	,@StartDate         datetime     
	,@EndDate           datetime     
	,@ReportUser        int          
	,@result_type		int
 )
 as

 begin

		set transaction isolation level read uncommitted;
		set nocount on;

		--declare
		--	@Facility     varchar(max) = '1680'
		--	,@Physician   varchar(max) = '1934369'
		--	,@DateType    int          = 1			--0=DOS,1=SentDate
		--	,@StartDate   datetime     = '20220301'
		--	,@EndDate     datetime     = '20220331'
		--	,@ReportUser  int          = 80
		--	,@result_type int          = 0;	--0=Summary, 1=PatientEncountersbyPhysician, 2=ProviderRVUAnalysis, 3=ProviderOpportunityExpanded

	
		----------------------------------------------------------------------------------------------------------------------------------

		declare
			@Code              bit          = 0    -- 0 CPT,  1 Billing
			,@ConsultantOnly    int          = 2    -- All Records
			--,@CODES             varchar(max) = '99284,99285,99291,99292'
			--,@PatientClass      varchar(max) = '4599,4600'
			--,@DateType          int          = 1    -- DOS
			,@Override          varchar(max) = '-1'
			,@DisplayNoOverride int          = 0    --0 false
			,@SharedVisitsOnly  int          = 0;   -- 0 False

		-- Insert statements for procedure here
		declare
			@m_Facility           varchar(max)
			= @Facility
			,@m_Physician         varchar(max) = @Physician
			,@m_Code              bit          = @Code
			,@m_StartDate         datetime     = @StartDate
			,@m_EndDate           datetime     = @EndDate -- needs to be datetime data type to use function DateAdd(second, 86399, @m_EndDate)
			,@m_Consultant        int          = @ConsultantOnly
			--,@m_CODES             varchar(max) = @CODES
			--,@m_PatientClass      varchar(max) = @PatientClass
			,@m_DateType          int          = @DateType
			,@m_Override          varchar(max) = @Override
			,@m_DisplayNoOverride int          = @DisplayNoOverride;
		--@m_CODES_CNT int = 0


		-- PatientEncountersbyPhysician
		if object_id('TempDB..#Provider1', 'U') is not null drop table #Provider1;
		if object_id('TempDB..#Data1', 'U') is not null drop table #Data1;
		if object_id('TempDB..#Override1', 'U') is not null drop table #Override1;
		if object_id('TempDB..#ICD10CM', 'U') is not null drop table #ICD10CM;
		if object_id('TempDB..#Charts', 'U') is not null drop table #Charts;
		if object_id('TempDB..#SentProcedure', 'U') is not null drop table #SentProcedure;
		if object_id('TempDB..#ChartConsultingPhysician', 'U') is not null drop table #ChartConsultingPhysician;
		if object_id('TempDB..#ChartDiagnoses', 'U') is not null drop table #ChartDiagnoses;
		if object_id('TempDB..#ChartICD9Desc', 'U') is not null drop table #ChartICD9Desc;
		if object_id('TempDB..#ChartDiagnoses10', 'U') is not null drop table #ChartDiagnoses10;
		if object_id('TempDB..#ProcedureClassCodes', 'U') is not null drop table #ProcedureClassCodes;
		if object_id('TempDB..#ChartMaxAdjIndFL', 'U') is not null drop table #ChartMaxAdjIndFL;
		if object_id('TempDB..#ChartFacilityLevel', 'U') is not null drop table #ChartFacilityLevel;
		if object_id('TempDB..#ChartFP', 'U') is not null drop table #ChartFP;
		if object_id('TempDB..#ChartMaxAdjIndPL', 'U') is not null drop table #ChartMaxAdjIndPL;
		if object_id('TempDB..#ChartPhysicianLevel', 'U') is not null drop table #ChartPhysicianLevel;
		if object_id('TempDB..#ChartPP', 'U') is not null drop table #ChartPP;
		if object_id('TempDB..#ChartIP', 'U') is not null drop table #ChartIP;
		if object_id('TempDB..#ChartFacilityLevelDesc', 'U') is not null drop table #ChartFacilityLevelDesc;
		if object_id('TempDB..#ChartPhysicianLevelDesc', 'U') is not null drop table #ChartPhysicianLevelDesc;
		if object_id('TempDB..#ChartOverride', 'U') is not null drop table #ChartOverride;
		-- PatientEncountersbyPhysician

	
		-- ProviderRVUAnalysis
		if object_id('TempDB..#tmp', 'U') is not null drop table #tmp;
		if object_id('TempDB..#CHART_rvu', 'U') is not null drop table #CHART_rvu;
		if object_id('TempDB..#SENT_PROCEDURE', 'U') is not null drop table #SENT_PROCEDURE;
		-- ProviderRVUAnalysis


		-- ProviderOpportunityExpanded
		if object_id('TempDB..#CHART_poe', 'U') is not null drop table #CHART_poe;
		if object_id('TempDB..#CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT', 'U') is not null drop table #CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT;
		if object_id('TempDB..#CHARGE_MASTER', 'U') is not null drop table #CHARGE_MASTER;
		if object_id('TempDB..#tmp1', 'U') is not null drop table #tmp1;
		if object_id('TempDB..#tmp2', 'U') is not null drop table #tmp2;
		-- ProviderOpportunityExpanded


		-- Data result temp tables
		if object_id('TempDB..#PatientEncountersbyPhysician', 'U') is not null drop table #PatientEncountersbyPhysician;
		if object_id('TempDB..#ProviderRVUAnalysis', 'U') is not null drop table #ProviderRVUAnalysis;
		if object_id('TempDB..#ProviderOpportunityExpanded', 'U') is not null drop table #ProviderOpportunityExpanded;
		-- Data result temp tables



		print 'Section: 00 ' + convert(varchar, getdate(), 121)
		--print 'Begin Patient Encounters by Physician:  ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------------------------------------
		-- Patient Encounters by Physician

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


		print 'Section: 01 ' + convert(varchar, getdate(), 121)
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

		create nonclustered index ix_cls_CHARTS_ChartID on #Charts (chart_ID); -- added index 12/12/2017


		print 'Section: 02 ' + convert(varchar, getdate(), 121)
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

		--delete from
		--#Charts
		--where
		--    patient_class_ID not in
		--    (
		--        select * from SplitString(@m_PatientClass, ',')
		--    );
		--------------------------------------------------
		-- new 


		print 'Section: 03 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------------------------------------

		-- Places selected CODES into Temp Table
		if object_id('TempDB..#CODES1', 'U') is not null drop table #CODES1;

		SELECT DISTINCT CASE @Code
			WHEN 1
					THEN BILLING_CODE
				ELSE CPT_CODE
				END CODE
		into #CODES1
		FROM CHARGE_MASTER  WITH (NOLOCK)
		WHERE SERVICE_AGREEMENT_ID IN (
				SELECT SERVICE_AGREEMENT_ID
				FROM SERVICE_AGREEMENT WITH (NOLOCK)
				WHERE FACILITY_ID in (select * from SplitString(@Facility, ','))
					AND GETDATE() BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
				)
			AND GETDATE() BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
		ORDER BY CODE;



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


		print 'Section: 04 ' + convert(varchar, getdate(), 121)
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


		print 'Section: 05 ' + convert(varchar, getdate(), 121)
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
			,t.location_code = null --c.LOCATION_CODE
			,t.no_physician_services = c.NO_PHYSICIAN_SERVICES
			,t.service_agreement_ID = c.SERVICE_AGREEMENT_ID
			,t.PATIENT_DOB = null --c.PATIENT_DOB
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
			,RESIDENT_PHYS_PRESENT = null
									--case
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


		print 'Section: 06 ' + convert(varchar, getdate(), 121)
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
				--and psp.PATIENT_CLASS_ID in
				--    (
				--        select * from SplitString(@m_PatientClass, ',')
				--    )
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
				--and fl.PATIENT_CLASS_ID in
				--    (
				--        select * from SplitString(@m_PatientClass, ',')
				--    )
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


		print 'Section: 07 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------------------------------------
	
		-- populate subset of Sent_Procedure (tuning step added 12/5/2017)
	  --  select
	  --      sp.seq
	  --      ,sp.chart_ID
	  --      ,sp.source_ID
	  --      ,sp.source_CD
	  --  into #SentProcedure
	  --  from
	  --      SENT_PROCEDURE as sp with (nolock)
			--join #Charts as c on sp.chart_ID = c.chart_ID;

	  --  create nonclustered index ix_cls_SentProcedure_Seq on #SentProcedure (SEQ);

	  --  alter table #SentProcedure
	  --  add
	  --      Class varchar(2)
	  --      ,Adjustment_Ind varchar(1)
	  --      ,Quantity int
	  --      ,CPT_Code varchar(5)
	  --      ,Billing_Code varchar(20)
	  --      ,Service_Agreement_ID int
	  --      ,Level_ID int;

	  --  update
	  --      t
	  --  set
	  --      t.class = sp.class
	  --      ,t.Adjustment_Ind = sp.Adjustment_Ind
	  --      ,t.Quantity = sp.quantity
	  --      ,t.cpt_code = sp.cpt_code
	  --      ,t.billing_code = sp.billing_code
	  --      ,t.service_agreement_ID = sp.service_agreement_ID
	  --      ,t.level_ID = sp.level_ID
	  --  from
	  --      #SentProcedure as t
			--join SENT_PROCEDURE as sp with (nolock) on t.seq = sp.seq;

		
		select
			--sp.seq
			sp.chart_ID
			--,sp.source_ID
			,sp.source_CD
			,sp.class
			,sp.Adjustment_Ind
			,sp.quantity
			,sp.cpt_code
			,sp.billing_code
			,sp.service_agreement_ID
			,sp.level_ID
		into #SentProcedure
		from
			SENT_PROCEDURE as sp with (nolock)
			join #Charts as c on sp.chart_ID = c.chart_ID;


		update c
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


		print 'Section: 08 ' + convert(varchar, getdate(), 121)
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

		create nonclustered index ix_cls_Data1_ChartID on #Data1 (chart_ID); -- added index 12/12/2017

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
			,[Physician Level] varchar(max)
			,[Physician Procedure] varchar(max)
			,[Infusion/Injection] varchar(max)
			,FacilityLevelDesc varchar(1000)
			,PhysicianLevelDesc varchar(1000)
			,Override varchar(10)
			,Financial_Class varchar(100)
			,Anesthesia_Codes varchar(100)
			,Surgical_Procedures varchar(100);


		print 'Section: 09 ' + convert(varchar, getdate(), 121)
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


		print 'Section: 10 ' + convert(varchar, getdate(), 121)
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



		print 'Section: 11 ' + convert(varchar, getdate(), 121)
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


		print 'Section: 12 ' + convert(varchar, getdate(), 121)
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



		print 'Section: 13 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------------------------------------

		-- derive CaseCode for all records in #SentProcedure with applicable Class value
		select
			chart_ID
			,Class
			,CPT_Code
			,CaseCode = case @m_Code when 0 then CPT_CODE else BILLING_CODE end
		into
			#ProcedureClassCodes
		from
			#SentProcedure
		where
			class in ('FP', 'PP', 'IP');



		print 'Section: 14 ' + convert(varchar, getdate(), 121)
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


		print 'Section: 15 ' + convert(varchar, getdate(), 121)
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


		print 'Section: 16 ' + convert(varchar, getdate(), 121)
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


		print 'Section: 17 ' + convert(varchar, getdate(), 121)
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


		print 'Section: 18 ' + convert(varchar, getdate(), 121)
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


		print 'Section: 19 ' + convert(varchar, getdate(), 121)
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



		print 'Section: 20 ' + convert(varchar, getdate(), 121)
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


		print 'Section: 21 ' + convert(varchar, getdate(), 121)
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


		print 'Section: 22 ' + convert(varchar, getdate(), 121)
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

		update
			d
		set
			d.Anesthesia_Codes = null
									--ltrim(stuff((
			--                                     select
			--                                         ', ' + ANESTHESIA_CODE
			--                                     from
			--                                         CHART_ANESTHESIA_CODE as cac
			--                                     where
			--                                         cac.CHART_ID = d.CHART_ID
			--                                     order by
			--                                         ANESTHESIA_CODE
			--                                     for xml path(''), type
			--                                 ).value('.', 'VARCHAR(MAX)')
			--                                    ,1
			--                                    ,1
			--                                    ,''
			--                                )
			--                          )
		from
			#Data1 as d;


		-- populate Surgical_Procedures

		update
			d
		set
			d.Surgical_Procedures = null
										--ltrim(stuff((
			 --                                       select
			 --                                           ', ' + SURGICAL_PROCEDURE_CODE
			 --                                       from
			 --                                           CHART_ANESTHESIA_SURGICAL_PROCEDURE as casp
			 --                                       where
			 --                                           casp.CHART_ID = d.CHART_ID
			 --                                       order by
			 --                                           SURGICAL_PROCEDURE_CODE
			 --                                       for xml path(''), type
			 --                                   ).value('.', 'VARCHAR(MAX)')
			 --                                      ,1
			 --                                      ,1
			 --                                      ,''
			 --                                  )
			 --                            )
		from
			#Data1 as d;




		print 'Section: 23 ' + convert(varchar, getdate(), 121)
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
			,Service_Agreement_ID          int
			,Financial_Class_CD            varchar(65)
			,Consulting_Physician_Name     varchar(max)
			,Diagnoses                     varchar(max)
			,ICD9_Diagnoses_Desc           varchar(max)
			,ICD10_Diagnoses               varchar(max)
			,ICD10_Diagnoses_Desc          varchar(max)
			,[Facility Level]              varchar(max)
			,[Facility Procedure]          varchar(max)
			,[Physician Level]             varchar(max)
			,[Physician Procedure]         varchar(max)
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
				,SERVICE_AGREEMENT_ID
				,Financial_Class_CD
				,Consulting_Physician_Name
				,Diagnoses
				,ICD9_Diagnoses_Desc
				,ICD10_Diagnoses
				,ICD10_Diagnoses_Desc
				,[Facility Level]
				,[Facility Procedure]
				,[Physician Level]
				,[Physician Procedure]
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


		declare @minCode varchar(150);

		declare @i int;
		set @i = 0;
		while @i < (select count(*)from #CODES1)
		begin


			set @minCode = (select top 1 CODE from #CODES1 order by CODE);

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
					,SERVICE_AGREEMENT_ID
					,Financial_Class_CD
					,Consulting_Physician_Name
					,Diagnoses
					,ICD9_Diagnoses_Desc
					,ICD10_Diagnoses
					,ICD10_Diagnoses_Desc
					,[Facility Level]
					,[Facility Procedure]
					,[Physician Level]
					,[Physician Procedure]
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
			where CODE = @minCode;

		end;





		print 'Section: 24 ' + convert(varchar, getdate(), 121)
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
		into #PatientEncountersbyPhysician
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
			and @m_Override in ('-1')
			and
			(
				@SharedVisitsOnly = 0
				or case
					   when isnull([ProcedureProvider], '') = '' then 0
					   when isnull([Physician Name], '') = isnull([ProcedureProvider], '') then 0
				   else 1 end = 1
			)
		union
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
			and @m_Override not in ('-1')
			and
			(
				@SharedVisitsOnly = 0
				or case
					   when isnull([ProcedureProvider], '') = '' then 0
					   when isnull([Physician Name], '') = isnull([ProcedureProvider], '') then 0
				   else 1 end = 1
			);
		--order by
		--    [Physician Name]
		--    ,[Location Code]
		--    ,[DOS]
		--    ,[Patient Name];


		delete from #PatientEncountersbyPhysician
		where physician_ID = -1;


		alter table #PatientEncountersbyPhysician
		add Facility_ID varchar(15);

		update #PatientEncountersbyPhysician
		set Facility_ID = c.FACILITY_ID
		from
			#PatientEncountersbyPhysician pep
			inner join dbo.CHART c on pep.chart_id = c.CHART_ID;



		print 'Section: 25 ' + convert(varchar, getdate(), 121)
		--print 'End Patient Encounters by Physician:  ' + convert(varchar, getdate(), 121)
		--print 'Begin Provider RVU Analysis:  ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------------------------------------

/********************************************************************************************************************************/
/********************************************************************************************************************************/
/********************************************************************************************************************************/

		----------------------------------------------------------------------------------------------------------------------------------
		-- Provider RVU Analysis

		--set transaction isolation level read uncommitted;
		--set nocount on;

		--declare
		--	@Facility   varchar(max) = '1680'
		--	,@StartDate datetime     = '20211001'
		--	,@EndDate   datetime     = '20211031';

		declare
			@EM_MLP     int      = 0;			-- 0=Physician, 1=Mid-Level Provider (NP), -1=E&M Performing Provider
			--,@StartDate datetime = '20190801'
			--,@EndDate  datetime = '20190831';


		declare @Today datetime = dateadd(day, datediff(day, 0, getdate()), 0);
	
	
		----------------------------------------------------------------------------------------------------	
	
	
		print 'Section: 01 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------
		
		if object_id('TempDB..#tmp', 'U') is not null drop table #tmp;
		create table #tmp
		(
		CHART_ID int
		)

		if @m_DateType = 0
		begin
	
			insert into #tmp
			select c.CHART_ID		
			from 
				dbo.CHART c
				inner join dbo.SENT_PROCEDURE sp on c.CHART_ID = sp.chart_id and class in ('PL','PP')
			where
				c.FACILITY_ID in (select * from SplitString(@Facility, ','))
				and c.TIME_OF_SERVICE between @m_StartDate and dateadd(second,86399,@m_EndDate)

		end
		else
		begin

			insert into #tmp
			select c.CHART_ID
			from 
				dbo.CHART c
				inner join dbo.SENT_PROCEDURE sp on c.CHART_ID = sp.chart_id and class in ('PL','PP')
			where
				c.FACILITY_ID in (select * from SplitString(@Facility, ','))
				and c.SENT_DATE between @m_StartDate and dateadd(second,86399,@m_EndDate);

		end


		create nonclustered index idx_tmp__CHART_ID on #tmp (CHART_ID);

	
		print 'Section: 02 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------

		declare @DaysDiff int = datediff(day, @m_StartDate, @m_EndDate);

		declare @MinChartID int;
		declare @MaxChartID int;
		declare @AdjChartID int;

		select @MinChartID = min(CHART_ID), @MaxChartID = max(CHART_ID)  from #tmp;
		select @AdjChartID = case when @DaysDiff <= 30 then @MaxChartID - 1000000
									when @DaysDiff between 31 and 60 then @MaxChartID - 2000000
									when @DaysDiff between 61 and 90 then @MaxChartID - 3000000
									when @DaysDiff between 91 and 120 then @MaxChartID - 4000000
									when @DaysDiff between 121 and 150 then @MaxChartID - 5000000
								else @MaxChartID - 6000000 end;

		create table #CHART_rvu
			(
			CHART_ID                        int
			,SERVICE_AGREEMENT_ID           int
			,FACILITY_ID                    int
			,FACILITY_CHART_ID              varchar(20)
			,TIME_OF_SERVICE                datetime
			,SENT_DATE                      datetime
			,FINANCIAL_CLASS_CD             varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
			,NURSE_PRACTITIONER_ID          int
			,PROVIDER_EVAL_PERFORMED_BY_IND int
			,PHYSICIAN_ID					int
			);

		insert into #CHART_rvu
		select
			c.CHART_ID
			,c.SERVICE_AGREEMENT_ID
			,c.FACILITY_ID
			,c.FACILITY_CHART_ID
			,c.TIME_OF_SERVICE
			,c.SENT_DATE
			,c.FINANCIAL_CLASS_CD
			,c.NURSE_PRACTITIONER_ID
			,c.PROVIDER_EVAL_PERFORMED_BY_IND
			,c.PHYSICIAN_ID
		from 
			dbo.CHART c
			inner join (select CHART_ID from #tmp where CHART_ID between @MinChartID and @AdjChartID) as ca on c.CHART_ID = ca.CHART_ID
		--option (recompile);

		insert into #CHART_rvu
		select
			c.CHART_ID
			,c.SERVICE_AGREEMENT_ID
			,c.FACILITY_ID
			,c.FACILITY_CHART_ID
			,c.TIME_OF_SERVICE
			,c.SENT_DATE
			,c.FINANCIAL_CLASS_CD
			,c.NURSE_PRACTITIONER_ID
			,c.PROVIDER_EVAL_PERFORMED_BY_IND
			,c.PHYSICIAN_ID
		from 
			dbo.CHART c
			inner join (select CHART_ID from #tmp where CHART_ID between @AdjChartID+1  and @MaxChartID) as ca on c.CHART_ID = ca.CHART_ID
		--option (recompile);

	
		--create nonclustered index idx_CHART_ID on #CHART_rvu (CHART_ID)

		alter table #CHART_rvu add FACILITY_PROF_ID int
		update c
		set FACILITY_PROF_ID = fp.FACILITY_PROF_ID
		from 
			#CHART_rvu c
			inner join
			FACILITY_PROFESSIONAL fp with (nolock) on (case
														   when c.PROVIDER_EVAL_PERFORMED_BY_IND is null
																or c.PROVIDER_EVAL_PERFORMED_BY_IND = 0 then c.PHYSICIAN_ID
														   when c.PROVIDER_EVAL_PERFORMED_BY_IND = 1 then
															   c.nurse_practitioner_id end
													  ) = fp.FACILITY_PROF_ID


		delete from #CHART_rvu
		where
			FACILITY_PROF_ID not in (select FACILITY_PROF_ID from #Provider1);
	
	
		print 'Section: 03 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------
	
		select 
			sp.class
			,sp.chart_id
			,sp.time_of_service
			,sp.sent_date
			,sp.physician_id
			,sp.cpt_code
			,sp.quantity
			,sp.charge_master_id
		into #SENT_PROCEDURE
		from 
			dbo.SENT_PROCEDURE sp
			inner join #CHART_rvu c on sp.chart_id = c.CHART_ID
		where
			sp.class in ('PL', 'PP');
	
	
		print 'Section: 04 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------
	
		select distinct
			c.FACILITY_ID
			,c.CHART_ID
			,c.FACILITY_CHART_ID
			,convert(datetime,(convert(varchar(10),sp.TIME_OF_SERVICE,101))) [TIME_OF_SERVICE]
			,convert(datetime,(convert(varchar(10),c.SENT_DATE,101))) [SENT_DATE]
			--,rtrim(coalesce(fp.LAST_NAME, '') + ', ' + coalesce(fp.FIRST_NAME, '') + ' ' + coalesce(fp.MIDDLE_NAME, '')) Provider
			,fp.FACILITY_PROF_ID
			,fpr.[DESCRIPTION] [PROVIDER_ROLE]
			,sp.CPT_CODE
			,(cm.[DESCRIPTION]) [CM_DESC]		-- varchar(100)
			,(cpr.[DESCRIPTION]) [RVU_DESC]	-- varchar(50)
			,sp.QUANTITY
			,round(sp.quantity * isnull(cpr2.WORK_RVU, cpr.WORK_RVU), 2) [WORK_RVU]
			,isnull(cpr2.FULLY_IMPLEMENTED_FAC_TOT, cpr.FULLY_IMPLEMENTED_FAC_TOT) [TOTAL_RVU] --[FULLY_IMPLEMENTED_FAC_TOT]
			,round(sp.quantity * cpr.FULLY_IMPLEMENTED_FAC_TOT, 2) [TOTAL_RVU_BU]
			,cm.CHARGE_MASTER_ID
			,isnull(ca.CHARGE_AMOUNT,0) [CHARGE_AMOUNT]
			,round(sp.quantity * ca.CHARGE_AMOUNT, 2) as [TOTAL_CHARGE]
			,case when sp.class = 'PL' then sp.quantity else 0 end as [EM_Qty]
			,case when sp.class = 'PP' then sp.quantity else 0 end as [Proc_Qty]
			,sp.CLASS
			,c.FINANCIAL_CLASS_CD
			,ffc.FINANCIAL_CLASS_ID
		into #ProviderRVUAnalysis
		from
			#SENT_PROCEDURE sp 
			left join dbo.CHARGE_MASTER cm  on cm.CHARGE_MASTER_ID = sp.charge_master_id
			left join dbo.CHARGE_MASTER_CHARGE_AMOUNT ca  on ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID and dateadd(day, datediff(day, 0, sp.time_of_service), 0) between ca.EFFECTIVE_DATE and isnull(ca.EXPIRATION_DATE,'12/31/9999')
			left join dbo.PHYSICIAN_PROCEDURE_EVALUATION ppe  on sp.class = 'PP' and ppe.CHART_ID = sp.chart_id and ppe.PHYSICIAN_PROCEDURE_ID = cm.CHARGE_MASTER_ID
			left join dbo.CMS_PHYSICIAN_RVU cpr on cpr.HCPCS = sp.cpt_code and @Today between cpr.EFFECTIVE_DT and cpr.EXPIRATION_DT and nullif(cpr.[MOD], '') is null
			left join dbo.CMS_PHYSICIAN_RVU cpr2 on cpr2.HCPCS = sp.cpt_code and @Today between cpr2.EFFECTIVE_DT and cpr2.EXPIRATION_DT and ppe.MODIFIERS is not null and ppe.MODIFIERS like '%' + cpr2.[MOD] + '%'
			,#CHART_rvu c 
			left join FACILITY_FINANCIAL_CLASS ffc on c.SERVICE_AGREEMENT_ID = ffc.SERVICE_AGREEMENT_ID
				and c.FINANCIAL_CLASS_CD = ffc.FINANCIAL_CLASS_CD collate Latin1_General_100_CS_AS
			,dbo.FACILITY_PROFESSIONAL fp 
			,dbo.FACILITY_PROFESSIONAL_ROLE fpr 
			,dbo.SERVICE_AGREEMENT sa
		where
			sp.chart_id = c.CHART_ID 
			and sp.class in ('PL', 'PP') 
			and fp.ROLE_ID = fpr.FACILITY_PROF_ROLE_ID
			and fp.ROLE_ID <> 7
			and fp.FACILITY_PROF_ID = case sa.EVALUATE_PHYSICIAN_SVC
										  when 1 then
											  case
												  when (
													   sp.class = 'PL' or sa.COLLECT_PROCEDURE_PHYSICIANS = 'N'
													   ) and c.NURSE_PRACTITIONER_ID > 0
													   and
														   (
														   c.PROVIDER_EVAL_PERFORMED_BY_IND is null
														   or c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
														   ) then c.NURSE_PRACTITIONER_ID
												  else sp.physician_id end
										  else
											  case
												  when sp.class = 'PL' and c.NURSE_PRACTITIONER_ID > 0 
													and @EM_MLP = 1 then c.NURSE_PRACTITIONER_ID
													--and 0 = 1 then c.NURSE_PRACTITIONER_ID
												  else sp.physician_id end end and cpr.HCPCS = sp.cpt_code
			and sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			and fp.FACILITY_PROF_ID in (select FACILITY_PROF_ID from #Provider1);


		drop table #CHART_rvu	-- added because drop statement above does not always run (not sure ??) jherrera 11/12/2021
	
	
		print 'Section: 05 ' + convert(varchar, getdate(), 121)
		--print 'End Provider RVU Analysis:  ' + convert(varchar, getdate(), 121)
		--print 'Begin Provider Opportunity Expanded:  ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------------------------------------

/********************************************************************************************************************************/
/********************************************************************************************************************************/
/********************************************************************************************************************************/

		----------------------------------------------------------------------------------------------------------------------------------
		-- Provider Opportunity Expanded
	
		--set transaction isolation level read uncommitted;
		--set nocount on;
		----set ansi_warnings off;

		--declare
		--	@Facility   varchar(max) = '1680'
		--	,@StartDate datetime     = '20210801'
		--	,@EndDate   datetime     = '20210831';

	
		----------------------------------------------------------------------------------------------------
		-- PROVIDER OPPORTUNITY REPORT - EXPANDED


		print 'Section: 01 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------

		create table #chart_poe
		(
		FACILITY_ID int
		,SERVICE_AGREEMENT_ID int
		,CHART_ID int
		,medical_record_num varchar(15)
		,FACILITY_ADMIN_CHART_ID varchar(20)
		,di_Status int
		,Account varchar(20)
		,PHYSICIAN_HISTORY_ID int
		,OVERRIDE_PHYS_HIST_ID int
		,Physician_History_Reason_If_Different_ID int
		,PotentialCPT varchar(5)
		,SENT_DATE datetime
		,TIME_OF_SERVICE datetime
		,PATIENT_CLASS_ID int
		,OVERRIDE_PHYSICIAN_SERVICE_PROC_ID int
		,PHYSICIAN_EXAM_ID int
		,OVERRIDE_PHYS_EXAM_ID int
		,NURSE_PRACTITIONER_ID int
		,PROVIDER_EVAL_PERFORMED_BY_IND bit
		,PHYSICIAN_ID int
		,POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE varchar(5)
		,CHART_STATUS_ID int
		,No_Physician_Services bit	
		,PATIENT_DISPOSITION_ID int
		,SCRIBE_ID int
		,PRIMARY_COMPLAINT varchar(6)
		,COMPLETED_BY_USER_PROFILE_ID int
		,FACILITY_CHART_ID varchar(20)
		,PHYSICIAN_SERVICE_PROC_ID int
		,FINANCIAL_CLASS_CD varchar(10)
		,ADD_PHYSICIAN_SVC_25_MODIFIER bit
		,ADD_MODIFIER_57_TO_PHYSICIAN_LOS bit
		,EDITED_BY_EXPERT bit
		,PHYSICIAN_MDM_ID int	
		)

		if @m_DateType = 0
		begin
	
			insert into #CHART_poe
			select
				c.FACILITY_ID
				,c.SERVICE_AGREEMENT_ID
				,c.CHART_ID
				,c.[medical_record_num]
				,c.FACILITY_ADMIN_CHART_ID
				,(
				 select
					 max([DEFICIENCY_STATUS_ID])
				 from
					 DOCUMENTATION_INEQUITY di
				 where
					 di.CHART_ID = c.CHART_ID
				 ) 'di_Status'
				,c.FACILITY_CHART_ID Account
				,c.PHYSICIAN_HISTORY_ID
				,c.OVERRIDE_PHYS_HIST_ID
				,c.Physician_History_Reason_If_Different_ID
				,c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE PotentialCPT
				,c.SENT_DATE
				,c.TIME_OF_SERVICE
				,c.PATIENT_CLASS_ID
				,c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
				,c.PHYSICIAN_EXAM_ID
				,c.OVERRIDE_PHYS_EXAM_ID
				,c.NURSE_PRACTITIONER_ID
				,c.PROVIDER_EVAL_PERFORMED_BY_IND
				,c.PHYSICIAN_ID
				,c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
				,c.CHART_STATUS_ID
				,c.NO_PHYSICIAN_SERVICES
				,c.PATIENT_DISPOSITION_ID
				,c.SCRIBE_ID
				,c.PRIMARY_COMPLAINT
				,c.COMPLETED_BY_USER_PROFILE_ID
				,c.FACILITY_CHART_ID
				,c.PHYSICIAN_SERVICE_PROC_ID
				,c.FINANCIAL_CLASS_CD
				,c.ADD_PHYSICIAN_SVC_25_MODIFIER
				,c.ADD_MODIFIER_57_TO_PHYSICIAN_LOS
				,c.EDITED_BY_EXPERT
				,c.PHYSICIAN_MDM_ID
			from
				CHART c
				outer apply (
							select
								max([DEFICIENCY_STATUS_ID]) [DEFICIENCY_STATUS_ID]
							from
								DOCUMENTATION_INEQUITY di
							where
								di.CHART_ID = c.CHART_ID
							) di
			where
				c.FACILITY_ID in (select * from SplitString(@Facility, ','))
				and c.CHART_STATUS_ID = 5
				and c.TIME_OF_SERVICE between @m_StartDate and dateadd(second, 86399, @m_EndDate)
				and (di.DEFICIENCY_STATUS_ID is null or di.DEFICIENCY_STATUS_ID != 8);

		end
		else
		begin

			insert into #CHART_poe
			select
				c.FACILITY_ID
				,c.SERVICE_AGREEMENT_ID
				,c.CHART_ID
				,c.[medical_record_num]
				,c.FACILITY_ADMIN_CHART_ID
				,(
				 select
					 max([DEFICIENCY_STATUS_ID])
				 from
					 DOCUMENTATION_INEQUITY di
				 where
					 di.CHART_ID = c.CHART_ID
				 ) 'di_Status'
				,c.FACILITY_CHART_ID Account
				,c.PHYSICIAN_HISTORY_ID
				,c.OVERRIDE_PHYS_HIST_ID
				,c.Physician_History_Reason_If_Different_ID
				,c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE PotentialCPT
				,c.SENT_DATE
				,c.TIME_OF_SERVICE
				,c.PATIENT_CLASS_ID
				,c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
				,c.PHYSICIAN_EXAM_ID
				,c.OVERRIDE_PHYS_EXAM_ID
				,c.NURSE_PRACTITIONER_ID
				,c.PROVIDER_EVAL_PERFORMED_BY_IND
				,c.PHYSICIAN_ID
				,c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
				,c.CHART_STATUS_ID
				,c.NO_PHYSICIAN_SERVICES
				,c.PATIENT_DISPOSITION_ID
				,c.SCRIBE_ID
				,c.PRIMARY_COMPLAINT
				,c.COMPLETED_BY_USER_PROFILE_ID
				,c.FACILITY_CHART_ID
				,c.PHYSICIAN_SERVICE_PROC_ID
				,c.FINANCIAL_CLASS_CD
				,c.ADD_PHYSICIAN_SVC_25_MODIFIER
				,c.ADD_MODIFIER_57_TO_PHYSICIAN_LOS
				,c.EDITED_BY_EXPERT
				,c.PHYSICIAN_MDM_ID
			from
				CHART c
				outer apply (
							select
								max([DEFICIENCY_STATUS_ID]) [DEFICIENCY_STATUS_ID]
							from
								DOCUMENTATION_INEQUITY di
							where
								di.CHART_ID = c.CHART_ID
							) di
			where
				c.FACILITY_ID in (select * from SplitString(@Facility, ','))
				and c.CHART_STATUS_ID = 5
				and c.SENT_DATE between @m_StartDate and dateadd(second, 86399, @m_EndDate)
				and (di.DEFICIENCY_STATUS_ID is null or di.DEFICIENCY_STATUS_ID != 8);

		end



		alter table #CHART_poe add FACILITY_PROF_ID int
		update c
		set FACILITY_PROF_ID = fp.FACILITY_PROF_ID
		from 
			#CHART_poe c
			inner join
			FACILITY_PROFESSIONAL fp with (nolock) on (case
														   when c.PROVIDER_EVAL_PERFORMED_BY_IND is null
																or c.PROVIDER_EVAL_PERFORMED_BY_IND = 0 then c.PHYSICIAN_ID
														   when c.PROVIDER_EVAL_PERFORMED_BY_IND = 1 then
															   c.nurse_practitioner_id end
													  ) = fp.FACILITY_PROF_ID


		delete from #CHART_poe
		where
			FACILITY_PROF_ID not in (select FACILITY_PROF_ID from #Provider1);

		create nonclustered index idx_CHART__CHART_ID on #CHART_poe (CHART_ID);


		print 'Section: 02 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------

		select cphrid.*
		into #CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT
		from 
			CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT cphrid
			inner join #CHART_poe c on cphrid.CHART_ID = c.CHART_ID;

		create nonclustered index idx_CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT__CHART_ID on #CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT (CHART_ID);


		print 'Section: 03 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------

		--select cmc.*
		--into #CHARGE_MASTER
		--from 
		--	CHARGE_MASTER cmc with (nolock) 
		--	inner join #CHART c on cmc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		--                                                     and cmc.CHARGE_MASTER_USAGE_CODE = 4
		--                                                     and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cmc.EFFECTIVE_DATE and cmc.EXPIRATION_DATE


		print 'Section: 04 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------

			select
				c.SERVICE_AGREEMENT_ID 'ServiceAgreementId'
				,sa.COMPANY_ID 'CompanyId'
				,c.FACILITY_ID 'FacilityId'
				,c.CHART_ID 'ChartID'
				,c.PATIENT_DISPOSITION_ID
				--,(
				-- select
				--     pd.DESCRIPTION
				-- from
				--     PATIENT_DISPOSITION pd with (nolock)
				-- where
				--     c.PATIENT_DISPOSITION_ID = pd.PATIENT_DISPOSITION_ID
				-- ) 'PatientDisposition'
				--,(
				-- select
				--     scribe.LAST_NAME + ', ' + scribe.FIRST_NAME
				-- from
				--     FACILITY_PROFESSIONAL scribe with (nolock)
				-- where
				--     scribe.FACILITY_PROF_ID = c.SCRIBE_ID
				-- ) as 'Scribe'
				,c.PRIMARY_COMPLAINT
				,(
				 select top 1
						icd.medium_desc
				 from
					 ICD_9_CM icd with (nolock)
				 where
					 c.primary_complaint = icd.icd9_code
				 ) as 'Diagnosis'
				 ,c.COMPLETED_BY_USER_PROFILE_ID
				,c.di_Status
				,fp1.FACILITY_PROF_ID AttendingProviderID
				,fp1.EMPLOYEE_IDENTIFIER AttendingProviderEID
				,(
				 select
					 isnull(fpr.[DESCRIPTION], 'Physician')
				 from
					 FACILITY_PROFESSIONAL_ROLE fpr with (nolock)
				 where
					 fpr.FACILITY_PROF_ROLE_ID = fp1.ROLE_ID
				 ) as AttendingProviderType
				,fp2.FACILITY_PROF_ID PerformingProviderID
				,c.FACILITY_CHART_ID Account
				,case
					 when examDoc.PHYSICIAN_SERVICE_RATING_CODE_ID is not null
						  and examDoc.PHYSICIAN_SERVICE_RATING_CODE_ID <> isnull(examExp.PHYSICIAN_SERVICE_RATING_CODE_ID, 4) then
						 4 -- PE
					 when cphrid.HISTORY_REASON_ID is not null -- History (HPI,ROS,PFSH)
				then     case
							 when charindex('HPI', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0 then 1
							 when charindex('ROS', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0 then 2
							 when charindex('PFSH', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0 then 3
							 else -1 -- no reason if different selected
						 end
					 when c.PHYSICIAN_HISTORY_ID <> c.OVERRIDE_PHYS_HIST_ID then
						 case
							 when c.PHYSICIAN_HISTORY_ID <= 0 then c.OVERRIDE_PHYS_HIST_ID
							 else c.PHYSICIAN_HISTORY_ID end
					 else c.Physician_History_Reason_If_Different_ID end 'ReasonID'
				,psp.SERVICE_LEVEL_CD [Level]
				,(
				 select
					 max(SERVICE_LEVEL_CD)
				 from
					 PHYSICIAN_SERVICE_PROCEDURE with (nolock)
				 where
					 SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID and CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
				 ) PotentialLevel
				,psp.BILLING_CODE
				,psp.CPT_CODE CPTCode
				,c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE PotentialCPT
				,case
					 when charged.CHARGE_AMOUNT is null then
						 case
							 when chargedD.[PAYMENT_RATE] is null then
								 case
									 when charged_2.CHARGE_AMOUNT is null then chargedD_2.CHARGE_AMOUNT
									 else charged_2.CHARGE_AMOUNT end
							 else chargedD.[PAYMENT_RATE] end
					 else charged.CHARGE_AMOUNT end as Charged
				,case
					 when potential.CHARGE_AMOUNT is null then
						 case
							 when potentialD.[PAYMENT_RATE] is null then
								 case
									 when potential_2.CHARGE_AMOUNT is null then potentialD_2.CHARGE_AMOUNT
									 else potential_2.CHARGE_AMOUNT end
							 else potentialD.[PAYMENT_RATE] end
					 else potential.CHARGE_AMOUNT end as PotentialCharge
				,c_rvu.WORK_RVU as Charged_RVU -- DAH 03/31/17 added per ACS-9487
				,p_rvu.WORK_RVU as Potential_RVU
				--,(
				-- select top 1
				--        sap.FACILITY_PAYOR_NAME
				-- from
				--     CHART_PAYOR cp with (nolock)
				--     inner join SERVICE_AGREEMENT_PAYOR sap with (nolock) on sap.SERVICE_AGREEMENT_PAYOR_ID = cp.SERVICE_AGREEMENT_PAYOR_ID
				-- where
				--     cp.CHART_ID = c.CHART_ID
				--     and dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) between sap.EFFECTIVE_DATE and sap.EXPIRATION_DATE
				-- ) Insurance
				,dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) SentDate
				,dateadd(day, 0, datediff(day, 0, c.TIME_OF_SERVICE)) DOS
				,fp1.PROVIDER_BUSINESS_UNIT_ID
				,c.PATIENT_CLASS_ID            -- DAH 02/08/17 added per ACS-11616 	
				,psp.OVERRIDE_ONLY_IND         -- DAH 02/08/17 added per ACS-11616 	
			into #tmp1
			from
				#CHART_poe c with (nolock)
				inner join SERVICE_AGREEMENT sa with (nolock) on sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				inner join PHYSICIAN_SERVICE_PROCEDURE psp with (nolock) on (
																			psp.PHYSICIAN_SERVICE_PROC_ID = c.PHYSICIAN_SERVICE_PROC_ID
																			and nullif(c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID, -1) is null
																			)
				inner join PATIENT_CLASS pcl with (nolock) on c.PATIENT_CLASS_ID = pcl.PATIENT_CLASS_ID
				left join #CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT cphrid with (nolock) on cphrid.CHART_ID = c.CHART_ID
				left join PHYSICIAN_HISTORY_REASON_IF_DIFFERENT phrid with (nolock) on phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID = cphrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID
				left join PHYSICIAN_SERVICE_RATING_CODE examDoc with (nolock) on examDoc.PHYSICIAN_SERVICE_CLASS_CD = 1
																				 and examDoc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
																				 and examDoc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
																				 and examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
																				 and examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID
																				 and examDoc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
				left join PHYSICIAN_SERVICE_RATING_CODE examExp with (nolock) on examExp.PHYSICIAN_SERVICE_CLASS_CD = 1
																				 and examExp.PHYSICIAN_SERVICE_CATEGORY_ID = 2
																				 and examExp.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
																				 and examExp.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
																				 and examExp.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_EXAM_ID
																				 and examExp.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
				left join FACILITY_PROFESSIONAL fp1 with (nolock) on fp1.FACILITY_PROF_ID = case
																								when c.NURSE_PRACTITIONER_ID > 0
																									 and
																										 (
																										 c.PROVIDER_EVAL_PERFORMED_BY_IND is null
																										 or c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
																										 ) then
																									c.NURSE_PRACTITIONER_ID
																								else c.PHYSICIAN_ID end
				left join FACILITY_PROFESSIONAL fp2 with (nolock) on fp2.FACILITY_PROF_ID = c.PHYSICIAN_ID
				left join FACILITY_FINANCIAL_CLASS ffc with (nolock) on ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
																		and ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD
				left join CHARGE_MASTER cmc with (nolock) on cmc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
															 and cmc.CHARGE_MASTER_USAGE_CODE in (4,5) --= 4
															 and cmc.CPT_CODE = psp.CPT_CODE
															 and cmc.BILLING_CODE = psp.BILLING_CODE
															 and cmc.PATIENT_CLASS_ID in (-1, psp.PATIENT_CLASS_ID)
															 --and isnull(cmc.MODIFIER_REQUIRED, 0) = psp.[PROCEDURES] --ACS-10249 08/04/17
															 -- 09/18/2019
															  and isnull(psp.MODIFIER,'') =
																			 case  						
																				   when 
																				   c.ADD_PHYSICIAN_SVC_25_MODIFIER = 1 
																				   and 
																						   (select count(*) 
																								 from PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock) where psp3.service_agreement_id = c.service_agreement_id
																								  and cmc.CPT_CODE = psp3.CPT_CODE	
																								   and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between psp3.EFFECTIVE_DATE and psp3.EXPIRATION_DATE 
																								   and  psp3.PHYSICIAN_SERVICE_PROC_ID = c.PHYSICIAN_SERVICE_PROC_ID 
																								 and modifier = '25') > 0
																				   then '25'
																				   when c.ADD_MODIFIER_57_TO_PHYSICIAN_LOS = 1 
																						   and (select count(*) 
																								 from PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock) where psp3.service_agreement_id = c.service_agreement_id
																								 and modifier = '57') > 0
																				   then '57'

																				   when isnull(c.ADD_PHYSICIAN_SVC_25_MODIFIER, 0) = 0 and psp.MODIFIER = '25'
																				   then '25'						   
																				   else ''
																			 end 

															 and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cmc.EFFECTIVE_DATE and cmc.EXPIRATION_DATE
				left join CHARGE_MASTER_CHARGE_AMOUNT charged with (nolock) on charged.CHARGE_MASTER_ID = cmc.CHARGE_MASTER_ID
																			   and dateadd(
																							  day
																							  ,datediff(
																										   day
																										   ,0
																										   ,c.TIME_OF_SERVICE
																									   )
																							  ,0
																						  ) between charged.EFFECTIVE_DATE and coalesce(
																																		   charged.EXPIRATION_DATE
																																		   ,'12/31/9999'
																																	   )
				left join PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE charged_2 with (nolock) on charged_2.CPT_CODE = psp.CPT_CODE
																							  and c.TIME_OF_SERVICE between charged_2.EFFECTIVE_DATE and charged_2.EXPIRATION_DATE
																							  and charged_2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				left join CMS_ADDENDUM_B chargedD with (nolock) on chargedD.HCPCS_CPT_CODE = psp.CPT_CODE
				left join PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE chargedD_2 with (nolock) on chargedD_2.CPT_CODE = psp.CPT_CODE
																							   and c.TIME_OF_SERVICE between chargedD_2.EFFECTIVE_DATE and chargedD_2.EXPIRATION_DATE
																							   and chargedD_2.SERVICE_AGREEMENT_ID = -1
				left join CMS_PHYSICIAN_RVU c_rvu with (nolock) on cmc.CPT_CODE = c_rvu.HCPCS -- DAH 03/31/17 added per ACS-9487
																   and c.TIME_OF_SERVICE between c_rvu.EFFECTIVE_DT and c_rvu.EXPIRATION_DT

				--ACS-10249 08/04/17
				left join PHYSICIAN_SERVICE_PROCEDURE psp2 with (nolock) on psp2.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
																			and psp2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
																			and psp2.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
																			and c.TIME_OF_SERVICE between psp2.EFFECTIVE_DATE and psp2.EXPIRATION_DATE -- DAH 09/18/17 ACS-10360 added to correct mulitple records 
																			and psp2.SERVICE_LEVEL_CD <> 0 --DAH 07/20/18 ACS-12567 added to correct multiple Potential Fee records
																			and isnull(psp2.MODIFIER, '') = case
																												when c.ADD_PHYSICIAN_SVC_25_MODIFIER = 1
																													 and
																														 (
																														 select
																															 count(*)
																														 from
																															 PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock)
																														 where
																															 psp3.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
																															 and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between psp3.EFFECTIVE_DATE and psp3.EXPIRATION_DATE -- 09/18/2019
																															 and MODIFIER = '25'
																														 ) > 0 then
																													'25'
																												when c.ADD_MODIFIER_57_TO_PHYSICIAN_LOS = 1
																													 and
																														 (
																														 select
																															 count(*)
																														 from
																															 PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock)
																														 where
																															 psp3.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
																															 and MODIFIER = '57'
																														 ) > 0 then
																													'57'
																												when isnull(c.ADD_PHYSICIAN_SVC_25_MODIFIER, 0) = 0 and psp2.MODIFIER = '25' and psp2.[PROCEDURES] = 0 then '25'  -- 09/18/2019
																												else '' end
				left join CHARGE_MASTER cmp with (nolock) on cmp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
															 and cmp.CHARGE_MASTER_USAGE_CODE in (4,5) --= 4
															 and cmp.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
															 and cmp.BILLING_CODE = psp2.BILLING_CODE --ACS-10249 08/04/17
															 --and isnull(cmp.MODIFIER_REQUIRED, 0) = psp2.[PROCEDURES]
															 -- 09/18/2019  
															  and isnull(psp2.MODIFIER,'') =
																			 case                           					   
																				   when 
																				   c.ADD_PHYSICIAN_SVC_25_MODIFIER = 1 
																				   and 
																						   (select count(*) 
																								 from PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock) where psp3.service_agreement_id = c.service_agreement_id
																								  and cmp.CPT_CODE = psp3.CPT_CODE	
																								  and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between psp3.EFFECTIVE_DATE and psp3.EXPIRATION_DATE -- new line / testing ****
																								  and modifier = '25') > 0
																				   then '25'
																				   when c.ADD_MODIFIER_57_TO_PHYSICIAN_LOS = 1 
																						   and (select count(*) 
																								 from PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock) where psp3.service_agreement_id = c.service_agreement_id
																								 and modifier = '57') > 0
																				   then '57'
																				   when isnull(c.ADD_PHYSICIAN_SVC_25_MODIFIER, 0) = 0 and psp2.MODIFIER = '25' and psp2.[PROCEDURES] = 0 then '25'						  
																				   else ''
																			 end 
															 and cmp.PATIENT_CLASS_ID in (-1, psp2.PATIENT_CLASS_ID)
															 and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cmp.EFFECTIVE_DATE and cmp.EXPIRATION_DATE
				left join CHARGE_MASTER_CHARGE_AMOUNT potential with (nolock) on potential.CHARGE_MASTER_ID = cmp.CHARGE_MASTER_ID
																				 and dateadd(
																								day
																								,datediff(
																											 day
																											 ,0
																											 ,c.TIME_OF_SERVICE
																										 )
																								,0
																							) between potential.EFFECTIVE_DATE and coalesce(
																																			   potential.EXPIRATION_DATE
																																			   ,'12/31/9999'
																																		   )
				left join PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potential_2 with (nolock) on potential_2.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
																								and c.TIME_OF_SERVICE between potential_2.EFFECTIVE_DATE and potential_2.EXPIRATION_DATE
																								and potential_2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				left join CMS_ADDENDUM_B potentialD with (nolock) on potentialD.HCPCS_CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
				left join PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potentialD_2 with (nolock) on potentialD_2.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
																								 and c.TIME_OF_SERVICE between potentialD_2.EFFECTIVE_DATE and potentialD_2.EXPIRATION_DATE
																								 and potentialD_2.SERVICE_AGREEMENT_ID = -1
				left join CMS_PHYSICIAN_RVU p_rvu with (nolock) on cmp.CPT_CODE = p_rvu.HCPCS -- DAH 03/31/17 added per ACS-9487
																   and c.TIME_OF_SERVICE between p_rvu.EFFECTIVE_DT and p_rvu.EXPIRATION_DT
			where
				c.CHART_STATUS_ID = 5 and isnull(sa.EVALUATE_PHYSICIAN_SVC, 0) = 1 and isnull(No_Physician_Services, 0) = 0
				and
					(
					isnull(sa.CONDITION_PHYSICIAN_SERVICES_ON_DATE_OF_SERVICE, 0) = 0
					or dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between isnull(
																							  sa.PHYSICIAN_SERVICES_START_DATE_OF_SERVICE
																							  ,sa.EFFECTIVE_DATE
																						  ) and isnull(
																										  PHYSICIAN_SERVICES_END_DATE_OF_SERVICE
																										  ,getdate()
																									  )
					) and nullif(c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE, '') is not null
				and c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE <> psp.CPT_CODE and c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <= 0
				and psp.SERVICE_LEVEL_CD <
					(
					select
						max(SERVICE_LEVEL_CD)
					from
						PHYSICIAN_SERVICE_PROCEDURE with (nolock)
					where
						SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID and CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
					) and
						  (
						  cphrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID is not null -- DAH 02/08/17 added per ACS-11616 
						  or c.PHYSICIAN_EXAM_ID <> c.OVERRIDE_PHYS_EXAM_ID
						  );

		print 'Section: 05 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------
	
			select
				c.SERVICE_AGREEMENT_ID 'ServiceAgreementId'
				,sa.COMPANY_ID 'CompanyId'
				,c.FACILITY_ID 'FacilityId'
				,c.CHART_ID 'ChartID'
				,c.PATIENT_DISPOSITION_ID
				--,(
				-- select
				--     pd.DESCRIPTION
				-- from
				--     PATIENT_DISPOSITION pd with (nolock)
				-- where
				--     c.PATIENT_DISPOSITION_ID = pd.PATIENT_DISPOSITION_ID
				-- ) 'PatientDisposition'
				--,(
				-- select
				--     scribe.LAST_NAME + ', ' + scribe.FIRST_NAME
				-- from
				--     FACILITY_PROFESSIONAL scribe with (nolock)
				-- where
				--     scribe.FACILITY_PROF_ID = c.SCRIBE_ID
				-- ) as 'Scribe'
				,c.PRIMARY_COMPLAINT
				,(
				 select top 1
						icd.medium_desc
				 from
					 ICD_9_CM icd with (nolock)
				 where
					 c.primary_complaint = icd.icd9_code
				 ) as 'Diagnosis'
				 ,c.COMPLETED_BY_USER_PROFILE_ID
				,c.di_Status
				,fp1.FACILITY_PROF_ID AttendingProviderID
				,fp1.EMPLOYEE_IDENTIFIER AttendingProviderEID
				,(
				 select
					 isnull(fpr.[DESCRIPTION], 'Physician')
				 from
					 FACILITY_PROFESSIONAL_ROLE fpr with (nolock)
				 where
					 fpr.FACILITY_PROF_ROLE_ID = fp1.ROLE_ID
				 ) as AttendingProviderType
				,fp2.FACILITY_PROF_ID PerformingProviderID
				,c.FACILITY_CHART_ID Account
				,case
					 when examDoc.PHYSICIAN_SERVICE_RATING_CODE_ID is not null
						  and examDoc.PHYSICIAN_SERVICE_RATING_CODE_ID <> isnull(examExp.PHYSICIAN_SERVICE_RATING_CODE_ID, 4) then
						 4 -- PE
					 when cphrid.HISTORY_REASON_ID is not null -- History (HPI,ROS,PFSH)
				then     case
							 when charindex('HPI', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0 then 1
							 when charindex('ROS', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0 then 2
							 when charindex('PFSH', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0 then 3
							 else -1 -- no reason if different selected
						 end
					 when c.PHYSICIAN_HISTORY_ID <> c.OVERRIDE_PHYS_HIST_ID then
						 case
							 when c.PHYSICIAN_HISTORY_ID <= 0 then c.OVERRIDE_PHYS_HIST_ID
							 else c.PHYSICIAN_HISTORY_ID end
					 else c.Physician_History_Reason_If_Different_ID end 'ReasonID'
				,psp.SERVICE_LEVEL_CD [Level]
				,(
				 select
					 max(SERVICE_LEVEL_CD)
				 from
					 PHYSICIAN_SERVICE_PROCEDURE with (nolock)
				 where
					 SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID and CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
				 ) PotentialLevel
				,psp.BILLING_CODE
				,psp.CPT_CODE CPTCode
				,c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE PotentialCPT
				,case
					 when charged.CHARGE_AMOUNT is null then
						 case
							 when chargedD.[PAYMENT_RATE] is null then
								 case
									 when charged_2.CHARGE_AMOUNT is null then chargedD_2.CHARGE_AMOUNT
									 else charged_2.CHARGE_AMOUNT end
							 else chargedD.[PAYMENT_RATE] end
					 else charged.CHARGE_AMOUNT end as Charged
				,case
					 when potential.CHARGE_AMOUNT is null then
						 case
							 when potentialD.[PAYMENT_RATE] is null then
								 case
									 when potential_2.CHARGE_AMOUNT is null then potentialD_2.CHARGE_AMOUNT
									 else potential_2.CHARGE_AMOUNT end
							 else potentialD.[PAYMENT_RATE] end
					 else potential.CHARGE_AMOUNT end as PotentialCharge
				,c_rvu.WORK_RVU as Charged_RVU -- DAH 03/31/17 added per ACS-9487
				,p_rvu.WORK_RVU as Potential_RVU
				--,(
				-- select top 1
				--        sap.FACILITY_PAYOR_NAME
				-- from
				--     CHART_PAYOR cp with (nolock)
				--     inner join SERVICE_AGREEMENT_PAYOR sap with (nolock) on sap.SERVICE_AGREEMENT_PAYOR_ID = cp.SERVICE_AGREEMENT_PAYOR_ID
				-- where
				--     cp.CHART_ID = c.CHART_ID
				--     and dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) between sap.EFFECTIVE_DATE and sap.EXPIRATION_DATE
				-- ) Insurance
				,dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) SentDate
				,dateadd(day, 0, datediff(day, 0, c.TIME_OF_SERVICE)) DOS
				,fp1.PROVIDER_BUSINESS_UNIT_ID
				,c.PATIENT_CLASS_ID            -- DAH 02/08/17 added per ACS-11616 
				,psp.OVERRIDE_ONLY_IND         -- DAH 02/08/17 added per ACS-11616 		
			into #tmp2
			from
				#CHART_poe c with (nolock)
				inner join SERVICE_AGREEMENT sa with (nolock) on sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				--inner join FACILITY f with (nolock) on f.FACILITY_ID = c.FACILITY_ID
				inner join PHYSICIAN_SERVICE_PROCEDURE psp with (nolock) on psp.PHYSICIAN_SERVICE_PROC_ID = c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
				inner join PATIENT_CLASS pcl with (nolock) on c.PATIENT_CLASS_ID = pcl.PATIENT_CLASS_ID
				left join #CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT cphrid with (nolock) on cphrid.CHART_ID = c.CHART_ID
				left join PHYSICIAN_HISTORY_REASON_IF_DIFFERENT phrid with (nolock) on phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID = cphrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID
				left join PHYSICIAN_SERVICE_RATING_CODE examDoc with (nolock) on examDoc.PHYSICIAN_SERVICE_CLASS_CD = 1
																				 and examDoc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
																				 and examDoc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
																				 and examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
																				 and examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID
																				 and examDoc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
				left join PHYSICIAN_SERVICE_RATING_CODE examExp with (nolock) on examExp.PHYSICIAN_SERVICE_CLASS_CD = 1
																				 and examExp.PHYSICIAN_SERVICE_CATEGORY_ID = 2
																				 and examExp.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
																				 and examExp.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
																				 and examExp.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_EXAM_ID
																				 and examExp.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
				left join FACILITY_PROFESSIONAL fp1 with (nolock) on fp1.FACILITY_PROF_ID = case
																								when c.NURSE_PRACTITIONER_ID > 0
																									 and
																										 (
																										 c.PROVIDER_EVAL_PERFORMED_BY_IND is null
																										 or c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
																										 ) then
																									c.NURSE_PRACTITIONER_ID
																								else c.PHYSICIAN_ID end
				left join FACILITY_PROFESSIONAL fp2 with (nolock) on fp2.FACILITY_PROF_ID = c.PHYSICIAN_ID
				left join FACILITY_FINANCIAL_CLASS ffc with (nolock) on ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
																		and ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD
				left join CHARGE_MASTER cmc with (nolock) on cmc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
															 and cmc.CHARGE_MASTER_USAGE_CODE in (4,5) --= 4
															 and cmc.CPT_CODE = psp.CPT_CODE
															 and cmc.BILLING_CODE = psp.BILLING_CODE
															 and cmc.PATIENT_CLASS_ID in (-1, psp.PATIENT_CLASS_ID)
															 --and isnull(cmc.MODIFIER_REQUIRED, 0) = psp.[PROCEDURES] --ACS-10249 08/04/17
															 -- 09/18/2019
															  and isnull(psp.MODIFIER,'') =
																			 case  						
																				   when 
																				   c.ADD_PHYSICIAN_SVC_25_MODIFIER = 1 
																				   and 
																						   (select count(*) 
																								 from PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock) where psp3.service_agreement_id = c.service_agreement_id
																								  and cmc.CPT_CODE = psp3.CPT_CODE	
																								   and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between psp3.EFFECTIVE_DATE and psp3.EXPIRATION_DATE 
																								   and  psp3.PHYSICIAN_SERVICE_PROC_ID = c.PHYSICIAN_SERVICE_PROC_ID 
																								 and modifier = '25') > 0
																				   then '25'
																				   when c.ADD_MODIFIER_57_TO_PHYSICIAN_LOS = 1 
																						   and (select count(*) 
																								 from PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock) where psp3.service_agreement_id = c.service_agreement_id
																								 and modifier = '57') > 0
																				   then '57'

																				   when isnull(c.ADD_PHYSICIAN_SVC_25_MODIFIER, 0) = 0 and psp.MODIFIER = '25'
																				   then '25'						   
																				   else ''
																			 end 
															 and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cmc.EFFECTIVE_DATE and cmc.EXPIRATION_DATE
				left join CHARGE_MASTER_CHARGE_AMOUNT charged with (nolock) on charged.CHARGE_MASTER_ID = cmc.CHARGE_MASTER_ID
																			   and dateadd(
																							  day
																							  ,datediff(
																										   day
																										   ,0
																										   ,c.TIME_OF_SERVICE
																									   )
																							  ,0
																						  ) between charged.EFFECTIVE_DATE and coalesce(
																																		   charged.EXPIRATION_DATE
																																		   ,'12/31/9999'
																																	   )
				left join PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE charged_2 with (nolock) on charged_2.CPT_CODE = psp.CPT_CODE
																							  and c.TIME_OF_SERVICE between charged_2.EFFECTIVE_DATE and charged_2.EXPIRATION_DATE
																							  and charged_2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				left join CMS_ADDENDUM_B chargedD with (nolock) on chargedD.HCPCS_CPT_CODE = psp.CPT_CODE
				left join PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE chargedD_2 with (nolock) on chargedD_2.CPT_CODE = psp.CPT_CODE
																							   and c.TIME_OF_SERVICE between chargedD_2.EFFECTIVE_DATE and chargedD_2.EXPIRATION_DATE
																							   and chargedD_2.SERVICE_AGREEMENT_ID = -1
				left join CMS_PHYSICIAN_RVU c_rvu with (nolock) on cmc.CPT_CODE = c_rvu.HCPCS -- DAH 03/31/17 added per ACS-9487
																   and c.TIME_OF_SERVICE between c_rvu.EFFECTIVE_DT and c_rvu.EXPIRATION_DT

				left join PHYSICIAN_SERVICE_PROCEDURE psp2 with (nolock) 
				  on psp2.cpt_code = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
				  and psp2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				  and psp2.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
				  and c.time_of_service between psp2.effective_date and psp2.expiration_date  -- DAH 09/18/17 ACS-10360 added to correct mulitple records 
				  and psp2.service_level_cd <> 0  --DAH 07/20/18 ACS-12567 added to correct multiple Potential Fee records
				   and isnull(psp2.MODIFIER,'') =
						 case                           					   
							   when 
							   c.ADD_PHYSICIAN_SVC_25_MODIFIER = 1 
							   and 
									   (select count(*) 
											 from PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock) where psp3.service_agreement_id = c.service_agreement_id
											 and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between psp3.EFFECTIVE_DATE and psp3.EXPIRATION_DATE 
											 and modifier = '25') > 0
							   then '25'
							   when c.ADD_MODIFIER_57_TO_PHYSICIAN_LOS = 1 
									   and (select count(*) 
											 from PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock) where psp3.service_agreement_id = c.service_agreement_id
											 and modifier = '57') > 0
							   then '57'
							   when isnull(c.ADD_PHYSICIAN_SVC_25_MODIFIER, 0) = 0 and psp2.MODIFIER = '25' and psp2.[PROCEDURES] = 0 then '25'
						   
							   else ''
						 end 


				--  LEFT JOIN CHARGE_MASTER cmp with (nolock) ON cmc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID -- DAH 08/04/16 changed cmc. to cmp. ****** 
				left join CHARGE_MASTER cmp with (nolock) on cmp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
															 and cmp.CHARGE_MASTER_USAGE_CODE in (4,5) --= 4
															 and cmp.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE  --psp.CPT_CODE --20190918 JHerrera
															 and cmp.BILLING_CODE = psp2.BILLING_CODE
															 -- 09/18/2019  
															  and isnull(psp2.MODIFIER,'') =
																			 case                           					   
																				   when 
																				   c.ADD_PHYSICIAN_SVC_25_MODIFIER = 1 
																				   and 
																						   (select count(*) 
																								 from PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock) where psp3.service_agreement_id = c.service_agreement_id
																								  and cmp.CPT_CODE = psp3.CPT_CODE	
																								  and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between psp3.EFFECTIVE_DATE and psp3.EXPIRATION_DATE -- new line / testing ****
																								  and modifier = '25') > 0
																				   then '25'
																				   when c.ADD_MODIFIER_57_TO_PHYSICIAN_LOS = 1 
																						   and (select count(*) 
																								 from PHYSICIAN_SERVICE_PROCEDURE psp3 with (nolock) where psp3.service_agreement_id = c.service_agreement_id
																								 and modifier = '57') > 0
																				   then '57'
																				   when isnull(c.ADD_PHYSICIAN_SVC_25_MODIFIER, 0) = 0 and psp2.MODIFIER = '25' and psp2.[PROCEDURES] = 0 then '25'						  
																				   else ''
																			 end 
															 and cmp.PATIENT_CLASS_ID in (-1, psp2.PATIENT_CLASS_ID)
															 and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between cmp.EFFECTIVE_DATE and cmp.EXPIRATION_DATE
				left join CHARGE_MASTER_CHARGE_AMOUNT potential with (nolock) on potential.CHARGE_MASTER_ID = cmp.CHARGE_MASTER_ID
																				 and dateadd(
																								day
																								,datediff(
																											 day
																											 ,0
																											 ,c.TIME_OF_SERVICE
																										 )
																								,0
																							) between potential.EFFECTIVE_DATE and coalesce(
																																			   potential.EXPIRATION_DATE
																																			   ,'12/31/9999'
																																		   )
				left join PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potential_2 with (nolock) on potential_2.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
																								and c.TIME_OF_SERVICE between potential_2.EFFECTIVE_DATE and potential_2.EXPIRATION_DATE
																								and potential_2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				left join CMS_ADDENDUM_B potentialD with (nolock) on potentialD.HCPCS_CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
				left join PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potentialD_2 with (nolock) on potentialD_2.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
																								 and c.TIME_OF_SERVICE between potentialD_2.EFFECTIVE_DATE and potentialD_2.EXPIRATION_DATE
																								 and potentialD_2.SERVICE_AGREEMENT_ID = -1
				left join CMS_PHYSICIAN_RVU p_rvu with (nolock) on cmp.CPT_CODE = p_rvu.HCPCS -- DAH 03/31/17 added per ACS-9487
																   and c.TIME_OF_SERVICE between p_rvu.EFFECTIVE_DT and p_rvu.EXPIRATION_DT
			where
				c.CHART_STATUS_ID = 5 and isnull(sa.EVALUATE_PHYSICIAN_SVC, 0) = 1 and isnull(No_Physician_Services, 0) = 0
				and
					(
					isnull(sa.CONDITION_PHYSICIAN_SERVICES_ON_DATE_OF_SERVICE, 0) = 0
					or dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between isnull(
																							  sa.PHYSICIAN_SERVICES_START_DATE_OF_SERVICE
																							  ,sa.EFFECTIVE_DATE
																						  ) and isnull(
																										  PHYSICIAN_SERVICES_END_DATE_OF_SERVICE
																										  ,getdate()
																									  )
					) and nullif(c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE, '') is not null
				and c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE <> psp.CPT_CODE
				and c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0 -- ACS-10360 DAH 09/18/17  changed from '<= 0' to '> 0'

				and psp.SERVICE_LEVEL_CD <
					(
					select
						max(SERVICE_LEVEL_CD)
					from
						PHYSICIAN_SERVICE_PROCEDURE with (nolock)
					where
						SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID and CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
					);
	
	
		print 'Section: 06 ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------

		select distinct
			x.ServiceAgreementId
			,x.CompanyId
			,x.FacilityId
			,x.ChartID
			,x.PATIENT_DISPOSITION_ID
			,x.PRIMARY_COMPLAINT
			,x.Diagnosis
			,x.COMPLETED_BY_USER_PROFILE_ID
			,x.di_Status
			,x.AttendingProviderID
			,x.AttendingProviderEID
			,x.AttendingProviderType
			,x.PerformingProviderID
			,x.Account
			,x.ReasonID
			,x.[Level]
			,x.PotentialLevel
			,x.CPTCode
			,x.PotentialCPT
			,x.Charged
			,x.PotentialCharge
			,x.Charged_RVU
			,x.Potential_RVU
			,x.SentDate
			,x.DOS
			,x.PROVIDER_BUSINESS_UNIT_ID
			,x.PATIENT_CLASS_ID
			,x.OVERRIDE_ONLY_IND
			,case
				 when x.ReasonID > 0 then
					 substring(x.PotentialCPT, 4, 2) + substring(x.CPTCode, 4, 2) + case
																						when x.ReasonID = 1 then 'h'
																						when x.ReasonID = 2 then 'r'
																						when x.ReasonID = 3 then 'x'
																						when x.ReasonID = 4 then 'e' end
				 else null end DeficiencyCode
			,x.BILLING_CODE
		into #ProviderOpportunityExpanded
		from
			(select * from #tmp1 union all select * from #tmp2) x
		where
			(x.di_Status is null or x.di_Status <> 8);	-- Exclude contested deficiencies


		drop table #CHART_poe


		print 'Section: 07 ' + convert(varchar, getdate(), 121)
		--print 'End Provider Opportunity Expanded:  ' + convert(varchar, getdate(), 121)
		----------------------------------------------------------------------------------------------------------------------------------

/********************************************************************************************************************************/
/********************************************************************************************************************************/
/********************************************************************************************************************************/

		----------------------------------------------------------------------------------------------------------------------------------
	

		if @result_type = 0
		begin

			select 
				pep.Facility_ID
				,pep.FacilityName
				,pep.physician_ID
				,pep.[Physician Name]
				,count(1) [Total_of_ProFee]
				,sum(case when pep.[Facility Level] is null then 0 else 1 end) [ProFee_EM]
				,prvua.[Work_RVU]
				,prvua.[Total_RVU]
				,poe.[Total_Volume_EM]
				--,poe.[Total_RVU]
				,poe.[Total_RVU_Dollars]
				,sum(case when (pep.[Physician Procedure] like '%C5501%'
									or pep.[Physician Procedure] like '%C5502%'
									or pep.[Physician Procedure] like '%C5503%') then 1 else 0 end) [Total_Unsigned_Accounts]
				,sum(case when datediff(day,pep.DOS,pep.[Sent Date]) > 60 then 1 else 0 end) [Total_Late_Charges]
			from
				#PatientEncountersbyPhysician pep
				outer apply (select 
								sum(prvua.WORK_RVU) [Work_RVU]
								,sum(prvua.TOTAL_RVU) [Total_RVU]
							 from #ProviderRVUAnalysis prvua 
							 where
								pep.Facility_ID = prvua.FACILITY_ID
								and pep.physician_ID = prvua.FACILITY_PROF_ID
							) prvua
				outer apply (select
								count(poe.ChartID) [Total_Volume_EM]
								,sum(poe.Potential_RVU) [Total_RVU]
								,sum(poe.Charged_RVU) - sum(poe.Potential_RVU) [Total_RVU_Dollars]
							 from #ProviderOpportunityExpanded poe 
							 where 
								pep.Facility_ID = poe.FacilityId
								and pep.physician_ID = poe.PerformingProviderID
							) poe
			group by 
				pep.Facility_ID
				,pep.FacilityName
				,pep.physician_ID
				,pep.[Physician Name]
				,prvua.Work_RVU
				,prvua.Total_RVU
				,poe.[Total_Volume_EM]
				--,poe.[Total_RVU]
				,poe.[Total_RVU_Dollars];

		end

		else if @result_type = 1
		begin

			select *
			from
				#PatientEncountersbyPhysician

		end

		else if @result_type = 2
		begin

			select upper(fp.LAST_NAME + ', ' + fp.FIRST_NAME) [PROVIDER], f.[NAME] [FACILITY], rvu.*
			from
				#ProviderRVUAnalysis rvu
				inner join dbo.FACILITY f on rvu.FACILITY_ID = f.FACILITY_ID
				left join dbo.FACILITY_PROFESSIONAL fp on rvu.FACILITY_PROF_ID = fp.FACILITY_PROF_ID

		end

		else if @result_type = 3
		begin

			select upper(fp.LAST_NAME + ', ' + fp.FIRST_NAME) [PROVIDER], f.[NAME] [FACILITY], poe.*
			from
				#ProviderOpportunityExpanded poe
				inner join dbo.FACILITY f on poe.FacilityId = f.FACILITY_ID
				left join dbo.FACILITY_PROFESSIONAL fp on poe.PerformingProviderID = fp.FACILITY_PROF_ID

		end

end;
GO
GRANT EXECUTE ON  [dbo].[rpt_PhysicianScorecard] TO [dbx_ExecuteReportProcs]
GO
