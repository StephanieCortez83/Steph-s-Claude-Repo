SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[rpt_CorroHealth_QA_Exclusion_Report]
(
	@Facility_Id varchar(max) 
		,@DateType   int      
		,@StartDate  datetime 
		,@EndDate    datetime 
		,@UserClass  varchar(150)
		,@UserGroup  varchar(max)
		,@IsActive   int
		,@Coder		 varchar(max)
)
as

begin


	set transaction isolation level read uncommitted;

	--declare
	--	@Facility_Id varchar(max) = '795'
	--	,@DateType   int          = 0	-- 0=DOS, 1=COMPLETED, 2=APPROVED
	--	,@StartDate  datetime     = '20210515'
	--	,@EndDate    datetime     = '20210515'
	--	,@UserClass  int		  = -1
	--	,@UserGroup  int		  = -1
	--	,@IsActive   int		  = -1
	--	,@Coder		 int		  = -1;

	----------------------------------------------------------------------------------------------------------------------------------

	if object_id('TempDB..#CHART', 'U') is not null drop table #CHART;
	if object_id('TempDB..#QA_EXCLUDE', 'U') is not null drop table #QA_EXCLUDE;
	if object_id('TempDB..#QA_EXCLUDE_SECOND_LEVEL', 'U') is not null drop table #QA_EXCLUDE_SECOND_LEVEL;


	----------------------------------------------------------------------------------------------------------------------------------

	select 
		c.FACILITY_ID
		,c.CHART_ID
		,c.FACILITY_CHART_ID
		,c.TIME_OF_SERVICE
		,c.COMPLETION_DATE
		,c.APPROVED_DATE
		,c.COMPLETED_BY_USER_PROFILE_ID [CODER_ID]
		,cdr.LAST_NAME + ', ' + cdr.FIRST_NAME [CODER]
		,cdr.IS_ACTIVE
		,cdr.USER_CLASS_CD [USER_CLASS_ID]
		,cdr.USER_GROUP_ID
		,c.APPROVED_BY_USER_PROFILE_ID [AUDITOR_ID]
		,adr.LAST_NAME + ', ' + adr.FIRST_NAME [AUDITOR]
		,c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID [SECOND_LEVEL_AUDITOR_ID]
		,sadr.LAST_NAME + ', ' + sadr.FIRST_NAME [SECOND_LEVEL_AUDITOR]
	into #CHART
	from
		dbo.CHART c
		left join dbo.USER_PROFILE cdr on c.COMPLETED_BY_USER_PROFILE_ID = cdr.USER_PROFILE_ID
		left join dbo.USER_PROFILE adr on c.APPROVED_BY_USER_PROFILE_ID = adr.USER_PROFILE_ID
		left join dbo.USER_PROFILE sadr on c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID = sadr.USER_PROFILE_ID
	where
		(@Facility_Id = '-1' or c.FACILITY_ID in (select items from dbo.SplitString(@Facility_Id,',')))
		and (
				@DateType = 0 and c.TIME_OF_SERVICE between @StartDate and dateadd(second,86399,@EndDate)
				or @DateType = 1 and c.COMPLETION_DATE between @StartDate and dateadd(second,86399,@EndDate)
				or @DateType = 2 and c.APPROVED_DATE between @StartDate and dateadd(second,86399,@EndDate)
			)
		and (@UserClass = '-1' or cdr.USER_CLASS_CD in (select items from dbo.SplitString(@UserClass,',')))
		and (@UserGroup = '-1' or cdr.USER_GROUP_ID in (select items from dbo.SplitString(@UserGroup,',')))
		and (@IsActive = '-1' or cdr.IS_ACTIVE = 'Y')
		and (@Coder = '-1' or c.COMPLETED_BY_USER_PROFILE_ID in (select items from dbo.SplitString(@Coder,',')))


	----------------------------------------------------------------------------------------------------------------------------------

	select 
		z.EXCLUSION_TYPE
		,c.FACILITY_ID
		,f.[NAME] [FACILITY]
		,z.CHART_ID
		,z.FACILITY_CHART_ID
		,c.TIME_OF_SERVICE
		,c.COMPLETION_DATE
		,c.APPROVED_DATE
		,c.CODER_ID
		,c.[CODER]
		,c.IS_ACTIVE
		,c.[USER_CLASS_ID]
		,c.USER_GROUP_ID
		--,z.AUDITOR_ID
		,c.[AUDITOR_ID]
		,c.[AUDITOR]
		,z.CODER_CODE
		,z.AUDITOR_CODE
		,z.EXCLUDE_REASON_ID
        ,r.EXCLUDE_FROM_QA_REPORT_REASON_DESCRIPTION [EXCLUDE_REASON_DESCRIPTION]
		,z.EXCLUDE_FROM_QA_REPORT
	into #QA_EXCLUDE
	from
		(
		select 
			'DIAGNOSIS' [EXCLUSION_TYPE]
			,x.CHART_ID
			,x.FACILITY_CHART_ID
			,x.AUDITOR_USER_PROFILE_ID
			,x.CODER_ICD10_CODE	[CODER_CODE]
			,x.AUDITOR_ICD10_CODE [AUDITOR_CODE]
			,x.EXCLUDE_FROM_QA_REPORT_REASON_ID [EXCLUDE_REASON_ID]
			,x.EXCLUDE_FROM_QA_REPORT
		from 
			CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION x

		union all

		select 
			'FACILITY_LOS' [EXCLUSION_TYPE]
			,x.CHART_ID
			,x.FACILITY_CHART_ID
			,x.AUDITOR_USER_PROFILE_ID 
			,x.CODER_CPT_CODE
			,x.AUDITOR_CPT_CODE
			,x.EXCLUDE_FROM_QA_REPORT_REASON_ID [EXCLUDE_REASON_ID]
			,x.EXCLUDE_FROM_QA_REPORT
		from 
			CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION x

		union all

		select 
			'PHYSICIAN_LOS' [EXCLUSION_TYPE]
			,x.CHART_ID
			,x.FACILITY_CHART_ID
			,x.AUDITOR_USER_PROFILE_ID
			,x.CODER_CPT_CODE
			,x.AUDITOR_CPT_CODE
			,x.EXCLUDE_FROM_QA_REPORT_REASON_ID [EXCLUDE_REASON_ID]
			,x.EXCLUDE_FROM_QA_REPORT
		from 
			CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION x

		union all

		select 
			'PROCEDURE_LOS' [EXCLUSION_TYPE]
			,x.CHART_ID
			,x.FACILITY_CHART_ID
			,x.AUDITOR_USER_PROFILE_ID
			,x.CODER_CPT_CODE
			,x.AUDITOR_CPT_CODE
			,x.EXCLUDE_FROM_QA_REPORT_REASON_ID [EXCLUDE_REASON_ID]
			,x.EXCLUDE_FROM_QA_REPORT
		from 
			CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION x
		) z
		inner join #CHART c on z.CHART_ID = c.CHART_ID
		inner join dbo.FACILITY f on c.FACILITY_ID = f.FACILITY_ID
		left join dbo.EXCLUDE_FROM_QA_REPORT_REASON r on z.EXCLUDE_REASON_ID = r.EXCLUDE_FROM_QA_REPORT_REASON_ID


	----------------------------------------------------------------------------------------------------------------------------------

	select
		z.EXCLUSION_TYPE
		,c.FACILITY_ID
		,f.[NAME] [FACILITY]
		,z.CHART_ID
		,z.FACILITY_CHART_ID
		,c.TIME_OF_SERVICE
		,c.COMPLETION_DATE
		,c.APPROVED_DATE
		,c.CODER_ID
		,c.[CODER]
		,c.IS_ACTIVE
		,c.[USER_CLASS_ID]
		,c.USER_GROUP_ID
		--,z.AUDITOR_ID
		,c.SECOND_LEVEL_AUDITOR_ID [AUDITOR_ID]
		,c.SECOND_LEVEL_AUDITOR [AUDITOR]
		,z.FIRST_AUDITOR_CODE
		,z.SECOND_AUDITOR_CODE
		,z.EXCLUDE_REASON_ID
        ,r.EXCLUDE_FROM_QA_REPORT_REASON_DESCRIPTION [EXCLUDE_REASON_DESCRIPTION]
		,z.EXCLUDE_FROM_QA_REPORT
	into #QA_EXCLUDE_SECOND_LEVEL
	from
		(
		select 
			'DIAGNOSIS' [EXCLUSION_TYPE]
			,x.CHART_ID
			,x.FACILITY_CHART_ID
			,x.SECOND_AUDITOR_USER_PROFILE_ID [AUDITOR_ID]
			,x.FIRST_AUDITOR_ICD10_CODE	[FIRST_AUDITOR_CODE]
			,x.SECOND_AUDITOR_ICD10_CODE [SECOND_AUDITOR_CODE]
			,x.EXCLUDE_FROM_QA_REPORT_REASON_ID [EXCLUDE_REASON_ID]
			,x.EXCLUDE_FROM_QA_REPORT
		from 
			dbo.CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION x

		union all

		select 
			'FACILITY_LOS' [EXCLUSION_TYPE]
			,x.CHART_ID
			,x.FACILITY_CHART_ID
			,x.SECOND_AUDITOR_USER_PROFILE_ID [AUDITOR_ID]
			,x.FIRST_AUDITOR_CPT_CODE
			,x.SECOND_AUDITOR_CPT_CODE
			,x.EXCLUDE_FROM_QA_REPORT_REASON_ID [EXCLUDE_REASON_ID]
			,x.EXCLUDE_FROM_QA_REPORT
		from 
			dbo.CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION x

		union all

		select 
			'PHYSICIAN_LOS' [EXCLUSION_TYPE]
			,x.CHART_ID
			,x.FACILITY_CHART_ID
			,x.SECOND_AUDITOR_USER_PROFILE_ID [AUDITOR_ID]
			,x.FIRST_AUDITOR_CPT_CODE
			,x.SECOND_AUDITOR_CPT_CODE
			,x.EXCLUDE_FROM_QA_REPORT_REASON_ID [EXCLUDE_REASON_ID]
			,x.EXCLUDE_FROM_QA_REPORT
		from 
			CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION x

		union all

		select 
			'PROCEDURE_LOS' [EXCLUSION_TYPE]
			,x.CHART_ID
			,x.FACILITY_CHART_ID
			,x.SECOND_LEVEL_AUDITOR_USER_PROFILE_ID [AUDITOR_ID]
			,x.FIRST_AUDITOR_CPT_CODE
			,x.SECOND_AUDITOR_CPT_CODE
			,x.EXCLUDE_FROM_QA_REPORT_REASON_ID [EXCLUDE_REASON_ID]
			,x.EXCLUDE_FROM_QA_REPORT
		from 
			CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION x
		) z
		inner join #CHART c on z.CHART_ID = c.CHART_ID
		inner join dbo.FACILITY f on c.FACILITY_ID = f.FACILITY_ID
		left join dbo.EXCLUDE_FROM_QA_REPORT_REASON r on z.EXCLUDE_REASON_ID = r.EXCLUDE_FROM_QA_REPORT_REASON_ID


	----------------------------------------------------------------------------------------------------------------------------------

	select 
		qae.EXCLUSION_TYPE
		,qae.FACILITY_ID
		,qae.FACILITY
		,qae.CHART_ID
		,qae.FACILITY_CHART_ID
		,qae.TIME_OF_SERVICE
		,qae.COMPLETION_DATE
		,qae.APPROVED_DATE
		,qae.CODER_ID
		,qae.CODER
		,qae.IS_ACTIVE
		,qae.USER_CLASS_ID
		,qae.USER_GROUP_ID
		,qae.AUDITOR_ID
		,qae.AUDITOR
		--,null 'SECOND_LEVEL_AUDITOR_ID'
		--,null 'SECOND_LEVEL_AUDITOR'
		,qae_sl.AUDITOR_ID [SECOND_LEVEL_AUDITOR_ID]
		,qae_sl.AUDITOR [SECOND_LEVEL_AUDITOR]
		,qae.CODER_CODE
		,qae.AUDITOR_CODE
		--,null 'FIRST_AUDITOR_CODE'
		--,null 'SECOND_AUDITOR_CODE'
		,qae_sl.FIRST_AUDITOR_CODE
		,qae_sl.SECOND_AUDITOR_CODE
		,qae.EXCLUDE_REASON_ID
		,qae.EXCLUDE_REASON_DESCRIPTION
	from
		#QA_EXCLUDE qae
		left join #QA_EXCLUDE_SECOND_LEVEL qae_sl on qae.FACILITY_CHART_ID = qae_sl.FACILITY_CHART_ID and qae.AUDITOR_CODE = qae_sl.SECOND_AUDITOR_CODE
	where
		(qae.EXCLUDE_FROM_QA_REPORT = 1 or qae_sl.EXCLUDE_FROM_QA_REPORT = 1)
	order by 1,3,4


	----------------------------------------------------------------------------------------------------------------------------------


end
GO
GRANT EXECUTE ON  [dbo].[rpt_CorroHealth_QA_Exclusion_Report] TO [dbx_ExecuteReportProcs]
GO
