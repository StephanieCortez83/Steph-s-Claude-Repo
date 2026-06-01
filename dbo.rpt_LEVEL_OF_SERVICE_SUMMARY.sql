SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[rpt_LEVEL_OF_SERVICE_SUMMARY]
	 @ReportUser  int
	,@AsOfDate    datetime   
    ,@Facility    int       
    ,@Facility2   int       
    ,@Disposition varchar(15)
    ,@LOS         varchar(25)
WITH EXEC AS CALLER
AS
BEGIN	
---- TEST PARMS
--declare
--     @AsOfDate    datetime    = '04/19/2024'
--    ,@Facility    int         = 916
--    ,@Facility2   int         = -1
--    ,@Disposition varchar(15) = 'ALL'   
--    ,@LOS         varchar(25) = '1,2,3,4,5,6,7,8'
--    ,@ReportUser  int         = 80;
---- TEST PARMS
--  (select items from RevCycleDB.dbo.SplitString(@LOS,','))
if object_id('TempDB..#PreWork1', 'U') is not null drop table #PreWork1;
if object_id('TempDB..#Temp1', 'U') is not null drop table #Temp1;
if object_id('TempDB..#results', 'U') is not null drop table #results;
if object_id('TempDB..#final_results', 'U') is not null drop table #final_results;
select * into #PreWork1
from 
(
select
    los.Facility
    ,los.FACILITY_ID
    ,los.patient_class_id
    ,los.patient_class
    ,los.Class
    ,los.[Year]
    ,los.[Month]
    ,los.Disposition
	,sum(los.TotLOS)  TotLOS
	,sum(los.TotLOS1) TotLOS1
	,sum(los.TotLOS2) TotLOS2
	,sum(los.TotLOS3) TotLOS3
	,sum(los.TotLOS4) TotLOS4
	,sum(los.TotLOS5) TotLOS5
	,sum(los.TotLOS6) TotLOS6
	,sum(los.TotLOS7) TotLOS7
	,sum(los.TotLOS8) TotLOS8
	,sum(los.TotLOS1_8) TotLOS1_8
    ,NUll TotLOS9
    ,NUll PctLOS9
	,NULL TotLOS10
    ,NULL PctLOS10
	,NULL TotLOS11
    ,NULL PctLOS11
    ,NULL TotLOS12
    ,NULL PctLOS12					
    ,NULL TotLOS13
    ,NULL PctLOS13					
	,NULL TotLOS_CON
	,NULL TotLOS14
    ,NULL PctLOS14
	,NULL TotLOS15
    ,NULL PctLOS15
	,NULL TotLOS16
    ,NULL PctLOS16
	,NULL TotLOS17
    ,NULL PctLOS17
	,NULL TotLOS18
    ,NULL PctLOS18 
	,NULL TotLOS19
    ,NULL PctLOS19
	,NULL TotLOS20
    ,NULL PctLOS20 				
	,NULL TotLOS_PRE
	,NULL TotLOS21
    ,NULL PctLOS21
	,NULL TotLOS22
    ,NULL PctLOS22
	,NULL TotLOS23
    ,NULL PctLOS23
	,NULL TotLOS24
    ,NULL PctLOS24
	,NULL TotLOS25
    ,NULL PctLOS25
	,NULL TotLOS26
    ,NULL PctLOS26
	,NULL TotLOS_INP
	,NULL TotLOS27
    ,NULL PctLOS27
	,NULL TotLOS28
    ,NULL PctLOS28
	,NULL TotLOS29
    ,NULL PctLOS29
	,NULL TotLOS30
    ,NULL PctLOS30
	,NULL TotLOS31
    ,NULL PctLOS31
	,NULL TotLOS32
    ,NULL PctLOS32
	,NULL TotLOS_NH
	,NULL TotLOS33
    ,NULL PctLOS33
	,NULL TotLOS34
    ,NULL PctLOS34
	,NULL TotLOS35
    ,NULL PctLOS35
	,NULL TotLOS36
    ,NULL PctLOS36
    ,NULL TotLOS37
    ,NULL PctLOS37
	,NULL TotLOS38
    ,NULL PctLOS38
	,NULL TotLOS_OBS	
-- into #PreWork1
from
    LOS_Facility_Summary los
where
    (
    (year(@AsOfDate) > los.Year) or
                                     (
                                     year(@AsOfDate) = los.Year and month(@AsOfDate) >= los.Month
                                     )
    ) and
          (
          los.FACILITY_ID = @Facility or los.FACILITY_ID = @Facility2
          ) and
                (
                Disposition in (@Disposition) or 'ALL' in (@Disposition)
                )
group by 
     los.Facility
    ,los.FACILITY_ID
    ,los.patient_class_id
    ,los.patient_class
    ,los.Class
    ,los.[Year]
    ,los.[Month]
    ,los.Disposition
union all
select
    los.Facility
    ,los.FACILITY_ID
    ,los.patient_class_id
    ,los.patient_class
    ,los.Class
    ,los.[Year]
    ,los.[Month]
    ,los.Disposition
	,TotLOS
	,NULL TotLOS1
	,NULL TotLOS2
	,NULL TotLOS3
	,NULL TotLOS4
	,NULL TotLOS5
	,NULL TotLOS6
	,NULL TotLOS7
	,NULL TotLOS8
	,NULL TotLOS1_8
    ,los.TotLOS9
    ,los.PctLOS9
	,los.TotLOS10
    ,los.PctLOS10
	,los.TotLOS11
    ,los.PctLOS11
    ,los.TotLOS12
    ,los.PctLOS12					
    ,los.TotLOS13
    ,los.PctLOS13					
	,los.TotLOS_CON
	,los.TotLOS14
    ,los.PctLOS14
	,los.TotLOS15
    ,los.PctLOS15
	,los.TotLOS16
    ,los.PctLOS16
	,los.TotLOS17
    ,los.PctLOS17
	,los.TotLOS18
    ,los.PctLOS18 
	,los.TotLOS19
    ,los.PctLOS19
	,los.TotLOS20
    ,los.PctLOS20 				
	,los.TotLOS_PRE
	,los.TotLOS21
    ,los.PctLOS21
	,los.TotLOS22
    ,los.PctLOS22
	,los.TotLOS23
    ,los.PctLOS23
	,los.TotLOS24
    ,los.PctLOS24
	,los.TotLOS25
    ,los.PctLOS25
	,los.TotLOS26
    ,los.PctLOS26
	,los.TotLOS_INP
	,los.TotLOS27
    ,los.PctLOS27
	,los.TotLOS28
    ,los.PctLOS28
	,los.TotLOS29
    ,los.PctLOS29
	,los.TotLOS30
    ,los.PctLOS30
	,los.TotLOS31
    ,los.PctLOS31
	,los.TotLOS32
    ,los.PctLOS32
	,los.TotLOS_NH
	,los.TotLOS33
    ,los.PctLOS33
	,los.TotLOS34
    ,los.PctLOS34
	,los.TotLOS35
    ,los.PctLOS35
	,los.TotLOS36
    ,los.PctLOS36
	,los.TotLOS37
    ,los.PctLOS37
	,los.TotLOS38
    ,los.PctLOS38
	,los.TotLOS_OBS
from
    LOS_Facility_Summary los
where
    (
    (year(@AsOfDate) > los.Year) or
                                     (
                                     year(@AsOfDate) = los.Year and month(@AsOfDate) >= los.Month
                                     )
    ) and
          (
          los.FACILITY_ID = @Facility or los.FACILITY_ID = @Facility2
          ) and
                (
                Disposition in (@Disposition) or 'ALL' in (@Disposition)
                )
) as t1
-- ******************************************
select
     los.Facility
    ,los.FACILITY_ID
    ,los.patient_class_id
    ,los.patient_class
    ,los.Class
    ,los.[Year]
    ,los.[Month]
    ,los.Disposition
    ,  (case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
     + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
     + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
     + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end) [TotLOS]
    ,(case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) [TotLOS1]
    ,(case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end) [TotLOS2]
    ,(case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) [TotLOS3]
    ,(case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end) [TotLOS4]
    ,(case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) [TotLOS5]
    ,(case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end) [TotLOS6]
    ,(case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) [TotLOS7]
    ,(case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end) [TotLOS8]
    ,(case
          when ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end)
                + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
                + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end)
                + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
                + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end)
                + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
                + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end)
                + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
               ) = 0 then 0
          else
    (case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) * 1.00
    / ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
       + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
       + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
       + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
      ) end
     ) [PctLOS1]
    ,(case
          when ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end)
                + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
                + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end)
                + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
                + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end)
                + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
                + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end)
                + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
               ) = 0 then 0
          else
    (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end) * 1.00
    / ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
       + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
       + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
       + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
      ) end
     ) [PctLOS2]
    ,(case
          when ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end)
                + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
                + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end)
                + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
                + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end)
                + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
                + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end)
                + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
               ) = 0 then 0
          else
    (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) * 1.00
    / ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
       + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
       + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
       + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
      ) end
     ) [PctLOS3]
    ,(case
          when ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end)
                + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
                + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end)
                + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
                + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end)
                + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
                + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end)
                + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
               ) = 0 then 0
          else
    (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end) * 1.00
    / ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
       + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
       + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
       + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
      ) end
     ) [PctLOS4]
    ,(case
          when ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end)
                + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
                + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end)
                + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
                + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end)
                + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
                + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end)
                + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
               ) = 0 then 0
          else
    (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) * 1.00
    / ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
       + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
       + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
       + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
      ) end
     ) [PctLOS5]
    ,(case
          when ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end)
                + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
                + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end)
                + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
                + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end)
                + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
                + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end)
                + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
               ) = 0 then 0
          else
    (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end) * 1.00
    / ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
       + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
       + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
       + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
      ) end
     ) [PctLOS6]
    ,(case
          when ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end)
                + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
                + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end)
                + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
                + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end)
                + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
                + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end)
                + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
               ) = 0 then 0
          else
    (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) * 1.00
    / ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
       + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
       + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
       + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
      ) end
     ) [PctLOS7]
    ,(case
          when ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end)
                + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
                + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end)
                + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
                + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end)
                + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
                + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end)
                + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
               ) = 0 then 0
          else
    (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end) * 1.00
    / ((case when '1' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS1 else 0 end) + (case when '2' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS2 else 0 end)
       + (case when '3' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS3 else 0 end) + (case when '4' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS4 else 0 end)
       + (case when '5' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS5 else 0 end) + (case when '6' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS6 else 0 end)
       + (case when '7' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS7 else 0 end) + (case when '8' in (select items from RevCycleDB.dbo.SplitString(@LOS,',')) then los.TotLOS8 else 0 end)
      ) end
     ) [PctLOS8]
    ,los.TotLOS9
    ,los.PctLOS9
    ,los.TotLOS10
    ,los.PctLOS10
    ,los.TotLOS11
    ,los.PctLOS11
    ,los.TotLOS12
    ,los.PctLOS12
    ,los.TotLOS13
    ,los.PctLOS13
    ,los.TotLOS_CON
    ,los.TotLOS14
    ,los.PctLOS14
    ,los.TotLOS15
    ,los.PctLOS15
    ,los.TotLOS16
    ,los.PctLOS16
    ,los.TotLOS17
    ,los.PctLOS17
    ,los.TotLOS18
    ,los.PctLOS18
    ,los.TotLOS19
    ,los.PctLOS19
    ,los.TotLOS20
    ,los.PctLOS20
    ,los.TotLOS_PRE
    ,los.TotLOS21
    ,los.PctLOS21
    ,los.TotLOS22
    ,los.PctLOS22
    ,los.TotLOS23
    ,los.PctLOS23
    ,los.TotLOS24
    ,los.PctLOS24
    ,los.TotLOS25
    ,los.PctLOS25
    ,los.TotLOS26
    ,los.PctLOS26
    ,los.TotLOS_INP
    ,los.TotLOS27
    ,los.PctLOS27
    ,los.TotLOS28
    ,los.PctLOS28
    ,los.TotLOS29
    ,los.PctLOS29
    ,los.TotLOS30
    ,los.PctLOS30
    ,los.TotLOS31
    ,los.PctLOS31
    ,los.TotLOS32
    ,los.PctLOS32
    ,los.TotLOS_NH
    ,los.TotLOS33
    ,los.PctLOS33
    ,los.TotLOS34
    ,los.PctLOS34
    ,los.TotLOS35
    ,los.PctLOS35
    ,los.TotLOS36
    ,los.PctLOS36
    ,los.TotLOS37
    ,los.PctLOS37
    ,los.TotLOS38
    ,los.PctLOS38
    ,los.TotLOS_OBS
into #Temp1
from
#PreWork1 los
--------------------------------------------------------------------------
-- used when selecting multiple facilities and data is needed to be combined
-- update Facility
if @Facility2 <> -1
    begin
        update
            #Temp1
        set
            Facility =
                (
                select
                    stuff((
                          select
                              ', ' + facility
                          from
                              (select distinct Facility as facility from #Temp1) x
                          order by
                              facility
                          for xml path('')
                          )
                          ,1
                          ,1
                          ,''
                         )
                );
        update
            #Temp1
        set
            FACILITY_ID =
                (
                select max(FACILITY_ID)from #Temp1
                );
        update
            #Temp1
        set
            patient_class_id =
                (
                select max(patient_class_id)from #Temp1
                );
    end;
select
    Facility
    ,FACILITY_ID
    ,patient_class_id
    ,patient_class
    ,Class
    ,[Year]
    ,[Month]
    ,Disposition
    ,sum(TotLOS) as TotLOS
    ,sum(TotLOS1) as TotLOS1
    ,sum(PctLOS1) as PctLOS1
    ,sum(TotLOS2) as TotLOS2
    ,sum(PctLOS2) as PctLOS2
    ,sum(TotLOS3) as TotLOS3
    ,sum(PctLOS3) as PctLOS3
    ,sum(TotLOS4) as TotLOS4
    ,sum(PctLOS4) as PctLOS4
    ,sum(TotLOS5) as TotLOS5
    ,sum(PctLOS5) as PctLOS5
    ,sum(TotLOS6) as TotLOS6
    ,sum(PctLOS6) as PctLOS6
    ,sum(TotLOS7) as TotLOS7
    ,sum(PctLOS7) as PctLOS7
    ,sum(TotLOS8) as TotLOS8
    ,sum(PctLOS8) as PctLOS8
    ,sum(TotLOS9) as TotLOS9
    ,sum(PctLOS9) as PctLOS9
    ,sum(TotLOS10) as TotLOS10
    ,sum(PctLOS10) as PctLOS10
    ,sum(TotLOS11) as TotLOS11
    ,sum(PctLOS11) as PctLOS11
    ,sum(TotLOS12) as TotLOS12
    ,sum(PctLOS12) as PctLOS12
    ,sum(TotLOS13) as TotLOS13
    ,sum(PctLOS13) as PctLOS13
    ,sum(TotLOS_CON) as TotLOS_CON
    ,sum(TotLOS14) as TotLOS14
    ,sum(PctLOS14) as PctLOS14
    ,sum(TotLOS15) as TotLOS15
    ,sum(PctLOS15) as PctLOS15
    ,sum(TotLOS16) as TotLOS16
    ,sum(PctLOS16) as PctLOS16
    ,sum(TotLOS17) as TotLOS17
    ,sum(PctLOS17) as PctLOS17
    ,sum(TotLOS18) as TotLOS18
    ,sum(PctLOS18) as PctLOS18
    ,sum(TotLOS19) as TotLOS19
    ,sum(PctLOS19) as PctLOS19
    ,sum(TotLOS20) as TotLOS20
    ,sum(PctLOS20) as PctLOS20
    ,sum(TotLOS_PRE) as TotLOS_PRE
    ,sum(TotLOS21) as TotLOS21
    ,sum(PctLOS21) as PctLOS21
    ,sum(TotLOS22) as TotLOS22
    ,sum(PctLOS22) as PctLOS22
    ,sum(TotLOS23) as TotLOS23
    ,sum(PctLOS23) as PctLOS23
    ,sum(TotLOS24) as TotLOS24
    ,sum(PctLOS24) as PctLOS24
    ,sum(TotLOS25) as TotLOS25
    ,sum(PctLOS25) as PctLOS25
    ,sum(TotLOS26) as TotLOS26
    ,sum(PctLOS26) as PctLOS26
    ,sum(TotLOS_INP) as TotLOS_INP
    ,sum(TotLOS27) as TotLOS27
    ,sum(PctLOS27) as PctLOS27
    ,sum(TotLOS28) as TotLOS28
    ,sum(PctLOS28) as PctLOS28
    ,sum(TotLOS29) as TotLOS29
    ,sum(PctLOS29) as PctLOS29
    ,sum(TotLOS30) as TotLOS30
    ,sum(PctLOS30) as PctLOS30
    ,sum(TotLOS31) as TotLOS31
    ,sum(PctLOS31) as PctLOS31
    ,sum(TotLOS32) as TotLOS32
    ,sum(PctLOS32) as PctLOS32
    ,sum(TotLOS_NH) as TotLOS_NH
    ,sum(TotLOS33) as TotLOS33
    ,sum(PctLOS33) as PctLOS33
    ,sum(TotLOS34) as TotLOS34
    ,sum(PctLOS34) as PctLOS34
    ,sum(TotLOS35) as TotLOS35
    ,sum(PctLOS35) as PctLOS35
    ,sum(TotLOS36) as TotLOS36
    ,sum(PctLOS36) as PctLOS36
    ,sum(TotLOS37) as TotLOS37
    ,sum(PctLOS37) as PctLOS37
    ,sum(TotLOS38) as TotLOS38
    ,sum(PctLOS38) as PctLOS38
    ,sum(TotLOS_OBS) as TotLOS_OBS
	,lag(sum(TotLOS1), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth1]
	,lag(sum(TotLOS2), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth2]
	,lag(sum(TotLOS3), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth3]
	,lag(sum(TotLOS4), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth4]
	,lag(sum(TotLOS5), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth5]
	,lag(sum(TotLOS6), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth6]
	,lag(sum(TotLOS7), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth7]
	,lag(sum(TotLOS8), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth8]
	,lag(sum(TotLOS9), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth9]
	,lag(sum(TotLOS10), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth10]
	,lag(sum(TotLOS11), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth11]
	,lag(sum(TotLOS12), 1, 0) over(partition by FACILITY_ID, patient_class_id, Class, [Year], Disposition order by [Year], [Month]) [PriorMth12]
into #results
from #Temp1
group by
    Facility
    ,FACILITY_ID
    ,patient_class_id
    ,patient_class
    ,Class
    ,[Year]
    ,[Month]
    ,Disposition
order by
    Facility
    ,FACILITY_ID
    ,patient_class_id
    ,patient_class
    ,Class
    ,[Year]
    ,[Month]
    ,Disposition;
select 
	r.Facility
	,r.FACILITY_ID
	,r.patient_class_id
	,r.patient_class
	,r.Class
	,r.[Year]
	,r.[Month]
	,r.Disposition
	,r.TotLOS
	,r.TotLOS1
	,r.PctLOS1
	,r.TotLOS2
	,r.PctLOS2
	,r.TotLOS3
	,r.PctLOS3
	,r.TotLOS4
	,r.PctLOS4
	,r.TotLOS5
	,r.PctLOS5
	,r.TotLOS6
	,r.PctLOS6
	,r.TotLOS7
	,r.PctLOS7
	,r.TotLOS8
	,r.PctLOS8
	,r.TotLOS9
	,r.PctLOS9
	,r.TotLOS10
	,r.PctLOS10
	,r.TotLOS11
	,r.PctLOS11
	,r.TotLOS12
	,r.PctLOS12
	,r.TotLOS13
	,r.PctLOS13
	,r.TotLOS_CON
	,r.TotLOS14
	,r.PctLOS14
	,r.TotLOS15
	,r.PctLOS15
	,r.TotLOS16
	,r.PctLOS16
	,r.TotLOS17
	,r.PctLOS17
	,r.TotLOS18
	,r.PctLOS18
	,r.TotLOS19
	,r.PctLOS19
	,r.TotLOS20
	,r.PctLOS20
	,r.TotLOS_PRE
	,r.TotLOS21
	,r.PctLOS21
	,r.TotLOS22
	,r.PctLOS22
	,r.TotLOS23
	,r.PctLOS23
	,r.TotLOS24
	,r.PctLOS24
	,r.TotLOS25
	,r.PctLOS25
	,r.TotLOS26
	,r.PctLOS26
	,r.TotLOS_INP
	,r.TotLOS27
	,r.PctLOS27
	,r.TotLOS28
	,r.PctLOS28
	,r.TotLOS29
	,r.PctLOS29
	,r.TotLOS30
	,r.PctLOS30
	,r.TotLOS31
	,r.PctLOS31
	,r.TotLOS32
	,r.PctLOS32
	,r.TotLOS_NH
	,r.TotLOS33
	,r.PctLOS33
	,r.TotLOS34
	,r.PctLOS34
	,r.TotLOS35
	,r.PctLOS35
	,r.TotLOS36
	,r.PctLOS36
	,r.TotLOS37
	,r.PctLOS37
	,r.TotLOS38
	,r.PctLOS38
	,r.TotLOS_OBS
	,case when sum(r.PriorMth1) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS1) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth1) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth1) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var1]
	,case when sum(r.PriorMth2) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS2) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth2) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth2) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var2]
	,case when sum(r.PriorMth3) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS3) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth3) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth3) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var3]
	,case when sum(r.PriorMth4) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS4) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth4) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth4) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var4]
	,case when sum(r.PriorMth5) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS5) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth5) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth5) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var5]
	,case when sum(r.PriorMth6) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS6) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth6) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth6) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var6]
	,case when sum(r.PriorMth7) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS7) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth7) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth7) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var7]
	,case when sum(r.PriorMth8) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS8) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth8) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth8) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var8]
	,case when sum(r.PriorMth9) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS9) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth9) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth9) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var9]
	,case when sum(r.PriorMth10) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS10) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth10) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth10) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var10]
	,case when sum(r.PriorMth11) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS11) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth11) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth11) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var11]
	,case when sum(r.PriorMth12) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) = 0 then 0 
		else (sum(r.TotLOS12) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) 
				- sum(r.PriorMth12) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]))
					/ cast(sum(r.PriorMth12) over(partition by FACILITY_ID, patient_class_id, Class, [Year], [Month]) as decimal) end / 2 [MoM_Var12]
into #final_results
from 
	#results r;
declare @user_class int = (select up.USER_CLASS_CD from USER_PROFILE up where up.USER_PROFILE_ID = @ReportUser)
select 
	fr.Facility
	,fr.FACILITY_ID
	,fr.patient_class_id
	,fr.patient_class
	,fr.Class
	,fr.[Year]
	,fr.[Month]
	,fr.Disposition
	,fr.TotLOS
	,fr.TotLOS1
	,fr.PctLOS1
	,fr.TotLOS2
	,fr.PctLOS2
	,fr.TotLOS3
	,fr.PctLOS3
	,fr.TotLOS4
	,fr.PctLOS4
	,fr.TotLOS5
	,fr.PctLOS5
	,fr.TotLOS6
	,fr.PctLOS6
	,fr.TotLOS7
	,fr.PctLOS7
	,fr.TotLOS8
	,fr.PctLOS8
	,fr.TotLOS9
	,fr.PctLOS9
	,fr.TotLOS10
	,fr.PctLOS10
	,fr.TotLOS11
	,fr.PctLOS11
	,fr.TotLOS12
	,fr.PctLOS12
	,fr.TotLOS13
	,fr.PctLOS13
	,fr.TotLOS_CON
	,fr.TotLOS14
	,fr.PctLOS14
	,fr.TotLOS15
	,fr.PctLOS15
	,fr.TotLOS16
	,fr.PctLOS16
	,fr.TotLOS17
	,fr.PctLOS17
	,fr.TotLOS18
	,fr.PctLOS18
	,fr.TotLOS19
	,fr.PctLOS19
	,fr.TotLOS20
	,fr.PctLOS20
	,fr.TotLOS_PRE
	,fr.TotLOS21
	,fr.PctLOS21
	,fr.TotLOS22
	,fr.PctLOS22
	,fr.TotLOS23
	,fr.PctLOS23
	,fr.TotLOS24
	,fr.PctLOS24
	,fr.TotLOS25
	,fr.PctLOS25
	,fr.TotLOS26
	,fr.PctLOS26
	,fr.TotLOS_INP
	,fr.TotLOS27
	,fr.PctLOS27
	,fr.TotLOS28
	,fr.PctLOS28
	,fr.TotLOS29
	,fr.PctLOS29
	,fr.TotLOS30
	,fr.PctLOS30
	,fr.TotLOS31
	,fr.PctLOS31
	,fr.TotLOS32
	,fr.PctLOS32
	,fr.TotLOS_NH
	,fr.TotLOS33
	,fr.PctLOS33
	,fr.TotLOS34
	,fr.PctLOS34
	,fr.TotLOS35
	,fr.PctLOS35
	,fr.TotLOS36
	,fr.PctLOS36
	,fr.TotLOS37
	,fr.PctLOS37
	,fr.TotLOS38
	,fr.PctLOS38
	,fr.TotLOS_OBS
	,(case when @user_class = 1 then (case when fr.MoM_Var1 < -0.15 then 1 when fr.MoM_Var1 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL1]
	,(case when @user_class = 1 then (case when fr.MoM_Var2 < -0.15 then 1 when fr.MoM_Var2 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL2]
	,(case when @user_class = 1 then (case when fr.MoM_Var3 < -0.15 then 1 when fr.MoM_Var3 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL3]
	,(case when @user_class = 1 then (case when fr.MoM_Var4 < -0.15 then 1 when fr.MoM_Var4 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL4]
	,(case when @user_class = 1 then (case when fr.MoM_Var5 < -0.15 then 1 when fr.MoM_Var5 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL5]
	,(case when @user_class = 1 then (case when fr.MoM_Var6 < -0.15 then 1 when fr.MoM_Var6 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL6]
	,(case when @user_class = 1 then (case when fr.MoM_Var7 < -0.15 then 1 when fr.MoM_Var7 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL7]
	,(case when @user_class = 1 then (case when fr.MoM_Var8 < -0.15 then 1 when fr.MoM_Var8 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL8]
	,(case when @user_class = 1 then (case when fr.MoM_Var9 < -0.15 then 1 when fr.MoM_Var9 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL9]
	,(case when @user_class = 1 then (case when fr.MoM_Var10 < -0.15 then 1 when fr.MoM_Var10 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL10]
	,(case when @user_class = 1 then (case when fr.MoM_Var11 < -0.15 then 1 when fr.MoM_Var11 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL11]
	,(case when @user_class = 1 then (case when fr.MoM_Var12 < -0.15 then 1 when fr.MoM_Var12 > 0.15 then 3 else 0 end) else 0 end) [MoM_HL12]
	,(case when @user_class = 1 then (case when fr.MoM_Var1 < -0.15 then 1 when fr.MoM_Var1 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var2 < -0.15 then 1 when fr.MoM_Var2 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var3 < -0.15 then 1 when fr.MoM_Var3 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var4 < -0.15 then 1 when fr.MoM_Var4 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var5 < -0.15 then 1 when fr.MoM_Var5 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var6 < -0.15 then 1 when fr.MoM_Var6 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var7 < -0.15 then 1 when fr.MoM_Var7 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var8 < -0.15 then 1 when fr.MoM_Var8 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var9 < -0.15 then 1 when fr.MoM_Var9 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var10 < -0.15 then 1 when fr.MoM_Var10 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var11 < -0.15 then 1 when fr.MoM_Var11 > 0.15 then 3 else 0 end) else 0 end) 
		+ (case when @user_class = 1 then (case when fr.MoM_Var12 < -0.15 then 1 when fr.MoM_Var12 > 0.15 then 3 else 0 end) else 0 end) [MoM_Sub_Expand]
from 
	#final_results fr
order by
    Facility
    ,FACILITY_ID
    ,patient_class_id
    ,patient_class
    ,Class
    ,[Year] desc
    ,[Month] desc
    ,Disposition
END
GO
