SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO















	--use revcycledb

CREATE procedure [dbo].[rpt_CoderProductivitybyTimetoComplete]
(
	 @Coder varchar(8000)
	,@UserGroup varchar(8000)
	,@ChartStatus varchar(15)
	,@Company varchar(8000)
	,@Facility varchar(8000)
	,@DateType int
	,@START_DATE datetime
	,@END_DATE datetime
	,@Time int
	,@ReportUser int
	,@TimeZone varchar(50)
)
as

begin

	set transaction isolation level read uncommitted
	set nocount on;

	--declare 
	--	@Coder varchar(8000) = '6373,6372,7321,8057,7842,7639,7951,8125,8201,7684,7935,7869,8084,8082,8208,6696,8054,7455,8067,7926,8035,8139,8196,8070,8448,8189,7703,8019,7817,7868,7843,8333,8332,7120,7904,7702,8204,7880,7946,8236,6876,8062,7884,7938,7964,8073,7925,7621,7948,6730,8002,7533,8419,8081,7279,7427,8237,7641,6956,8012,7883,8127,6521,7417,6787,7989,8206,8069,7994,6637,7909,8164,7428,7642,6694,7902,8279,7852,7936,7903,7414,7927,8447,7856,8203,8126,6734,7276,7416,7996,7845,7966,8331,7673,7435,8195,8334,7147,7582,8033,6929,8231,7972,7997,7447,7640,8451,8380,8191,7453,7906,8337,8075,8058,8278,8066,7119,8227,8238,8131,7944,8023,7277,7766,7995,7923,7581,8452,7577,8064,8188,7423,8160,7990,7704,8198,7118,8226,8239,8235,8230,7960,7692,6923,7999,8241,7705,8071,7456,8450,8446,7998,7901,8202,7859,7945,7949,8223,7918,6724,8022,6286,8327,8159,7956,8336,8224,7871,7450,7911,7300,7814,8006,8128,7828,8158,7947,6453,7992'
	--	,@UserGroup varchar(8000) = '125'
	--	,@ChartStatus varchar(15) = '5'
	--	,@Facility varchar(8000) = '-1' --'581,724,672,988,1022,918,947,1248,978,967,916,597,596,598,595,841,948,931,1157,934,932,1156,946,1249,923,1250,966,507,919,1154,926,1053,1083,1055,591,980,629,933,1155,941,1054,741,920,949,930,689,1074,1070,1082,909,1009,1005,1008,1006,1010,1007,1056,1236,1235,1237,466,910,809,1166,703,417,810,257,258,259,544,523,789,261,1127,1230,1110,1153,1228,1229,1108,1096,1160,975,1039,1095,1139,989,974,1136,1106,1149,1109,1137,987,1111,1003,1066,410,1028,1140,973,1030,1143,1159,1145,1144,1029,990,1031,1161,1142,1107,1138,409,1163,1171,1173,1207,1179,1209,1219,1180,1187,1191,1194,1178,1177,1172,1206,1175,1190,1183,1208,1203,1189,1185,1197,1192,1195,1188,1193,1174,1201,1186,1202,1196,276,277,1254,914,529,1013,525,526,527,528,797,1043,490,900,901,532,1068,1162,1158,1150,1151,1152,954,492,925,924,922,1042,795,1198,1223,1199,500,865,1032,427,1184,775,784,888,1012,1091,1231,1036,1034,1035,963,960,961,962,894,881,491,908,637,1226,1224,1225,331,391,402,295,472,361,311,394,327,504,454,455,459,964,368,348,291,370,297,699,307,362,995,359,360,503,347,421,501,505,286,319,554,364,284,358,325,418,426,516,405,727,329,330,334,413,412,296,318,400,401,332,392,337,317,339,447,448,310,893,1164,1165,428,323,353,324,356,972,499,431,313,308,398,399,336,377,376,502,506,335,885,322,320,1204,289,304,404,302,906,755,697,696,246,265,478,950,997,449,811,236,215,970,968,969,680,372,365,300,292,1061,1062,1059,1063,1060,1064,534,1014,905,945,817,818,819,915,710,713,1234,912,721,718,722,1041,719,1088,913,720,993,992,994,1141,1147,787,1019,1075,1076,1077,1078,1079,1080,1081,1020,1181,1017,1018,1148,1182,541,936,921,1122,1121,1170,1123,1119,1117,1118,1116,1115,1114,1120,351,757,1256,1169,461,272,273,765,530,262,388,349,716,715,714,820,771,770,769,1211,1212,1213,1215,1217,1216,1214,389,669,996,733,734,706,725,726,707,708,768,395,965,939,940,983,938,937,985,866,862,861,864,863,1242,826,779,955,984,673,678,971,632,694,695,956,623,957,458,1233,732,1098,1101,1097,1099,1128,237,312,1040,1044,977,1021,1134,876,793,897,896'
	--	,@DateType int = 1
	--	,@START_DATE datetime = '20180426'
	--	,@END_DATE datetime = '20180428'
	--	,@Time int = 0


	declare @CTOffSet VARCHAR(9) = (select CT_OFFSET from TIME_ZONE where DESCRIPTION=@TimeZone);
	declare @Operator varchar(1) = substring(@CTOffSet, 1, 1);
	declare @hms varchar(8) = substring(@CTOffSet, 2, LEN(@CTOffSet)-1); 
	declare @hours decimal(10,2) = datepart(hour, @hms);
	declare @minutes decimal(10,2) = datepart(minute, @hms);
	declare @HrsOffSet decimal(10,2) = cast(@Operator + convert(varchar, datepart(hour, @hms)) as decimal(10,2));
	declare @MinOffSet decimal(10,2) = cast(@Operator + convert(varchar, datepart(minute, @hms)) as decimal(10,2));


	Declare @m_ReportUserClass INT =  (select User_Class_cd from user_profile where user_profile_id = @ReportUser);
	
	
	----------------------------------------------------------------------------------------------------

	if object_id('TempDB..#chart_pre', 'U') is not null drop table #chart_pre
	if object_id('TempDB..#chart_tmp', 'U') is not null drop table #chart_tmp
	if object_id('TempDB..#coder', 'U') is not null drop table #coder
	if object_id('TempDB..#chart_infusion_result', 'U') is not null	drop table #chart_infusion_result
	if object_id('TempDB..#Data1', 'U') is not null	drop table #Data1
	if object_id('TempDB..#Data2', 'U') is not null	drop table #Data2
	if object_id('TempDB..#Data3', 'U') is not null	drop table #Data3
	if object_id('TempDB..#lognotes_tmp', 'U') is not null drop table #lognotes_tmp
	if object_id('TempDB..#Log_Note1', 'U') is not null	drop table #Log_Note1
	if object_id('TempDB..#Log_Note2', 'U') is not null	drop table #Log_Note2
		
	



----------------------------------------------------------------------------------------------------
	
	create table #Data1	 
	(
		CHART_ID int,
		CUID int,
		FACILITY_CHART_ID varchar(20),
		FACILITY_ID int,
		PATIENT_DISPOSITION_ID int,
		CPT_CODE varchar(5),
		QUANTITY int,
		CHARGE_MASTER_ID int,
		TIME_OF_SERVICE datetime,
		CATEGORY  varchar(10)
	);

	create table #CHART_pre
	(
		chart_id int
		,chart_status_id int
		,COMPLETED_BY_USER_PROFILE_ID int
		,facility_chart_id varchar(150)
		,facility_id int
		,patient_disposition_id int
		,TIME_OF_SERVICE datetime
		,COMPLETION_DATE datetime
		,OVERRIDE_FACILITY_LEVEL_ID int
		,FACILITY_LEVEL_ID int
		,PATIENT_CLASS_ID int
		,OVERRIDE_PHYSICIAN_SERVICE_PROC_ID int
		,PHYSICIAN_SERVICE_PROC_ID int
	);
	
	--print 'Section: 00 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	declare @sql varchar(8000)
	set @sql = '
	select 
		chart_id
		,chart_status_id
		,COMPLETED_BY_USER_PROFILE_ID
		,facility_chart_id
		,facility_id
		,patient_disposition_id
		,TIME_OF_SERVICE
		,COMPLETION_DATE
		,OVERRIDE_FACILITY_LEVEL_ID
		,FACILITY_LEVEL_ID
		,PATIENT_CLASS_ID
		,OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		,PHYSICIAN_SERVICE_PROC_ID
	from
		CHART c
	where '
	
	if @DateType = 0
	set @sql = @sql + '
	convert(varchar,dateadd(dd, datediff(dd, 0, dateadd(hh,'  +  convert(varchar(10), @HrsOffSet) + ' , dateadd(mi,'  +  convert(varchar(10), @MinOffSet) +  ', c.time_of_service))), 0),112) between ' + convert(varchar,@START_DATE,112) + ' and ' + '''' + convert(varchar,@END_DATE,112) + ''''  

	if @DateType = 1
	set @sql = @sql + '
		       convert(varchar,dateadd(dd, datediff(dd, 0, dateadd(hh,'  +  convert(varchar(10), @HrsOffSet) + ' , dateadd(mi,'  +  convert(varchar(10), @MinOffSet) +  ', c.COMPLETION_DATE))), 0),112) between ' + convert(varchar,@START_DATE,112) + ' and ' + '''' + convert(varchar,@END_DATE,112) + ''''  

	set @sql = @sql + '
		and c.chart_status_id in (select items from dbo.SplitString(' + '''' + @ChartStatus + '''' + ',' + '''' + ',' + '''' + '))' --+ '
		--and c.facility_id in (select items from revcycledb.dbo.SplitString(' + '''' + @Facility + '''' + ',' + '''' + ',' + '''' + '))'
		--and c.COMPLETED_BY_USER_PROFILE_ID in (select items from revcycledb.dbo.SplitString(' + '''' + @Coder + '''' + ',' + '''' + ',' + '''' + '))'

--	print @sql
 
-- select * from #CHART_pre

	insert into #CHART_pre
	exec (@sql)
	
	--print 'Section: 01 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	create table #coder
	(
		CUID int		
	);
	



insert into #coder

select distinct  
	c.COMPLETED_BY_USER_PROFILE_ID as CUID
	from 	
	#CHART_pre c 
where 
exists ( SELECT 1							
			  FROM USER_PROFILE 			
			  WHERE 
			  USER_GROUP_ID in (select items from dbo.SplitString(@UserGroup,','))	
			  and is_active = 'Y'				
			  and c.COMPLETED_BY_USER_PROFILE_ID = user_profile_id 
			  UNION				
			  SELECT 1				
			  FROM USER_GROUP_TO_USER_PROFILE ugup ,				
			  user_profile up				
			  where up.user_profile_id = ugup.user_profile_id				
			  and up.is_active = 'Y'				
			  AND ugup.USER_GROUP_ID in (select items from dbo.SplitString(@UserGroup,','))	
			  and c.COMPLETED_BY_USER_PROFILE_ID = ugup.user_profile_id
			)

and (@Coder = '-1' or COMPLETED_BY_USER_PROFILE_ID in (select items from dbo.SplitString(@Coder,',')))			 				
and 1 = (													
	SELECT 1 													
	FROM USER_PROFILE													
	WHERE USER_PROFILE_ID = @ReportUser													
	and is_active = 'Y'												
	and USER_GROUP_ID in (1,116,203) 												
													
													
	UNION													
													
	SELECT 1													
	FROM USER_GROUP_TO_USER_PROFILE ugup,													
	user_profile up													
	where up.user_profile_id = ugup.user_profile_id													
	and up.is_active = 'Y'													
	and ugup.USER_PROFILE_ID = @ReportUser													
	AND ugup.USER_GROUP_ID in (1,116,203)												
	)	

	
union				


select distinct  
	c.COMPLETED_BY_USER_PROFILE_ID as CUID
	from 	
	#CHART_pre c 
where 
exists ( SELECT 1							
			  FROM USER_PROFILE 			
			  WHERE 
			  USER_GROUP_ID in (select items from dbo.SplitString(@UserGroup,','))	
			  and is_active = 'Y'
			  and USER_CLASS_CD = 4				
			  and c.COMPLETED_BY_USER_PROFILE_ID = user_profile_id 
			  UNION				
			  SELECT 1				
			  FROM USER_GROUP_TO_USER_PROFILE ugup ,				
			  user_profile up				
			  where up.user_profile_id = ugup.user_profile_id				
			  and up.is_active = 'Y'
			  and up.USER_CLASS_CD = 4				
			  AND ugup.USER_GROUP_ID in (select items from dbo.SplitString(@UserGroup,','))	
			  and c.COMPLETED_BY_USER_PROFILE_ID = ugup.user_profile_id
			)

and (@Coder = '-1' or COMPLETED_BY_USER_PROFILE_ID in (select items from dbo.SplitString(@Coder,',')))			 				
and 1 = (													
	SELECT 1 													
	FROM USER_PROFILE													
	WHERE USER_PROFILE_ID = @ReportUser													
	and is_active = 'Y'												
	and USER_CLASS_CD = 4
	)	

	

create nonclustered index idx_CUID on #coder (CUID)
	


	----------------------------------------------------------------------------------------------------

	select 
		chart_id
		,chart_status_id
		,COMPLETED_BY_USER_PROFILE_ID
		,facility_chart_id
		,facility_id
		,patient_disposition_id
		,TIME_OF_SERVICE
		,COMPLETION_DATE
		,OVERRIDE_FACILITY_LEVEL_ID
		,FACILITY_LEVEL_ID
		,PATIENT_CLASS_ID
		,OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		,PHYSICIAN_SERVICE_PROC_ID
	into #CHART_tmp
	from #CHART_pre
	where 
		(@Facility = '-1' or facility_id in (select items from dbo.SplitString(@Facility,',')))
		and COMPLETED_BY_USER_PROFILE_ID in (select CUID from #coder)
		and facility_id in ( 
					SELECT sa.facility_id						
					FROM FACILITY_USER_AUTHORIZATION  FUA WITH (NOLOCK),						
					USER_PROFILE UP	WITH (NOLOCK),
					service_agreement sa WITH (NOLOCK)					
					WHERE 
					fua.user_profile_id = up.user_profile_id						
					and fua.facility_id = sa.facility_id
				    and (@Company = '-1' or sa.company_id in (select items from dbo.SplitString(@Company,',')))
					and UP.IS_ACTIVE = 'Y'						
					and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
					and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE												
					and FUA.USER_PROFILE_ID = @ReportUser
					)


	create nonclustered index chart_id on #CHART_tmp (CHART_ID)
	
	

	--print 'Section: 02 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	-- FP/FP*****************************************	
	insert into #Data1	
	select 
		c.chart_id,
		c.COMPLETED_BY_USER_PROFILE_ID as CUID, 
		c.facility_chart_id as FACILITY_CHART_ID, 
		c.facility_id,
		c.patient_disposition_id, 
		cm.CPT_CODE , 
		fpe.quantity,
		cm.charge_master_id,
		coalesce(fpe.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
		'FP/FP'
	from 
		charge_master cm,
		#CHART_tmp c
		left join facility_procedure_evaluation fpe on c.chart_id = fpe.chart_id 
	where 
		cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID;
	
	
	--print 'Section: 03 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	-- FP/PI*****************************************	
	insert into #Data1	
	select 
		c.chart_id,
		c.COMPLETED_BY_USER_PROFILE_ID as CUID, 
		c.facility_chart_id as FACILITY_CHART_ID, 
		c.facility_id,
		c.patient_disposition_id, 
		cm.CPT_CODE,
		cpi.UNITS Quantity,
		cm.CHARGE_MASTER_ID,
		c.TIME_OF_SERVICE,
		'FP/PI'
	from 
		charge_master cm,
		#CHART_tmp c,
		CHART_PACKAGE_ITEM cpi, 
		CHARGE_PACKAGE_ITEM ci
	where 
		c.chart_ID = cpi.chart_ID
		and ci.CHARGE_PACKAGE_ITEM_ID = cpi.CHARGE_PACKAGE_ITEM_ID
		and cm.CHARGE_MASTER_ID = ci.CHARGE_MASTER_ID;
	
	
	--print 'Section: 04 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	-- FP/AS*****************************************
	insert into #Data1	
	select 
		c.chart_id,
		c.COMPLETED_BY_USER_PROFILE_ID as CUID, 
		c.facility_chart_id as FACILITY_CHART_ID, 
		c.facility_id,
		c.patient_disposition_id, 
		cm.CPT_CODE , 
		cas.UNITS Quantity,
		cm.charge_master_id,
		c.TIME_OF_SERVICE as TIME_OF_SERVICE,
		'FP/AS'
	from 
		charge_master cm,
		#CHART_tmp c,
		CHART_ADDITIONAL_SUPPLIES cas  
	where 
	c.chart_id = cas.chart_id 
	and cm.CHARGE_MASTER_ID = cas.CHARGE_MASTER_ID;
	
	
	--print 'Section: 05 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	-- FP/OP*****************************************
	insert into #Data1		
	select 
		c.chart_id,
		c.COMPLETED_BY_USER_PROFILE_ID as CUID, 
		c.facility_chart_id as FACILITY_CHART_ID, 
		c.facility_id,
		c.patient_disposition_id, 
		cm.CPT_CODE ,  
		oer.[UNITS] Quantity,
		cm.CHARGE_MASTER_ID,
		coalesce(oer.[DATE_OF_SERVICE], c.TIME_OF_SERVICE) TIME_OF_SERVICE,
		'FP/OP'
	from 
		charge_master cm,
		#CHART_tmp c,
		CHART_OBSERVATION_ENCOUNTER_RESULT oer
	where 
		c.chart_ID = oer.chart_ID
		and cm.CHARGE_MASTER_ID = oer.CHARGE_MASTER_ID;
	
	
	--print 'Section: 06 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	select * 
	into #chart_infusion_result
	from chart_infusion_result 
	where CHART_ID in (select distinct chart_id from #CHART_tmp)

	-- IP/IP*****************************************
	insert into #Data1
	select 
		c.chart_id,
		c.COMPLETED_BY_USER_PROFILE_ID as CUID, 
		c.facility_chart_id as FACILITY_CHART_ID, 
		c.facility_id,
		c.patient_disposition_id, 
		cm.CPT_CODE , 
		cir.UNITS Quantity,
		cm.charge_master_id,
		coalesce(cir.DATE_OF_SERVICE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
		'IP/IP'
	from 
		charge_master cm,
		#CHART_tmp c,
		#chart_infusion_result cir
	where 
		c.chart_id = cir.chart_id 
		and cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID;
	
	
	--print 'Section: 07 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	-- PP/PP*****************************************
	insert into #Data1	
	select 
		c.chart_id,
		c.COMPLETED_BY_USER_PROFILE_ID as CUID, 
		c.facility_chart_id as FACILITY_CHART_ID, 
		c.facility_id,
		c.patient_disposition_id, 
		cm.CPT_CODE ,  
		ppe.Quantity,
		cm.CHARGE_MASTER_ID,
		coalesce(ppe.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
		'PP/PP'
	from 
		charge_master cm,
		#CHART_tmp c,
		physician_procedure_evaluation ppe 
	where 
		c.chart_ID = ppe.chart_ID
		and cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID;
	
	
	--print 'Section: 08 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	-- /CA*****************************************
	insert into #Data1	
	select 
		c.chart_id,
		c.COMPLETED_BY_USER_PROFILE_ID as CUID, 
		c.facility_chart_id as FACILITY_CHART_ID, 
		c.facility_id,
		c.patient_disposition_id, 
		cm.CPT_CODE ,  
		ca.Quantity,
		cm.CHARGE_MASTER_ID,
		coalesce(ca.REVISED_DATE_OF_SERVICE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
		'CA'
	from 
		charge_master cm,
		#CHART_tmp c,
		chart_adjustment ca 
	where 
		c.chart_ID = ca.chart_ID
		and cm.CHARGE_MASTER_ID = ca.CHARGE_MASTER_ID;
	
	
	--print 'Section: 09 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	-- FL/FL*****************************************
	insert into #Data1	
	select 
		c.chart_id,
		c.COMPLETED_BY_USER_PROFILE_ID as CUID, 
		c.facility_chart_id as FACILITY_CHART_ID, 
		c.facility_id,
		c.patient_disposition_id, 
		fl.CPT_CODE , 
		1 Quantity,
		coalesce((select max(cm.charge_master_id) 
								from charge_master cm 
								where 
								cm.BILLING_CODE = fl.BILLING_CODE  
								AND    cm.CPT_CODE = fl.CPT_CODE
								AND    cm.SERVICE_AGREEMENT_ID = fl.SERVICE_AGREEMENT_ID
								AND    cm.CHARGE_MASTER_USAGE_CODE = 2
								and    cm.EFFECTIVE_DATE <= getdate()
								and    cm.EXPIRATION_DATE >= getdate()
								and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID or cm.patient_class_id = -1)),null) as charge_master_id, 
		c.TIME_OF_SERVICE,
		'FL/FL'
	from 
		#CHART_tmp c,
		facility_level fl  
	where 
		(case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 then c.FACILITY_LEVEL_ID
						when c.OVERRIDE_FACILITY_LEVEL_ID = '' then c.FACILITY_LEVEL_ID
						else c.OVERRIDE_FACILITY_LEVEL_ID
						end) = fl.FACILITY_LEVEL_ID;
	
	
	--print 'Section: 10 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	-- PL/PL*****************************************
	insert into #Data1	
	select 
		c.chart_id,
		c.COMPLETED_BY_USER_PROFILE_ID as CUID, 
		c.facility_chart_id as FACILITY_CHART_ID, 
		c.facility_id,
		c.patient_disposition_id,
		(select psp.CPT_CODE 
					from physician_service_procedure psp
					where psp.PHYSICIAN_SERVICE_PROC_ID = 
						(case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
								and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
							then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
							else c.PHYSICIAN_SERVICE_PROC_ID end)
					) as CPT_CD,
		1 as Quantity,
			coalesce((select max(cm.charge_master_id) 
							from charge_master cm 
							where 
							cm.BILLING_CODE = psp.BILLING_CODE  
							AND    cm.CPT_CODE = psp.CPT_CODE
							AND    cm.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
							AND    cm.CHARGE_MASTER_USAGE_CODE = 4
							and    cm.EFFECTIVE_DATE <= getdate()
							and    cm.EXPIRATION_DATE >= getdate()
							and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID or cm.patient_class_id = -1)),null) 
						as charge_master_id, 
		c.TIME_OF_SERVICE,
		'PL/PL'
	from 
		#CHART_tmp c,
		physician_service_procedure psp  
	where 
		(case 
						when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
							and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
						then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
						else c.PHYSICIAN_SERVICE_PROC_ID end
			 ) = psp.PHYSICIAN_SERVICE_PROC_ID;
	
	
	--print 'Section: 11 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	-- /AP*****************************************
	insert into #Data1		
	select 
		c.chart_id,
		c.COMPLETED_BY_USER_PROFILE_ID as CUID, 
		c.facility_chart_id as FACILITY_CHART_ID, 
		c.facility_id,
		c.patient_disposition_id, 
		cm.CPT_CODE,
		cap.QUANTITY,
		cm.CHARGE_MASTER_ID,
		coalesce(cap.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
		'AP'
	from 
		charge_master cm,
		#CHART_tmp c,
		CHART_ADDITIONAL_PROCEDURE cap  
	where 
		c.chart_ID = cap.chart_ID
		and cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID;


	create nonclustered index idx_CHART_ID on #Data1 (CHART_ID)
	
	
	--print 'Section: 12 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	select 
		ln.log_note_id, ln.chart_id, ln.completion_date, 
		ln.COMPLETED_BY_USER_ID, ln.CATEGORY_ID
	into #lognotes_tmp
	from 
		log_note ln
	where 
		ln.CHART_ID in (select distinct d1.CHART_ID from #Data1 d1)

	create nonclustered index idx_CATEGORY_ID on #lognotes_tmp (CATEGORY_ID)


	--print 'Section: 13 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	select 
		ln.log_note_id, ln.chart_id, ln.completion_date, 
		ln.COMPLETED_BY_USER_ID, ln.CATEGORY_ID , lnc.[DESCRIPTION]
	into #Log_Note1
	from 
		#lognotes_tmp ln,
		log_note_category lnc
	where 
		ln.CATEGORY_ID = lnc.LOG_NOTE_CATEGORY_ID
		and lnc.LOG_NOTE_CATEGORY_ID in (2,6,10,11,12,13,14,15,22,23,26)
	

	
	
	
	--print 'Section: 14 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	select * 	
	into #Log_Note2			
	from	
	(
	select 
		ln.log_note_id, ln.chart_id, ln.completion_date, 
		ln.COMPLETED_BY_USER_ID, ln.CATEGORY_ID , lnc.[DESCRIPTION]
	from 
		log_note ln  ,
		log_note_category lnc
	where 
		ln.CATEGORY_ID = lnc.LOG_NOTE_CATEGORY_ID
		and ln.CATEGORY_ID = 3 
		and ln.summary = 'Chart approved.'		
		and ln.CHART_ID in (select distinct CHART_ID from #Data1)
	) t4;
	
	
	--print 'Section: 15 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	;with ctePending 
	as (
		select ln1.chart_id, max(ln1.completion_date) as completion_date
		from #Log_Note1 ln1
		where ln1.category_id = 6
		group by ln1.chart_id
		)

	DELETE #Log_Note1	
	FROM ctePending p
	  INNER JOIN #Log_Note1 ln1
	  ON ln1.chart_id = p.chart_id 
	  and ln1.COMPLETION_DATE <= p.completion_date;
	
	
	--print 'Section: 16 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	select * 	
	into #Data2		
	from	
	(	
	select 
		d.chart_id,
		d.CUID, 
		d.FACILITY_CHART_ID, 
		d.facility_id,
		d.patient_disposition_id,

		(select max(completion_date) from #LOG_NOTE1 
			where chart_id = d.chart_id
			and completed_by_user_id = d.CUID
			and category_id = 10 )  as max_start_date,

		(select min(completion_date) from #LOG_NOTE1 
			where chart_id = d.chart_id
			and completed_by_user_id = d.cuid
			and description like '%complete%' )  as min_start_date,

		(select max(completion_date) from #LOG_NOTE1
			where chart_id = d.chart_id
			and completed_by_user_id = d.cuid
			and category_id = 2 )  as completed_date,
 
 
 
		d.CPT_CODE, 
		d.quantity,
		d.charge_master_id,
		d.time_of_service ,
		d.category,

		--ACS-13071 DAH 09/13/18 added max, this was corrected going forward in ACS-12329,
		-- small numbers of records with multiple approved records with same date/time, ex. chart chart_id = 52871574 
	 (select max(COMPLETED_BY_USER_ID) from #Log_Note2  														
	  where chart_id = d.chart_id
	  and completion_date = ( select max(completion_date) from #Log_Note2
									 where d.chart_id = chart_id ) 
	  ) as AUID

	from 
		#data1 d 
	) t3;
	
	
	--print 'Section: 17 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	select distinct *
	,case when @m_ReportUserClass <> 4 then cast(chart_id as varchar(20)) else Facility_CHART_ID end as CHART_ID_1
	,(case when t4.Time_in_Seconds < 16 then 1
			when t4.Time_in_Seconds between 16 and 30 then 2
			when t4.Time_in_Seconds between 31 and 45 then 3
			when t4.Time_in_Seconds between 46 and 60 then 4
		else 99 end) [Time]
	into #Data3	
	from	
	(
	select 
		up.last_name  +', ' + up.First_name  as Coder,
		up2.last_name  +', ' + up2.First_name  as Auditor,
		chart_id as CHART_ID,
		facility_chart_id as Facility_Chart_ID,
		f.[name] as Facility_Name,

		case when max_start_date is null then min_start_date else max_start_date end as Coding_Last_Start_Date_Time,
		completed_date as Coding_Complete_Date_Time,

		CAST( ROUND((DATEDIFF(SECOND, case when max_start_date is null then min_start_date else max_start_date end, completed_date)) * 1.00 / 60, 2) AS FLOAT)  as Time_in_Minutes, 
		CAST( ROUND((DATEDIFF(SECOND, case when max_start_date is null then min_start_date else max_start_date end, completed_date)) * 1.00 , 2) AS FLOAT)  as Time_in_Seconds, 
 
			pd.description as Patient_Disposition,
		case when pd.description = 'Inpatient' then 'IP'
				when pd.description = 'Observation' then 'OBS'
		else 'ED' end as Disposition_Category,
			d.CPT_CODE,	
			d.QUANTITY,
			cm.description as [Procedure],
			d.time_of_service,
		d.category
	 from 
		#Data2 d
		inner join user_profile up on d.CUID = up.user_profile_id 
		left join user_profile up2 on d.AUID = up2.user_profile_id 
		inner join facility f  on d.facility_id = f.fACILITY_ID 
		inner join PATIENT_DISPOSITION pd on d.patient_disposition_id = pd.patient_disposition_id
		inner join charge_master cm on d.charge_master_id = cm.charge_master_id 
	 where 
		completed_date is not null
	 ) t4
	 
	 
	 --print 'Section: 18 ' + convert(varchar, getdate(), 121)
	 ----------------------------------------------------------------------------------------------------
	 
	

	select 
	    'ALL' All_Records
		,Coder
		,Auditor
		,CHART_ID_1 as CHART_ID
		,Facility_Name
		,Coding_Last_Start_Date_Time
		,Coding_Complete_Date_Time
		,Time_in_Minutes
		,Time_in_Seconds
		,Patient_Disposition
		,Disposition_Category
		,CPT_CODE
		,QUANTITY
		,[Procedure]
		,TIME_OF_SERVICE
		,CATEGORY
		,[Time]
	from 
		#Data3 
	where 
		(@Time = 0 or [Time] = @Time)

	
	--print 'Section: 19 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------


end







GO
GRANT EXECUTE ON  [dbo].[rpt_CoderProductivitybyTimetoComplete] TO [dbx_ExecuteReportProcs]
GO
