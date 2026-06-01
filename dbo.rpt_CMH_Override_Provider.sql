SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











-- 

CREATE PROCEDURE [dbo].[rpt_CMH_Override_Provider]
  @Facility varchar(max) ,
  @Code BIT = 0,	
  @DateType BIT = 0,	
  @StartDate DATEtime ,
  @EndDate DATEtime  ,
  @CODES varchar(max) 

  AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	

  -- Insert statements for procedure here
  DECLARE @m_Facility varchar(max) = @Facility;
  DECLARE @m_Code BIT = @Code;
  DECLARE @m_DateType BIT = @DateType;
  DECLARE @m_StartDate DATEtime = @StartDate;
  DECLARE @m_EndDate DATEtime = @EndDate;
  DECLARE @m_CODES varchar(max) = @CODES;



-- Place selected Facilities into Temp Table
if object_id('TempDB..#FACILITY1', 'U') is not null drop table #FACILITY1;

select * into #FACILITY1
	from 
	(SELECT items as Facility_ID FROM SPLITSTRING(@m_Facility, ','))t1;

-- select * from #FACILITY1    --- testing only  / remove **************


-- Places selected CODES into Temp Table
if object_id('TempDB..#CODES1', 'U') is not null drop table #CODES1;

select * into #CODES1
	from 
	(SELECT items as CODE FROM SPLITSTRING(@m_CODES, ','))t1;

-- select * from #CODES1    --- testing only  / remove **************




if object_id('TempDB..#Charts', 'U') is not null drop table #Charts;
create table #Charts (chart_ID int)

if @m_DateType = 0
begin	-- in this case, peformance is better like this instead of using CASE @m_DateType in a WHERE statement
	insert INTO #Charts	
	select sp.chart_ID 
	from SENT_PROCEDURE as sp with(nolock)
	where 
	exists ( select * from #FACILITY1 f1 where  sp.FACILITY_ID = f1.FACILITY_ID )
		and sp.time_of_service BETWEEN @m_StartDate AND DateAdd(second, 86399, @m_EndDate)	-- performance can be improved in some cases by using functions only on params (not on table columns).
		and sp.CLASS in ( 'PL', 'PP', 'IP' )
		and CASE @m_Code WHEN 1
								THEN sp.BILLING_CODE
								ELSE sp.CPT_CODE
								END in ( select CODE from #CODES1 )

end

--select * from #Charts --- testing only  / remove **************


else
begin
		insert INTO #Charts	
	select sp.chart_ID 
	from SENT_PROCEDURE as sp with(nolock)
	where 
	exists ( select * from #FACILITY1 f1 where  sp.FACILITY_ID = f1.FACILITY_ID )
		and sp.Sent_Date BETWEEN @m_StartDate AND DateAdd(second, 86399, @m_EndDate)	-- performance can be improved in some cases by using functions only on params (not on table columns).
		and sp.CLASS in ( 'PL', 'PP', 'IP' )
		and CASE @m_Code WHEN 1
								THEN sp.BILLING_CODE
								ELSE sp.CPT_CODE
								END in ( select CODE from #CODES1 )
		
	
end

create clustered index ix_cls_CHARTS_ChartID on #Charts (Chart_ID)		


 


if object_id('TempDB..#PrelimResults', 'U') is not null				
begin				
	drop table #PrelimResults			
end;				
				
select * 				
into #PrelimResults				
from				
(				

  

SELECT 
c.FACILITY_ID ,
c.FACILITY_CHART_ID [Account],
	  c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME [Patient Name],
	  CASE @m_DateType
		  WHEN 0
			  THEN c.TIME_OF_SERVICE
		  ELSE c.SENT_DATE
		  END [Date],


 (select code
							  from
									(
									select 
									CASE @m_Code WHEN 0 THEN t1.CPT_CODE ELSE t1.BILLING_CODE END as code,									
									max(t1.qty) qty
									from
										(select 
										sp1.billing_code, sp1.cpt_code, sum(sp1.quantity) as qty
										from 
										sent_procedure sp1 WITH (NOLOCK)
										where sp1.chart_id = c.CHART_ID
										and sp1.class = 'PL'
										and sp1.ADJUSTMENT_IND <> 'Y'
										group by sp1.billing_code, sp1.cpt_code
										)t1 group by 
										CASE @m_Code WHEN 0 THEN t1.CPT_CODE ELSE t1.BILLING_CODE END
									)t2 where qty > 0
								)	[Provider Level] ,




-- Chart Adjustments, Source CD = CA were selecting multiple descriptions causing query to error

--(select 
--			psp.description 
--			from 
--			sent_procedure sp WITH (NOLOCK),
--			physician_service_procedure psp WITH (NOLOCK)
--			where 
--			sp.CHART_ID = c.CHART_ID
--			and sp.CLASS = 'PL'
--			and psp.service_agreement_id = sp.service_agreement_id
--			and psp.physician_service_proc_id = sp.level_id 
--			and psp.patient_class_id = sp.patient_class_id -- New line Added ACS-13002 DAH 08/20/18 ******

--			and CASE @m_Code WHEN 0 THEN sp.CPT_CODE ELSE sp.BILLING_CODE END
--							in (select t2.code
--							  from
--									(
--									select CASE @m_Code WHEN 0 THEN t1.CPT_CODE ELSE t1.BILLING_CODE END as code,
--									max(t1.qty) qty
--									from
--										(select 
--										sp1.billing_code, sp1.cpt_code, sum(sp1.quantity) as qty
--										from 
--										sent_procedure sp1 WITH (NOLOCK)
--										where sp1.chart_id = c.CHART_ID
--										and sp1.class = 'PL'
--                                        and sp1.ADJUSTMENT_IND <> 'Y'
--										group by sp1.billing_code, sp1.cpt_code
--										)t1 group by CASE @m_Code WHEN 0 THEN t1.CPT_CODE ELSE t1.BILLING_CODE END
--									)t2 where qty > 0
--								)	

--			)  ProviderLevelDesc ,

-- ACS-14032 ******
(select
case when t1.adjustment_ind = 'Y' then 'Procedure Adjustment - ' + t1.description 
	else t1.description  end -- as Desc1

from (
select top 1 
			sp.adjustment_ind,
			psp.description 
			from 
			sent_procedure sp WITH (NOLOCK),
			physician_service_procedure psp WITH (NOLOCK)
			where 
			sp.CHART_ID = c.chart_id
			and sp.CLASS = 'PL'
			and psp.service_agreement_id = sp.service_agreement_id
			and psp.physician_service_proc_id = sp.level_id 
			and psp.patient_class_id = sp.patient_class_id -- New line Added ACS-13002 DAH 08/20/18 ******

			and CASE @m_Code WHEN 0 THEN sp.CPT_CODE ELSE sp.BILLING_CODE END
							in (select t2.code
							  from
									(
									select CASE @m_Code WHEN 0 THEN t1.CPT_CODE ELSE t1.BILLING_CODE END as code,
									max(t1.qty) qty
									from
										(
										select 
										sp1.billing_code, sp1.cpt_code, sum(sp1.quantity) as qty
										from 
										sent_procedure sp1 WITH (NOLOCK)
										where sp1.chart_id = c.chart_id
										and sp1.class = 'PL'
                                        and sp1.ADJUSTMENT_IND <> 'Y'
										group by sp1.billing_code, sp1.cpt_code
										)t1 group by CASE @m_Code WHEN 0 THEN t1.CPT_CODE ELSE t1.BILLING_CODE END
									)t2 where qty > 0
								)	
order by sp.adjustment_ind desc
) t1
)as ProviderLevelDesc ,



-- Chart Adjustments, Source CD = CA were selecting multiple descriptions causing query to error

 LTRIM(STUFF((
				  SELECT ', ' + CASE @m_Code
						  WHEN 0
							  THEN CPT_CODE
						  ELSE BILLING_CODE
						  END
				  FROM SENT_PROCEDURE WITH (NOLOCK)
				  WHERE CHART_ID = c.CHART_ID
					  AND CLASS = 'PP'
					  and ADJUSTMENT_IND <> 'Y'				
				  ORDER BY CASE @m_Code WHEN 0 THEN CPT_CODE ELSE BILLING_CODE END
				  FOR XML PATH(''),
					  TYPE
				  ).value('.', 'VARCHAR(MAX)'), 1, 1, '')) [Provider Procedure],



	  LTRIM(STUFF((
				  SELECT ', ' + CASE @m_Code
						  WHEN 0
							  THEN CPT_CODE
						  ELSE BILLING_CODE
						  END
				  FROM SENT_PROCEDURE WITH (NOLOCK)
				  WHERE CHART_ID = c.CHART_ID
					  AND CLASS = 'IP'					
				  ORDER BY CASE @m_Code WHEN 0 THEN CPT_CODE ELSE BILLING_CODE END
				  FOR XML PATH(''),
					  TYPE
				  ).value('.', 'VARCHAR(MAX)'), 1, 1, '')) [Infusion/Injection],


 pd.[DESCRIPTION] [PATIENT_DISPOSITION],
 pdm.[FACILITY_PATIENT_DISPOSITION],



   LTRIM(STUFF((
				  SELECT ', ' + cm.description
				FROM sent_procedure sp WITH (NOLOCK),
				charge_master cm   WITH (NOLOCK)
				WHERE sp.CHART_ID = c.chart_id
				and sp.charge_master_id = cm.charge_master_id
				and CASE @m_Code WHEN 0 THEN sp.CPT_CODE ELSE sp.BILLING_CODE END
							in (select t2.code
							  from
									(
									select CASE @m_Code WHEN 0 THEN t1.CPT_CODE ELSE t1.BILLING_CODE END as code,
									max(t1.qty) qty
									from
										(select 
										sp1.billing_code, sp1.cpt_code, sum(sp1.quantity) as qty
										from 
										sent_procedure sp1 WITH (NOLOCK)
										where sp1.chart_id = c.CHART_ID
										and sp1.class = 'PP'
										and sp1.ADJUSTMENT_IND <> 'Y'
										group by sp1.billing_code, sp1.cpt_code
										)t1 group by CASE @m_Code WHEN 0 THEN t1.CPT_CODE ELSE t1.BILLING_CODE END
									)t2 where qty > 0
								)	
                ORDER BY cm.charge_master_id
				FOR XML PATH(''),
				 TYPE
				  ).value('.', 'VARCHAR(500)'), 1, 1, '')) as CHARGE_MASTER_DESCRIPTION_PP


  FROM 
  CHART c WITH (NOLOCK) 
  LEFT JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
  LEFT JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON pdm.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID
  WHERE 
  exists ( select * from #charts c1 where  c.chart_id = c1.chart_id )
  
  

) t1;



select 
f.Name as Facility_Name,
f.Abbreviated_Name as Facility_Abbrev_Name,
p.facility_id, 
p.account,
p.[Patient Name] ,
p.Date,
p.[Provider Level],
p.ProviderLevelDesc,
p.[Provider Procedure],
p.[Infusion/Injection],
p.[PATIENT_DISPOSITION],
p.[FACILITY_PATIENT_DISPOSITION],
p.CHARGE_MASTER_DESCRIPTION_PP
from 
#PrelimResults p,
facility f
where 
p.facility_id = f.facility_id 
order by account	


END







GO
GRANT EXECUTE ON  [dbo].[rpt_CMH_Override_Provider] TO [dbx_ExecuteReportProcs]
GO
