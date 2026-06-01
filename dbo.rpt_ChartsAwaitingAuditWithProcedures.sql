SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

	CREATE procedure [dbo].[rpt_ChartsAwaitingAuditWithProcedures]
		@Code       bit
		,@Facility  varchar(max)
		,@Status    int
		,@Coder     varchar(max)
		,@StartDate date
		,@EndDate   date
	with exec as caller
	as
	declare @m_Code as int = @Code;
	declare @m_Facility as varchar(max) = @Facility;
	declare @m_Status as int = @Status;
	declare @m_Coder as varchar(max) = @Coder;
	declare @m_StartDate as date = @StartDate;
	declare @m_EndDate as date = @EndDate;

	select distinct
		   sa.[DESCRIPTION] [Service Agreement]
		   ,cl.[DESCRIPTION] [Clinic]
		   ,c.CHART_ID [Patient ID]
		   ,c.FACILITY_ADMIN_CHART_ID [EMPI]
		   ,c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME [Patient Name]
		   ,c.TIME_OF_SERVICE [DOS]
		   ,pdm.FACILITY_PATIENT_DISPOSITION [Disposition]
		   ,case c.CHART_STATUS_ID
				when 2 then cs.[DESCRIPTION] + ' - ' + pr.[DESCRIPTION]
				when 5 then cs.[DESCRIPTION] + ' ' + convert(varchar, c.SENT_DATE, 101)
				else cs.[DESCRIPTION] end [ACS Status]
		   ,case c.OVERRIDE_FACILITY_LEVEL_ID
				when null then fl.CPT_CODE
				when -1 then fl.CPT_CODE
				else ofl.CPT_CODE end + case c.NON_ER_PROCEDURES_OVERRIDE when 1 then '-25' else '' end [Facility Level]
		   ,ltrim(stuff(
						   (
						   select
							   ', ' + case @m_Code when 0 then cm.CPT_CODE else cm.BILLING_CODE end
							   + case fpe.MODIFIERS
									 when null then ''
									 when '' then ''
									 else '-' + fpe.MODIFIERS end
						   from
							   CHARGE_MASTER cm
							   inner join FACILITY_PROCEDURE_EVALUATION fpe on cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID
						   where
							   fpe.CHART_ID = c.CHART_ID
						   order by
							   cm.CPT_CODE
						   for xml path(''), type
						   ).value('.', 'VARCHAR(MAX)')
						   ,1
						   ,1
						   ,''
					   )
				 ) [Facility Procedures]
		   ,case c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
				when null then psp.CPT_CODE
				when -1 then psp.CPT_CODE
				else opsp.CPT_CODE end [Physician Level]
		   ,ltrim(stuff(
						   (
						   select
							   ', ' + case @m_Code when 0 then cm.CPT_CODE else cm.BILLING_CODE end
							   + case ppe.MODIFIERS
									 when null then ''
									 when '' then ''
									 else '-' + ppe.MODIFIERS end
						   from
							   CHARGE_MASTER cm
							   inner join PHYSICIAN_PROCEDURE_EVALUATION ppe on cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
						   where
							   ppe.CHART_ID = c.CHART_ID
						   order by
							   cm.CPT_CODE
						   for xml path(''), type
						   ).value('.', 'VARCHAR(MAX)')
						   ,1
						   ,1
						   ,''
					   )
				 ) [Physician Procedures]
		   ,ltrim(stuff(
						   (
						   select
							   ', ' + case @m_Code when 0 then cm.CPT_CODE else cm.BILLING_CODE end
							   + case cir.MODIFIERS
									 when null then ''
									 when '' then ''
									 else '-' + cir.MODIFIERS end
						   from
							   CHARGE_MASTER cm
							   inner join CHART_INFUSION_RESULT cir on cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID
						   where
							   cir.CHART_ID = c.CHART_ID
						   order by
							   cm.CPT_CODE
						   for xml path(''), type
						   ).value('.', 'VARCHAR(MAX)')
						   ,1
						   ,1
						   ,''
					   )
				 ) [Infusion-Injection]
		   ,ltrim(stuff((
						select
							', ' + cdc.ICD10_CODE --cdc.ICD9_CODE
						from
							--CHART_DIAGNOSIS_CODE cdc
							CHART_DIAGNOSIS_CODE_ICD10 cdc
						where
							cdc.CHART_ID = c.CHART_ID
						order by cdc.POSTING_ORDER asc
							--case when POSTING_ORDER is null then 1 else 0 end
							--,POSTING_ORDER desc
						for xml path(''), type
						).value('.', 'VARCHAR(MAX)')
						,1
						,1
						,''
					   )
				 ) [Diagnosis Codes]
		   ,fp.LAST_NAME + ', ' + fp.FIRST_NAME [Provider]
		   ,coder.LAST_NAME + ', ' + coder.FIRST_NAME [Coder]
		   ,auditor.LAST_NAME + ', ' + auditor.FIRST_NAME [Auditor]
		   ,c.CODER_COMMENT [Comments]
		   ,c.COMPLETION_DATE [Date Completed]
		   ,cast(sa.EVALUATE_PHYSICIAN_SVC as int) [Profee Level On]
		   ,cast(sa.EVALUATE_PHYSICIAN_PROCEDURES as int) [Profee Procs On]
		   ,cast(sa.EVALUATE_FACILITY_SVC as int) [Facility Level On]
		   ,cast(sa.EVALUATE_FACILITY_PROCEDURES as int) [Facility Procs On]
		   ,cast(sa.INFUSION_INJECTION_METHOD_ID as int) [Inf-Inj On]
		   ,cast(sa.PERFORM_DIAGNOSIS_CODING as int) [Dx Coding On]
	from(((((((((((PENDING_REASON pr with (nolock)
		right outer join CHART c with (nolock) on (pr.PENDING_REASON_ID = c.PENDING_REASON_ID))
		left outer join FACILITY_LEVEL fl with (nolock) on (fl.FACILITY_LEVEL_ID = c.FACILITY_LEVEL_ID))
		left outer join FACILITY_LEVEL ofl with (nolock) on (ofl.FACILITY_LEVEL_ID = c.OVERRIDE_FACILITY_LEVEL_ID))
		left outer join PHYSICIAN_SERVICE_PROCEDURE psp with (nolock) on (psp.PHYSICIAN_SERVICE_PROC_ID = c.PHYSICIAN_SERVICE_PROC_ID))
		left outer join PHYSICIAN_SERVICE_PROCEDURE opsp with (nolock) on (opsp.PHYSICIAN_SERVICE_PROC_ID = c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID))
		left outer join FACILITY_PROFESSIONAL fp with (nolock) on (fp.FACILITY_PROF_ID = c.PHYSICIAN_ID))
		left outer join SERVICE_AGREEMENT_CLINIC cl with (nolock) on (cl.CLINIC_ID = c.CLINIC_ID))
		left outer join USER_PROFILE auditor with (nolock) on (auditor.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID))
		left outer join USER_PROFILE coder with (nolock) on (coder.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID))
		left outer join SERVICE_AGREEMENT sa with (nolock) on (sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID))
		left outer join PATIENT_DISPOSITION_MAP pdm with (nolock) on (pdm.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID))
		left outer join CHART_STATUS cs with (nolock) on (cs.CHART_STATUS_ID = c.CHART_STATUS_ID)
	where
		(c.FACILITY_ID in
			 (
			 select * from SplitString(@m_Facility, ',')
			 )
		) and (c.CHART_STATUS_ID = @m_Status) and (c.TIME_OF_SERVICE between @m_StartDate and @m_EndDate)
		and (c.COMPLETED_BY_USER_PROFILE_ID in
				 (
				 select * from SplitString(@m_Coder, ',')
				 )
			);
GO
GRANT EXECUTE ON  [dbo].[rpt_ChartsAwaitingAuditWithProcedures] TO [dbx_ExecuteReportProcs]
GO
