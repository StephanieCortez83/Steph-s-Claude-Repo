SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[rpt_TenetRandomChartByCoder] (   @Facility varchar(MAX) 
														,@DateType int 
														,@StartDate datetime
														,@EndDate datetime
														,@HideName int
														,@Coder int
														,@FacilityLevel varchar(MAX) 
														,@Audit int
														,@UserGroup varchar(MAX) 
														,@PatientClass	varchar(MAX) 
														)
AS
	BEGIN
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

		SET NOCOUNT ON;



-- Test Parameters 

--declare 
-- @Facility int = 1782
--,@DateType int = 1   -- 0 DOS, 1 Sent
--,@StartDate datetime = '11/01/2024'
--,@EndDate datetime =   '11/05/2024'
--,@HideName int = 0  -- 0 No, 1 Yes
--,@Coder int = -1  -- -1 All 
--,@FacilityLevel varchar(5) = '-1'  -- -1 All
--,@Audit int = 3				-- 1 Audit, 2 Not Audited, 3 Combined
--,@UserGroup int = -1		-- -1 All 
--,@PatientClass	int = 5667  --  -999 All
--;


DECLARE 
 @IncludeAllFacilities		    bit = IIF(@Facility LIKE '%-1%', 1, 0)
,@IncludeAllUserGroups		    bit = IIF(@UserGroup LIKE '%-1%', 1, 0)
,@IncludeAllPatientClass		bit = IIF(@PatientClass LIKE '%-999%', 1, 0)
,@IncludeAllFacilityLevel	    bit = IIF(@FacilityLevel LIKE '%-1%', 1, 0)



		--convert multiple params to table
		SELECT	CAST(value AS int) FACILITY_ID
		INTO	#Facilities
		FROM	STRING_SPLIT(@Facility, ',');

		SELECT	CAST(value AS int) USER_GROUP_ID
		INTO	#UserGroups
		FROM	STRING_SPLIT(@UserGroup, ',');				

		SELECT	CAST(value AS int) PATIENT_CLASS_ID
		INTO	#PatientClass
		FROM	STRING_SPLIT(@PatientClass, ',');

		SELECT	CAST(value AS int) Facility_Level_ID
		INTO	#FacilityLevel
		FROM	STRING_SPLIT(@FacilityLevel, ',');






if object_id('TempDB..#Facility1', 'U') is not null				
begin				
	drop table #Facility1			
end;

if object_id('TempDB..#temp3', 'U') is not null				
begin				
	drop table #temp3			
end;

if object_id('TempDB..#temp4', 'U') is not null				
begin				
	drop table #temp4
end;

if object_id('TempDB..#temp5', 'U') is not null				
begin				
	drop table #temp5
end;





create table #temp3 
(
COMPLETED_BY_USER_PROFILE_ID int,
Facility_ID int,
Facility varchar(50), 
Facility_Chart_ID varchar(20), 
DOS Date, 
FACILITY_LEVEL_ID  varchar(5),
PATIENT_CLASS_ID   int,
Coder_Name varchar(100),
APPROVED_BY_USER_PROFILE_ID int,
SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID int
);	




create table #temp4 
(
COMPLETED_BY_USER_PROFILE_ID int,
Facility_ID int,
Facility varchar(50), 
Facility_Chart_ID varchar(20),
DOS Date, 
Coder_Name varchar(100),
FACILITY_LEVEL_ID  varchar(5),
PATIENT_CLASS_ID   int,
APPROVED_BY_USER_PROFILE_ID int,
SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID int 
);	




select * 	
into #Facility1
from	
(
select facility_id, name from facility 
where facility_id in (select facility_id from #Facilities) 
)t1




if object_id('TempDB..#PatientClass1', 'U') is not null				
begin				
	drop table #PatientClass1
end;



SELECT	DISTINCT
				pc.PATIENT_CLASS_ID
		INTO	#PatientClass1
		FROM	dbo.PATIENT_CLASS				 pc
				INNER JOIN dbo.SERVICE_AGREEMENT sa
					ON pc.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		WHERE	(1 = @IncludeAllFacilities
				 OR sa.FACILITY_ID IN (SELECT FACILITY_ID FROM #Facilities))

				AND sa.COMPANY_ID in ( 19, 298) 

				AND (@IncludeAllPatientClass = 1
					 OR pc.DESCRIPTION IN (SELECT	pc1.DESCRIPTION
										   FROM		PATIENT_CLASS pc1
										   WHERE	pc1.PATIENT_CLASS_ID IN (select PATIENT_CLASS_ID from #PatientClass)
										   )
					 );







declare @ii int				
set @ii = (select count(facility_id) from #Facilities)				
while @ii > 0 
begin				




if object_id('TempDB..#temp1', 'U') is not null				
begin				
	drop table #temp1			
end;
if object_id('TempDB..#temp2', 'U') is not null				
begin				
	drop table #temp2			
end;
if object_id('TempDB..#coder_tenure', 'U') is not null				
begin				
	drop table #coder_tenure			
end;



-- *****

-- Auditor/Usergroup


if object_id('TempDB..#auditor', 'U') is not null drop table #auditor


select distinct t1.USER_PROFILE_ID 
into #auditor
from  				
		(
		SELECT USER_PROFILE_ID 
		FROM USER_PROFILE				
		WHERE  USER_PROFILE_ID <> 2
		and ( CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR IS_ACTIVE = 'Y' )		
		and (USER_GROUP_ID in (select USER_GROUP_ID from #UserGroups) OR -1 = @IncludeAllUserGroups )
			
		UNION				
				
		SELECT up.USER_PROFILE_ID 
		FROM USER_GROUP_TO_USER_PROFILE ugup,				
		user_profile up				
		where up.user_profile_id = ugup.user_profile_id
		and UP.USER_PROFILE_ID <> 2
		and ( up.CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR up.IS_ACTIVE = 'Y' )
		and (ugup.USER_GROUP_ID in (select USER_GROUP_ID from #UserGroups) OR -1 = @IncludeAllUserGroups )
		
		) t1


create nonclustered index idx_USER_PROFILE_ID on #auditor (USER_PROFILE_ID);




-- *****



-- Audited Data
select 
c.chart_id,
1 as Rank,
f.name,
c.facility_id,
c.facility_chart_id, 
cast(c.time_of_service as date) as DOS,
c.COMPLETED_BY_USER_PROFILE_ID ,
up.last_name + ', ' + up.first_name as Coder_Name,

fl.CPT_CODE as FACILITY_LEVEL_ID,


c.START_QA_DATE, 
c.START_QA_USER_PROFILE_ID,
c.APPROVED_DATE,
c.APPROVED_BY_USER_PROFILE_ID,

c.START_SECOND_LEVEL_QA_DATETIME, 
c.START_SECOND_LEVEL_QA_USER_PROFILE_ID, 
c.SECOND_LEVEL_QA_APPROVED_DATETIME, 
c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID,

c.patient_disposition_id,
c.PATIENT_CLASS_ID

into #temp1
from 
user_profile up,
#Facility1 f,
chart c 
left outer join facility_level fl
on (case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 then c.FACILITY_LEVEL_ID
				when c.OVERRIDE_FACILITY_LEVEL_ID = '' then c.FACILITY_LEVEL_ID
				else c.OVERRIDE_FACILITY_LEVEL_ID
				end) = fl.FACILITY_LEVEL_ID

where up.user_profile_id = c.COMPLETED_BY_USER_PROFILE_ID
and c.facility_id = f.facility_id
and c.facility_id = (select min(facility_id) from #Facility1)
-- and c.chart_status_id = 5		-- Sent
and 
(										
(@DateType = 0 and c.TIME_OF_SERVICE between @StartDate and  DateAdd(second, 86399, @EndDate) )										
or 										
(@DateType = 1 and c.SENT_DATE between @StartDate and  DateAdd(second, 86399, @EndDate) )										
) 										



and ((c.START_QA_DATE is not null 
	and c.START_QA_USER_PROFILE_ID is not null
	and c.APPROVED_DATE is not null
	and c.APPROVED_BY_USER_PROFILE_ID <> 2 
	and c.APPROVED_BY_USER_PROFILE_ID in (select USER_PROFILE_ID from #auditor)
	)
	or 
	(c.START_SECOND_LEVEL_QA_DATETIME is not null  
    and c.START_SECOND_LEVEL_QA_USER_PROFILE_ID is not null  
    and c.SECOND_LEVEL_QA_APPROVED_DATETIME is not null  
    and c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 2 )
	and c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID in (select USER_PROFILE_ID from #auditor)
	)

and ( up.CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR up.IS_ACTIVE = 'Y' ) -- Active Coder

and (-1 in (@Coder) OR c.COMPLETED_BY_USER_PROFILE_ID in (@Coder) ) 
and (1 = @Audit OR 3 = @Audit)

 
;






-- Not Audited Data
INSERT INTO #temp1
select 
c.chart_id,
2 as Rank,
f.name,
c.facility_id,
c.facility_chart_id, 
cast(c.time_of_service as date) as DOS,
c.COMPLETED_BY_USER_PROFILE_ID ,
up.last_name + ', ' + up.first_name as Coder_Name,

fl.CPT_CODE as FACILITY_LEVEL_ID,

c.START_QA_DATE, 
c.START_QA_USER_PROFILE_ID,
c.APPROVED_DATE,
c.APPROVED_BY_USER_PROFILE_ID,

c.START_SECOND_LEVEL_QA_DATETIME, 
c.START_SECOND_LEVEL_QA_USER_PROFILE_ID, 
c.SECOND_LEVEL_QA_APPROVED_DATETIME, 
c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID,

c.patient_disposition_id,
c.PATIENT_CLASS_ID

from 
user_profile up,
#Facility1 f,
chart c 
left outer join facility_level fl
on (case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 then c.FACILITY_LEVEL_ID
				when c.OVERRIDE_FACILITY_LEVEL_ID = '' then c.FACILITY_LEVEL_ID
				else c.OVERRIDE_FACILITY_LEVEL_ID
				end) = fl.FACILITY_LEVEL_ID



where up.user_profile_id = c.COMPLETED_BY_USER_PROFILE_ID
and c.facility_id = f.facility_id
and c.facility_id = (select min(facility_id) from #Facility1)
and 
(										
(@DateType = 0 and c.TIME_OF_SERVICE between @StartDate and  DateAdd(second, 86399, @EndDate) )										
or 										
(@DateType = 1 and c.SENT_DATE between @StartDate and  DateAdd(second, 86399, @EndDate) )										
)

 -- and c.patient_disposition_id in (1,6,7,8,9,10) -- OutPatient <> 4

and ( up.CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR up.IS_ACTIVE = 'Y' ) -- Active Coder
and (-1 in (@Coder) OR c.COMPLETED_BY_USER_PROFILE_ID in (@Coder) ) 

       


and not exists ( select * from #temp1 where chart_id = c.chart_id ) 

-- this will include pushed charts, not audited charts
and (	(c.START_QA_DATE is null 
	and c.START_QA_USER_PROFILE_ID is null)
and 	
		(c.START_SECOND_LEVEL_QA_DATETIME is null  
    and c.START_SECOND_LEVEL_QA_USER_PROFILE_ID is null  )
	)
  
and (2 = @Audit OR 3 = @Audit)







----------------------------------------------------------------------------------------------------------------------------------
-- tenure 
	select 
		up.USER_PROFILE_ID, UP.CREATION_DATE_TIME 
		,case when datediff(day,min(UP.CREATION_DATE_TIME),getdate()) between 0 and 30 then 1
			--	when datediff(day,min(UP.CREATION_DATE_TIME),getdate()) between 91 and 180 then 2
			--	when datediff(day,min(UP.CREATION_DATE_TIME),getdate()) between 181 and 270 then 3
			--	when datediff(day,min(UP.CREATION_DATE_TIME),getdate()) between 271 and 365 then 4
			else 2 end [TenureId]
--		,case when datediff(day,min(UP.CREATION_DATE_TIME),getdate()) between 0 and 90 then '0 - 3 Months'
--				when datediff(day,min(UP.CREATION_DATE_TIME),getdate()) between 91 and 180 then '3 - 6 Months'
--				when datediff(day,min(UP.CREATION_DATE_TIME),getdate()) between 181 and 270 then '6 - 9 Months'
--				when datediff(day,min(UP.CREATION_DATE_TIME),getdate()) between 271 and 365 then '9 - 12 Months'
--			else '12+ Months' end [Tenure]
	into #coder_tenure
	from
		user_profile up
	where
	up.is_active = 'Y'
	group by up.USER_PROFILE_ID, UP.CREATION_DATE_TIME


	----------------------------------------------------------------------------------------------------------------------------------




select * 	
into #temp2
from	
(
select 
t.COMPLETED_BY_USER_PROFILE_ID, 
t.facility_id,
count(*) as CNT
from #temp1 t,
#coder_tenure ct
where 
t.COMPLETED_BY_USER_PROFILE_ID = ct.USER_PROFILE_ID
and ct.TenureId <> 1
group by t.COMPLETED_BY_USER_PROFILE_ID, t.facility_id
having count(*) >= 3     -- to require a min of 3 charts per facility
)t2



declare @Coder_i int
set	@Coder_i = 1	



	
declare @i int				
set @i = (select count(distinct(COMPLETED_BY_USER_PROFILE_ID)) from #temp2)				
while @i > 0 
begin				
insert into #temp3  
				SELECT TOP 30 
				t1.COMPLETED_BY_USER_PROFILE_ID,
				t1.facility_id, 
				t1.name,
				t1.facility_chart_id, 
				t1.DOS,
				t1.FACILITY_LEVEL_ID,				
				t1.PATIENT_CLASS_ID,								
				case when @HideName = 0 then t1.Coder_Name
				when @HideName = 1	then concat('Coder', @Coder_i)
				end  as Coder_Name,
				t1.APPROVED_BY_USER_PROFILE_ID,
				t1.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
				

				FROM 
				#temp1 t1
				where 
				t1.COMPLETED_BY_USER_PROFILE_ID = (select min(COMPLETED_BY_USER_PROFILE_ID) from #temp2) 
				ORDER BY rank, NEWID();
				
				delete from #temp2
				where COMPLETED_BY_USER_PROFILE_ID = (select min(COMPLETED_BY_USER_PROFILE_ID) from #temp2)
				;

set @i = (select count(distinct(COMPLETED_BY_USER_PROFILE_ID)) from #temp2)	
set	@Coder_i = @Coder_i + 1
end				



delete from #Facility1
		where facility_id = (select min(facility_id ) from #Facility1);

set @ii = (select count(facility_id) from #Facility1)		
end				






declare @Coder_ii int
set	@Coder_ii = 1




declare @Coder_Cnt int				
set @Coder_Cnt = (select count(distinct(COMPLETED_BY_USER_PROFILE_ID)) from #temp3)				
while @Coder_Cnt > 0 
begin





if object_id('TempDB..#temp3A', 'U') is not null				
begin drop table #temp3A	end;

select 
COMPLETED_BY_USER_PROFILE_ID,
				facility_id, 
				Facility,
				facility_chart_id,
				DOS,
				Coder_Name, 
				FACILITY_LEVEL_ID,
				PATIENT_CLASS_ID,
				APPROVED_BY_USER_PROFILE_ID,
				SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID,
				
dense_rank() over (
partition by COMPLETED_BY_USER_PROFILE_ID, facility_id
order by facility_chart_id
) as CoderFacilityRank
 into #temp3A
from 
#temp3				
where COMPLETED_BY_USER_PROFILE_ID = (select min(COMPLETED_BY_USER_PROFILE_ID) from #temp3);



-------------


 
if object_id('TempDB..#temp3B', 'U') is not null				
begin drop table #temp3B	end;


 select *, 
 case when row_number() over (order by facility_chart_id) > 30 then row_number() over (order by facility_chart_id) - 30
 else row_number() over (order by facility_chart_id) end as rowNumber
  into #temp3B
 from #temp3A where CoderFacilityRank <= ( select ceiling(30.00 / count(distinct(facility_id))) 
										 from #temp3A
										 where COMPLETED_BY_USER_PROFILE_ID = (select min(COMPLETED_BY_USER_PROFILE_ID) from #temp3)
										 ) 



declare @3B_REC_CNT int				
set @3B_REC_CNT = (select count(*) from #temp3B)	


IF @3B_REC_CNT = 30
BEGIN
insert into #temp4  
 select COMPLETED_BY_USER_PROFILE_ID, facility_id, 
 Facility, Facility_Chart_id, DOS, Coder_Name, FACILITY_LEVEL_ID, Patient_Class_ID, APPROVED_BY_USER_PROFILE_ID
 ,SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID 
 from  #temp3B
END;
ELSE

IF @3B_REC_CNT > 30
BEGIN -- if count > 30 then 
insert into #temp4  
 select COMPLETED_BY_USER_PROFILE_ID, facility_id, 
 Facility, Facility_Chart_id, DOS, Coder_Name, FACILITY_LEVEL_ID, Patient_Class_ID, APPROVED_BY_USER_PROFILE_ID
 ,SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
  from  #temp3B
 where rowNumber <= (30 - (select max(CoderFacilityRank) from #temp3B))  
END; 
ELSE



BEGIN -- if count < 30 then 
insert into #temp4  
 select top 30 t1.COMPLETED_BY_USER_PROFILE_ID, t1.facility_id, 
 t1.Facility, t1.Facility_Chart_id, t1.DOS, t1.Coder_Name, t1.FACILITY_LEVEL_ID, t1.Patient_Class_ID, t1.APPROVED_BY_USER_PROFILE_ID
 ,t1.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
 from
 (select 
 COMPLETED_BY_USER_PROFILE_ID, facility_id, 
 Facility, Facility_Chart_id, DOS, Coder_Name, FACILITY_LEVEL_ID, Patient_Class_ID, APPROVED_BY_USER_PROFILE_ID, SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
  from  #temp3B
 union
 select 
 COMPLETED_BY_USER_PROFILE_ID, facility_id, 
 Facility, Facility_Chart_id, DOS, Coder_Name, FACILITY_LEVEL_ID, Patient_Class_ID, APPROVED_BY_USER_PROFILE_ID, SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
  from  #temp3A
  ) t1
END; 



delete from #temp3
where COMPLETED_BY_USER_PROFILE_ID = (select min(COMPLETED_BY_USER_PROFILE_ID) from #temp3);



 set @Coder_Cnt = (select count(distinct(COMPLETED_BY_USER_PROFILE_ID)) from #temp3);	
 set @Coder_ii = @Coder_ii + 1


end	






 select 
 t.Facility, t.Facility_Chart_id, t.DOS, t.Coder_Name, t.FACILITY_LEVEL_ID, t.PATIENT_CLASS_ID, pc.[DESCRIPTION] as PatientClass,
 t.APPROVED_BY_USER_PROFILE_ID, 
 t.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID,
 case when  t.APPROVED_BY_USER_PROFILE_ID is null then  t.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID else t.APPROVED_BY_USER_PROFILE_ID end as Auditor_ID
into #temp5  
from #temp4 t
left outer join PATIENT_CLASS pc on pc.PATIENT_CLASS_ID = t.PATIENT_CLASS_ID
where 
(1 = @IncludeAllFacilityLevel OR t.FACILITY_LEVEL_ID in (select Facility_Level_ID from #FacilityLevel) ) 

and ( @IncludeAllPatientClass = 1
	 OR	
	 t.PATIENT_CLASS_ID IN (SELECT PATIENT_CLASS_ID	 FROM #PatientClass1)  
	 )   



select 
Facility, 
Facility_Chart_id, 
DOS, 
Coder_Name, 
FACILITY_LEVEL_ID,
PatientClass,
( select up.last_name + ', '+ up.first_name from user_profile up where up.USER_PROFILE_ID = #temp5.Auditor_ID) as Auditor_Name 
from 
#temp5  
order by 
Facility, Coder_Name, DOS



End


GO
