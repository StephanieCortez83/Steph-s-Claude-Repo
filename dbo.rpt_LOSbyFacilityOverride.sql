SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =============================================
-- Author:		Jay Herrera
-- Create date: 01/09/2019
-- Description:	SQL Code for Level of Service by Facility Override
-- =============================================


CREATE PROCEDURE [dbo].[rpt_LOSbyFacilityOverride]
  @Facility varchar(max),
  @Code BIT = 0,
  @DateType BIT = 0,
  @StartDate DATE,
  @EndDate DATE,
  @PatientClass varchar(max),
  @OverrideType char(1),
  @Override varchar(max)
AS



begin
	set transaction isolation level read uncommitted
	SET NOCOUNT ON;


-- Test Parameters **********************************************************************
 -- declare 
	-- @Facility varchar(max) = '1661' -- East Boston Neighborhood - Behavioral Health
	--,@PatientClass varchar(max) = '-999'
	--,@DateType bit = 0	-- 0 DOS
	--,@StartDate datetime = '20210210'
	--,@EndDate datetime	 = '20210210'
	--,@Code bit = 0
	--,@Override varchar(max) = '38651'
-- Test Parameters **********************************************************************

  -- Insert statements for procedure here
  DECLARE @m_Facility varchar(max) = @Facility
  DECLARE @m_Code BIT = @Code;
  DECLARE @m_DateType BIT = @DateType;
  DECLARE @m_StartDate DATEtime = @StartDate;	--  use DateTime to support DatePart(Second)
  DECLARE @m_EndDate DATEtime = @EndDate;		--  use DateTime to support DatePart(Second)
  DECLARE @m_PatientClass varchar(max) = @PatientClass;
  DECLARE @m_OverrideType char(1) = @OverrideType;
  DECLARE @m_Override varchar(max) = @Override;

      
IF object_id('TempDB..#Data1', 'U') IS NOT NULL DROP TABLE #Data1;
if object_id('TempDB..#ICD10CM', 'U') is not null DROP TABLE #ICD10CM;
if object_id('TempDB..#Charts', 'U') is not null DROP TABLE #Charts;

if object_id('TempDB..#SentProcedure', 'U') is not null DROP TABLE #SentProcedure;
if object_id('TempDB..#ChartDiagnoses', 'U') is not null DROP TABLE #ChartDiagnoses;
if object_id('TempDB..#ChartICD9Desc', 'U') is not null DROP TABLE #ChartICD9Desc;
if object_id('TempDB..#ChartDiagnoses10', 'U') is not null DROP TABLE #ChartDiagnoses10;
if object_id('TempDB..#ProcedureClassCodes', 'U') is not null DROP TABLE #ProcedureClassCodes;
if object_id('TempDB..#ChartMaxAdjIndFL', 'U') is not null DROP TABLE #ChartMaxAdjIndFL;
if object_id('TempDB..#ChartFacilityLevel', 'U') is not null DROP TABLE #ChartFacilityLevel;
if object_id('TempDB..#ChartFP', 'U') is not null DROP TABLE #ChartFP;
if object_id('TempDB..#ChartMaxAdjIndPL', 'U') is not null DROP TABLE #ChartMaxAdjIndPL;
if object_id('TempDB..#ChartPhysicianLevel', 'U') is not null DROP TABLE #ChartPhysicianLevel;
if object_id('TempDB..#ChartPP', 'U') is not null DROP TABLE #ChartPP;
if object_id('TempDB..#ChartIP', 'U') is not null DROP TABLE #ChartIP;
if object_id('TempDB..#ChartFacilityLevelDesc', 'U') is not null DROP TABLE #ChartFacilityLevelDesc;
if object_id('TempDB..#ChartPhysicianLevelDesc', 'U') is not null DROP TABLE #ChartPhysicianLevelDesc;


-- Places selected CODES into Temp Table
if object_id('TempDB..#CODES1', 'U') is not null drop table #CODES1;

--select * into #CODES1
--from (SELECT items as CODE FROM SPLITSTRING(@m_CODES, ',')) as t1;

	select distinct
		case @Code when 1 then BILLING_CODE else CPT_CODE end CODE
	into #CODES1
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
				FACILITY_ID in (@Facility)
				and getdate() between EFFECTIVE_DATE and EXPIRATION_DATE
		)
		and getdate() between EFFECTIVE_DATE and EXPIRATION_DATE
	order by
		CODE;



-- Place selected Overrides into Temp Table
if object_id('TempDB..#OVERRIDES', 'U') is not null drop table #OVERRIDES;

create table #OVERRIDES
(		
CODE int
)

insert into #OVERRIDES
SELECT cast(items as int) as CODE FROM SPLITSTRING(@m_Override, ',');




create table #Charts (chart_ID int, DateParam datetime)

if @m_DateType = 0
begin	
	insert INTO #Charts	(chart_ID, DateParam)
	select c.chart_ID, DateParam = c.time_of_service
	from CHART as c with(nolock)
	where 
		c.FACILITY_ID in (SELECT items FROM SPLITSTRING(@m_Facility, ',')) 
		and c.time_of_service BETWEEN @m_StartDate AND DateAdd(second, 86399, @m_EndDate)	
		and ( -999 in (SELECT items FROM SPLITSTRING(@m_PatientClass, ',')) 
			or c.patient_class_id in (SELECT items FROM SPLITSTRING(@m_PatientClass, ',')) )
end
else
begin
	insert INTO #Charts (chart_ID, DateParam)
	select c.chart_ID, DateParam = c.sent_date
	from CHART as c with(nolock)
	where 
		c.FACILITY_ID in (SELECT items FROM SPLITSTRING(@m_Facility, ',')) 
		and c.Sent_Date BETWEEN @m_StartDate AND DateAdd(second, 86399, @m_EndDate)
		and ( -999 in (SELECT items FROM SPLITSTRING(@m_PatientClass, ',')) 
			or c.patient_class_id in (SELECT items FROM SPLITSTRING(@m_PatientClass, ',')) )
end

alter table #Charts 
add chart_status_ID int

update t
set t.chart_status_ID = c.chart_status_ID
from
	#Charts as t
	join CHART as c with(NOLOCK) on t.chart_ID = c.chart_ID

DELETE FROM #Charts WHERE chart_status_ID <> 5

create clustered index ix_cls_CHARTS_ChartID on #Charts (Chart_ID)

-- populate subset of Sent_Procedure
	select sp.seq, sp.chart_ID, sp.source_ID, sp.source_CD 
	 into #SentProcedure
	from Sent_Procedure as sp with(nolock)
		join #Charts as c on sp.chart_ID = c.chart_ID

	create clustered index ix_cls_SentProcedure_Seq on #SentProcedure (Seq)

	alter table #SentProcedure
	add
		Class varchar(2),
		Adjustment_Ind varchar(1),
		Quantity int,
		CPT_Code varchar(5),
		Billing_Code varchar(20),
		Service_Agreement_ID int,
		Level_ID int,
		Charge_Master_ID int

	update t
	set	
		t.class = sp.class,
		t.Adjustment_Ind = sp.Adjustment_Ind,
		t.Quantity = sp.quantity,
		t.cpt_code = sp.cpt_code,
		t.billing_code = sp.billing_code,
		t.service_agreement_ID = sp.service_agreement_ID,
		t.level_ID = sp.level_ID,
		t.charge_master_ID = sp.charge_master_ID
	from 
		#SentProcedure as t
		join Sent_Procedure as sp with(nolock) on t.seq = sp.seq

--	delete from #SentProcedure where cpt_code not in (select code from #Codes1) and billing_code not in (select code from #Codes1);



	delete from #SentProcedure where chart_ID not in 
			(select chart_ID from #SentProcedure where cpt_code in (select code from #Codes1)
				or billing_code in (select code from #Codes1));



alter table #Charts
add
	facility_ID int,
	facility_Chart_ID varchar(20),
	patient_last_name varchar(35),
	patient_first_name varchar(25),
	service_agreement_ID int,
	financial_class_cd varchar(10),
	patient_disposition_ID int,
	patient_disposition_map_ID int,
	cuid int,
	DOS date,
    SENT_DATE date,
    PATIENT_CLASS_ID int,
	OVERRIDE_FACILITY_LEVEL_ID int,
	OVERRIDE_PHYSICIAN_SERVICE_PROC_ID int


update t
set 
	t.facility_ID = c.facility_ID,
	t.facility_Chart_ID = c.facility_Chart_ID,
	t.patient_last_name = c.patient_last_name,
	t.patient_first_name = c.patient_first_name,
	t.service_agreement_ID = c.service_agreement_ID
from
	#Charts as t
	join CHART as c with(NOLOCK) on t.chart_ID = c.chart_ID

update t
set 
	t.financial_class_cd = c.financial_class_cd,
	t.patient_disposition_ID = c.patient_disposition_ID,
	t.patient_disposition_map_ID = c.patient_disposition_map_ID,
	t.cuid = c.COMPLETED_BY_USER_PROFILE_ID,
	t.DOS = c.TIME_OF_SERVICE,
	t.SENT_DATE = c.SENT_DATE,
	t.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
from
	#Charts as t
	join CHART as c with(NOLOCK) on t.chart_ID = c.chart_ID

update t
set
	t.OVERRIDE_FACILITY_LEVEL_ID = c.OVERRIDE_FACILITY_LEVEL_ID,
	t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
from
	#Charts t
	join CHART c with (nolock) on t.chart_ID = c.CHART_ID


SELECT *
INTO #Data1
FROM (
SELECT 
	c.chart_ID,	
	c.facility_ID,
	c.FACILITY_CHART_ID [Account],
	c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME [Patient Name],
	c.DateParam,

	c.service_agreement_ID,
	c.financial_class_cd,

	pd.[DESCRIPTION] [PATIENT_DISPOSITION],
	pdm.[FACILITY_PATIENT_DISPOSITION] ,
	c.cuid,
	c.DOS,
	c.SENT_DATE,
	c.PATIENT_CLASS_ID,
	c.OVERRIDE_FACILITY_LEVEL_ID,
	c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID

  FROM 
	#Charts as c
	LEFT JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
	LEFT JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON pdm.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID

) T3;

create clustered index ix_cls_Data1_ChartID on #Data1 (Chart_ID)

-- add columns to #Data1 for subsequent population of FOR XML data 
	alter table #Data1 
	add	
		Facility  varchar(50),	
		Diagnoses varchar(max),
		ICD9_Diagnoses_Desc varchar(max),
		ICD10_Diagnoses varchar(max),
		ICD10_Diagnoses_Desc varchar(max),
		[Facility Level] varchar(max),
		[Facility Procedure] varchar(max),
		[Physician Level] varchar(max),
		[Physician Procedure] varchar(max),
		[Infusion/Injection] varchar(max),
		FacilityLevelDesc varchar(1000),
		PhysicianLevelDesc varchar(1000),
		Charge_Master_Description_PP varchar(500),
		Charge_Master_Description_FP varchar(500),
		Financial_Class varchar(100),
		Coder       varchar(100),
		Patient_Class   varchar(50)

-- populate Facility
	update c
	set c.Facility = f.name
	from #Data1 as c
		join Facility as f 
			on c.facility_ID = f.facility_ID
			



-- populate Diagnoses 
	select c.chart_ID, cdc.ICD9_Code
	 into #ChartDiagnoses
	from
		Chart_Diagnosis_Code as cdc with(nolock)
		join #Charts as c on cdc.chart_ID = c.chart_ID

	update c
	set c.Diagnoses = LTRIM(STUFF((
						SELECT ', ' + ICD9_Code
					FROM #ChartDiagnoses as t
					where t.CHART_ID = c.chart_id
					ORDER BY ICD9_Code 			
					FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 1, ''))
	from #Data1 as c


-- populate ICD9_Diagnoses_Desc 
	select c.chart_ID, cm9.icd9_Code, cm9.short_description
	 into #ChartICD9Desc
	from
		Chart_Diagnosis_Code as cdc with(nolock)
		join #Charts as c on cdc.chart_ID = c.chart_ID
		join ICD_9_CM as cm9 with(nolock)
			on cm9.icd9_code = cdc.ICD9_Code
			and getdate() between cm9.effective_date and cm9.expiration_date

	update c
	set c.ICD9_Diagnoses_Desc = LTRIM(STUFF((
						SELECT ', ' + short_description
					FROM #ChartICD9Desc as t
					where t.CHART_ID = c.chart_id
					ORDER BY ICD9_Code 			
					FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 1, ''))
	from #Data1 as c


-- populate ICD10_Diagnoses 
	select c.chart_ID, cdc10.ICD10_Code
	 into #ChartDiagnoses10
	from
		Chart_Diagnosis_Code_ICD10 as cdc10 with(nolock)
		join #Charts as c on cdc10.chart_ID = c.chart_ID

	update c
	set c.ICD10_Diagnoses = LTRIM(STUFF((
						SELECT ', ' + ICD10_Code
					FROM #ChartDiagnoses10 as t
					where t.CHART_ID = c.chart_id
					ORDER BY ICD10_Code 			
					FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 1, ''))
	from #Data1 as c



-- derive CaseCode for all records in #SentProcedure with applicable Class value
	select chart_ID, Class, CPT_Code,
		CaseCode = CASE @m_Code WHEN 0 THEN CPT_CODE
							  ELSE BILLING_CODE END
		, charge_master_ID
	 INTO #ProcedureClassCodes
	from #SentProcedure
	where class in ('FP', 'PP', 'IP')


-- populate [Facility Level]
	select chart_ID, Adjustment_Ind = max(Adjustment_Ind) 
	 INTO #ChartMaxAdjIndFL
	from #SentProcedure
	where class = 'FL'
	group by chart_ID

	SELECT  
		sp.chart_ID, 
		FacilityLevel = CASE 
			WHEN @m_Code = 0 AND (sp.ADJUSTMENT_IND <> 'Y' OR sp.QUANTITY > 0) -- Handle adjustment where the level is removed
				THEN sp.CPT_CODE
			WHEN @m_Code = 1 AND (sp.ADJUSTMENT_IND <> 'Y' OR sp.QUANTITY > 0) 
				THEN sp.BILLING_CODE
			ELSE NULL END  
	 INTO #ChartFacilityLevel
	from #SentProcedure as sp
		join #ChartMaxAdjIndFL as a on sp.chart_ID = a.chart_ID and sp.Adjustment_Ind = a.Adjustment_Ind
	where sp.class = 'FL'

	UPDATE t1 SET t1.[Facility Level] = t2.FacilityLevel FROM #Data1 as t1 join #ChartFacilityLevel as t2 on t1.chart_ID = t2.chart_ID	


-- populate [Facility Procedure]
	select * into #ChartFP from #ProcedureClassCodes where class = 'FP'

	update c
	set c.[Facility Procedure] = LTRIM(STUFF((
						SELECT ',' + CaseCode
					FROM #ChartFP as t
					where t.CHART_ID = c.chart_id
					ORDER BY CPT_Code 			
					FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 1, ''))
	from #Data1 as c


-- populate [Physician Level]
	select chart_ID, Adjustment_Ind = max(Adjustment_Ind) 
	 INTO #ChartMaxAdjIndPL
	from #SentProcedure
	where class = 'PL'
	group by chart_ID

	SELECT  
		sp.chart_ID, 
		PhysicianLevel = CASE 
			WHEN @m_Code = 0 AND (sp.ADJUSTMENT_IND <> 'Y' OR sp.QUANTITY > 0) -- Handle adjustment where the level is removed
				THEN sp.CPT_CODE
			WHEN @m_Code = 1 AND (sp.ADJUSTMENT_IND <> 'Y' OR sp.QUANTITY > 0) THEN sp.BILLING_CODE
			ELSE NULL END
	 INTO #ChartPhysicianLevel
	from #SentProcedure as sp
		join #ChartMaxAdjIndPL as a on sp.chart_ID = a.chart_ID and sp.Adjustment_Ind = a.Adjustment_Ind
	where sp.class = 'PL'

	UPDATE t1 SET t1.[Physician Level] = t2.PhysicianLevel FROM #Data1 as t1 join #ChartPhysicianLevel as t2 on t1.chart_ID = t2.chart_ID	


-- populate [Physician Procedure]
	select * into #ChartPP from #ProcedureClassCodes where class = 'PP'

	update c
	set c.[Physician Procedure] = LTRIM(STUFF((
						SELECT ', ' + CaseCode
					FROM #ChartPP as t
					where t.CHART_ID = c.chart_id
					ORDER BY CPT_Code 			
					FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 1, ''))
	from #Data1 as c


-- populate Charge_Master_Description_PP
	update c
	set c.Charge_Master_Description_PP = LTRIM(STUFF((
						SELECT ', ' + cm.description
					FROM #ChartPP as t
						join charge_master as cm with(NOLOCK) on t.charge_master_ID = cm.charge_master_ID
					where t.CHART_ID = c.chart_id
					ORDER BY cm.charge_master_ID 			
					FOR XML PATH(''), TYPE).value('.', 'VARCHAR(500)'), 1, 1, ''))
	from #Data1 as c


-- populate Charge_Master_Description_FP
	update c
	set c.Charge_Master_Description_FP = LTRIM(STUFF((
						SELECT ', ' + cm.description
					FROM #ChartFP as t
						join charge_master as cm with(NOLOCK) on t.charge_master_ID = cm.charge_master_ID
					where t.CHART_ID = c.chart_id
					ORDER BY cm.charge_master_ID 			
					FOR XML PATH(''), TYPE).value('.', 'VARCHAR(500)'), 1, 1, ''))
	from #Data1 as c




-- populate [Infusion/Injection]
	select * into #ChartIP from #ProcedureClassCodes where class = 'IP'

	update c
	set c.[Infusion/Injection] = LTRIM(STUFF((
						SELECT ', ' + CaseCode
					FROM #ChartIP as t
					where t.CHART_ID = c.chart_id
					ORDER BY CaseCode 			
					FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 1, ''))
	from #Data1 as c


-- populate FacilityLevelDesc
	select sp.chart_ID, fl.Description
	 into #ChartFacilityLevelDesc
	from 
		#SentProcedure as sp
		join FACILITY_LEVEL as fl WITH (NOLOCK) 
			on sp.level_ID = fl.facility_level_ID
			and sp.service_agreement_ID = fl.service_agreement_ID
	where sp.CLASS = 'FL'

	UPDATE t1 SET t1.FacilityLevelDesc = t2.Description FROM #Data1 as t1 join #ChartFacilityLevelDesc as t2 on t1.chart_ID = t2.chart_ID	


-- populate PhysicianLevelDesc
	select sp.chart_ID, psp.description	
	 into #ChartPhysicianLevelDesc
	from 
		#SentProcedure as sp
		join physician_service_procedure as psp WITH (NOLOCK)
			on sp.level_ID = psp.physician_service_proc_ID
			and sp.service_agreement_ID = psp.service_agreement_ID
	where 
		sp.CLASS = 'PL'
		and sp.source_cd = 'PL'

	UPDATE t1 SET t1.PhysicianLevelDesc = t2.Description FROM #Data1 as t1 join #ChartPhysicianLevelDesc as t2 on t1.chart_ID = t2.chart_ID	


-- populate ICD10_Diagnoses_Desc 
	select c.chart_ID, Short_Description = cast(null as varchar(150)), icd10.ICD10_CODE   --icd10.posting_order
	 into #ICD10CM
	from	
		#Data1 as c
		join CHART_DIAGNOSIS_CODE_ICD10 as icd10 with(nolock) on icd10.CHART_ID = c.chart_id

	update t	-- broke out this REPLACE join to a separate step to avoid unpredictable poor performance
	set t.short_description = cm10.short_description
	from 
		#ICD10CM as t 
		join ICD_10_CM as cm10 with(nolock) 
			on cm10.icd_10_code = replace(t.ICD10_CODE, '.', '' )
			and getdate() between cm10.effective_date and cm10.expiration_date

	update c		-- note that some Chart_IDs in CHART_DIAGNOSIS_CODE_ICD10 have duplicate values for Posting_Order which was producing random results if ordered by Posting_Order
	set c.ICD10_Diagnoses_Desc = LTRIM(STUFF((
					  SELECT ', ' + short_description
					FROM #ICD10CM as t
					where t.CHART_ID = c.chart_id
					ORDER BY ICD10_CODE --POSTING_ORDER				
					FOR XML PATH(''),
					 TYPE
					  ).value('.', 'VARCHAR(MAX)'), 1, 1, ''))
	from #Data1 as c


-- populate Financial_Class 
	update c
	set c.financial_class = fc.description
	from #Data1 as c
		join Facility_Financial_Class as fc 
			on c.service_agreement_ID = fc.service_agreement_ID
			and c.financial_class_cd = fc.financial_class_cd


-- populate Coder
	update c
	set c.Coder = up.last_name  +', ' + up.First_name
	from #Data1 as c
		join user_profile as up 
			on c.cuid = up.user_profile_id

-- populate Patient Class
	update c
	set c.Patient_Class = pc.description
	from #Data1 as c
		join PATIENT_CLASS as pc 
			on c.patient_class_id = pc.patient_class_id





select -- FACILITY OVERRIDE Data
    'ALL' as AllData
    ,d.Facility
    ,d.Account
    ,d.[Patient Name]
    ,[Date] = DateParam
    ,d.[Facility Level]
    ,d.FacilityLevelDesc
    ,d.[Facility Procedure]
    ,d.[Physician Level]
    ,d.PhysicianLevelDesc
    ,d.[Physician Procedure]
    ,d.[Infusion/Injection]
    ,d.[Diagnoses]
    ,d.[ICD9_Diagnoses_Desc]
    ,d.ICD10_Diagnoses
    ,d.ICD10_Diagnoses_Desc
    ,d.PATIENT_DISPOSITION
    ,d.FACILITY_PATIENT_DISPOSITION
    ,d.CHARGE_MASTER_DESCRIPTION_PP
    ,d.CHARGE_MASTER_DESCRIPTION_FP
    ,d.FINANCIAL_CLASS
    ,d.Coder
    ,d.DOS
    ,d.SENT_DATE
    ,d.Patient_Class
	,d.OVERRIDE_FACILITY_LEVEL_ID
	,d.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID	
	,fl.CPT_CODE
	,fl.BILLING_CODE
from
    #Data1 d
	,FACILITY_LEVEL fl
where

d.[Facility Level] is not null
and isnull(d.OVERRIDE_FACILITY_LEVEL_ID,'-1') != '-1'
and	d.OVERRIDE_FACILITY_LEVEL_ID = fl.FACILITY_LEVEL_ID
and ( ('A' = @m_OverrideType) or ('F' = @m_OverrideType) )
and 
	( fl.FACILITY_LEVEL_ID  
		 in (select code from #OVERRIDES)  
		 OR '-1' in (select code from #OVERRIDES) ) 


									
union 

select   -- PHYSICIAN OVERRIDE Data
    'ALL' as AllData
    ,d.Facility
    ,d.Account
    ,d.[Patient Name]
    ,[Date] = DateParam
    ,d.[Facility Level]
    ,d.FacilityLevelDesc
    ,d.[Facility Procedure]
    ,d.[Physician Level]
    ,d.PhysicianLevelDesc
    ,d.[Physician Procedure]
    ,d.[Infusion/Injection]
    ,d.[Diagnoses]
    ,d.[ICD9_Diagnoses_Desc]
    ,d.ICD10_Diagnoses
    ,d.ICD10_Diagnoses_Desc
    ,d.PATIENT_DISPOSITION
    ,d.FACILITY_PATIENT_DISPOSITION
    ,d.CHARGE_MASTER_DESCRIPTION_PP
    ,d.CHARGE_MASTER_DESCRIPTION_FP
    ,d.FINANCIAL_CLASS
    ,d.Coder
    ,d.DOS
    ,d.SENT_DATE
    ,d.Patient_Class
	,d.OVERRIDE_FACILITY_LEVEL_ID
	,d.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID	
	,psp.CPT_CODE
	,psp.BILLING_CODE
	
from
    #Data1 d
   ,PHYSICIAN_SERVICE_PROCEDURE psp
where
	d.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = psp.PHYSICIAN_SERVICE_PROC_ID
and ( ('A' = @m_OverrideType) or ('P' = @m_OverrideType) )
and 
	( psp.PHYSICIAN_SERVICE_PROC_ID  
		 in (select code from #OVERRIDES)  
		 OR '-1' in (select code from #OVERRIDES) )


order by
    [Account]
    ,[Patient Name]
    ,[Date];
 
 END

GO
GRANT EXECUTE ON  [dbo].[rpt_LOSbyFacilityOverride] TO [dbx_ExecuteReportProcs]
GO
