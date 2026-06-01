SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO













-- =============================================
-- Author:		Don Hutton
-- Create date: 6/27/2018
-- Description:	Query for Preventive Charts in Level of Service Summary 
-- =============================================




CREATE PROCEDURE [dbo].[rpt_LOS_SUMMARY_PREVENTIVE_CHART] 
    @Facility int,
	@ReportDate DATE,
	@patient_class_id int
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	set transaction isolation level read uncommitted

	SET NOCOUNT ON;

	DECLARE @m_Facility INT = @Facility;
	DECLARE @m_ReportDate Date = @ReportDate;
	DECLARE @m_patient_class_id INT = @patient_class_id;

	
	-- ****

	declare @service_agreement_id int = (select service_agreement_id from service_agreement where facility_id = @m_Facility);

declare @Run int = 
(
select
sum(Preventive_Cat) as Preventive_Cat
from
(
select 
case when count(*) > 0 then 1 else 0 end as Preventive_Cat
from PHYSICIAN_SERVICE_PROCEDURE
where 
service_agreement_id = @service_agreement_id
and reporting_column between 14 and 20

union all 

select 
case when count(*) > 0 then 1 else 0 end as Preventive_Cat
from FACILITY_LEVEL
where 
service_agreement_id = @service_agreement_id
and reporting_column between 14 and 20
) x
);


IF @Run > 0	
BEGIN	



if object_id('TempDB..#PrelimResults', 'U') is not null				
begin				
	drop table #PrelimResults			
end;				
				
select * 				
into #PrelimResults				
from				
(	

select facility_id, 
       patient_class_id,
       case when class = 'FL' then 'Facility' else 'Physician' end Class, 
       ColumnNum, 
       lrc.SHORT_DESCRIPTION CPT_CODE,
			 sum(curlos) curlos,			 
			 sum(curlosop) curlosop,
			 sum(ytdlos) ytdlos,
			 sum(ytdlosop) ytdlosop,
			 sum(d90los) d90los,
			 sum(d90losop) d90losop,
			 sum(itdlos) itdlos,
			 sum(itdlosop) itdlosop
from  LOS_REPORT_COLUMN lrc, 
      (
	  select facility_id, 
       patient_class_id, 
       class,
			 ColumnNum,
			 curlos,
			 curlosop,
			 ytdlos,
			 ytdlosop,
			 d90los,
			 d90losop,
			 itdlos,
			 itdlosop
from 	(select x.facility_id, 
       x.patient_class_id, 
       x.class, 
			 x.ColumnNum,
			 sum(x.curlos) curlos,
			 sum(x.curlosop) curlosop,
			 sum(x.ytdlos) ytdlos,
			 sum(x.ytdlosop) ytdlosop,
			 sum(x.d90los) d90los,
			 sum(x.d90losop) d90losop,
			 sum(x.itdlos) itdlos,
			 sum(x.itdlosop) itdlosop
from (

select sp.facility_id,
       sp.patient_class_id,
       sp.class,
       fl.REPORTING_COLUMN ColumnNum,
	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)
	           and  month(sp.TIME_OF_SERVICE) = month(@m_ReportDate)
	        then sp.QUANTITY else 0 end CURLOS,
	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)
	           and  month(sp.TIME_OF_SERVICE) = month(@m_ReportDate)
	           and  pd.outpatient_ind = 1
	           then sp.QUANTITY else 0 end CURLOSOP,

    case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)
	          then sp.QUANTITY else 0 end YTDLOS,

	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)	           
	           and  pd.outpatient_ind = 1
	           then sp.QUANTITY else 0 end YTDLOSOP,

	case when datediff(dd, cast(sp.TIME_OF_SERVICE as date), @m_ReportDate) <= 90
	           then sp.QUANTITY else 0 end D90LOS,

	case when datediff(dd, cast(sp.TIME_OF_SERVICE as date), @m_ReportDate) <= 90
	           and  pd.outpatient_ind = 1
	           then sp.QUANTITY else 0 end D90LOSOP,

	sp.QUANTITY ITDLOS,
	case when sp.PATIENT_DISPOSITION_ID in (1, 6, 7, 8, 9)
	          then sp.QUANTITY else 0 end ITDLOSOP

from sent_procedure sp, patient_disposition pd, facility f, FACILITY_LEVEL fl
where sp.CLASS = 'FL'
and   f.facility_id = sp.facility_id
and   sp.patient_disposition_id = pd.patient_disposition_id
and   sp.TIME_OF_SERVICE <= @m_ReportDate
and   fl.FACILITY_LEVEL_ID = sp.LEVEL_ID
and   sp.facility_id = @m_Facility
and   fl.REPORTING_COLUMN between 14 and 20 -- Preventive
union all
select sp.facility_id,
       sp.patient_class_id,
       sp.class,
       pl.REPORTING_COLUMN ColumnNum,
	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)
	           and  month(sp.TIME_OF_SERVICE) = month(@m_ReportDate)
	        then sp.QUANTITY else 0 end CURLOS,

	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)
	           and  month(sp.TIME_OF_SERVICE) = month(@m_ReportDate)
	           and  pd.outpatient_ind = 1
	           then sp.QUANTITY else 0 end CURLOSOP,

	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)
	          then sp.QUANTITY else 0 end YTDLOS,

	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)	           
	           and  pd.outpatient_ind = 1
	           then sp.QUANTITY else 0 end YTDLOSOP,
			   
			   
    case when datediff(dd, cast(sp.TIME_OF_SERVICE as date), @m_ReportDate) <= 90
	           then sp.QUANTITY else 0 end D90LOS,

	case when datediff(dd, cast(sp.TIME_OF_SERVICE as date), @m_ReportDate) <= 90
	           and  pd.outpatient_ind = 1
	           then sp.QUANTITY else 0 end D90LOSOP,			   	           


	sp.QUANTITY ITDLOS,
	case when sp.PATIENT_DISPOSITION_ID in (1, 6, 7, 8, 9)
	          then sp.QUANTITY else 0 end ITDLOSOP


from sent_procedure sp, patient_disposition pd, facility f, PHYSICIAN_SERVICE_PROCEDURE pl
where sp.CLASS = 'PL'
and   f.facility_id = sp.facility_id
and   sp.patient_disposition_id = pd.patient_disposition_id
and   sp.TIME_OF_SERVICE <= @m_ReportDate
and   pl.PHYSICIAN_SERVICE_PROC_ID = sp.LEVEL_ID
and   sp.facility_id = @m_Facility
and   pl.REPORTING_COLUMN between 14 and 20 -- Preventive

union all

select sp.facility_id,
       sp.patient_class_id,
       'PL' as class,
       pl.REPORTING_COLUMN ColumnNum,
	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)
	           and  month(sp.TIME_OF_SERVICE) = month(@m_ReportDate)
	        then sp.QUANTITY else 0 end CURLOS,

	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)
	           and  month(sp.TIME_OF_SERVICE) = month(@m_ReportDate)
	           and  pd.outpatient_ind = 1
	           then sp.QUANTITY else 0 end CURLOSOP,

	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)
	          then sp.QUANTITY else 0 end YTDLOS,

	case when year(sp.TIME_OF_SERVICE) = year(@m_ReportDate)	           
	           and  pd.outpatient_ind = 1
	           then sp.QUANTITY else 0 end YTDLOSOP,
			   
			   
    case when datediff(dd, cast(sp.TIME_OF_SERVICE as date), @m_ReportDate) <= 90
	           then sp.QUANTITY else 0 end D90LOS,

	case when datediff(dd, cast(sp.TIME_OF_SERVICE as date), @m_ReportDate) <= 90
	           and  pd.outpatient_ind = 1
	           then sp.QUANTITY else 0 end D90LOSOP,			   	           


	sp.QUANTITY ITDLOS,
	case when sp.PATIENT_DISPOSITION_ID in (1, 6, 7, 8, 9)
	          then sp.QUANTITY else 0 end ITDLOSOP


from 
sent_procedure sp, 
patient_disposition pd, 
facility f, 
PHYSICIAN_SERVICE_PROCEDURE pl
where sp.CLASS = 'PP' and sp.cpt_code = '99217'
and   f.facility_id = sp.facility_id
and   sp.patient_disposition_id = pd.patient_disposition_id
and   sp.TIME_OF_SERVICE <= @m_ReportDate  
and sp.service_agreement_id = pl.SERVICE_AGREEMENT_ID
and sp.patient_class_id = pl.PATIENT_CLASS_ID
and pl.CPT_CODE = '99217'
and   sp.facility_id = @m_Facility 
and   pl.REPORTING_COLUMN between 14 and 20 -- Preventive

) x
group by x.facility_id,
         x.patient_class_id,
               x.class,
	x.ColumnNum) y

union 
-- exception for CMH

select distinct @m_Facility, @m_patient_class_id, 'PL', rc.column_id ColumnNum, 0,0,0,0,0,0,0,0 
from 	 LOS_REPORT_COLUMN rc
where    rc.column_id between 14 and 18 -- Preventive
and @m_Facility IN ( select facility_id
					from service_agreement sa
					where company_id = 50
					and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE	)


union

select distinct @m_Facility, @m_patient_class_id, 'FL', rc.column_id ColumnNum, 0,0,0,0,0,0,0,0 
from 	 LOS_REPORT_COLUMN rc
where    rc.column_id between 14 and 18 -- Preventive
and @m_Facility IN ( select facility_id
					from service_agreement sa
					where company_id = 50
					and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE	)

union

select distinct @m_Facility, @m_patient_class_id, 'PL', rc.column_id ColumnNum, 0,0,0,0,0,0,0,0 
from 	 LOS_REPORT_COLUMN rc
where    rc.column_id between 14 and 20 -- Preventive
and @m_Facility NOT IN ( select facility_id
					from service_agreement sa
					where company_id = 50
					and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE	)


union

select distinct @m_Facility, @m_patient_class_id, 'FL', rc.column_id ColumnNum, 0,0,0,0,0,0,0,0 
from 	 LOS_REPORT_COLUMN rc
where    rc.column_id between 14 and 20 -- Preventive
and @m_Facility NOT IN ( select facility_id
					from service_agreement sa
					where company_id = 50
					and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE	)

--select distinct @m_Facility, @m_patient_class_id, 'PL', rc.column_id ColumnNum, 0,0,0,0,0,0,0,0 
--from 	 LOS_REPORT_COLUMN rc
--where    rc.column_id between 14 and 20 -- Preventive

--union

--select distinct @m_Facility, @m_patient_class_id, 'FL', rc.column_id ColumnNum, 0,0,0,0,0,0,0,0 
--from 	 LOS_REPORT_COLUMN rc
--where    rc.column_id between 14 and 20 -- Preventive

--select distinct sa.facility_id, fl.patient_class_id, 'FL', fl.REPORTING_COLUMN ColumnNum, 0,0,0,0,0,0,0,0 
--from 	facility_level fl, service_agreement sa
--where     fl.REPORTING_COLUMN > 0
--and       sa.service_agreement_id = fl.service_agreement_id
--and       fl.REPORTING_COLUMN between 14 and 20 -- Preventive
--and       sa.facility_id = @m_Facility
--and       fl.patient_class_id = @m_patient_class_id		
--union
--select distinct sa.facility_id, pl.patient_class_id, 'PL', pl.REPORTING_COLUMN ColumnNum, 0,0,0,0,0,0,0,0 
--from 	 PHYSICIAN_SERVICE_PROCEDURE pl, service_agreement sa
--where 	  pl.REPORTING_COLUMN > 0
--and       sa.service_agreement_id = pl.service_agreement_id
--and       pl.REPORTING_COLUMN between 14 and 20 -- Preventive
--and       sa.facility_id = @m_Facility
--and       pl.patient_class_id = @m_patient_class_id					
) z
where z.facility_id = @Facility
and   z.patient_class_id = @m_patient_class_id					
and   z.ColumnNum = lrc.COLUMN_ID
and   z.Class = lrc.SERVICE_TYPE
group by z.facility_id, z.patient_class_id,     case when z.class = 'FL' then 'Facility' else 'Physician' end,
			lrc.SHORT_DESCRIPTION, z.ColumnNum
 ) T1



--  select * from #PrelimResults	-- testing only  / remove **************
 
 
 

  select facility_id, patient_class_id, class, columnNum, CPT_Code,  
   ColumnNum as chart_sort, 
 curlos,
 (select sum(curlos) from #PrelimResults  where class = 'Facility' group by facility_id, patient_class_id, class) as TOT_curlos,
 curlosop,   
 (select sum(curlosop) from #PrelimResults  where class = 'Facility'  group by facility_id, patient_class_id, class) as TOT_curlosop,
 ytdlos,
 (select sum(ytdlos) from #PrelimResults  where class = 'Facility' group by facility_id, patient_class_id, class) as TOT_ytdlos,
 ytdlosop,   
 (select sum(ytdlosop) from #PrelimResults  where class = 'Facility' group by facility_id, patient_class_id, class) as TOT_ytdlosop,
 d90los,
 (select sum(d90los) from #PrelimResults  where class = 'Facility'  group by facility_id, patient_class_id, class) as TOT_d90los,
 d90losop,   
 (select sum(d90losop) from #PrelimResults  where class = 'Facility'  group by facility_id, patient_class_id, class) as TOT_d90losop,
 itdlos,
 (select sum(itdlos) from #PrelimResults  where class = 'Facility'  group by facility_id, patient_class_id, class) as TOT_itdlos,
 itdlosop,   
 (select sum(itdlosop) from #PrelimResults  where class = 'Facility'  group by facility_id, patient_class_id, class) as TOT_itdlosop
  from #PrelimResults
  where class = 'Facility'	
  
union

select 
 facility_id, patient_class_id, class, columnNum, CPT_Code,  
  ColumnNum as chart_sort, 
 curlos,
 (select sum(curlos) from #PrelimResults  where class = 'Physician'  group by facility_id, patient_class_id, class) as TOT_curlos,
 curlosop,   
 (select sum(curlosop) from #PrelimResults  where class = 'Physician'  group by facility_id, patient_class_id, class) as TOT_curlosop,
 ytdlos,
 (select sum(ytdlos) from #PrelimResults  where class = 'Physician' group by facility_id, patient_class_id, class) as TOT_ytdlos,
 ytdlosop,   
 (select sum(ytdlosop) from #PrelimResults  where class = 'Physician'  group by facility_id, patient_class_id, class) as TOT_ytdlosop,
 d90los,
 (select sum(d90los) from #PrelimResults  where class = 'Physician' group by facility_id, patient_class_id, class) as TOT_d90los,
 d90losop,   
 (select sum(d90losop) from #PrelimResults  where class = 'Physician' group by facility_id, patient_class_id, class) as TOT_d90losop,
 itdlos,
 (select sum(itdlos) from #PrelimResults  where class = 'Physician' group by facility_id, patient_class_id, class) as TOT_itdlos,
 itdlosop,   
 (select sum(itdlosop) from #PrelimResults  where class = 'Physician' group by facility_id, patient_class_id, class) as TOT_itdlosop
  from #PrelimResults
  where class = 'Physician'	  
 order by facility_id, patient_class_id, class, chart_sort 




 END;


END;
	
















GO
GRANT EXECUTE ON  [dbo].[rpt_LOS_SUMMARY_PREVENTIVE_CHART] TO [dbx_ExecuteReportProcs]
GO
