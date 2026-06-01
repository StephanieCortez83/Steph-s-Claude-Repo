SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[RVU_REPORTING_BILLED_CHART_UPDATE] 
		@BILLING_CONTROL_ID int,
		@FACILITY_ID int
AS

DELETE from RevCycleDB.dbo.RVU_REPORTING_BILLED_CHARTS 
WHERE RVU_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID
AND   FACILITY_ID = @FACILITY_ID

declare  @BeginDate datetime
declare  @EndDate datetime

set @BeginDate = (select pbr.Period_Begin_Date  from RVU_REPORTING_BILLING_CONTROL pbr 
					where pbr.RVU_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID)
set @EndDate = (select pbr.Period_End_Date  from RVU_REPORTING_BILLING_CONTROL pbr 
					where pbr.RVU_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID)			
set @EndDate = DATEADD(day,1,@EndDate)
					
select	distinct c.chart_id
into	#tempPEMA
from	sent_procedure sp,
		chart c
where	sp.chart_id = c.chart_id
and		((c.time_of_service <= @EndDate and c.time_of_service >= '2011-06-01' 
			and (SELECT COUNT(*) from RevCycleDB.dbo.RVU_REPORTING_BILLED_CHARTS pbc1 
				 WHERE c.CHART_ID = pbc1.CHART_ID) = 0 ) 
		or convert(varchar, sp.time_of_service, 112) >= @BeginDate and convert(varchar, sp.time_of_service, 112) < @EndDate)	
and		c.facility_id = @FACILITY_ID
and		sp.class in ('PL','PP')
and		(select count(*) from RevCycleDB.dbo.RVU_REPORTING_BILLED_CHARTS prbc
			where prbc.chart_id = c.chart_id) = 0

insert into RevCycleDB.dbo.RVU_REPORTING_BILLED_CHARTS (chart_id, RVU_REPORTING_BILLING_CONTROL_ID, facility_id)
(Select chart_id, @BILLING_CONTROL_ID, @FACILITY_ID from #tempPEMA)

drop table #tempPEMA


GO
GRANT EXECUTE ON  [dbo].[RVU_REPORTING_BILLED_CHART_UPDATE] TO [dbx_ExecuteReportProcs]
GO
