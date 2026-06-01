SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	

CREATE proc [dbo].[rpt_ProviderDailyLevelofServiceSummarybyCPT]
(
	@ReportUser int
	,@Company int
	,@Facility varchar(max)
	,@StartDate datetime
	,@EndDate datetime
	,@CPT     varchar(max)
	,@PatientClass   varchar(max)
	,@Disposition    varchar(max)
	,@DataSummary    int
)
as
begin
	
	set transaction isolation level read uncommitted;

	--declare 
	--	@ReportUser int = 80,
	--	@Company int = 121, 
	--	@Facility int = 1353, 
	--	@StartDate datetime = '09/16/2022',
	--	@EndDate datetime = '11/30/2022',
	--	@CPT     varchar(max) =  '99218',  -- '-1' All
	--	@PatientClass   int = 5586, 		--  -1  All
	--	@Disposition    varchar(20) = '-1',     -- '-1' All
	--	@DataSummary    int = 1;				-- 1 Day, 2 Month, 3 Quarter




	-- Step 0 AuthorizedFacilities  ******************************

	if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;

	select *
	into #AuthorizedFacilities
	from
	(
		select distinct
			fua.FACILITY_ID
		from
			FACILITY_USER_AUTHORIZATION fua
			,USER_PROFILE up
			,SERVICE_AGREEMENT sa
		where
			fua.USER_PROFILE_ID = up.USER_PROFILE_ID
			and fua.FACILITY_ID = sa.FACILITY_ID
			and up.IS_ACTIVE = 'Y'
			and getdate() between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
			and getdate() between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
			and sa.DEMO_TEST_SITE_IND = 0
			and fua.USER_PROFILE_ID = @ReportUser
			and sa.COMPANY_ID = @Company
			and
			(
				@Facility = '-1' or fua.FACILITY_ID in ( select items from dbo.SplitString(@Facility, ',') )
			)
	) fa;



	-- Step 1 Data Pull *******************************************


	if object_id('TempDB..#LOS1', 'U') is not null drop table #LOS1;


	select
		sp.chart_id
		,sp.service_agreement_id
		,sp.patient_class_id
		,sp.class                                              Class
		,dateadd(day, datediff(day, 0, sp.time_of_service), 0) DOS
		,case
			 when pd.OUTPATIENT_IND in (1, 6, 7, 8, 9, 10, 11) then 'Outpatient'
			 when pd.PATIENT_DISPOSITION_ID in (2, 3, 4, 5) then 'Admitted'
		 else 'Unknown' end                                    Disposition
		,sp.cpt_code
		,sp.quantity
		,source_cd
	into #LOS1
	from
		SENT_PROCEDURE          sp with (nolock)
		join SERVICE_AGREEMENT           sa with (nolock) on sa.SERVICE_AGREEMENT_ID = sp.service_agreement_id
		join PATIENT_DISPOSITION         pd with (nolock) on pd.PATIENT_DISPOSITION_ID = sp.patient_disposition_id
		join PHYSICIAN_SERVICE_PROCEDURE pl with (nolock) on pl.PHYSICIAN_SERVICE_PROC_ID = sp.level_id
		join CHART                       c with (nolock) on sp.chart_id = c.CHART_ID
	where
		sp.class = 'PL'
		and sp.time_of_service between @StartDate and dateadd(second, 86399, @EndDate)
		and sp.facility_id in
			(
				select FACILITY_ID from #AuthorizedFacilities
			);



	-- ****************************************************************
	-- Step 1.1 Check for PBA adjustments


	insert into #LOS1
	select distinct
		los.chart_id
		,los.service_agreement_id
		,los.patient_class_id
		,los.Class                                                                   Class
		,dateadd(day, datediff(day, 0, cpbaa.REVISED_DATE_OF_SERVICE), 0)            DOS
		,los.Disposition
		,cm.CPT_CODE
		,case when cpbaa.IS_CHART_OVERVIEW = 1 then (cpbaa.QUANTITY * -1) else 0 end Quantity
		,'PA'                                                                        as source_cd
	from
		#LOS1 los
		,CHART_POST_BILL_AUDIT_ADJUSTMENT cpbaa
		,CHARGE_MASTER cm
		,PHYSICIAN_SERVICE_PROCEDURE pl
		,CHART c
	where
		los.chart_id = cpbaa.CHART_ID
		and cpbaa.IS_CHART_OVERVIEW = 1
		and los.Class = 'PL'
		and cpbaa.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
		and cm.CHARGE_MASTER_USAGE_CODE = 4
		and los.chart_id = c.CHART_ID
		and pl.PHYSICIAN_SERVICE_PROC_ID = (case
												when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null
													 and c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1 then
													c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
											else c.PHYSICIAN_SERVICE_PROC_ID end
										   )
		and not exists
	(
		select los2.chart_id from #LOS1 los2 where source_cd = 'CA'
	); -- exclude CA

	

	-- POS. Quantity / Add PBA PL 
	insert into #LOS1
	select distinct
		los.chart_id
		,los.service_agreement_id
		,los.patient_class_id
		,los.Class                                                            Class
		,dateadd(day, datediff(day, 0, cpbaa.REVISED_DATE_OF_SERVICE), 0)     DOS
		,los.Disposition
		,cm.CPT_CODE
		,case when cpbaa.IS_CHART_OVERVIEW = 0 then cpbaa.QUANTITY else 0 end Quantity
		,'PA'                                                                 as source_cd
	from
		#LOS1 los
		,CHART_POST_BILL_AUDIT_ADJUSTMENT cpbaa
		,CHARGE_MASTER cm
		,PHYSICIAN_SERVICE_PROCEDURE pl
	where
		los.chart_id = cpbaa.CHART_ID
		and los.Class = 'PL'
		and cpbaa.IS_CHART_OVERVIEW = 0
		and cpbaa.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
		and cm.CHARGE_MASTER_USAGE_CODE = 4
		and los.service_agreement_id = pl.SERVICE_AGREEMENT_ID
		and cm.CPT_CODE = pl.CPT_CODE
		and cm.BILLING_CODE = pl.BILLING_CODE
		and cpbaa.MODIFIERS = pl.MODIFIER
		and not exists
	(
		select los2.chart_id from #LOS1 los2 where source_cd = 'CA'
	); -- exclude CA

	

	-- Step 1.2 Adds all CPT's when no data exists ***********************


	if object_id('TempDB..#CPT1', 'U') is not null drop table #CPT1;

	select
		SERVICE_AGREEMENT_ID
		,PATIENT_CLASS_ID
		,CPT_CODE
	into #CPT1
	from
		[dbo].[PHYSICIAN_SERVICE_PROCEDURE]
	where
		SERVICE_AGREEMENT_ID in
		(
			select distinct service_agreement_id from #LOS1
		);

	insert into #LOS1
	select
		00000000    as chart_id
		,c.SERVICE_AGREEMENT_ID
		,c.PATIENT_CLASS_ID
		,'PL'       as Class
		,@StartDate as DOS
		,'Admitted' as Disposition
		,c.CPT_CODE
		,0          as Quantity
		,'PL'       as source_cd
	from
		#CPT1 c;

	insert into #LOS1
	select
		00000000      as chart_id
		,c.SERVICE_AGREEMENT_ID
		,c.PATIENT_CLASS_ID
		,'PL'         as Class
		,@StartDate   as DOS
		,'Outpatient' as Disposition
		,c.CPT_CODE
		,0            as Quantity
		,'PL'         as source_cd
	from
		#CPT1 c;

	

	-- Step 1.3 Clean Data based on ReportUser parameters*******************************************
	
	
	if @CPT <> '-1'
	begin
		delete from
		#LOS1
		where
			cpt_code not in ( select items from dbo.SplitString(@CPT, ',') );
	end;
	


	if @PatientClass <> '-1'
	begin
		delete from
		#LOS1
		where
			patient_class_id not in
			(
				select
					PATIENT_CLASS_ID
				from
					PATIENT_CLASS
				where
					SERVICE_AGREEMENT_ID in
					(
						select
							SERVICE_AGREEMENT_ID
						from
							SERVICE_AGREEMENT
						where
							COMPANY_ID = @Company
							and FACILITY_ID in
								(
									select FACILITY_ID from #AuthorizedFacilities
								)
					)
					and DESCRIPTION in
						(
							select
								DESCRIPTION
							from
								PATIENT_CLASS
							where
								PATIENT_CLASS_ID in ( select items from dbo.SplitString(@PatientClass, ',') )
						)
			);
	end;



	if @Disposition <> '-1'
	begin
		delete from
		#LOS1
		where
			Disposition not in ( select items from dbo.SplitString(@Disposition, ',') )
	end;



	-- Step 2 Aggregate  *******************************************


	if object_id('TempDB..#LOS1_Total', 'U') is not null
		drop table #LOS1_Total;



	select
		service_agreement_id
		,patient_class_id
		,Class
		,year(DOS)          'Year'
		,month(DOS)         'MONTH'
		,case
			 when @DataSummary = 1 then convert(varchar, DOS, 102)                     -- Date
			 when @DataSummary = 2 then right('0' + cast(month(DOS) as varchar(2)), 2) -- Month
			 when @DataSummary = 3 then case
											when month(DOS) in (1, 2, 3) then '1'
											when month(DOS) in (4, 5, 6) then '2'
											when month(DOS) in (7, 8, 9) then '3'
										else '4' end                                   -- Quarter
		 end                as DateSummary
		,Disposition
		,sum(quantity)      as QTY_TOTAL
	into
		#LOS1_Total
	from
		#LOS1
	group by
		service_agreement_id
		,patient_class_id
		,Class
		,year(DOS)
		,month(DOS)
		,case
			 when @DataSummary = 1 then convert(varchar, DOS, 102)                     -- Date
			 when @DataSummary = 2 then right('0' + cast(month(DOS) as varchar(2)), 2) -- Month
			 when @DataSummary = 3 then case
											when month(DOS) in (1, 2, 3) then '1'
											when month(DOS) in (4, 5, 6) then '2'
											when month(DOS) in (7, 8, 9) then '3'
										else '4' end                                   -- Quarter
		 end
		,Disposition;




	-- Step 3   *******************************************



	;
	with FacilityLOSSummary
	as
	(
		select
			f.NAME + ' - ' + pc.DESCRIPTION 'Facility'
			,x.service_agreement_id
			,c.COMPANY_ID                   Company_ID
			,c.NAME                         Organization
			,f.FACILITY_ID
			,x.patient_class_id
			,pc.DESCRIPTION                 Patient_Class
			,x.Class
			,x.[Year]
			,x.[Month]
			,x.DateSummary
			,x.Disposition
			,x.cpt_code
			,x.QTY_TOTAL
			,x.QTY
		from
			FACILITY f with (nolock)
			,SERVICE_AGREEMENT sa with (nolock)
			,PATIENT_CLASS pc with (nolock)
			,COMPANY c with (nolock)
			,(
				 select
					 los.service_agreement_id
					 ,case
						  when los.patient_class_id = -1 then
						  (
							  select
								  max(pc2.PATIENT_CLASS_ID)
							  from
								  PATIENT_CLASS pc2 with (nolock)
							  where
								  pc2.SERVICE_AGREEMENT_ID = los.service_agreement_id
								  and pc2.DEFAULT_IND = 1
						  )
						  when los.patient_class_id is null then
						  (
							  select
								  max(pc2.PATIENT_CLASS_ID)
							  from
								  PATIENT_CLASS pc2 with (nolock)
							  where
								  pc2.SERVICE_AGREEMENT_ID = los.service_agreement_id
								  and pc2.DEFAULT_IND = 1
						  )
					  else los.patient_class_id end patient_class_id
					 ,case
						  when los.Class = 'FL' then 'Facility'
						  when los.Class = 'PL' then 'Pro-Fee'
					  else 'Other' end              as Class
					 ,los.[Year]
					 ,los.[Month]
					 ,los.DateSummary
					 ,los.Disposition
					 ,los.cpt_code
					 ,los.QTY_TOTAL
					 ,los.QTY
				 from
				 (
					 select
						 m.service_agreement_id
						 ,m.patient_class_id
						 ,m.Class
						 ,m.[Year]
						 ,m.[Month]
						 ,m.DateSummary
						 ,m.Disposition
						 ,m.cpt_code
						 ,lt.QTY_TOTAL
						 ,sum(m.quantity) as QTY
					 from
					 (
						 select
							 sp.chart_id
							 ,sp.service_agreement_id
							 ,sp.patient_class_id
							 ,sp.Class      Class
							 ,year(sp.DOS)  'Year'
							 ,month(sp.DOS) 'Month'
							 ,case
								  when @DataSummary = 1 then convert(varchar, DOS, 102)                     -- Date
								  when @DataSummary = 2 then right('0' + cast(month(DOS) as varchar(2)), 2) -- Month
								  when @DataSummary = 3 then case
																 when month(DOS) in (1, 2, 3) then '1'
																 when month(DOS) in (4, 5, 6) then '2'
																 when month(DOS) in (7, 8, 9) then '3'
															 else '4' end                                   -- Quarter
							  end           as DateSummary
							 ,sp.Disposition
							 ,sp.cpt_code
							 ,sp.quantity
						 from
							 #LOS1 sp
					 ) m
						 ,#LOS1_Total lt
					 where
						 m.service_agreement_id = lt.service_agreement_id
						 and m.patient_class_id = lt.patient_class_id
						 and m.Class = lt.Class
						 and m.DateSummary = lt.DateSummary
						 and m.[Year] = lt.[Year]
						 and m.[Month] = lt.[MONTH]
						 and m.Disposition = lt.Disposition
					 group by
						 m.service_agreement_id
						 ,m.patient_class_id
						 ,m.Class
						 ,m.[Year]
						 ,m.[Month]
						 ,m.DateSummary
						 ,m.Disposition
						 ,m.cpt_code
						 ,lt.QTY_TOTAL
				 ) as los
			 ) x
		where
			sa.SERVICE_AGREEMENT_ID = x.service_agreement_id
			and f.FACILITY_ID = sa.FACILITY_ID
			and pc.PATIENT_CLASS_ID = x.patient_class_id
			and pc.SERVICE_AGREEMENT_ID = x.service_agreement_id
			and c.COMPANY_ID = sa.COMPANY_ID
	)





	-- Output *********




	select
		los.*
	from
		FacilityLOSSummary los
	where
		los.FACILITY_ID in
		(
			select
				fua.FACILITY_ID
			from
				FACILITY_USER_AUTHORIZATION fua
			where
				getdate() between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
				and fua.USER_PROFILE_ID = @ReportUser
		)
	order by
		los.Facility
		,los.Patient_Class
		,los.Class
		,los.DateSummary asc
		,los.Disposition desc;


end
GO
