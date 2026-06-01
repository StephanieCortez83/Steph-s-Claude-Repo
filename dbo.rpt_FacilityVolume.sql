SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[rpt_FacilityVolume]
(@Facility_Id			  varchar(max)
    ,@DateType            int
    ,@StartDate           datetime
    ,@EndDate             datetime
    ,@PatientClass        varchar(25)
    ,@PatientDisposition  varchar(25) 
    ,@AccountManager      varchar(150)
    ,@Vendor_Id           varchar(150))
as

begin

	set transaction isolation level read uncommitted
	set nocount on;


	--/* TEST PARMS */
	--declare @values varchar(max)	
	--select @values = coalesce(@values,'') + convert(varchar,x.FACILITY_ID) + ','
	--from 
	--	(select distinct f.FACILITY_ID
	--	 from
	--		FACILITY f
	--		inner join SERVICE_AGREEMENT sa on f.FACILITY_ID = sa.FACILITY_ID
	--	 where
	--		sa.DEMO_TEST_SITE_IND = 0
	--		and getdate() between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
	--	) x	
	----select @values

	--declare
	--	@Facility_Id         varchar(max) = '978,1056' --case when right(@values, 1) = ',' then left(@values, len(@values) - 1) else @values end
	--	,@DateType           int          = 3
	--	,@StartDate          datetime     = '20191001'
	--	,@EndDate            datetime     = '20191007'
	--	,@PatientClass       varchar(25)  = '-99'
	--	,@PatientDisposition varchar(25)  = '-99'
	--	,@AccountManager     varchar(150) = '0'
	--	,@Vendor_Id          varchar(150) = '-1';
	--/* TEST PARMS */

	declare
		@ps_Facility_Id         varchar(max) = @Facility_Id
		,@ps_DateType           int          = @DateType
		,@ps_StartDate          datetime     = @StartDate
		,@ps_EndDate            datetime     = @EndDate
		,@ps_PatientClass       varchar(25)  = @PatientClass
		,@ps_PatientDisposition varchar(25)  = @PatientDisposition
		,@ps_AccountManager     varchar(150) = @AccountManager
		,@ps_Vendor_Id          varchar(150) = @Vendor_Id;

	
	print 'Section: 01 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	if object_id('TempDB..#Facility', 'U') is not null drop table #Facility;
	if object_id('TempDB..#CHART', 'U') is not null drop table #CHART;
	if object_id('TempDB..#CHARTs', 'U') is not null drop table #CHARTs;
	if object_id('TempDB..#APV', 'U') is not null drop table #APV;
	if object_id('TempDB..#APV_90Days', 'U') is not null drop table #APV_90Days;
	if object_id('TempDB..#APV_12Months', 'U') is not null drop table #APV_12Months;
	if object_id('TempDB..#pre_results', 'U') is not null drop table #pre_results;


	----------------------------------------------------------------------------------------------------

	declare
		@ps_Start_12Months datetime = (select convert(datetime, dateadd(dd, -(day(dateadd(month,-12,@ps_EndDate)) - 1), dateadd(month,-12,@ps_EndDate))))
	declare 
		@ps_Start_90Days datetime = (select convert(datetime, dateadd(dd, -(day(dateadd(day,-90,@ps_EndDate)) - 1), dateadd(day,-90,@ps_EndDate))))
	--select @ps_Start_12Months, @ps_Start_90Days


	----------------------------------------------------------------------------------------------------

	select FACILITY_ID
	into #Facility
	from
		FACILITY
	where
		FACILITY_ID in (select items from [dbo].[SplitString](@ps_Facility_Id,','))
	
	
	print 'Section: 02 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	declare @ps_Date varchar(25)
		= case when @ps_DateType = 0 then 'c.APPROVED_DATE'
				when @ps_DateType = 1 then 'c.COMPLETION_DATE'
				when @ps_DateType = 2 then 'c.TIME_OF_SERVICE'
				when @ps_DateType = 3 then 'c.SENT_DATE'
				when @ps_DateType = 4 then 'c.DATE_RECEIVED'
			else null end


	create table #CHART
	(
	[SERVICE_AGREEMENT_ID]          int
	,[FACILITY_ID]                  int
	,[TIME_OF_SERVICE]              datetime
	,[COMPLETION_DATE]              datetime
	,[APPROVED_DATE]                datetime
	,[SENT_DATE]                    datetime
	,[DATE_RECEIVED]                datetime
	,[PATIENT_CLASS_ID]             int
	,[PATIENT_DISPOSITION_ID]       int
	,[COMPLETED_BY_USER_PROFILE_ID] int
	,[OBS_Client_User]              int
	,[ED_Ind]                       int
	,[BILL_PRO_FEE_IND]             int
	);


	declare @dyn_sql varchar(max)
	set @dyn_sql = '

	select 
		c.SERVICE_AGREEMENT_ID
		,c.FACILITY_ID
		,c.TIME_OF_SERVICE
		,c.COMPLETION_DATE
		,c.APPROVED_DATE
		,c.SENT_DATE
		,c.DATE_RECEIVED
		,c.PATIENT_CLASS_ID
		,c.PATIENT_DISPOSITION_ID
		,c.COMPLETED_BY_USER_PROFILE_ID
		,case
			 when
				 (
				 select distinct
						1
				 from
					 USER_PROFILE up
				 where
					 up.USER_PROFILE_ID = c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID and up.USER_CLASS_CD = 4
				 ) = 1 then 1
			 else 0 end [OBS_Client_User]
		,case
			 when c.PATIENT_DISPOSITION_ID <> 5 then 1
			 when c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID =
				 (
				 select
					 sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
				 from
					 SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sao
				 where
					 sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 1 and sao.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				 ) then 1
			 else 0 end [ED_Ind]
		,case
			 when sa.BILL_PRO_FEE_METHOD_CD = 1 and c.CHART_ID in
														(
														select
															sp.chart_id
														from
															SENT_PROCEDURE sp with (nolock)
														where
															c.CHART_ID = sp.chart_id and sp.class in (''PL'',''PP'')
														) then 1
			 else 0 end [BILL_PRO_FEE_IND]
	from
		CHART c
		inner join #Facility f on c.FACILITY_ID = f.FACILITY_ID
		inner join SERVICE_AGREEMENT sa on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		inner join SERVICE_AGREEMENT_MANAGEMENT_TEAM samt on sa.SERVICE_AGREEMENT_ID = samt.SERVICE_AGREEMENT_ID and samt.MANAGEMENT_TEAM_ROLE_ID = 1
	where
		--c.FACILITY_ID in (' + @ps_Facility_Id + ')' + '
		 ' + @ps_Date + ' between ' + '''' + convert(varchar(10),@ps_StartDate,112) + '''' + ' and ' + '''' + convert(varchar(10),dateadd(day,1,@ps_EndDate),112) + '''' + '
		and (' + '''' + @ps_PatientClass + '''' + ' = ''-99'' or c.PATIENT_CLASS_ID in (' + @ps_PatientClass + '))' + '
		and (' + '''' + @ps_PatientDisposition + '''' + ' = ''-99'' or c.PATIENT_DISPOSITION_ID in (' + @ps_PatientDisposition + '))' + '
		and (' + '''' + @ps_AccountManager + '''' + ' = ''0'' or samt.USER_PROFILE_ID in (' + @ps_AccountManager + '))
		and (' + '''' + @ps_Vendor_Id + '''' + ' = ''-1''
				or ltrim(rtrim(coalesce(stuff((
										select ''-'' + convert(varchar,sl.SERVICE_LOCATION_ID)
										from 
											[dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla 
											inner join [dbo].[SERVICE_LOCATION] sl on sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
											inner join [dbo].[COMPANY] cpy on cpy.COMPANY_ID = sl.COMPANY_ID
										where 
											sla.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
											and getdate() between EFFECTIVE_DATE AND EXPIRATION_DATE
										order by sl.SERVICE_LOCATION_ID
										for xml path('''')
										), 1, 1, ''''), ''N/A''))) in (' + '''' + replace(@ps_Vendor_Id,',',''',''') + '''' + '))'
		
	print @dyn_sql
	insert into #CHART
	exec (@dyn_sql)


	print 'Section: 03 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- APV Date Range (User Parameter Values)

	select 
		a.FACILITY_ID
		,a.PATIENT_CLASS_ID
		,a.PATIENT_DISPOSITION_ID
		,count(1) [COUNT]
		,count(1)*1.00 / datediff(day,@ps_StartDate,dateadd(day,1,@ps_EndDate))*1.00 [APV]
	into #APV
	from 
		#CHART a
	group by 
		a.FACILITY_ID
		,a.PATIENT_CLASS_ID
		,a.PATIENT_DISPOSITION_ID


	print 'Section: 04 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- APV 90 Days

	create table #CHARTs
		(
		CHART_ID int
		)

	set @dyn_sql = ''
	set @dyn_sql = '

	select distinct CHART_ID
	from
		CHART c
	where
		c.FACILITY_ID in (' + @ps_Facility_Id + ')' + '
		and ' + @ps_Date + ' between ' + '''' + convert(varchar(10),@ps_Start_90Days,112) + '''' + ' and ' + '''' + convert(varchar(10),dateadd(day,1,@ps_EndDate),112) + '''' + ''

	--print (@dyn_sql)
	insert into #CHARTs
	exec (@dyn_sql)


	create table #APV_90Days
		(
		[FACILITY_ID]             int
		,[PATIENT_CLASS_ID]       int
		,[PATIENT_DISPOSITION_ID] int
		,[COUNT]                  int
		,[APV]                    decimal(18, 2)
		);

	set @dyn_sql = ''
	set @dyn_sql = '

	select 
		c.FACILITY_ID
		,c.PATIENT_CLASS_ID
		,c.PATIENT_DISPOSITION_ID
		,count(1) [COUNT]
		,count(1)*1.00 / datediff(day,' + '''' + convert(varchar(10),@ps_Start_90Days,112) + '''' + ',dateadd(day,1,' + '''' + convert(varchar(10),dateadd(day,1,@ps_EndDate),112) + '''' + '))*1.00 [APV]
	from
		#CHARTs cs
		inner join CHART c on cs.CHART_ID = c.CHART_ID
		inner join SERVICE_AGREEMENT sa on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		inner join SERVICE_AGREEMENT_MANAGEMENT_TEAM samt on sa.SERVICE_AGREEMENT_ID = samt.SERVICE_AGREEMENT_ID and samt.MANAGEMENT_TEAM_ROLE_ID = 1
	where
		--c.FACILITY_ID in (' + @ps_Facility_Id + ')' + '
		--and ' + @ps_Date + ' between ' + '''' + convert(varchar(10),@ps_Start_90Days,112) + '''' + ' and ' + '''' + convert(varchar(10),dateadd(day,1,@ps_EndDate),112) + '''' + '
		(' + '''' + @ps_PatientClass + '''' + ' = ''-99'' or c.PATIENT_CLASS_ID in (' + @ps_PatientClass + '))' + '
		and (' + '''' + @ps_PatientDisposition + '''' + ' = ''-99'' or c.PATIENT_DISPOSITION_ID in (' + @ps_PatientDisposition + '))' + '
		and (' + '''' + @ps_AccountManager + '''' + ' = ''0'' or samt.USER_PROFILE_ID in (' + @ps_AccountManager + '))
		and (' + '''' + @ps_Vendor_Id + '''' + ' = ''-1''
				or ltrim(rtrim(coalesce(stuff((
										select ''-'' + convert(varchar,sl.SERVICE_LOCATION_ID)
										from 
											[dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla 
											inner join [dbo].[SERVICE_LOCATION] sl on sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
											inner join [dbo].[COMPANY] cpy on cpy.COMPANY_ID = sl.COMPANY_ID
										where 
											sla.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
											and getdate() between EFFECTIVE_DATE AND EXPIRATION_DATE
										order by sl.SERVICE_LOCATION_ID
										for xml path('''')
										), 1, 1, ''''), ''N/A''))) in (' + '''' + replace(@ps_Vendor_Id,',',''',''') + '''' + '))
	group by 
		c.FACILITY_ID
		,c.PATIENT_CLASS_ID
		,c.PATIENT_DISPOSITION_ID'
		
	--print @dyn_sql
	insert into #APV_90Days
	exec (@dyn_sql)


	print 'Section: 05 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- APV 12 Months @ps_Start_12Months

	truncate table #CHARTs

	set @dyn_sql = ''
	set @dyn_sql = '

	select distinct CHART_ID
	from
		CHART c
	where
		c.FACILITY_ID in (' + @ps_Facility_Id + ')' + '
		and ' + @ps_Date + ' between ' + '''' + convert(varchar(10),@ps_Start_12Months,112) + '''' + ' and ' + '''' + convert(varchar(10),dateadd(day,1,@ps_EndDate),112) + '''' + ''

	--print (@dyn_sql)
	insert into #CHARTs
	exec (@dyn_sql)


	create table #APV_12Months
		(
		[FACILITY_ID]             int
		,[PATIENT_CLASS_ID]       int
		,[PATIENT_DISPOSITION_ID] int
		,[COUNT]                  int
		,[APV]                    decimal(18, 2)
		);

	set @dyn_sql = ''
	set @dyn_sql = '

	select 
		c.FACILITY_ID
		,c.PATIENT_CLASS_ID
		,c.PATIENT_DISPOSITION_ID
		,count(1) [COUNT]
		,count(1)*1.00 / datediff(day,' + '''' + convert(varchar(10),@ps_Start_12Months,112) + '''' + ',dateadd(day,1,' + '''' + convert(varchar(10),dateadd(day,1,@ps_EndDate),112) + '''' + '))*1.00 [APV]
	from
		#CHARTs cs
		inner join CHART c on cs.CHART_ID = c.CHART_ID
		inner join SERVICE_AGREEMENT sa on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		inner join SERVICE_AGREEMENT_MANAGEMENT_TEAM samt on sa.SERVICE_AGREEMENT_ID = samt.SERVICE_AGREEMENT_ID and samt.MANAGEMENT_TEAM_ROLE_ID = 1
	where
		--c.FACILITY_ID in (' + @ps_Facility_Id + ')' + '
		--and ' + @ps_Date + ' between ' + '''' + convert(varchar(10),@ps_Start_12Months,112) + '''' + ' and ' + '''' + convert(varchar(10),dateadd(day,1,@ps_EndDate),112) + '''' + '
		(' + '''' + @ps_PatientClass + '''' + ' = ''-99'' or c.PATIENT_CLASS_ID in (' + @ps_PatientClass + '))' + '
		and (' + '''' + @ps_PatientDisposition + '''' + ' = ''-99'' or c.PATIENT_DISPOSITION_ID in (' + @ps_PatientDisposition + '))' + '
		and (' + '''' + @ps_AccountManager + '''' + ' = ''0'' or samt.USER_PROFILE_ID in (' + @ps_AccountManager + '))
		and (' + '''' + @ps_Vendor_Id + '''' + ' = ''-1''
				or ltrim(rtrim(coalesce(stuff((
										select ''-'' + convert(varchar,sl.SERVICE_LOCATION_ID)
										from 
											[dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla 
											inner join [dbo].[SERVICE_LOCATION] sl on sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
											inner join [dbo].[COMPANY] cpy on cpy.COMPANY_ID = sl.COMPANY_ID
										where 
											sla.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
											and getdate() between EFFECTIVE_DATE AND EXPIRATION_DATE
										order by sl.SERVICE_LOCATION_ID
										for xml path('''')
										), 1, 1, ''''), ''N/A''))) in (' + '''' + replace(@ps_Vendor_Id,',',''',''') + '''' + '))
	group by 
		c.FACILITY_ID
		,c.PATIENT_CLASS_ID
		,c.PATIENT_DISPOSITION_ID'
		
	--print @dyn_sql
	insert into #APV_12Months
	exec (@dyn_sql)
	
	
	print 'Section: 06 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	select 
		c.SERVICE_AGREEMENT_ID
		,c.FACILITY_ID
		,f.[NAME] [FACILITY]
		--,emr.EMR_SYSTEM
		,c.TIME_OF_SERVICE
		,c.COMPLETION_DATE
		,c.APPROVED_DATE
		,c.SENT_DATE
		,c.DATE_RECEIVED
		,c.PATIENT_CLASS_ID
		,pc.[DESCRIPTION] [PATIENT_CLASS]
		,c.PATIENT_DISPOSITION_ID
		,pd.[DESCRIPTION] [PATIENT_DISPOSITION]
		,a.APV
		,a1.APV [APV_90DAYS]
		,a2.APV [APV_12MONTHS]
		--,c.[VENDOR]
		,c.COMPLETED_BY_USER_PROFILE_ID
		,case
			 when c.OBS_Client_User = 1 and c.ED_Ind = 0 then 0
			 when up.USER_CLASS_CD = 4 then 0
			 when up.USER_CLASS_CD = 5 then 0
			 else 1 end CCS_NonVendor
		,case
			 when c.OBS_Client_User = 1 and c.ED_Ind = 0 then 0
			 when up.USER_CLASS_CD = 4 then 0
			 when up.USER_CLASS_CD = 5 then 1
			 else 0 end CCS_Vendor
		--,case when c.BILL_PRO_FEE_IND = 1 then 1 else 0 end ProFee
		,case
			 when up.USER_CLASS_CD = 4 then 1
			 when c.OBS_Client_User = 1 and c.ED_Ind = 0 then 1
			 else 0 end SaaS
	into #pre_results
	from 
		#CHART c
		inner join FACILITY f on c.FACILITY_ID = f.FACILITY_ID
		inner join PATIENT_DISPOSITION pd on c.PATIENT_DISPOSITION_ID = pd.PATIENT_DISPOSITION_ID
		inner join PATIENT_CLASS pc on c.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID
		inner join #APV a on c.FACILITY_ID = a.FACILITY_ID and c.PATIENT_CLASS_ID = a.PATIENT_CLASS_ID and c.PATIENT_DISPOSITION_ID = a.PATIENT_DISPOSITION_ID
		inner join #APV_90Days a1 on c.FACILITY_ID = a1.FACILITY_ID and c.PATIENT_CLASS_ID = a1.PATIENT_CLASS_ID and c.PATIENT_DISPOSITION_ID = a1.PATIENT_DISPOSITION_ID
		inner join #APV_12Months a2 on c.FACILITY_ID = a2.FACILITY_ID and c.PATIENT_CLASS_ID = a2.PATIENT_CLASS_ID and c.PATIENT_DISPOSITION_ID = a2.PATIENT_DISPOSITION_ID
		left join USER_PROFILE up on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID
	
	
	print 'Section: 07 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	select 
		pr.FACILITY_ID
		,pr.FACILITY
		,ltrim(rtrim(coalesce(
								stuff(
									(
									select 
										',' + es.[DESCRIPTION]
									from
										SERVICE_AGREEMENT sa
										inner join SERVICE_AGREEMENT_EMR_SYSTEM saes on sa.SERVICE_AGREEMENT_ID = saes.SERVICE_AGREEMENT_ID 
										inner join EMR_SYSTEM_TYPE est on saes.emr_system_type_id = est.emr_system_type_id
										inner join EMR_SYSTEM es on saes.emr_system_id = es.emr_system_id
									where
										est.EMR_SYSTEM_TYPE_ID = 5	--Documentation
										and pr.FACILITY_ID = sa.FACILITY_ID
									order by es.[DESCRIPTION]
									for xml path('')
									)
									,1
									,1
									,''
										)
								,'N/A'
							)
					)
				) [EMR_SYSTEM]
		,convert(date,(convert(varchar(10),pr.TIME_OF_SERVICE,101))) [TIME_OF_SERVICE]
		,convert(date,(convert(varchar(10),pr.COMPLETION_DATE,101))) [COMPLETION_DATE]
		,convert(date,(convert(varchar(10),pr.APPROVED_DATE,101))) [APPROVED_DATE]
		,convert(date,(convert(varchar(10),pr.SENT_DATE,101))) [SENT_DATE]
		,convert(date,(convert(varchar(10),pr.DATE_RECEIVED,101))) [DATE_RECEIVED]
		,pr.PATIENT_CLASS_ID
		,pr.PATIENT_CLASS
		,pr.PATIENT_DISPOSITION_ID
		,pr.PATIENT_DISPOSITION
		,pr.APV
		,pr.APV_90DAYS
		,pr.APV_12MONTHS
		,ltrim(rtrim(coalesce(stuff((
										select '-' + convert(varchar,sl.SERVICE_LOCATION_ID)
										from 
											[dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla 
											inner join [dbo].[SERVICE_LOCATION] sl on sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
											inner join [dbo].[COMPANY] cpy on cpy.COMPANY_ID = sl.COMPANY_ID
										where 
											sla.SERVICE_AGREEMENT_ID = pr.SERVICE_AGREEMENT_ID
											and getdate() between EFFECTIVE_DATE and EXPIRATION_DATE
										order by sl.SERVICE_LOCATION_ID
										for xml path('')
										), 1, 1, ''), 'N/A'))) [VENDOR_ID]
		,ltrim(rtrim(coalesce(
								stuff(
									(
									select
										',' + sl.[NAME] --cpy.[NAME]
									from
										[dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla
										inner join [dbo].[SERVICE_LOCATION] sl on sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
										inner join [dbo].[COMPANY] cpy on cpy.COMPANY_ID = sl.COMPANY_ID
									where
										sla.SERVICE_AGREEMENT_ID = pr.SERVICE_AGREEMENT_ID
										and getdate() between EFFECTIVE_DATE and EXPIRATION_DATE
									order by
										cpy.[NAME]
									for xml path('')
									)
									,1
									,1
									,''
										)
								,'N/A'
							)
					)
				) [VENDOR]
		--,sl.[NAME] [VENDOR]
		--,pr.COMPLETED_BY_USER_PROFILE_ID
		--,pr.CCS_NonVendor
		--,pr.CCS_Vendor
		--,pr.SaaS
		,case when pr.CCS_NonVendor = 1 then 'FS-Domestic' 
				when pr.CCS_Vendor = 1 then 'FS-Global' 
				when pr.SaaS = 1 then 'SaaS' else null end [SERVICE_MODEL]
	from 
		#pre_results pr
		--left join (select
		--				sla.SERVICE_AGREEMENT_ID, sl.[NAME]
		--			from
		--				[dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla
		--				inner join [dbo].[SERVICE_LOCATION] sl on sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
		--				inner join [dbo].[COMPANY] cpy on cpy.COMPANY_ID = sl.COMPANY_ID
		--			where
		--				getdate() between EFFECTIVE_DATE and EXPIRATION_DATE
		--			) sl on pr.SERVICE_AGREEMENT_ID = sl.SERVICE_AGREEMENT_ID
	order by pr.FACILITY
	
	
	print 'Section: 08 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	

end

GO
GRANT EXECUTE ON  [dbo].[rpt_FacilityVolume] TO [dbx_ExecuteReportProcs]
GO
