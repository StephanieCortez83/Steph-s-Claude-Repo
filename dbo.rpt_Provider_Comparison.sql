SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Don Hutton
-- Create date: 10/19/2018
-- Description:	Stored procedure for Provider Comparison report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_Provider_Comparison] 
    @ReportUser INT,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@Facility VARCHAR(MAX),
	@Class VARCHAR(5),
	@PatientClass VARCHAR(50) ,
	@P_NP VARCHAR(5),				   -- Physician / Nurse Practitioner Parameter 
	@Provider VARCHAR(MAX),
	@GroupBy INT,              -- 1 Company, 2 Facility, 3 Provider
	@Provider_Comparison INT,  -- 0 No, 1 Yes
	@Provider_2 INT,
	@CHART INT,
	@Level VARCHAR(30)



	
	
AS
BEGIN



-- test parameters
--declare
--     @ReportUser           int          = 80
--    ,@StartDate           datetime     = '04/01/2023 00:00:00'
--    ,@EndDate             datetime     = '04/30/2023 00:00:00'
----    ,@Organization        int          = 80
--    ,@Facility            int          = 1372
--    ,@Class               int          = 1  -- 1/FL, 2/PL
--    ,@PatientClass        int          = 3
--    ,@P_NP                int          = 2  -- 1 NP/PA, 2 Physician
--    ,@Provider            int = 1967094 --'1561653,966685,1175131,966686,966601,966600'  --1561653
--    ,@GroupBy             int          = 2
--    ,@Provider_Comparison int          = 0
--    ,@Provider_2          int          = -1  --1175131
--    ,@CHART               int          = 0
----    ,@Level 



	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	set transaction isolation level read uncommitted	
	SET NOCOUNT ON;

	DECLARE @m_ReportUser INT = @ReportUser;
	DECLARE @m_StartDate DATETIME = @StartDate; 
	DECLARE @m_EndDate DATETIME = @EndDate;
	DECLARE @m_Facility VARCHAR(MAX) = @Facility;
	DECLARE @m_Class VARCHAR(5) = @Class;
	DECLARE @m_PatientClass VARCHAR(50) = @PatientClass;
	DECLARE @m_P_NP VARCHAR(5) = @P_NP; 
	DECLARE @m_Provider VARCHAR(MAX) = @Provider;
	DECLARE @m_GroupBy INT = @GroupBy;
	DECLARE @m_Provider_Comparison INT = @Provider_Comparison;
	DECLARE @m_Provider_2 INT = @Provider_2;
	DECLARE @m_CHART INT = @CHART;
	DECLARE @m_Level VARCHAR(30) = @Level;



  ----------------------------------------------------------------------------------------------------

-- wRVU
--declare @Today datetime = dateadd(day, datediff(day, 0, getdate()), 0);
--declare @EM_MLP int = 0;

--declare @rvuProvider varchar(max) = convert(varchar(max),@Provider) + case when @Provider_2 = -1 then '' else ',' + convert(varchar(150),@Provider_2) end;
--select @Provider, @Provider_2, @rvuProvider


----------------------------------------------------------------------------------------------------

if object_id('TempDB..#Provider1', 'U') is not null
    begin
        drop table #Provider1;
    end;
if object_id('TempDB..#Provider2', 'U') is not null
    begin
        drop table #Provider2;
    end;
if object_id('TempDB..#Data1', 'U') is not null
    begin
        drop table #Data1;
    end;
if object_id('TempDB..#Data2', 'U') is not null
    begin
        drop table #Data2;
    end;
if object_id('TempDB..#Data3', 'U') is not null
    begin
        drop table #Data3;
    end;
if object_id('TempDB..#ProviderComparisonResults1', 'U') is not null
    begin
        drop table #ProviderComparisonResults1;
    end;

if object_id('TempDB..#PrelimResults2', 'U') is not null
    begin
        drop table #PrelimResults2;
    end;

if object_id('TempDB..#Class', 'U') is not null
    begin
        drop table #Class;
    end;

if object_id('TempDB..#Max_Class1', 'U') is not null
    begin
        drop table #Max_Class1;
    end;
if object_id('TempDB..#Max_Class2', 'U') is not null
    begin
        drop table #Max_Class2;
    end;

-- wRVU
/*
if object_id('TempDB..#Charts', 'U') is not null
    begin
		drop table #Charts
	end;
if object_id('TempDB..#WORK_RVU', 'U') is not null
    begin
		drop table #WORK_RVU
	end;
*/

----------------------------------------------------------------------------------------------------

select
    *
into
    #Class
from
    (
    select
        PATIENT_CLASS_ID
    from
        [dbo].[PATIENT_CLASS] pc with (nolock)
        inner join [dbo].[SERVICE_AGREEMENT] sa with (nolock) on sa.SERVICE_AGREEMENT_ID = pc.SERVICE_AGREEMENT_ID
    where
        sa.FACILITY_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
		and pc.PHYSICIAN_SERVICE_CLASS_CD IN (SELECT items FROM dbo.SplitString(@m_PatientClass, ',') )		 
    ) T1;

create nonclustered index idx_PATIENT_CLASS_ID on #Class (PATIENT_CLASS_ID);


select
    *
into
    #Provider1
from
    (
    select distinct
           FACILITY_PROF_ID, ROLE_ID 
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
                FACILITY_PROF_ID IN (SELECT items FROM dbo.SplitString(@m_Provider, ',') )  
            ) T1 on T1.LAST_NAME = FP.LAST_NAME and T1.FIRST_NAME = FP.FIRST_NAME
    where
        FACILITY_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
		and FP.role_id IN (SELECT items FROM dbo.SplitString(@m_P_NP, ',') )
    ) T1;

create nonclustered index idx_FACILITY_PROF_ID on #Provider1 (FACILITY_PROF_ID);

select
    *
into
    #Provider2
from
    (
    select distinct
           FACILITY_PROF_ID, ROLE_ID 
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
                FACILITY_PROF_ID = @m_Provider_2
            ) T1 on T1.LAST_NAME = FP.LAST_NAME and T1.FIRST_NAME = FP.FIRST_NAME
    where
        FACILITY_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
		and FP.role_id IN (SELECT items FROM dbo.SplitString(@m_P_NP, ',') )
    ) T2;

create nonclustered index idx_FACILITY_PROF_ID on #Provider2 (FACILITY_PROF_ID);

select
    *
into
    #Data1
from
    (
    select
        y.SERVICE_AGREEMENT_ID
        ,y.physician_id
        ,y.PATIENT_CLASS_ID
        ,y.CLASS Class
        ,y.Provider_IND
        ,y.TotLOS TotLOS
        ,y.TotLOS1 TotLOS1
        ,y.TotLOS2 TotLOS2
        ,y.TotLOS3 TotLOS3
        ,y.TotLOS4 TotLOS4
        ,y.TotLOS5 TotLOS5
        ,y.TotLOS6 TotLOS6
        ,y.TotLOS7 TotLOS7
        ,y.TotLOS8 TotLOS8
    from
        (
        select
            a.SERVICE_AGREEMENT_ID
            ,a.physician_id 
            ,a.PATIENT_CLASS_ID
            ,a.CLASS Class
            ,a.Provider_IND
            ,sum(a.TOTLOS) TotLOS
            ,sum(a.TotLOS1) TotLOS1
            ,sum(a.TotLOS2) TotLOS2
            ,sum(a.TotLOS3) TotLOS3
            ,sum(a.TotLOS4) TotLOS4
            ,sum(a.TotLOS5) TotLOS5
            ,sum(a.TotLOS6) TotLOS6
            ,sum(a.TotLOS7) TotLOS7
            ,sum(a.TotLOS8) TotLOS8
        from
            (
            select  -- Demographics page ED Attending Provider
                sp.SERVICE_AGREEMENT_ID
                ,case
                     when c.PHYSICIAN_ID = 0 then c.NURSE_PRACTITIONER_ID
                     when c.PHYSICIAN_ID = -1 then c.NURSE_PRACTITIONER_ID
                     when c.PHYSICIAN_ID = null then c.NURSE_PRACTITIONER_ID
                     else c.PHYSICIAN_ID end as physician_id
                
                ,sp.PATIENT_CLASS_ID
                ,sp.CLASS Class
                ,case
                     when fl.REPORTING_COLUMN = 1 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS1
                ,case
                     when fl.REPORTING_COLUMN = 2 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS2
                ,case
                     when fl.REPORTING_COLUMN = 3 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS3
                ,case
                     when fl.REPORTING_COLUMN = 4 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS4
                ,case
                     when fl.REPORTING_COLUMN = 5 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS5
                ,case
                     when fl.REPORTING_COLUMN = 6 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS6
                ,case
                     when fl.REPORTING_COLUMN = 7 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS7
                ,case
                     when fl.REPORTING_COLUMN = 8 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS8
                ,case when sp.QUANTITY > 0 then sp.QUANTITY else 0 end TOTLOS
                ,0 as Provider_IND
            from
                SENT_PROCEDURE sp with (nolock)
                ,PATIENT_DISPOSITION pd with (nolock)
                ,FACILITY_LEVEL fl with (nolock)
                ,CHART c with (nolock)
            where
                sp.CLASS = 'FL' 
				and 1 IN (SELECT items FROM dbo.SplitString(@m_Class, ',') )
				and c.CHART_ID = sp.CHART_ID
                and pd.PATIENT_DISPOSITION_ID = sp.PATIENT_DISPOSITION_ID 
				and fl.FACILITY_LEVEL_ID = sp.LEVEL_ID
                and cast(sp.TIME_OF_SERVICE as date) between @m_StartDate and @m_EndDate 
				and sp.FACILITY_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
                and sp.PATIENT_CLASS_ID in ( select PATIENT_CLASS_ID from #Class )
				and exists (
					select
		            FACILITY_PROF_ID
			        from
					#Provider1
					where
					(c.PHYSICIAN_ID = FACILITY_PROF_ID
					or
					c.NURSE_PRACTITIONER_ID = FACILITY_PROF_ID)
					and ROLE_ID = 2
					)

            union all
			
			
			select    -- Demographics page NURSE PRACTITIONER/PA
                sp.SERVICE_AGREEMENT_ID
                ,case
                     when c.NURSE_PRACTITIONER_ID = 0 then sp.PHYSICIAN_ID
                     when c.NURSE_PRACTITIONER_ID = -1 then sp.PHYSICIAN_ID
                     else c.NURSE_PRACTITIONER_ID end as physician_id
                ,sp.PATIENT_CLASS_ID
                ,sp.CLASS Class
                ,case
                     when fl.REPORTING_COLUMN = 1 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS1
                ,case
                     when fl.REPORTING_COLUMN = 2 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS2
                ,case
                     when fl.REPORTING_COLUMN = 3 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS3
                ,case
                     when fl.REPORTING_COLUMN = 4 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS4
                ,case
                     when fl.REPORTING_COLUMN = 5 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS5
                ,case
                     when fl.REPORTING_COLUMN = 6 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS6
                ,case
                     when fl.REPORTING_COLUMN = 7 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS7
                ,case
                     when fl.REPORTING_COLUMN = 8 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS8
                ,case when sp.QUANTITY > 0 then sp.QUANTITY else 0 end TOTLOS
                ,0 as Provider_IND
            from
                SENT_PROCEDURE sp with (nolock)
                ,PATIENT_DISPOSITION pd with (nolock)
                ,FACILITY_LEVEL fl with (nolock)
                ,CHART c with (nolock)
            where
                sp.CLASS = 'FL' 
				and 1 IN (SELECT items FROM dbo.SplitString(@m_Class, ',') )
				and c.CHART_ID = sp.CHART_ID
                and pd.PATIENT_DISPOSITION_ID = sp.PATIENT_DISPOSITION_ID 
				and fl.FACILITY_LEVEL_ID = sp.LEVEL_ID
                and cast(sp.TIME_OF_SERVICE as date) between @m_StartDate and @m_EndDate 
				and sp.FACILITY_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
                and sp.PATIENT_CLASS_ID in ( select PATIENT_CLASS_ID from #Class)
				and exists (
					select
					FACILITY_PROF_ID
					from
					#Provider1
					where
					(c.PHYSICIAN_ID = FACILITY_PROF_ID
					or
					c.NURSE_PRACTITIONER_ID = FACILITY_PROF_ID)
					and ROLE_ID = 1
					)

            union all
			
			
			 --  PL Records ***


            select  --  Performing Provider listed on Physician Evaluation and Management page ****
                sp.SERVICE_AGREEMENT_ID
               
                ,case
                     when c.NURSE_PRACTITIONER_ID > 0
                          and
                              (
                              c.PROVIDER_EVAL_PERFORMED_BY_IND is null or c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                              ) then c.NURSE_PRACTITIONER_ID
                     else c.PHYSICIAN_ID end as physician_id
               
                ,sp.PATIENT_CLASS_ID
                ,sp.CLASS Class
                ,case
                     when PL.REPORTING_COLUMN = 1 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS1
                ,case
                     when PL.REPORTING_COLUMN = 2 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS2
                ,case
                     when PL.REPORTING_COLUMN = 3 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS3
                ,case
                     when PL.REPORTING_COLUMN = 4 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS4
                ,case
                     when PL.REPORTING_COLUMN = 5 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS5
                ,case
                     when PL.REPORTING_COLUMN = 6 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS6
                ,case
                     when PL.REPORTING_COLUMN = 7 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS7
                ,case
                     when PL.REPORTING_COLUMN = 8 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS8
                ,case when sp.QUANTITY > 0 then sp.QUANTITY else 0 end TOTLOS
                ,0 as Provider_IND
            from
                SENT_PROCEDURE sp with (nolock)
                ,PATIENT_DISPOSITION pd with (nolock)
                ,PHYSICIAN_SERVICE_PROCEDURE PL with (nolock)
                ,CHART c with (nolock)
            where
                sp.CLASS = 'PL' 
				and 2 IN (SELECT items FROM dbo.SplitString(@m_Class, ',') )
				and c.CHART_ID = sp.CHART_ID
                and pd.PATIENT_DISPOSITION_ID = sp.PATIENT_DISPOSITION_ID
                and PL.PHYSICIAN_SERVICE_PROC_ID = sp.LEVEL_ID
                and cast(sp.TIME_OF_SERVICE as date) between @m_StartDate and @m_EndDate 
				and sp.FACILITY_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
                and sp.PATIENT_CLASS_ID in (select PATIENT_CLASS_ID from #Class )

            ) a
        group by
            a.SERVICE_AGREEMENT_ID
            ,a.physician_id
            ,a.PATIENT_CLASS_ID
            ,a.CLASS
            ,a.Provider_IND
        ) y
    where
        exists
        (
        select
            FACILITY_PROF_ID
        from
            #Provider1
        where
            y.physician_id = FACILITY_PROF_ID
        )
    ) D1;


-- ***************************************************************************

-- determines max class if both Facility and Pro-Fee are selected by report user.



select
    *
into
    #Max_Class1
from
    (
    select
        x.SERVICE_AGREEMENT_ID
        ,x.Class
        ,rank() over (partition by
                          x.SERVICE_AGREEMENT_ID
                      order by
                          x.Tot desc
                          ,x.Class desc
                     ) as Rank
    from
        (
        select
            D1.SERVICE_AGREEMENT_ID
            ,D1.Class
            ,sum(D1.TotLOS3 + D1.TotLOS4 + D1.TotLOS5 + D1.TotLOS6 + D1.TotLOS7 + D1.TotLOS8) as Tot
        from
            #Data1 D1
        group by
            D1.SERVICE_AGREEMENT_ID
            ,D1.Class
        ) x
    ) tmp
where
    Rank = 1;




select
    *
into
    #Data2
from
    (
    select
        D1.*
    from
        #Data1 D1
        ,#Max_Class1 mc
    where
        D1.SERVICE_AGREEMENT_ID = mc.SERVICE_AGREEMENT_ID and D1.class = mc.Class
    ) y;

-- ***************************************************************************
-- Comparison Dataset


select
    *
into
    #Data3
from
    (
    select
        max(SERVICE_AGREEMENT_ID) as SERVICE_AGREEMENT_ID
        ,max(z.physician_id) as physician_id
        ,max(PATIENT_CLASS_ID) as patient_class_id
        ,z.CLASS Class
        ,z.Provider_IND
        ,sum(z.TotLOS) TotLOS
        ,sum(z.TotLOS1) TotLOS1
        ,sum(z.TotLOS2) TotLOS2
        ,sum(z.TotLOS3) TotLOS3
        ,sum(z.TotLOS4) TotLOS4
        ,sum(z.TotLOS5) TotLOS5
        ,sum(z.TotLOS6) TotLOS6
        ,sum(z.TotLOS7) TotLOS7
        ,sum(z.TotLOS8) TotLOS8
    from
        (
        select
            b.SERVICE_AGREEMENT_ID
            ,b.physician_id 
            ,b.PATIENT_CLASS_ID
            ,b.CLASS Class
            ,b.Provider_IND
            ,sum(b.TOTLOS) TotLOS
            ,sum(b.TotLOS1) TotLOS1
            ,sum(b.TotLOS2) TotLOS2
            ,sum(b.TotLOS3) TotLOS3
            ,sum(b.TotLOS4) TotLOS4
            ,sum(b.TotLOS5) TotLOS5
            ,sum(b.TotLOS6) TotLOS6
            ,sum(b.TotLOS7) TotLOS7
            ,sum(b.TotLOS8) TotLOS8
        from
            (       -- FL Records
            select  -- Demographics page ED Attending Provider
                sp.SERVICE_AGREEMENT_ID
                ,case
                     when c.PHYSICIAN_ID = 0 then c.NURSE_PRACTITIONER_ID
                     when c.PHYSICIAN_ID = -1 then c.NURSE_PRACTITIONER_ID
                     when c.PHYSICIAN_ID = null then c.NURSE_PRACTITIONER_ID
                     else c.PHYSICIAN_ID end as physician_id
                
                ,sp.PATIENT_CLASS_ID
                ,sp.CLASS Class
                ,case
                     when fl.REPORTING_COLUMN = 1 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS1
                ,case
                     when fl.REPORTING_COLUMN = 2 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS2
                ,case
                     when fl.REPORTING_COLUMN = 3 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS3
                ,case
                     when fl.REPORTING_COLUMN = 4 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS4
                ,case
                     when fl.REPORTING_COLUMN = 5 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS5
                ,case
                     when fl.REPORTING_COLUMN = 6 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS6
                ,case
                     when fl.REPORTING_COLUMN = 7 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS7
                ,case
                     when fl.REPORTING_COLUMN = 8 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS8
                ,case when sp.QUANTITY > 0 then sp.QUANTITY else 0 end TOTLOS
                ,1 as Provider_IND
            from
                SENT_PROCEDURE sp with (nolock)
                ,PATIENT_DISPOSITION pd with (nolock)
                ,FACILITY_LEVEL fl (nolock)
                ,CHART c with (nolock)
            where
                sp.CLASS = 'FL' 
				and 1 IN (SELECT items FROM dbo.SplitString(@m_Class, ',') )
				and c.CHART_ID = sp.CHART_ID
                and pd.PATIENT_DISPOSITION_ID = sp.PATIENT_DISPOSITION_ID 
				and fl.FACILITY_LEVEL_ID = sp.LEVEL_ID
                and cast(sp.TIME_OF_SERVICE as date) between @m_StartDate and @m_EndDate 
				and sp.FACILITY_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
                and sp.PATIENT_CLASS_ID in ( select PATIENT_CLASS_ID from #Class ) 
				and 1 = @m_Provider_Comparison
				and exists (
					select
					FACILITY_PROF_ID
					from
					#Provider2
					where
					(c.PHYSICIAN_ID = FACILITY_PROF_ID
					or
					c.NURSE_PRACTITIONER_ID = FACILITY_PROF_ID)
					and ROLE_ID = 2
					)

            union all

			        -- FL Records
			select  -- Demographics page NURSE PRACTITIONER/PA
                sp.SERVICE_AGREEMENT_ID                
                ,case
                     when c.NURSE_PRACTITIONER_ID = 0 then sp.PHYSICIAN_ID
                     when c.NURSE_PRACTITIONER_ID = -1 then sp.PHYSICIAN_ID
                     else c.NURSE_PRACTITIONER_ID end as physician_id
                ,sp.PATIENT_CLASS_ID
                ,sp.CLASS Class
                ,case
                     when fl.REPORTING_COLUMN = 1 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS1
                ,case
                     when fl.REPORTING_COLUMN = 2 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS2
                ,case
                     when fl.REPORTING_COLUMN = 3 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS3
                ,case
                     when fl.REPORTING_COLUMN = 4 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS4
                ,case
                     when fl.REPORTING_COLUMN = 5 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS5
                ,case
                     when fl.REPORTING_COLUMN = 6 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS6
                ,case
                     when fl.REPORTING_COLUMN = 7 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS7
                ,case
                     when fl.REPORTING_COLUMN = 8 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS8
                ,case when sp.QUANTITY > 0 then sp.QUANTITY else 0 end TOTLOS
                ,1 as Provider_IND
            from
                SENT_PROCEDURE sp with (nolock)
                ,PATIENT_DISPOSITION pd with (nolock)
                ,FACILITY_LEVEL fl (nolock)
                ,CHART c with (nolock)
            where
                sp.CLASS = 'FL' 
				and 1 IN (SELECT items FROM dbo.SplitString(@m_Class, ',') )
				and c.CHART_ID = sp.CHART_ID
                and pd.PATIENT_DISPOSITION_ID = sp.PATIENT_DISPOSITION_ID 
				and fl.FACILITY_LEVEL_ID = sp.LEVEL_ID
                and cast(sp.TIME_OF_SERVICE as date) between @m_StartDate and @m_EndDate 
				and sp.FACILITY_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
                and sp.PATIENT_CLASS_ID in ( select PATIENT_CLASS_ID from #Class ) 
				and 1 = @m_Provider_Comparison
				and exists (
					select
					FACILITY_PROF_ID
					from
					#Provider2
					where
					(c.PHYSICIAN_ID = FACILITY_PROF_ID
					or
					c.NURSE_PRACTITIONER_ID = FACILITY_PROF_ID)
					and ROLE_ID = 1
					)
            

            union all

			        -- PL Records ***
            select  --  Performing Provider listed on Physician Evaluation and Management page ****
                sp.SERVICE_AGREEMENT_ID                
                ,case
                     when c.NURSE_PRACTITIONER_ID > 0
                          and
                              (
                              c.PROVIDER_EVAL_PERFORMED_BY_IND is null or c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                              ) then c.NURSE_PRACTITIONER_ID
                     else c.PHYSICIAN_ID end as physician_id                
                
                ,sp.PATIENT_CLASS_ID
                ,sp.CLASS Class
                ,case
                     when pl.REPORTING_COLUMN = 1 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS1
                ,case
                     when pl.REPORTING_COLUMN = 2 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS2
                ,case
                     when pl.REPORTING_COLUMN = 3 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS3
                ,case
                     when pl.REPORTING_COLUMN = 4 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS4
                ,case
                     when pl.REPORTING_COLUMN = 5 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS5
                ,case
                     when pl.REPORTING_COLUMN = 6 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS6
                ,case
                     when pl.REPORTING_COLUMN = 7 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS7
                ,case
                     when pl.REPORTING_COLUMN = 8 and sp.QUANTITY > 0 then sp.QUANTITY
                     else 0 end TotLOS8
                ,case when sp.QUANTITY > 0 then sp.QUANTITY else 0 end TOTLOS
                ,1 as Provider_IND
            from
                SENT_PROCEDURE sp with (nolock)
                ,PATIENT_DISPOSITION pd with (nolock)
                ,PHYSICIAN_SERVICE_PROCEDURE pl (nolock)
                ,CHART c with (nolock)
            where
                sp.CLASS = 'PL' 
				and 2 IN (SELECT items FROM dbo.SplitString(@m_Class, ',') )
				and c.CHART_ID = sp.CHART_ID
                and pd.PATIENT_DISPOSITION_ID = sp.PATIENT_DISPOSITION_ID
                and pl.PHYSICIAN_SERVICE_PROC_ID = sp.LEVEL_ID
                and cast(sp.TIME_OF_SERVICE as date) between @m_StartDate and @m_EndDate 
				and sp.FACILITY_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
                and sp.PATIENT_CLASS_ID in ( select PATIENT_CLASS_ID from #Class ) 
				and 1 = @m_Provider_Comparison     


            ) b
        group by
            b.SERVICE_AGREEMENT_ID
            ,b.physician_id
            ,b.PATIENT_CLASS_ID
            ,b.CLASS
            ,b.Provider_IND
        ) z
    where
        z.physician_id = @m_Provider_2
    group by
        z.CLASS
        ,z.Provider_IND
    ) T2;



-- ***********
--determines max class if both Facility and Pro-Fee are selected by report user for Comparison Dataset.

select
    *
into
    #Max_Class2
from
    (
    select
        x.SERVICE_AGREEMENT_ID
        ,x.Class
        ,rank() over (partition by
                          x.SERVICE_AGREEMENT_ID
                      order by
                          x.Tot desc
                          ,x.Class desc
                     ) as Rank
    from
        (
        select
            D1.SERVICE_AGREEMENT_ID
            ,D1.Class
            ,sum(D1.TotLOS3 + D1.TotLOS4 + D1.TotLOS5 + D1.TotLOS6 + D1.TotLOS7 + D1.TotLOS8) as Tot
        from
            #Data3 D1
        group by
            D1.SERVICE_AGREEMENT_ID
            ,D1.Class
        ) x
    ) tmp
where
    Rank = 1;



insert into #Data2
select
    D1.*
from
    #Data3 D1
    ,#Max_Class2 mc
where
    D1.SERVICE_AGREEMENT_ID = mc.SERVICE_AGREEMENT_ID and D1.class = mc.Class;



-- *******************





select
    *
into
    #ProviderComparisonResults1
from
    (
    select
        case
            when x.Provider_IND = 0 then co.NAME
            else upper(fp1.LAST_NAME + ', ' + fp1.FIRST_NAME)end as COMPANY
        ,case when x.Provider_IND = 0 then sa.COMPANY_ID else x.physician_id end as company_id
        ,case
             when x.Provider_IND = 0 then f.NAME + ' - ' + psc.DESCRIPTION
             else upper(fp1.LAST_NAME + ', ' + fp1.FIRST_NAME)end as Facility
        ,case when x.Provider_IND = 0 then f.FACILITY_ID else x.physician_id end as FACILITY_ID
        ,upper(fp1.LAST_NAME + ', ' + fp1.FIRST_NAME) as Provider
        ,x.physician_id
        ,x.PATIENT_CLASS_ID
        ,psc.DESCRIPTION patient_class
        ,x.Class
        ,x.TotLOS
        ,x.TotLOS1
        ,x.PctLOS1
        ,x.TotLOS2
        ,x.PctLOS2
        ,x.TotLOS3
        ,x.PctLOS3
        ,x.TotLOS4
        ,x.PctLOS4
        ,x.TotLOS5
        ,x.PctLOS5
        ,x.TotLOS6
        ,x.PctLOS6
        ,x.TotLOS7
        ,x.PctLOS7
        ,x.TotLOS8
        ,x.PctLOS8
    from
        FACILITY f with (nolock)
        ,SERVICE_AGREEMENT sa with (nolock)
        ,PATIENT_CLASS pc with (nolock)
        ,PHYSICIAN_SERVICE_CLASS psc with (nolock)
        ,COMPANY co with (nolock)
        ,(
         select
             los.SERVICE_AGREEMENT_ID
             ,los.physician_id
             ,case
                  when los.PATIENT_CLASS_ID = -1 then
                      (
                      select
                          max(pc2.PATIENT_CLASS_ID)
                      from
                          PATIENT_CLASS pc2 with (nolock)
                      where
                          pc2.SERVICE_AGREEMENT_ID = los.SERVICE_AGREEMENT_ID and pc2.DEFAULT_IND = 1
                      )
                  when los.PATIENT_CLASS_ID is null then
                      (
                      select
                          max(pc2.PATIENT_CLASS_ID)
                      from
                          PATIENT_CLASS pc2 with (nolock)
                      where
                          pc2.SERVICE_AGREEMENT_ID = los.SERVICE_AGREEMENT_ID and pc2.DEFAULT_IND = 1
                      )
                  else los.PATIENT_CLASS_ID end patient_class_id
             ,case
                  when los.class = 'FL' then 'Facility'
                  when los.class = 'PL' then 'Pro-Fee'
                  else 'Other' end as Class
             ,los.Provider_IND
             ,los.TotLOS
             ,los.TotLOS1
             ,case
                  when los.TotLOS <> 0 then round((convert(float, los.TotLOS1) / los.TotLOS), 4)
                  else 0 end as PctLOS1
             ,los.TotLOS2
             ,case
                  when los.TotLOS <> 0 then round((convert(float, los.TotLOS2) / los.TotLOS), 4)
                  else 0 end as PctLOS2
             ,los.TotLOS3
             ,case
                  when (los.TotLOS - los.TotLOS1 - los.TotLOS2) <> 0 then
                      round((convert(float, los.TotLOS3) / (los.TotLOS - los.TotLOS1 - los.TotLOS2)), 4)
                  else 0 end as PctLOS3
             ,los.TotLOS4
             ,case
                  when (los.TotLOS - los.TotLOS1 - los.TotLOS2) <> 0 then
                      round((convert(float, los.TotLOS4) / (los.TotLOS - los.TotLOS1 - los.TotLOS2)), 4)
                  else 0 end as PctLOS4
             ,los.TotLOS5
             ,case
                  when (los.TotLOS - los.TotLOS1 - los.TotLOS2) <> 0 then
                      round((convert(float, los.TotLOS5) / (los.TotLOS - los.TotLOS1 - los.TotLOS2)), 4)
                  else 0 end as PctLOS5
             ,los.TotLOS6
             ,case
                  when (los.TotLOS - los.TotLOS1 - los.TotLOS2) <> 0 then
                      round((convert(float, los.TotLOS6) / (los.TotLOS - los.TotLOS1 - los.TotLOS2)), 4)
                  else 0 end as PctLOS6
             ,los.TotLOS7
             ,case
                  when (los.TotLOS - los.TotLOS1 - los.TotLOS2) <> 0 then
                      round((convert(float, los.TotLOS7) / (los.TotLOS - los.TotLOS1 - los.TotLOS2)), 4)
                  else 0 end as PctLOS7
             ,los.TotLOS8
             ,case
                  when (los.TotLOS - los.TotLOS1 - los.TotLOS2) <> 0 then
                      round((convert(float, los.TotLOS8) / (los.TotLOS - los.TotLOS1 - los.TotLOS2)), 4)
                  else 0 end as PctLOS8
         from
             #Data2 los
         ) x
        left join FACILITY_PROFESSIONAL fp1 with (nolock) on fp1.FACILITY_PROF_ID = x.physician_id
    where
        sa.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID and f.FACILITY_ID = sa.FACILITY_ID
        and pc.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID and pc.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
        and psc.PHYSICIAN_SERVICE_CLASS_CD = pc.PHYSICIAN_SERVICE_CLASS_CD and sa.COMPANY_ID = co.COMPANY_ID
    ) T1;




select
    *, null as [wRVU]
into
    #PrelimResults2
from
    (
    select
        case
            when @m_GroupBy = 1 then P1.COMPANY
            when @m_GroupBy = 2 then P1.Facility
            when @m_GroupBy = 3 then P1.Provider end as NAME
        ,case
             when @m_GroupBy = 1 then P1.company_id
             when @m_GroupBy = 2 then P1.FACILITY_ID
             when @m_GroupBy = 3 then P1.physician_id end as ID_NUM
        ,Class
        ,sum(P1.TotLOS1) as TotLOS1
        ,sum(P1.TotLOS2) as TotLOS2
        ,sum(P1.TotLOS3) as TotLOS3
        ,sum(P1.TotLOS4) as TotLOS4
        ,sum(P1.TotLOS5) as TotLOS5
        ,sum(P1.TotLOS6) as TotLOS6
        ,sum(P1.TotLOS7) as TotLOS7
        ,sum(P1.TotLOS8) as TotLOS8
    from
        #ProviderComparisonResults1 P1 with (nolock)
    group by
        case
            when @m_GroupBy = 1 then P1.COMPANY
            when @m_GroupBy = 2 then P1.Facility
            when @m_GroupBy = 3 then P1.Provider end
        ,case
             when @m_GroupBy = 1 then P1.company_id
             when @m_GroupBy = 2 then P1.FACILITY_ID
             when @m_GroupBy = 3 then P1.physician_id end
        ,Class
    ) x;


----------------------------------------------------------------------------------------------------
-- wRVU

/*

select
    CHART_ID
    ,facility_ID 
    ,FACILITY_CHART_ID
    ,SERVICE_AGREEMENT_ID
    ,SENT_DATE
    ,TIME_OF_SERVICE
    ,NURSE_PRACTITIONER_ID
    ,PROVIDER_EVAL_PERFORMED_BY_IND
into
    #Charts
from
    CHART as c with (nolock)
where
    facility_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
	and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between @m_StartDate and @m_EndDate;

select
    sa.COMPANY_ID
	,c.facility_ID
    ,f.[NAME] Facility
    ,rtrim(coalesce(fp.LAST_NAME, '') + ', ' + coalesce(fp.FIRST_NAME, '') + ' ' + coalesce(fp.MIDDLE_NAME, '')) [Provider]
    ,fp.FACILITY_PROF_ID
    ,fpr.[DESCRIPTION] Provider_Role
    ,sum(round(sp.QUANTITY * isnull(cpr2.WORK_RVU, cpr.WORK_RVU), 2)) as WORK_RVU
into #WORK_RVU
from
    SENT_PROCEDURE sp with (nolock)
    left join CHARGE_MASTER cm with (nolock) on cm.CHARGE_MASTER_ID = sp.CHARGE_MASTER_ID
    left join CHARGE_MASTER_CHARGE_AMOUNT ca with (nolock) on ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
              and dateadd(day, datediff(day, 0, sp.TIME_OF_SERVICE), 0) 
			  between ca.EFFECTIVE_DATE and isnull(ca.EXPIRATION_DATE,'12/31/9999')
    left join PHYSICIAN_PROCEDURE_EVALUATION ppe with (nolock) on sp.CLASS = 'PP' and ppe.CHART_ID = sp.CHART_ID
                                                                  and ppe.PHYSICIAN_PROCEDURE_ID = cm.CHARGE_MASTER_ID
    left join CMS_PHYSICIAN_RVU cpr on cpr.HCPCS = sp.CPT_CODE
                                       and @Today between cpr.EFFECTIVE_DT and cpr.EXPIRATION_DT
                                       and nullif(cpr.[MOD], '') is null
    left join CMS_PHYSICIAN_RVU cpr2 on cpr2.HCPCS = sp.CPT_CODE
                                        and @Today between cpr2.EFFECTIVE_DT and cpr2.EXPIRATION_DT
                                        and ppe.MODIFIERS is not null and ppe.MODIFIERS like '%' + cpr2.[MOD] + '%'
    ,#Charts as c
    ,FACILITY_PROFESSIONAL fp with (nolock)
    ,FACILITY_PROFESSIONAL_ROLE fpr with (nolock)
    ,FACILITY f with (nolock)
    ,SERVICE_AGREEMENT sa with (nolock)
where
    sp.CHART_ID = c.CHART_ID and sp.CLASS in ('PL', 'PP') and fp.ROLE_ID = fpr.FACILITY_PROF_ROLE_ID
    and fp.FACILITY_PROF_ID = case sa.EVALUATE_PHYSICIAN_SVC
                                  when 1 then
                                      case
                                          when (
                                               sp.CLASS = 'PL' or sa.COLLECT_PROCEDURE_PHYSICIANS = 'N'
                                               ) and c.NURSE_PRACTITIONER_ID > 0
                                               and
                                                   (
                                                   c.PROVIDER_EVAL_PERFORMED_BY_IND is null
                                                   or c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                                                   ) then c.NURSE_PRACTITIONER_ID
                                          else sp.PHYSICIAN_ID end
                                  else
                                      case
                                          when sp.CLASS = 'PL' and c.NURSE_PRACTITIONER_ID > 0 and @EM_MLP = 1 then
                                              c.NURSE_PRACTITIONER_ID
                                          else sp.PHYSICIAN_ID end end and cpr.HCPCS = sp.CPT_CODE
    and f.FACILITY_ID IN (SELECT items FROM dbo.SplitString(@m_Facility, ',') )
	and sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    and f.FACILITY_ID = c.facility_ID
	and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between @m_StartDate and @m_EndDate
    and
        (case sa.EVALUATE_PHYSICIAN_SVC
                when 1 then
                    case
                        when (
                             sp.CLASS = 'PL' or sa.COLLECT_PROCEDURE_PHYSICIANS = 'N'
                             ) and c.NURSE_PRACTITIONER_ID > 0
                             and
                                 (
                                 c.PROVIDER_EVAL_PERFORMED_BY_IND is null or c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                                 ) then c.NURSE_PRACTITIONER_ID
                        else sp.PHYSICIAN_ID end
                else
                    case
                        when sp.CLASS = 'PL' and c.NURSE_PRACTITIONER_ID > 0 and @EM_MLP = 1 then
                            c.NURSE_PRACTITIONER_ID
                        else sp.PHYSICIAN_ID end end in (select FACILITY_PROF_ID from #Provider1 union select FACILITY_PROF_ID from #Provider2)
									--in (@rvuProvider)
									--in (select items from RevCycleDB.dbo.SplitString(@rvuProvider, ','))
           )
group by 
    sa.COMPANY_ID
	,c.facility_ID
    ,f.[NAME]
    ,rtrim(coalesce(fp.LAST_NAME, '') + ', ' + coalesce(fp.FIRST_NAME, '') + ' ' + coalesce(fp.MIDDLE_NAME, ''))
    ,fp.FACILITY_PROF_ID
    ,fpr.[DESCRIPTION];

*/

----------------------------------------------------------------------------------------------------
-- Update #PrelimResults2 temp table with wRVU value

--select * from #PrelimResults2
--select * from #WORK_RVU


-- Group by Org
/*
if @m_Provider_Comparison = 0 and @m_GroupBy = 1
begin

	update #PrelimResults2
	set wRVU = w.WORK_RVU
	from 
		#PrelimResults2 p
		left join (select w.COMPANY_ID, sum(w.WORK_RVU) [WORK_RVU] from #WORK_RVU w group by w.COMPANY_ID) w on p.ID_NUM = w.COMPANY_ID

end

-- Group by Facility
if @m_Provider_Comparison = 0 and @m_GroupBy = 2
begin

	update #PrelimResults2
	set wRVU = w.WORK_RVU
	from 
		#PrelimResults2 p
		left join (select w.facility_ID, sum(w.WORK_RVU) [WORK_RVU] from #WORK_RVU w group by w.facility_ID) w on p.ID_NUM = w.facility_ID

end

-- Provider
if @m_Provider_Comparison = 1
begin

	update #PrelimResults2
	set wRVU = w.WORK_RVU
	from 
		#PrelimResults2 p
		left join #WORK_RVU w on p.ID_NUM = w.FACILITY_PROF_ID

end

*/
--select * from #PrelimResults2

----------------------------------------------------------------------------------------------------

;with UNPIVOT1
as
(select
     ID_NUM
     ,NAME
     ,row_number() over (partition by NAME order by NAME) as COLUMN_ID
     ,ASMT.Score
 from
     #PrelimResults2
     unpivot
         (
         Score
         for Assignment in (TotLOS1, TotLOS2, TotLOS3, TotLOS4, TotLOS5, TotLOS6, TotLOS7, TotLOS8, wRVU)
         ) as ASMT)
,[PERCENTAGE]
as
(select
     u.ID_NUM
     ,u.[NAME]
     ,u.COLUMN_ID
     ,case when u.COLUMN_ID = 9 then 'wRVU' else lrc.SHORT_DESCRIPTION end [SHORT_DESCRIPTION]
     ,Score
     ,(   (
          select
              case
                  when sum(Score) > 0 then cast(round(u.Score * 1.0 / sum(Score), 3) as float)
                  else 0 end
          from
              UNPIVOT1
          where
              [NAME] = u.[NAME] and COLUMN_ID between 3 and 9
              and COLUMN_ID IN (SELECT items FROM dbo.SplitString(@m_Level, ',') ) 
				
          )
      ) SCORE_PERCENTAGE
 from
     UNPIVOT1 u
     left join LOS_REPORT_COLUMN lrc on u.COLUMN_ID = lrc.COLUMN_ID and lrc.SERVICE_TYPE = 'FL'
 where
     u.COLUMN_ID between 3 and 9
     and u.COLUMN_ID IN (SELECT items FROM dbo.SplitString(@m_Level, ',') ) 
				
     )

select
    ID_NUM
    ,[NAME]
    ,COLUMN_ID
    ,SHORT_DESCRIPTION
    ,SCORE
    ,SCORE_PERCENTAGE
from
    [PERCENTAGE]
order by
    [NAME];






END














GO
GRANT EXECUTE ON  [dbo].[rpt_Provider_Comparison] TO [dbx_ExecuteReportProcs]
GO
