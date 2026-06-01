SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








-- =============================================
-- Author:		Don Hutton
-- Create date: 6/05/2018
-- Description:	Query for Coder Productivity by Manager Report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_CoderProductivityByManagerReport] 
    @ReportUser INT,
    @StartDate DATETIME,
	@EndDate DATETIME,
	@ACCT_MANAGER VARCHAR(MAX),
	@CLASS_CD VARCHAR(MAX),
	@USER_GROUP VARCHAR(MAX),
	@CHART_STATUS VARCHAR(MAX),	
	@CODER VARCHAR(MAX),
	@Manager VARCHAR(MAX),
	@Supervisor VARCHAR(MAX),
	@Secondary_Supervisor VARCHAR(MAX),
	@COMPANY VARCHAR(MAX) ,			-- -1 All
	@FACILITY VARCHAR(MAX) 			-- -1 All
	
AS
BEGIN

set transaction isolation level read uncommitted

DECLARE @m_ReportUser INT = @ReportUser;
DECLARE @m_StartDate DATETIME = @StartDate;
DECLARE @m_EndDate DATETIME = @EndDate;
DECLARE @m_ACCT_MANAGER VARCHAR(MAX) = @ACCT_MANAGER;
DECLARE @m_CLASS_CD VARCHAR(MAX) = @CLASS_CD;
DECLARE @m_USER_GROUP VARCHAR(MAX) = @USER_GROUP;
DECLARE @m_CHART_STATUS VARCHAR(MAX) = @CHART_STATUS;
DECLARE @m_CODER VARCHAR(MAX) = @CODER;
DECLARE @m_Manager VARCHAR(MAX) = @Manager;
DECLARE @m_Supervisor VARCHAR(MAX) = @Supervisor;
DECLARE @m_Secondary_Supervisor VARCHAR(MAX) = @Secondary_Supervisor;
DECLARE @m_COMPANY VARCHAR(MAX) = @COMPANY;
DECLARE @m_FACILITY VARCHAR(MAX) = @FACILITY;



if object_id('TempDB..#SA1', 'U') is not null drop table #SA1;

select distinct samt.service_agreement_id
INTO #SA1	
					from 
					SERVICE_AGREEMENT_MANAGEMENT_TEAM samt,
					SERVICE_AGREEMENT sa,  
					USER_PROFILE up
					where 
					samt.service_agreement_id = sa.service_agreement_id
					and 
					samt.user_profile_id = up.user_profile_id 
					and samt.management_team_role_id = 1
					and sa.DEMO_TEST_SITE_IND <> 1                
					and up.user_profile_id IN (
					      SELECT *
					      FROM dbo.SplitString(@m_ACCT_MANAGER, ',')
					)

					 and (sa.company_id in (SELECT * FROM dbo.SplitString(@m_COMPANY, ',')) 
					    or -1 in ( SELECT items FROM dbo.SplitString(@m_COMPANY, ',')) )
					and (sa.facility_id in (SELECT * FROM dbo.SplitString(@m_FACILITY, ','))
					    or -1 in ( SELECT items FROM dbo.SplitString(@m_FACILITY, ',')) )

                    and EXISTS (								
									SELECT *						
									FROM FACILITY_USER_AUTHORIZATION  FUA ,						
									USER_PROFILE UP	
									WHERE FUA.FACILITY_ID = sa.FACILITY_ID						
									AND fua.user_profile_id = up.user_profile_id						
									AND UP.IS_ACTIVE = 'Y'						
									and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE						
									AND FUA.USER_PROFILE_ID = @m_ReportUser						
									)

					-- Note: no effective date check is intentional ***


create nonclustered index idx_SA on #SA1 (service_agreement_id)





if object_id('TempDB..#Coder1', 'U') is not null drop table #Coder1;

SELECT distinct t1.user_profile_id, t1.LAST_NAME, t1.FIRST_NAME, t1.USER_CLASS_CD								
INTO #Coder1
from 
(select user_profile_id, LAST_NAME, FIRST_NAME, USER_CLASS_CD								
FROM USER_PROFILE				
WHERE 
	USER_GROUP_ID IN ( SELECT items FROM dbo.SplitString(@m_USER_GROUP, ',') )
	and user_class_cd in ( SELECT items FROM dbo.SplitString(@m_CLASS_CD, ',') )
	and ( user_profile_id in ( SELECT items FROM dbo.SplitString(@m_CODER, ',') ) 		
          or -1 in ( SELECT items FROM dbo.SplitString(@m_CODER, ',') )
	    )
	and ( manager_user_profile_id in ( SELECT items FROM dbo.SplitString(@m_Manager, ',') ) 		
          or -99 in ( SELECT items FROM dbo.SplitString(@m_Manager, ',') )
	    )					
    and ( supervisor_user_profile_id in ( SELECT items FROM dbo.SplitString(@m_Supervisor, ',') ) 		
          or -99 in ( SELECT items FROM dbo.SplitString(@m_Supervisor, ',') )
	    )					
and ( secondary_supervisor_user_profile_id in ( SELECT items FROM dbo.SplitString(@m_Secondary_Supervisor, ',') ) 		
          or -99 in ( SELECT items FROM dbo.SplitString(@m_Secondary_Supervisor, ',') )
	    )					
				
UNION				
				
SELECT up.user_profile_id, up.LAST_NAME, up.FIRST_NAME, up.USER_CLASS_CD				
FROM USER_GROUP_TO_USER_PROFILE ugup,				
user_profile up				
where up.user_profile_id = ugup.user_profile_id	
AND ugup.USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_USER_GROUP, ',') )
and up.user_class_cd in ( SELECT items FROM dbo.SplitString(@m_CLASS_CD, ',') )
and ( up.user_profile_id in ( SELECT items FROM dbo.SplitString(@m_CODER, ',') ) 		
          or -1 in ( SELECT items FROM dbo.SplitString(@m_CODER, ',') )
	)				
and ( up.manager_user_profile_id in ( SELECT items FROM dbo.SplitString(@m_Manager, ',') ) 		
          or -99 in ( SELECT items FROM dbo.SplitString(@m_Manager, ',') )
	    )
and ( up.supervisor_user_profile_id in ( SELECT items FROM dbo.SplitString(@m_Supervisor, ',') ) 		
          or -99 in ( SELECT items FROM dbo.SplitString(@m_Supervisor, ',') )
	    )
and ( up.secondary_supervisor_user_profile_id in ( SELECT items FROM dbo.SplitString(@m_Secondary_Supervisor, ',') ) 		
          or -99 in ( SELECT items FROM dbo.SplitString(@m_Secondary_Supervisor, ',') )
	    )					
														
)t1

create nonclustered index idx_user_profile_id on #Coder1 (user_profile_id)



if object_id('TempDB..#Prod1', 'U') is not null drop table #Prod1;	
if object_id('TempDB..#Prod2', 'U') is not null drop table #Prod2;
if object_id('TempDB..#Prod3', 'U') is not null drop table #Prod3;

create table #Prod1			
(			
	  [DATETIME] Datetime	
	, FACILITY_ID	int	
	, SERVICE_AGREEMENT_ID	int	
	, NAME	varchar(50)		
	, USERID	int	
	, COMPLETED_BY_USER_PROFILE_ID	int
	, APPROVED_BY_USER_PROFILE_ID int
	, SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID int	
	, USER_CLASS_CD	int	
)					




IF 3 in (SELECT items FROM dbo.SplitString(@m_CHART_STATUS, ','))
BEGIN			
	INSERT INTO #Prod1	
select 
c.COMPLETION_DATE as DATETIME, 
c.FACILITY_ID ,
c.SERVICE_AGREEMENT_ID,
coder.LAST_NAME + ', ' + coder.FIRST_NAME NAME, 
c.COMPLETED_BY_USER_PROFILE_ID as USERID,
c.COMPLETED_BY_USER_PROFILE_ID,
0 as APPROVED_BY_USER_PROFILE_ID,
0 as SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID,
coder.USER_CLASS_CD

  from chart c with(nolock) ,
  #Coder1 coder with(nolock) 
  where 
  coder.USER_PROFILE_ID=c.COMPLETED_BY_USER_PROFILE_ID  
  and c.chart_status_id in (3, 4, 5, 8)    
  and c.service_agreement_id in (  select service_agreement_id from  #SA1 )
  and c.COMPLETION_DATE between @StartDate and dateadd(hh, 32, dateadd(mi, 59, dateadd(ss,59,@EndDate)))
END



IF 4 in (SELECT items FROM dbo.SplitString(@m_CHART_STATUS, ','))
BEGIN			
	INSERT INTO #Prod1	
  select   
  c.APPROVED_DATE ,
  c.FACILITY_ID ,
  c.SERVICE_AGREEMENT_ID,
  auditor.LAST_NAME + ', ' + auditor.FIRST_NAME NAME,
  C.APPROVED_BY_USER_PROFILE_ID as USERID, 
  0 COMPLETED_BY_USER_PROFILE_ID,
  C.APPROVED_BY_USER_PROFILE_ID,
  0 as SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID,
  auditor.USER_CLASS_CD
   
  from chart c with(nolock),
  #Coder1 auditor 
  where 
  auditor.USER_PROFILE_ID=c.APPROVED_BY_USER_PROFILE_ID
  and c.chart_status_id in (3, 4, 5, 8)
  and c.APPROVAL_REASON_CODE = 3 -- excludes Pushed Charts
  and c.APPROVED_DATE between @StartDate and dateadd(hh, 32, dateadd(mi, 59, dateadd(ss,59,@EndDate)))    
  and c.service_agreement_id in (  select service_agreement_id from  #SA1 )	
END  	



IF 8 in (SELECT items FROM dbo.SplitString(@m_CHART_STATUS, ','))
BEGIN			
	INSERT INTO #Prod1
  select   
  c.SECOND_LEVEL_QA_APPROVED_DATETIME ,
  c.FACILITY_ID ,
  c.SERVICE_AGREEMENT_ID,
  auditor2.LAST_NAME + ', ' + auditor2.FIRST_NAME NAME, 
 C.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID  as USERID,
 0 COMPLETED_BY_USER_PROFILE_ID,
 0 APPROVED_BY_USER_PROFILE_ID,
 C.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID ,
 auditor2.USER_CLASS_CD
 
  from chart c with(nolock),
  #Coder1 auditor2 
  where 
  auditor2.USER_PROFILE_ID=c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
  and c.chart_status_id in (3, 4, 5, 8)
  and c.APPROVAL_REASON_CODE = 3 -- excludes Pushed Charts
  and c.SECOND_LEVEL_QA_APPROVED_DATETIME between @StartDate and dateadd(hh, 32, dateadd(mi, 59, dateadd(ss,59,@EndDate)))  
  and c.service_agreement_id in (  select service_agreement_id from  #SA1 )	
END	
  	
  

 
 create table #Prod2			
(			
	  ADate                 date	
	, FACILITY_ID	        int	
	, SERVICE_AGREEMENT_ID	int	
	, NAME	                varchar(50)		
	, USERID	            int
	, USER_CLASS_CD	        int		
	, COMPLETED         	int
	, APPROVED              int
	, SECOND_AUDIT          int		
)


INSERT INTO #Prod2
select 
cast(P1.DATETIME as date) ADate,
P1.FACILITY_ID ,
P1.SERVICE_AGREEMENT_ID,
P1.NAME, 
P1.USERID ,
P1.USER_CLASS_CD, 
sum(case when P1.COMPLETED_BY_USER_PROFILE_ID <> 0 THEN 1 ELSE 0 end) COMPLETED,
sum(case when P1.APPROVED_BY_USER_PROFILE_ID <> 0 THEN 1 ELSE 0 end) APPROVED,
sum(case when P1.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 0 THEN 1 ELSE 0 end) SECOND_AUDIT  
from #Prod1 P1
where
P1.user_class_cd = 5
and P1.DATETIME between dateadd(hh, 9, @StartDate) and dateadd(hh, 32, dateadd(mi, 59, dateadd(ss,59,@EndDate)))  
group by 
cast(P1.DATETIME as date) ,
P1.FACILITY_ID ,
P1.SERVICE_AGREEMENT_ID,
P1.NAME, P1.USERID ,
P1.USER_CLASS_CD


INSERT INTO #Prod2
select 
cast(P1.DATETIME as date) ADate,
P1.FACILITY_ID ,
P1.SERVICE_AGREEMENT_ID,
P1.NAME, P1.USERID ,
P1.USER_CLASS_CD,
sum(case when P1.COMPLETED_BY_USER_PROFILE_ID <> 0 THEN 1 ELSE 0 end) COMPLETED,
sum(case when P1.APPROVED_BY_USER_PROFILE_ID <> 0 THEN 1 ELSE 0 end) APPROVED,
sum(case when P1.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 0 THEN 1 ELSE 0 end) SECOND_AUDIT  
from #Prod1 P1
where
P1.user_class_cd <> 5 
and DATEADD(dd, DATEDIFF(dd, 0, P1.DATETIME), 0) BETWEEN @StartDate AND @EndDate
group by 
cast(P1.DATETIME as date),
P1.FACILITY_ID ,
P1.SERVICE_AGREEMENT_ID,
P1.NAME, P1.USERID ,
P1.USER_CLASS_CD


 --select * from #Prod2

select 
am.LAST_NAME + ', ' + am.FIRST_NAME as ACCT_MANAGER,
f.name as FACILITY,
P2.* 
into #Prod3
from 
FACILITY f with(nolock) , 
#Prod2 P2
left join SERVICE_AGREEMENT_MANAGEMENT_TEAM samt1 with(nolock) on P2.service_agreement_id = samt1.service_agreement_id
left join USER_PROFILE am with(nolock) on samt1.USER_PROFILE_ID=am.USER_PROFILE_ID 
where 
P2.FACILITY_ID = f.FACILITY_ID
and samt1.management_team_role_id = 1


select 
ACCT_MANAGER,
ADate,
       NAME as Coder,
       UserID,
       FACILITY,
       Facility_ID as FacilityID,
       COMPLETED,
       APPROVED as Audited,
       SECOND_AUDIT,
      (COMPLETED + APPROVED + SECOND_AUDIT) as TOTAL
from #Prod3


END










GO
GRANT EXECUTE ON  [dbo].[rpt_CoderProductivityByManagerReport] TO [dbx_ExecuteReportProcs]
GO
