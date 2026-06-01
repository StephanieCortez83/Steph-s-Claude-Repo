SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









-- =============================================
-- Author:		Don Hutton
-- Create date:	4/6/2020
-- Description:	Accounts By Facility and Service Level Report
-- Modified:
--				12/16/2020 | JHerrera | Modified date search in where clause to fix performance issues. 
--				06/20/2022 | Dhutton  | Jira AAR-1977 - Added DateType and Column TIME_OF_DIS  		
--				08/04/2023 | Dhutton  | Jira RACS-2900 - Add -1 and -2 Options to Temp Table '#FACILITY_SVC'
--
-- =============================================



CREATE PROCEDURE [dbo].[rpt_AccountsByFacilityAndServiceLevel]
	 
     @Facility        varchar(max)
    ,@ChartStatus     int         
    ,@DateType        int         
    ,@StartDate       datetime    
    ,@ThruDate        datetime    
    ,@ReportUser      int         
    ,@Levels          varchar(max)         
    ,@Class           varchar(2)  
    ,@DispositionType int         
    ,@Disposition     varchar(max)
AS
begin 



-- Parameters for testing 

--declare 
	
--     @Facility        varchar(max) = '-2'
--    ,@ChartStatus     int   = 5      
--    ,@DateType        int  = 3     -- 0 DOS, 1 Approved, 2 Sent, 3 Discharge 
--    ,@StartDate       datetime  = '08/01/2023'   
--    ,@ThruDate        datetime  = '08/04/2023'  
--    ,@ReportUser      int      = 80   
--    ,@Levels          varchar(max)     = '-1'    
--    ,@Class           varchar(2)  =  '-1'
--    ,@DispositionType int     = 1    
--    ,@Disposition     varchar(max) = '-99'




	set transaction isolation level read uncommitted

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	DECLARE @m_Facility varchar(max) = @Facility,
		@m_ChartStatus AS INT = @ChartStatus,
		@m_DateType as int = @DateType,
		@m_StartDate AS datetime = @StartDate,
		@m_ThruDate AS datetime = @ThruDate,
		@m_ReportUser AS int = @ReportUser,
		@m_Levels varchar(max) = @Levels,
		@m_Class varchar(2) = @Class,
		@m_DispositionType int = @DispositionType,
		@m_Disposition as varchar(max) = @Disposition
		;


if object_id('TempDB..#FACILITY_SVC', 'U') is not null
    begin
        drop table #FACILITY_SVC;
    end;
if object_id('TempDB..#RESULTS', 'U') is not null
    drop table #RESULTS;
if object_id('TempDB..#RESULTS1', 'U') is not null
    drop table #RESULTS1;
if object_id('TempDB..#RESULTS_2', 'U') is not null
    drop table #RESULTS_2;


if object_id('TempDB..#CHART1', 'U') is not null
    drop table #CHART1;






print 'Section: 00 ' + convert(varchar, getdate(), 121)
----------------------------------------------------------------------------------------------------

select
    *
into
    #FACILITY_SVC
from
    (
    SELECT DISTINCT fua.FACILITY_ID, sa.EVALUATE_FACILITY_SVC, sa.EVALUATE_PHYSICIAN_SVC, sa.COMPANY_ID
	FROM FACILITY_USER_AUTHORIZATION fua,
	USER_PROFILE up,
	SERVICE_AGREEMENT sa
	WHERE 
	fua.user_profile_id = up.user_profile_id
	and fua.facility_id = sa.facility_id 
	and up.IS_ACTIVE = 'Y'						
	and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
	and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
	and sa.DEMO_TEST_SITE_IND = 0
	and fua.USER_PROFILE_ID = @m_ReportUser	 

    and   ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_Facility, ','))
            OR	'-1'  in (SELECT * FROM SPLITSTRING(@m_Facility, ',')) 
			OR	'-2'  in (SELECT * FROM SPLITSTRING(@m_Facility, ',')) 
		   )
    ) T1;



 IF @m_Facility = '-2'	
BEGIN	

delete from #FACILITY_SVC WHERE COMPANY_ID = 19 -- Tenet Healthcare Corporation
END 



print 'Section: 01 ' + convert(varchar, getdate(), 121)
----------------------------------------------------------------------------------------------------



    select
         c.CHART_ID  
into #CHART1		 
     from
         CHART c
     where
(
		(
			@m_DateType = 0
			--and cast(c.TIME_OF_SERVICE as date) between @m_StartDate and @m_ThruDate
			and c.TIME_OF_SERVICE between @m_StartDate and dateadd(second,86399,@m_ThruDate)
		)
		or
		(
			@m_DateType = 1
			--and cast(c.APPROVED_DATE as date) between @m_StartDate and @m_ThruDate
			and c.APPROVED_DATE between @m_StartDate and dateadd(second,86399,@m_ThruDate)
		)
		or
		(
			@m_DateType = 2
			--and cast(c.SENT_DATE as date) between @m_StartDate and @m_ThruDate
			and c.SENT_DATE between @m_StartDate and dateadd(second,86399,@m_ThruDate)
		)
        or
		(
			@m_DateType = 3
			--and cast(c.SENT_DATE as date) between @m_StartDate and @m_ThruDate
			and c.TIME_OF_DIS between @m_StartDate and dateadd(second,86399,@m_ThruDate)
		)	
	)

and exists
         (
         select
             *
         from
             #FACILITY_SVC
         where
             EVALUATE_FACILITY_SVC = 1 
			 and FACILITY_ID = c.FACILITY_ID
         ); 
		 


create nonclustered index idx_CHART_ID on #CHART1 (CHART_ID);

print 'Section: 02 ' + convert(varchar, getdate(), 121)
----------------------------------------------------------------------------------------------------



select
    t1.CHART_ID
    ,f.NAME
    ,t1.FACILITY_ID
    ,t1.SERVICE_AGREEMENT_ID
    ,t1.CHART_STATUS_ID
    ,t1.ACCOUNT
    ,t1.DOS
	,t1.TIME_OF_DIS
    ,t1.CODER_ID
    ,t1.CODED_BY
    ,t1.START_QA_DATE
    ,t1.APPROVED_DATE
    ,t1.APPROVED_BY
    ,t1.START_SECOND_LEVEL_QA_DATETIME
    ,t1.SECOND_LEVEL_QA_APPROVED_DATETIME
    ,t1.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
    ,max(t1.CODER_FACILITY_CPT) as CODER_FACILITY_CPT
    ,max(t1.AUDITOR_FACILITY_CPT) as AUDITOR_FACILITY_CPT
    ,max(t1.CODER_PROFEE_CPT) as CODER_PROFEE_CPT
    ,max(t1.AUDITOR_PROFEE_CPT) as AUDITOR_PROFEE_CPT
    ,t1.PHYSICIAN_NAME
    ,t1.CLASS
    ,t1.FACILITY_CRITICAL_CARE_MINUTES
    ,t1.PHYSICIAN_CRITICAL_CARE_MINUTES
    ,t1.PATIENT_DISPOSITION_ID
    ,t1.PATIENT_DISPOSITION_MAP_ID
	,t1.[Level]

into
    #RESULTS
from
    FACILITY f
    ,(
     -- facility level***
     select
         c.CHART_ID
         ,c.FACILITY_ID
         ,c.SERVICE_AGREEMENT_ID
         ,c.CHART_STATUS_ID
         ,c.FACILITY_CHART_ID ACCOUNT
         ,c.TIME_OF_SERVICE DOS
		 ,c.TIME_OF_DIS
         ,c.COMPLETED_BY_USER_PROFILE_ID [CODER_ID]
         ,upper(coder.LAST_NAME + ', ' + coder.FIRST_NAME) CODED_BY
		 ,c.START_QA_DATE
         ,c.APPROVED_DATE
         ,c.APPROVED_BY_USER_PROFILE_ID APPROVED_BY
		 ,c.START_SECOND_LEVEL_QA_DATETIME
         ,c.SECOND_LEVEL_QA_APPROVED_DATETIME
         ,c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
         ,cfl.CPT_CODE CODER_FACILITY_CPT
         ,afl.CPT_CODE AUDITOR_FACILITY_CPT
         ,null CODER_PROFEE_CPT
         ,null AUDITOR_PROFEE_CPT
         ,upper(fp.LAST_NAME + ', ' + fp.FIRST_NAME) PHYSICIAN_NAME
         ,sp.CLASS
         ,c.FACILITY_CRITICAL_CARE_MINUTES
         ,c.[PHYSICIAN_CRITICAL_CARE_MINUTES]
         ,c.PATIENT_DISPOSITION_ID
         ,c.PATIENT_DISPOSITION_MAP_ID
		 ,afl.LEVEL_NUMBER as [Level]


     from
         CHART c
         inner join CHART_LOS_HISTORY los on c.CHART_ID = los.CHART_ID
         inner join USER_PROFILE coder on coder.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID			
         left join FACILITY_PROFESSIONAL fp on fp.FACILITY_PROF_ID = c.PHYSICIAN_ID
         left join FACILITY_LEVEL cfl on cfl.FACILITY_LEVEL_ID = isnull(
                                                                           nullif(los.OVERRIDE_FACILITY_LEVEL_ID, -1)
                                                                           ,los.FACILITY_LEVEL_ID
                                                                       )
         left join FACILITY_LEVEL afl on afl.FACILITY_LEVEL_ID = isnull(
                                                                           nullif(c.OVERRIDE_FACILITY_LEVEL_ID, -1)
                                                                           ,c.FACILITY_LEVEL_ID
                                                                       )
         left join SENT_PROCEDURE sp on c.CHART_ID = sp.CHART_ID

     where
        exists ( select * from #CHART1 where chart_id = c.chart_id) 


		and  c.CHART_STATUS_ID = @m_ChartStatus 




     union

     -- *** physician level *** --
     select
         c.CHART_ID
         ,c.FACILITY_ID
         ,c.SERVICE_AGREEMENT_ID
         ,c.CHART_STATUS_ID
         ,c.FACILITY_CHART_ID ACCOUNT
         ,c.TIME_OF_SERVICE DOS
		 ,c.TIME_OF_DIS
         ,coder.USER_PROFILE_ID [CODER_ID]
         ,upper(coder.LAST_NAME + ', ' + coder.FIRST_NAME) CODED_BY
		 ,c.START_QA_DATE
         ,c.APPROVED_DATE
         ,c.APPROVED_BY_USER_PROFILE_ID APPROVED_BY
		 ,c.START_SECOND_LEVEL_QA_DATETIME
         ,c.SECOND_LEVEL_QA_APPROVED_DATETIME
         ,c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
         ,null CODER_FACILITY_CPT
         ,null AUDITOR_FACILITY_CPT
         ,cpl.CPT_CODE CODER_PROFEE_CPT
         ,apl.CPT_CODE AUDITOR_PROFEE_CPT
         ,upper(fp.LAST_NAME + ', ' + fp.FIRST_NAME) PHYSICIAN_NAME
         ,sp.CLASS
         ,c.FACILITY_CRITICAL_CARE_MINUTES
         ,c.[PHYSICIAN_CRITICAL_CARE_MINUTES]
         ,c.PATIENT_DISPOSITION_ID
         ,c.PATIENT_DISPOSITION_MAP_ID
		 ,apl.SERVICE_LEVEL_CD

     from
         CHART c
         inner join CHART_LOS_HISTORY los on c.CHART_ID = los.CHART_ID
         inner join USER_PROFILE coder on coder.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
         left join FACILITY_PROFESSIONAL fp on fp.FACILITY_PROF_ID = c.PHYSICIAN_ID
         left join PHYSICIAN_SERVICE_PROCEDURE cpl on cpl.PHYSICIAN_SERVICE_PROC_ID = isnull(
                                                                                                nullif(los.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID, -1)
                                                                                                ,los.PHYSICIAN_SERVICE_PROC_ID
                                                                                            )
         left join PHYSICIAN_SERVICE_PROCEDURE apl on apl.PHYSICIAN_SERVICE_PROC_ID = isnull(
                                                                                                nullif(c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID, -1)
                                                                                                ,c.PHYSICIAN_SERVICE_PROC_ID
                                                                                            )
         left join SENT_PROCEDURE sp on c.CHART_ID = sp.CHART_ID

     where
	     exists ( select * from #CHART1 where chart_id = c.chart_id) 
		 and c.CHART_STATUS_ID = @m_ChartStatus 
		 

     ) t1
where
    f.FACILITY_ID = t1.FACILITY_ID
group by
    t1.CHART_ID
    ,f.NAME
    ,t1.FACILITY_ID
    ,t1.SERVICE_AGREEMENT_ID
    ,t1.CHART_STATUS_ID
    ,t1.ACCOUNT
    ,t1.DOS
	,t1.TIME_OF_DIS
    ,t1.CODER_ID
    ,t1.CODED_BY
	,t1.START_QA_DATE
    ,t1.APPROVED_DATE
    ,t1.APPROVED_BY
	,t1.START_SECOND_LEVEL_QA_DATETIME
    ,t1.SECOND_LEVEL_QA_APPROVED_DATETIME
    ,t1.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
    ,t1.PHYSICIAN_NAME
    ,t1.CLASS
    ,t1.FACILITY_CRITICAL_CARE_MINUTES
    ,t1.PHYSICIAN_CRITICAL_CARE_MINUTES
    ,t1.PATIENT_DISPOSITION_ID
    ,t1.PATIENT_DISPOSITION_MAP_ID
	,t1.[Level]
;



print 'Section: 03 ' + convert(varchar, getdate(), 121)
----------------------------------------------------------------------------------------------------


select 
t1.* 
into #RESULTS1
from
(
select * 
from #RESULTS
where 
class in ('FL', 'PL')
and '-1' in (@m_Class)
--and ([Level] in (@m_Levels) or -1 in (@m_Levels))
and ([Level] in (SELECT * FROM SPLITSTRING(@m_Levels, ','))
or  '-1' in (SELECT * FROM SPLITSTRING(@m_Levels, ',')) )

union

select * 
from #RESULTS
where 
class = 'FL'
and 'FL' in (@m_Class)
--and ([Level] in (@m_Levels) or -1 in (@m_Levels))
and ([Level] in (SELECT * FROM SPLITSTRING(@m_Levels, ','))
or  '-1' in (SELECT * FROM SPLITSTRING(@m_Levels, ',')) )

union

select * 
from #RESULTS
where 
class = 'PL'
and 'PL' in (@m_Class)
--and ([Level] in (@m_Levels) or -1 in (@m_Levels))
and ([Level] in (SELECT * FROM SPLITSTRING(@m_Levels, ','))
or  '-1' in (SELECT * FROM SPLITSTRING(@m_Levels, ',')) )
)t1


print 'Section: 04 ' + convert(varchar, getdate(), 121)
----------------------------------------------------------------------------------------------------



select
    r.NAME
 ,r.Chart_ID		-- added by dsexton to support new UPDATE statements
    ,r.ACCOUNT	
    ,r.DOS
	,r.TIME_OF_DIS
    ,r.CODER_ID
    ,r.CODED_BY

    ,(case
          when r.APPROVED_BY <> 2 and r.START_QA_DATE is not null and r.APPROVED_DATE is not null then 1
          else 0 end
     ) Audited
    ,r.APPROVED_BY as Auditor_ID
    ,(
     select
         up.LAST_NAME + ', ' + up.FIRST_NAME
     from
         USER_PROFILE up
     where
         up.USER_PROFILE_ID = r.APPROVED_BY
     ) as Auditor

    ,(case
          when r.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 2 and r.START_SECOND_LEVEL_QA_DATETIME is not null and r.SECOND_LEVEL_QA_APPROVED_DATETIME is not null then 1
          else 0 end
     ) Second_Audit
    ,r.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID as Second_Audit_ID
    ,(
     select
         up2.LAST_NAME + ', ' + up2.FIRST_NAME
     from
         USER_PROFILE up2
     where
         up2.USER_PROFILE_ID = r.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
     ) as Second_Auditor
    ,r.CODER_FACILITY_CPT
    ,r.AUDITOR_FACILITY_CPT
    ,r.CODER_PROFEE_CPT
    ,r.AUDITOR_PROFEE_CPT
    ,r.PHYSICIAN_NAME
    ,r.FACILITY_CRITICAL_CARE_MINUTES
    ,r.PHYSICIAN_CRITICAL_CARE_MINUTES
    ,r.PATIENT_DISPOSITION_ID
    ,r.PATIENT_DISPOSITION_MAP_ID

	/*
    ,(
          select top 1
                 cdc.ICD10_CODE
          from
              CHART_DIAGNOSIS_CODE_ICD10 cdc
          where
              r.CHART_ID = cdc.CHART_ID and cdc.DIAGNOSIS_TYPE_ID = 1 and cdc.IS_PRIMARY = 1 --Chief Complaint
          ) [CHIEF_COMPLAINT]
	*/
	, CHIEF_COMPLAINT = (select top 1 ICD10_Code from CHART_DIAGNOSIS_CODE_ICD10 where 1 = 0)		-- added by dsexton to replace the subquery (see corresponding UPDATE statements below)


		/*
		,(
          select top 1
                 SHORT_DESCRIPTION
          from
              ICD_10_CM cm
              ,CHART_DIAGNOSIS_CODE_ICD10 cdc
          where
              r.CHART_ID = cdc.CHART_ID and cm.ICD_10_CODE = replace(cdc.ICD10_CODE , '.', '')
			  and cdc.DIAGNOSIS_TYPE_ID = 1 and cdc.IS_PRIMARY = 1 --Chief Complaint
			  and getdate() between cm.EFFECTIVE_DATE and cm.EXPIRATION_DATE
          ) [CHIEF_COMPLAINT_DESC]
		*/
		, CHIEF_COMPLAINT_DESC = (select top 1 Short_Description from ICD_10_CM where 1 = 0)		-- added by dsexton to replace the subquery (see corresponding UPDATE statements below)


		/*
         ,(
          select top 1
                 cdc.ICD10_CODE
          from
              CHART_DIAGNOSIS_CODE_ICD10 cdc
          where
              r.CHART_ID = cdc.CHART_ID and cdc.DIAGNOSIS_TYPE_ID = 2 and cdc.IS_PRIMARY = 1 --Primary Dx
          ) [PRIMARY_COMPLAINT]
		*/
		, PRIMARY_COMPLAINT = (select top 1 ICD10_Code from CHART_DIAGNOSIS_CODE_ICD10 where 1 = 0)		-- added by dsexton to replace the subquery (see corresponding UPDATE statements below)


		/*
         ,(
          select top 1
                 SHORT_DESCRIPTION
          from
              ICD_10_CM cm
              ,CHART_DIAGNOSIS_CODE_ICD10 cdc
          where
              r.CHART_ID = cdc.CHART_ID and cm.ICD_10_CODE = replace(cdc.ICD10_CODE , '.', '')
			  and cdc.DIAGNOSIS_TYPE_ID = 2 and cdc.IS_PRIMARY = 1 --Primary Dx
			  and getdate() between cm.EFFECTIVE_DATE and cm.EXPIRATION_DATE
          ) [PRIMARY_COMPLAINT_DESC]
		*/ 
		, PRIMARY_COMPLAINT_DESC = (select top 1 Short_Description from ICD_10_CM where 1 = 0)		-- added by dsexton to replace the subquery (see corresponding UPDATE statements below)


		/*
         ,(
          select top 1
                 cdc.ICD10_CODE
          from
              CHART_DIAGNOSIS_CODE_ICD10 cdc
          where
              r.CHART_ID = cdc.CHART_ID and cdc.DIAGNOSIS_TYPE_ID = 3 and cdc.IS_PRIMARY = 1 --Chief Complaint and Primary Dx
          ) [Chief_Complaint_and_Primary_Dx]
		*/
		, Chief_Complaint_and_Primary_Dx = (select top 1 ICD10_Code from CHART_DIAGNOSIS_CODE_ICD10 where 1 = 0)	-- added by dsexton to replace the subquery (see corresponding UPDATE statements below)


		/*
         ,(
          select top 1
                 SHORT_DESCRIPTION
          from
              ICD_10_CM cm
              ,CHART_DIAGNOSIS_CODE_ICD10 cdc
          where
              r.CHART_ID = cdc.CHART_ID and cm.ICD_10_CODE = replace(cdc.ICD10_CODE , '.', '')
			  and cdc.DIAGNOSIS_TYPE_ID = 3 and cdc.IS_PRIMARY = 1 --Chief Complaint and Primary Dx
			  and getdate() between cm.EFFECTIVE_DATE and cm.EXPIRATION_DATE
          ) [Chief_Complaint_and_Primary_Dx_Desc]
		*/
		, Chief_Complaint_and_Primary_Dx_Desc = (select top 1 Short_Description from ICD_10_CM where 1 = 0)		-- added by dsexton to replace the subquery (see corresponding UPDATE statements below)

into
    #RESULTS_2
from
    #RESULTS1 r
 where exists
         (
         select
             *
         from
             FACILITY_USER_AUTHORIZATION fua
         where
             fua.USER_PROFILE_ID = @m_ReportUser
			 and fua.FACILITY_ID = r.FACILITY_ID 
			 and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
			 
         ) 


-- six UPDATE statements below added by dsexton to replace the six subqueries above
update r
set r.Chief_Complaint = cdc.ICD10_CODE
from #Results_2 as r 
	join CHART_DIAGNOSIS_CODE_ICD10 as cdc
		on r.CHART_ID = cdc.CHART_ID and cdc.DIAGNOSIS_TYPE_ID = 1 and cdc.IS_PRIMARY = 1

update r
set r.Chief_Complaint_Desc = cm.Short_Description
from #Results_2 as r 
	join CHART_DIAGNOSIS_CODE_ICD10 as cdc
		on r.CHART_ID = cdc.CHART_ID 
		and cdc.DIAGNOSIS_TYPE_ID = 1 and cdc.IS_PRIMARY = 1
	join ICD_10_CM as cm
		on cm.ICD_10_CODE = replace(cdc.ICD10_CODE , '.', '')
		and getdate() between cm.EFFECTIVE_DATE and cm.EXPIRATION_DATE

update r
set r.Primary_Complaint = cdc.ICD10_CODE
from #Results_2 as r 
	join CHART_DIAGNOSIS_CODE_ICD10 as cdc
		on r.CHART_ID = cdc.CHART_ID and cdc.DIAGNOSIS_TYPE_ID = 2 and cdc.IS_PRIMARY = 1

update r
set r.Primary_Complaint_Desc = cm.Short_Description
from #Results_2 as r 
	join CHART_DIAGNOSIS_CODE_ICD10 as cdc
		on r.CHART_ID = cdc.CHART_ID 
		and cdc.DIAGNOSIS_TYPE_ID = 2 and cdc.IS_PRIMARY = 1
	join ICD_10_CM as cm
		on cm.ICD_10_CODE = replace(cdc.ICD10_CODE , '.', '')
		and getdate() between cm.EFFECTIVE_DATE and cm.EXPIRATION_DATE

update r
set r.Chief_Complaint_and_Primary_Dx = cdc.ICD10_CODE
from #Results_2 as r 
	join CHART_DIAGNOSIS_CODE_ICD10 as cdc
		on r.CHART_ID = cdc.CHART_ID and cdc.DIAGNOSIS_TYPE_ID = 3 and cdc.IS_PRIMARY = 1

update r
set r.Chief_Complaint_and_Primary_Dx_Desc = cm.Short_Description
from #Results_2 as r 
	join CHART_DIAGNOSIS_CODE_ICD10 as cdc
		on r.CHART_ID = cdc.CHART_ID 
		and cdc.DIAGNOSIS_TYPE_ID = 3 and cdc.IS_PRIMARY = 1
	join ICD_10_CM as cm
		on cm.ICD_10_CODE = replace(cdc.ICD10_CODE , '.', '')
		and getdate() between cm.EFFECTIVE_DATE and cm.EXPIRATION_DATE


print 'Section: 05 ' + convert(varchar, getdate(), 121)
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Update results temp table to prevent Clients from seeing other Coder Names.




update
    #RESULTS_2
set
    CODED_BY = null
    ,Auditor = null
    ,Second_Auditor = null
from
    #RESULTS_2 r
    inner join USER_PROFILE up on r.CODER_ID = up.USER_PROFILE_ID
where
    up.USER_CLASS_CD != 4 and exists
    (
    select
        *
    from
        USER_PROFILE
    where
        USER_PROFILE_ID = @m_ReportUser and IS_ACTIVE = 'Y' and USER_CLASS_CD = 4
    );


print 'Section: 06 ' + convert(varchar, getdate(), 121)

----------------------------------------------------------------------------------------------------



if @m_DispositionType = 1
    begin

        select distinct
               ir.[NAME]
               ,ir.ACCOUNT
               ,ir.DOS
			   ,ir.TIME_OF_DIS
               ,ir.CODED_BY
               ,case when ir.Audited = 1 then ir.Auditor else null end as APPROVED_BY
               ,case when ir.Second_Audit = 1 then ir.Second_Auditor else null end as APPROVED_BY_SECOND
               ,max(ir.CODER_FACILITY_CPT) as CODER_FACILITY_CPT
               ,max(ir.AUDITOR_FACILITY_CPT) as AUDITOR_FACILITY_CPT
               ,max(ir.CODER_PROFEE_CPT) as CODER_PROFEE_CPT
               ,max(ir.AUDITOR_PROFEE_CPT) as AUDITOR_PROFEE_CPT
               ,ir.PHYSICIAN_NAME
               ,ir.FACILITY_CRITICAL_CARE_MINUTES
               ,ir.PHYSICIAN_CRITICAL_CARE_MINUTES
               ,pd.[DESCRIPTION] [PATIENT_DISPOSITION]
               ,ir.CHIEF_COMPLAINT
               ,ir.CHIEF_COMPLAINT_DESC
               ,ir.PRIMARY_COMPLAINT
               ,ir.PRIMARY_COMPLAINT_DESC
               ,ir.Chief_Complaint_and_Primary_Dx
               ,ir.Chief_Complaint_and_Primary_Dx_Desc

-- for validation
--into ##Tuned		-- added by dsexton  (compare to ##Original with validation query)

        from
            #RESULTS_2 ir
            left join PATIENT_DISPOSITION pd with (nolock) on pd.PATIENT_DISPOSITION_ID = ir.PATIENT_DISPOSITION_ID
        where
            (
            pd.PATIENT_DISPOSITION_ID in (SELECT * FROM SPLITSTRING(@m_Disposition, ',')) 
			or -99 in (SELECT * FROM SPLITSTRING(@m_Disposition, ',')) 
            )
        group by
            ir.[NAME]
            ,ir.ACCOUNT
            ,ir.DOS
			,ir.TIME_OF_DIS
            ,ir.CODED_BY
            ,case when ir.Audited = 1 then ir.Auditor else null end
            ,case when ir.Second_Audit = 1 then ir.Second_Auditor else null end
            ,ir.PHYSICIAN_NAME
            ,ir.FACILITY_CRITICAL_CARE_MINUTES
            ,ir.PHYSICIAN_CRITICAL_CARE_MINUTES
            ,pd.[DESCRIPTION]
            ,ir.CHIEF_COMPLAINT
            ,ir.CHIEF_COMPLAINT_DESC
            ,ir.PRIMARY_COMPLAINT
            ,ir.PRIMARY_COMPLAINT_DESC
            ,ir.Chief_Complaint_and_Primary_Dx
            ,ir.Chief_Complaint_and_Primary_Dx_Desc
			;


    end;
else if @m_DispositionType = 2
         begin


             if object_id('TempDB..#disposition', 'U') is not null
                 drop table #disposition;


             select
                 PATIENT_DISPOSITION_MAP_ID
             into
                 #disposition
             from
                 PATIENT_DISPOSITION_MAP pdm
             where
                 SERVICE_AGREEMENT_ID in
                     (
                     select
                         SERVICE_AGREEMENT_ID
                     from
                         SERVICE_AGREEMENT
                     where
                         FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_Facility, ','))
                     ) and FACILITY_PATIENT_DISPOSITION in
                               (
                               select
                                   FACILITY_PATIENT_DISPOSITION
                               from
                                   PATIENT_DISPOSITION_MAP
                               where
                                   PATIENT_DISPOSITION_MAP_ID in (SELECT * FROM SPLITSTRING(@m_Disposition, ','))
                               );





             select distinct
                    ir.[NAME]
                    ,ir.ACCOUNT
                    ,ir.DOS
					,ir.TIME_OF_DIS
                    ,ir.CODED_BY
                    ,case when ir.Audited = 1 then ir.Auditor else null end as APPROVED_BY
                    ,case when ir.Second_Audit = 1 then ir.Second_Auditor else null end as APPROVED_BY_SECOND
                    ,max(ir.CODER_FACILITY_CPT) as CODER_FACILITY_CPT
                    ,max(ir.AUDITOR_FACILITY_CPT) as AUDITOR_FACILITY_CPT
                    ,max(ir.CODER_PROFEE_CPT) as CODER_PROFEE_CPT
                    ,max(ir.AUDITOR_PROFEE_CPT) as AUDITOR_PROFEE_CPT
                    ,ir.PHYSICIAN_NAME
                    ,ir.FACILITY_CRITICAL_CARE_MINUTES
                    ,ir.PHYSICIAN_CRITICAL_CARE_MINUTES
                    ,cast(pdm.FACILITY_PATIENT_DISPOSITION as varchar) + ' - ' + pdm.DESCRIPTION as [PATIENT_DISPOSITION]
                    ,ir.CHIEF_COMPLAINT
                    ,ir.CHIEF_COMPLAINT_DESC
                    ,ir.PRIMARY_COMPLAINT
                    ,ir.PRIMARY_COMPLAINT_DESC
                    ,ir.Chief_Complaint_and_Primary_Dx
                    ,ir.Chief_Complaint_and_Primary_Dx_Desc
             from
                 #RESULTS_2 ir
                 left join PATIENT_DISPOSITION_MAP pdm with (nolock) on pdm.PATIENT_DISPOSITION_MAP_ID = ir.PATIENT_DISPOSITION_MAP_ID
             where
                 (
                 pdm.PATIENT_DISPOSITION_MAP_ID in
                     (
                     select PATIENT_DISPOSITION_MAP_ID from #disposition
                     ) or -99 in (SELECT * FROM SPLITSTRING(@m_Disposition, ','))
                 )
             group by
                 ir.[NAME]
                 ,ir.ACCOUNT
                 ,ir.DOS
				 ,ir.TIME_OF_DIS
                 ,ir.CODED_BY
                 ,case when ir.Audited = 1 then ir.Auditor else null end
                 ,case when ir.Second_Audit = 1 then ir.Second_Auditor else null end
                 ,ir.PHYSICIAN_NAME
                 ,ir.FACILITY_CRITICAL_CARE_MINUTES
                 ,ir.PHYSICIAN_CRITICAL_CARE_MINUTES
                 ,cast(pdm.FACILITY_PATIENT_DISPOSITION as varchar) + ' - ' + pdm.DESCRIPTION
                 ,ir.CHIEF_COMPLAINT
                 ,ir.CHIEF_COMPLAINT_DESC
                 ,ir.PRIMARY_COMPLAINT
                 ,ir.PRIMARY_COMPLAINT_DESC
                 ,ir.Chief_Complaint_and_Primary_Dx
                 ,ir.Chief_Complaint_and_Primary_Dx_Desc;

         end;




print 'Section: 07 ' + convert(varchar, getdate(), 121)
----------------------------------------------------------------------------------------------------

END





GO
GRANT EXECUTE ON  [dbo].[rpt_AccountsByFacilityAndServiceLevel] TO [dbx_ExecuteReportProcs]
GO
