SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[rpt_ChargePostingReconciliation]
(
    @Organization    int          
	,@Facility         varchar(max) 
    ,@ReportDate      datetime     
    ,@StartReportDate datetime     
    ,@UseMrn          int          
    ,@ReportUser      int          
	,@PatientClass	  varchar(max) 
)
as
begin

	-- Tuned report: Charge Posting Reconciliation
	-- set statistics io on

	--(@Facility nvarchar(209),@ReportDate datetime,@ReportUser int,@StartReportDate datetime,@Organization int,@UseMrn bit)-- Charge Posting Reconciliation

	set transaction isolation level read uncommitted;

	--declare
	--     @Organization    int          = 198
	--	  ,@Facility        varchar(max) = 1117       --  -1 All
	--    ,@ReportDate      datetime     = '06/15/2025'
	--    ,@StartReportDate datetime     = '06/15/2025'
	--    ,@UseMrn          int          = 0			-- 0 facility_chart_id, 1 MRN 
	--    ,@ReportUser      int          = 80
	--	  ,@PatientClass	  varchar(max) = '-1';


	if object_id('TempDB..#SERVICE_AGREEMENT', 'U') is not null
		drop table #SERVICE_AGREEMENT;

	select
		sa.SERVICE_AGREEMENT_ID
		,f.FACILITY_ID
		,f.[NAME] [FACILITY]
	into
		#SERVICE_AGREEMENT
	from
		SERVICE_AGREEMENT sa
		,FACILITY f
		,FACILITY_USER_AUTHORIZATION fua
	where
		(
			@Facility = '-1'
			or sa.FACILITY_ID in ( select items from dbo.SplitString(@Facility, ',') )
		) 
		and exists
	(
		select
			*
		from
			CHARGE_RECONCILIATION
		where
			SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
	)
		and @ReportDate between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
		and sa.FACILITY_ID = f.FACILITY_ID
		and f.FACILITY_ID = fua.FACILITY_ID
		and @ReportDate between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
		and sa.COMPANY_ID = @Organization
		and fua.USER_PROFILE_ID = @ReportUser;


	create nonclustered index idx_SERVICE_AGREEMENT_ID
	on #SERVICE_AGREEMENT (SERVICE_AGREEMENT_ID);


	--------------------------------------------------------------------------------------------------------------

	-- preprocess data from SENT_PROCEDURE		-- This can't be tuned any more through rewriting. It runs fast, but generates 4M LReads with a two-month date range.  9/6/2022, dsexton
	if object_id('TempDB..#SentProcedure', 'U') is not null
		drop table #SentProcedure;
	select
		sp.service_agreement_id
		,sp.facility_chart_id
		,sp.facility_admin_chart_id
		,sp.sent_date
		,sp.time_of_service
		,sp.cpt_code
		,sp.billing_code
		,sp.quantity
		,sp.mod_1
		,sp.mod_2
		,c.CHART_ID
		,sp.facility_id
		,sp.charge_master_id
		,sp.class
		,c.medical_record_num
		,c.patient_last_name + ', ' + c.patient_first_name as Patient_Name
		,c.PATIENT_DISPOSITION_ID
		,c.PATIENT_DISPOSITION_MAP_ID
		,c.PATIENT_CLASS_ID
	into
		#SentProcedure
	from
		SENT_PROCEDURE as sp with (nolock)
	join
	CHART              as c with (nolock) on sp.chart_id = c.CHART_ID
	where
		sp.sent_date between @StartReportDate and dateadd(second, 86399, @ReportDate)
		and exists
	(
		select
			*
		from
			#SERVICE_AGREEMENT sa
		where
			sa.SERVICE_AGREEMENT_ID = sp.service_agreement_id
	);

	create nonclustered index idx_SERVICE_AGREEMENT_ID
	on #SentProcedure (service_agreement_id);


	--------------------------------------------------------------------------------------------------------

	-- preprocess data from CHARGE_RECONCILIATION
	if object_id('TempDB..#ChargeReconciliation', 'U') is not null
		drop table #ChargeReconciliation;

	-- verified that this part can't be tuned any more.  No improvement from breaking out "Or's" and/or functions (stuff, substring, dateadd) to UNION statements.  dsexton, 9/6/2022
	select
		cr.service_agreement_id
		,cr.facility_chart_id
		,cr.time_of_service
		,cr.POSTING_DATE
		,cr.[PROCEDURE]
		,cr.cpt_code
		,cr.quantity
		,cr.ABSTRACT_STATUS
		,cr.Charge_Reconciliation_ID
		,stuff((
				   select
					   ', ' + MODIFIER
				   from
					   CHARGE_RECONCILIATION_MODIFIER crm
				   where
					   cr.CHARGE_RECONCILIATION_ID = crm.CHARGE_RECONCILIATION_ID
				   for xml path(''), type
			   ).value('.', 'varchar(max)')
				  ,1
				  ,2
				  ,''
			  ) MODIFIERS
	into
		#ChargeReconciliation
	from
		CHARGE_RECONCILIATION cr with (nolock)
	join
	#SentProcedure            as sp on cr.service_agreement_id = sp.service_agreement_id
									   and
									   (
										   cr.facility_chart_id = case
																	  when @UseMrn = 1 then
																		  ltrim(substring(
																							 sp.MEDICAL_RECORD_NUM
																							 ,patindex('%[^0]%', sp.MEDICAL_RECORD_NUM)
																							 ,20
																						 )
																			   )
																  else sp.facility_chart_id end
										   or cr.facility_chart_id = sp.facility_admin_chart_id
									   )
									   and (dateadd(day, datediff(day, 0, cr.time_of_service), 0) = dateadd(
																											   day
																											   ,datediff(
																															day
																															,0
																															,sp.time_of_service
																														)
																											   ,0
																										   )
										   )
									   and
									   (
										   cr.[PROCEDURE] = sp.billing_code
										   or cr.cpt_code = sp.cpt_code
									   )
									   and (cr.quantity = sp.quantity);



	if object_id('TempDB..#ChargeReconciliation_Distinct', 'U') is not null
		drop table #ChargeReconciliation_Distinct;

	select distinct
		*
	into
		#ChargeReconciliation_Distinct
	from
		#ChargeReconciliation;


	---------------------------------------------------------------------------------------

	if object_id('TempDB..#Results', 'U') is not null
		drop table #Results; -- to support tuning (replaces CTE structure), 9/6/2022 dsexton

	select
		f.FACILITY_ID
		,f.[NAME]                                                                                     Facility
		,sp.sent_date                                                                                Posted
		,sp.facility_chart_id                                                                        Account		
		,sp.medical_record_num                                                                       MRN
		,sp.time_of_service                                                                          DOS
		,sp.cpt_code                                                                                 CPT
		,sp.billing_code                                                                             SIM
		,sp.quantity                                                                                 Quantity
		,case
			 when nullif(sp.mod_1, '') is null then ''
		 else sp.mod_1 + case when nullif(sp.mod_2, '') is null then '' else ', ' + sp.mod_2 end end Modifiers
		,Status                                                                                      = cast(null as varchar(30)) -- Modified to support tuning.  Status is now populated near the end. 9/6/2022 dsexton                   
																																 /*	
	-- This subquery was the most expensive part of the report, and performance degraded exponentially as the amount of data to process increased due to date range and/or quantity of facilities.  9/6/2022, dsexton
	-- Moving this subquery to a separate step reduces LReads, CPU, and Duration by 50-98% (more processing = more improvement).		9/6/2022, dsexton

			   case when (sa.EXCLUDE_OBS_CHARGES_FROM_CHARGE_RECON is null or sa.EXCLUDE_OBS_CHARGES_FROM_CHARGE_RECON=0 or cmd.OBSERVATION_IND=0) and
						(SELECT COUNT(*) FROM #ChargeReconciliation_Distinct as cr
							where cr.SERVICE_AGREEMENT_ID = sp.service_agreement_id
								AND ( cr.FACILITY_CHART_ID = CASE WHEN @UseMrn = 1 THEN LTRIM(SUBSTRING(sp.MEDICAL_RECORD_NUM, PATINDEX ('%[^0]%', sp.MEDICAL_RECORD_NUM), 20)) ELSE sp.facility_chart_id END
									 OR cr.FACILITY_CHART_ID = sp.facility_admin_chart_id )
								AND (dateadd(day, datediff(day, 0, cr.TIME_OF_SERVICE), 0) = dateadd(day, datediff(day, 0, sp.time_of_service), 0))
								AND (cr.[PROCEDURE] = sp.billing_code or cr.CPT_CODE = sp.CPT_CODE)
								AND (cr.QUANTITY = sp.QUANTITY)) = 0 then 'Mismatch'

					when (SELECT COUNT(*) FROM #ChargeReconciliation_Distinct as cr
							where cr.SERVICE_AGREEMENT_ID = sp.service_agreement_id
								AND ( cr.FACILITY_CHART_ID = CASE WHEN @UseMrn = 1 THEN LTRIM(SUBSTRING(sp.MEDICAL_RECORD_NUM, PATINDEX ('%[^0]%', sp.MEDICAL_RECORD_NUM), 20)) ELSE sp.facility_chart_id END
									 OR cr.FACILITY_CHART_ID = sp.facility_admin_chart_id )
								AND (dateadd(day, datediff(day, 0, cr.TIME_OF_SERVICE), 0) = dateadd(day, datediff(day, 0, sp.time_of_service), 0))
								AND (cr.[PROCEDURE] = sp.billing_code or cr.CPT_CODE = sp.CPT_CODE)
								AND (cr.QUANTITY = sp.QUANTITY)) > 1 then 'Multiple Matches'

					else 'Match' end 'Status',           
	*/
		,sp.chart_id                                                                                 ChartID
		,sp.Patient_Name
		,case
			 when sp.class = 'FP' then 'Facility'
			 when sp.class = 'FL' then 'Facility'
			 when sp.class = 'IP' then 'Facility'
			 when sp.class = 'PP' then 'Physician'
			 when sp.class = 'PL' then 'Physician' end                                               as ChargeType
		,pd.DESCRIPTION                                                                              CCSDisposition
		,case
			 when pd.PATIENT_DISPOSITION_ID <> -1 then pdm.DESCRIPTION
		 else 'Unknown' end                                                                          as Facility_Disposition

																																 -- columns added to support tuning, 9/6/2022, dsexton
		,sa.EXCLUDE_OBS_CHARGES_FROM_CHARGE_RECON
		,cmd.OBSERVATION_IND
		,sp.service_agreement_id
		,sp.facility_admin_chart_id
		,isnull(sp.PATIENT_CLASS_ID,'-9999') [PATIENT_CLASS_ID]
		,pc.[DESCRIPTION] [PATIENT_CLASS]
	into
		#Results -- added to support tuning, 9/6/2022 dsexton

	from
		#SentProcedure       as sp
	join
	FACILITY                 f with (nolock) on sp.facility_id = f.FACILITY_ID
	join
	SERVICE_AGREEMENT        sa with (nolock) on sa.SERVICE_AGREEMENT_ID = sp.service_agreement_id
	join
	CHARGE_MASTER            cm with (nolock) on cm.CHARGE_MASTER_ID = sp.charge_master_id
	join
	CHARGE_MASTER_DEPARTMENT cmd with (nolock) on cmd.CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID
	join
	PATIENT_DISPOSITION      pd on sp.patient_disposition_id = pd.PATIENT_DISPOSITION_ID
	left outer join
	PATIENT_DISPOSITION_MAP  pdm on sp.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
	left join 
	PATIENT_CLASS pc on sp.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID
	where -- 
		sp.class in
		(
			select
				c.class
			from
				SA_CHARGE_RECON_CLASS_INCLUSION c with (nolock)
			where
				c.SERVICE_AGREEMENT_ID = sp.service_agreement_id
		)
		and sp.cpt_code not in
			(
				select
					cpt.CPT_CODE
				from
					SA_CHARGE_RECON_CPT_EXCLUSION cpt with (nolock)
				where
					cpt.SERVICE_AGREEMENT_ID = sp.service_agreement_id
			)
		and sp.billing_code not in
			(
				select
					sim.SIM
				from
					SA_CHARGE_RECON_SIM_EXCLUSION sim with (nolock)
				where
					sim.SERVICE_AGREEMENT_ID = sp.service_agreement_id
			)
		and (@PatientClass = '-1'
				or pc.PATIENT_CLASS_ID in ( select items from dbo.SplitString(@PatientClass, ',') )
			);

			

	if object_id('TempDB..#StatusMap', 'U') is not null
		drop table #StatusMap; -- Added to support tuning. Replaces the expensive subquery.  9/6/2022 dsexton

	select
		 cr.service_agreement_id
		,cr.Facility_Chart_ID
		,cr.time_of_service
		,cr.[Procedure]
		,cr.cpt_code
		,cr.Quantity
		,RowCnt = count(*) -- added to support tuning, 9/6/2022 dsexton
	into
		#StatusMap
	from
		#ChargeReconciliation_Distinct as cr
	where
		exists
	(
		select
			1
		from
			#Results as sp
		where
			cr.service_agreement_id = sp.service_agreement_id
			and
			(
				cr.Facility_Chart_ID = case
										   when @UseMrn = 1 then ltrim(substring(MRN, patindex('%[^0]%', MRN), 20))
									   else sp.Account end
				or -- verified that breaking out "Or's" and/or functions to UNIONs does not improve performance in this case. 9/6/2022, dsexton
				cr.FACILITY_CHART_ID = sp.facility_admin_chart_id
			)
			and dateadd(day, datediff(day, 0, cr.TIME_OF_SERVICE), 0) = dateadd(day, datediff(day, 0, sp.DOS), 0)
			and
			(
				cr.[PROCEDURE] = sp.SIM
				or cr.CPT_CODE = sp.CPT
			)
			and cr.Quantity = sp.Quantity
	)
	group by
		cr.service_agreement_id
		,cr.Facility_Chart_ID
		,cr.time_of_service
		,cr.[Procedure]
		,cr.cpt_code
		,cr.Quantity;


	alter table #Results add RowCnt int; -- added 9/6/2022, dsexton

	update
		sp -- added 9/6/2022, dsexton
	set
		sp.RowCnt = map.RowCnt
	from
		#Results as sp
	join
	#StatusMap   as map on sp.service_agreement_id = map.service_agreement_id
						   and (sp.Account = map.FACILITY_CHART_ID
						   or  sp.FACILITY_ADMIN_CHART_ID =  map.FACILITY_CHART_ID ) -- DAH 6/16/25 RAP-1132 added line for option to join on FACILITY_ADMIN_CHART_ID
						   and dateadd(day, datediff(day, 0, sp.DOS), 0) = dateadd(
																					  day
																					  ,datediff(day, 0, map.time_of_service)
																					  ,0
																				  )
						   and sp.SIM = map.[Procedure]
						   and sp.CPT = case when isnull(map.CPT_Code, '') <> '' then map.CPT_Code else sp.CPT end
						   and sp.Quantity = map.Quantity;


	-- added 9/6/2022, dsexton.  This part performs best as separate UPDATE statements rather than using a single UPDATE with CASE statements.
	update
		#Results
	set
		Status = 'Match'
	where
		RowCnt = 1;
	update
		#Results
	set
		Status = 'Multiple Matches'
	where
		RowCnt > 1;
	update
		#Results
	set
		Status = 'Mismatch'
	where
		RowCnt is null
		and
		(
			EXCLUDE_OBS_CHARGES_FROM_CHARGE_RECON is null
			or EXCLUDE_OBS_CHARGES_FROM_CHARGE_RECON = 0
			or OBSERVATION_IND = 0
		);
	update
		#Results
	set
		Status = 'Match'
	where
		RowCnt is null
		and not (
					EXCLUDE_OBS_CHARGES_FROM_CHARGE_RECON is null
					or EXCLUDE_OBS_CHARGES_FROM_CHARGE_RECON = 0
					or OBSERVATION_IND = 0
				);


	/*  For validation during testing ...   9/6/2022, dsexton
	drop table DBA..ChargePostingRecon_Tuned
	select DISTINCT * into DBA..ChargePostingRecon_Tuned from #Results

	--select Status, count(*) from #Results group by status
	*/

	-- modified to return rows from #Results	9/6/2022, dsexton
	select
		Facility_ID
		,Facility
		,Posted
		,Account
		,Facility_Admin_Chart_ID
		,MRN
		,DOS
		,CPT
		,SIM
		,Quantity
		,Modifiers
		,Status
		,ChartID
		,Patient_Name
		,ChargeType
		,CCSDisposition
		,Facility_Disposition
		,PATIENT_CLASS_ID
		,PATIENT_CLASS
	from
		#Results
	order by
		Status desc
		,Facility
		,Posted
		,Account
		,CPT
		,Quantity;

	-- do NOT use MaxDOP 1 for this report   9/6/2022, dsexton

 end
GO
