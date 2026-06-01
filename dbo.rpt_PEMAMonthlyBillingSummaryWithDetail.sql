SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[rpt_PEMAMonthlyBillingSummaryWithDetail]
	@ControlID int,
	@FacilityID int
as
begin

exec RCMSQL01.RevCycleDB.dbo.RVU_REPORTING_BILLED_CHART_UPDATE
	@Billing_Control_ID = @ControlID, 
	@facility_ID = @FacilityID;

if object_id('TempDB..#RVUReportingPreProcessCharts', 'U') is not null
begin
	drop table #RVUReportingPreProcessCharts
end;


if object_id('TempDB..#RVUReportingPreProcessSummary', 'U') is not null
begin
	drop table #RVUReportingPreProcessSummary
end;
CREATE TABLE #RVUReportingPreProcessSummary
(
	[facility_ID] [int] NULL,
	[SEQ] [int] NOT NULL,
	[AttendingBusinessUnit] [int] NULL,
	[BUSINESS_UNIT_NAME] [varchar](50) NOT NULL,
	[FACILITY_PROF_ID] [int] NOT NULL,
	[name] [varchar](52) NULL,
	[class] [varchar](2) NULL,
	[ProcPhysID] [int] NOT NULL,
	[quantity] [int] NULL,
	[chart_id] [int] NOT NULL,
	[facility_chart_id] [varchar](20) NULL,
	[WorkRVU] [decimal](22, 2) NULL,
	[TotalRVU] [decimal](22, 2) NULL,
	[NURSE_PRACTITIONER_ID] [int] NULL,
	[cpt_code] [varchar](5) NULL,
	[DESCRIPTION] [varchar](100) NULL,
	[CHARGE_AMOUNT] [money] NULL,
	[ControlID] [int] NOT NULL,
	[TotalCharge] [money] NULL,
	[Quantity_PL] [int] NOT NULL,
	[Quantity_PP] [int] NOT NULL,
	[ReportCategory] [varchar](20) NOT NULL,
	[PatientCount] [int] NOT NULL,
	[ChargeCount] [int] NOT NULL
)


if object_id('TempDB..#RVUReportingPreProcessSubreport', 'U') is not null
begin
	drop table #RVUReportingPreProcessSubreport
end;
CREATE TABLE #RVUReportingPreProcessSubreport
(
	[SEQ] [int] NOT NULL,
	[Facility_ID] [int] NOT NULL,
	[AttendingBusinessUnit] [int] NULL,
	[BUSINESS_UNIT_NAME] [varchar](50) NOT NULL,
	[FACILITY_PROF_ID] [int] NOT NULL,
	[name] [varchar](52) NULL,
	[class] [varchar](2) NULL,
	[ProcPhysID] [int] NULL,
	[quantity] [int] NULL,
	[chart_id] [int] NOT NULL,
	[PatientName] [varchar](62) NULL,
	[Medical_Record_Num] [varchar](20) NULL,
	[time_of_service] [datetime] NULL,
	[facility_chart_id] [varchar](20) NULL,
	[WorkRVU] [decimal](22, 2) NULL,
	[TotalRVU] [decimal](22, 2) NULL,
	[NURSE_PRACTITIONER_ID] [int] NULL,
	[cpt_code] [varchar](5) NULL,
	[DESCRIPTION] [varchar](100) NULL,
	[CHARGE_AMOUNT] [money] NULL,
	[ControlID] [int] NOT NULL,
	[TotalCharge] [money] NULL,
	[Quantity_PL] [int] NULL,
	[Quantity_PP] [int] NULL,
	[ReportCategory] [varchar](20) NOT NULL,
	[PatientCount] [int] NOT NULL
)


if object_id('TempDB..#tempCategory', 'U') is not null
begin
	drop table #tempCategory
end;

CREATE TABLE #tempCategory
(
	tempCategory varchar(40)
)

insert into #tempCategory (tempCategory) values('(1) MD Only')
insert into #tempCategory (tempCategory) values('(2) MD w/ MLP')
insert into #tempCategory (tempCategory) values('(3) Plastics')
insert into #tempCategory (tempCategory) values('(4) Excluded FX Care')
	
select 
	c.chart_id, c.facility_chart_id, c.physician_id, c.nurse_practitioner_id, 
	c.facility_ID, c.patient_first_name, c.patient_last_name, c.medical_record_num, c.time_of_service,
	pbc.RVU_REPORTING_BILLING_CONTROL_ID 
into #RVUReportingPreProcessCharts
from chart c, RCMSQL01.RevCycleDB.dbo.RVU_REPORTING_BILLED_CHARTS pbc
where c.chart_id = pbc.CHART_ID and c.facility_id = @facilityID and pbc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID

CREATE NONCLUSTERED INDEX ix_missing1
ON #RVUReportingPreProcessCharts (chart_id, physician_id, facility_ID)
INCLUDE (facility_chart_id, nurse_practitioner_id, patient_first_name, patient_last_name, medical_record_num, time_of_service)

-- Preprocess data to be used for the subreport.

/*
	The series of INSERT statements below used to be UNIONed together in a single query which was not performing well.
	That single large query was executed in a loop in the subreport.  Now the data is preprocessed all at once here, allowing the subreport loop to execute a small, efficient query.
	The commented lines listed below are found in each INSERT query and are leftover from the old query.  They are no longer necessary:
 
	 (in the FROM statement):
		--RVU_REPORTING_BILLED_CHARTS pbc	-- not necessary to join this table since this filtering is represented by joining to #RVUReportingPreProcessCharts instead of CHART

	 (in the WHERE statement):
		(not needed since not joining to RVU_REPORTING_BILLED_CHARTS pbc)
			--and pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
			--and c.chart_id = pbc.chart_id

		--and fp.FACILITY_PROF_ID = @FacilityProfID		--(not appropriate here when preprocessing all data, but is used in the modified query in the subreport)

	 (at the end of the large old UNIONed outer query):
		--) x											--(not needed since these queries are no longer UNIONed)
		--where x.ReportCategory = @ReportCategory		--(not appropriate here when preprocessing all data, but is used in the modified query in the subreport)
		--ORDER BY x.Time_Of_Service, x.Chart_ID		--(not necessary here when preprocessing all data, but is used in the modified query in the subreport)


	Other commented lines seen in each INSERT query were already commented out in the old version.
*/

	-- E&M - No Nurse Practitioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider in the FACILITY_PROF table, use EPIC service provider
	INSERT INTO #RVUReportingPreProcessSubreport
		select distinct 
		sp.SEQ,
		fp.Facility_ID,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,		
		fp.FACILITY_PROF_ID, fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		sp.physician_id as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.Patient_last_name + ', ' + c.Patient_First_Name as PatientName,
		c.Medical_Record_Num,
		c.time_of_service,
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then 0
			when pb.BUSINESS_UNIT_NAME like '%5c%' then 0
			when  fp.role_id = 1  then 1
			else 1 end) PatientCount			
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
and		c.facility_id = @facilityID
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
--and		(c.PHYSICIAN_ID = fp.FACILITY_PROF_ID or c.NURSE_PRACTITIONER_ID = fp.FACILITY_PROF_ID)	
--and		sp.physician_id = fp.FACILITY_PROF_ID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
--and		sp.facility_chart_id = epic.HSP_ACCOUNT_ID
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and		ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291'))
and		fp.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID 
and		fp.FACILITY_ID = @facilityID
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		c.NURSE_PRACTITIONER_ID <= 0
and		fp.ROLE_ID <> 1
--and		fp.FACILITY_PROF_ID = @FacilityProfID


	-- E&M - With Nurse Practitioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider in the FACILITY_PROF table, use EPIC billing provider
	INSERT INTO #RVUReportingPreProcessSubreport
		select distinct 
		sp.SEQ,
		fp.Facility_ID,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,		
		fp.FACILITY_PROF_ID, fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		sp.physician_id as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.Patient_last_name + ', ' + c.Patient_First_Name as PatientName,
		c.Medical_Record_Num,
		c.time_of_service,
		c.facility_chart_id,
		--(CASE when fp.facility_prof_id = c.nurse_practitioner_id then sp.quantity * rvu.WORK_RVU else 0) as WorkRVU, 
		--(CASE when fp.facility_prof_id = c.nurse_practitioner_id then sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT else 0) as TotalRVU,
		0 as WorkRVU,
		0 as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp2.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then 0
			when pb.BUSINESS_UNIT_NAME like '%5c%' then 0
			when fp.role_id = 1  then 1
			else 1 end) PatientCount			
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		FACILITY_PROFESSIONAL fp2 WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
and		c.facility_id = @facilityID
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
--and		(c.PHYSICIAN_ID = fp.FACILITY_PROF_ID or c.NURSE_PRACTITIONER_ID = fp.FACILITY_PROF_ID)	
--and		sp.physician_id = fp.FACILITY_PROF_ID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
--and		sp.facility_chart_id = epic.HSP_ACCOUNT_ID
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and		ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291'))
and		fp2.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID and fp2.FACILITY_ID = @facilityID and (fp2.INACTIVE_IND is null or fp2.INACTIVE_IND = 0)
and		fp.EMPLOYEE_IDENTIFIER = epic.CHARGE_ENTRY_ID
and		fp.FACILITY_ID = @facilityID
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		c.NURSE_PRACTITIONER_ID > 0	
and		fp2.ROLE_ID = 1
--and		fp.FACILITY_PROF_ID = @FacilityProfID


	-- E&M - No Nurse Practioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider not in the FACILITY_PROF table, use CCS Physician from Chart
	INSERT INTO #RVUReportingPreProcessSubreport
		select distinct 	
		sp.SEQ,
		fp.Facility_ID,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,		
		fp.FACILITY_PROF_ID, fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		sp.physician_id as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.Patient_last_name + ', ' + c.Patient_First_Name as PatientName,
		c.Medical_Record_Num,
		c.time_of_service,
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then 0
			when pb.BUSINESS_UNIT_NAME like '%5c%' then 0
			when  fp.role_id = 1  then 1
			else 1 end) PatientCount			
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
and		c.facility_id = @facilityID
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
--and		(c.PHYSICIAN_ID = fp.FACILITY_PROF_ID or c.NURSE_PRACTITIONER_ID = fp.FACILITY_PROF_ID)	
and		sp.physician_id = fp.FACILITY_PROF_ID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		sp.facility_chart_id = epic.FACILITY_CHART_ID
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and		ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291'))
and		epic.SERVICE_PROVIDER_ID not in (SELECT	fp2.EMPLOYEE_IDENTIFIER FROM FACILITY_PROFESSIONAL fp2 
								 WHERE		fp2.FACILITY_ID = @facilityID
								 AND		(fp2.INACTIVE_IND is NULL or fp2.INACTIVE_IND = 0))
and		fp.FACILITY_ID = @facilityID
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		c.NURSE_PRACTITIONER_ID <= 0
and		fp.ROLE_ID <> 1
--and		fp.FACILITY_PROF_ID = @FacilityProfID


	-- E&M - With Nurse Practioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider not in the FACILITY_PROF table, use CCS Physician from Chart
	INSERT INTO #RVUReportingPreProcessSubreport
		select distinct 
		sp.SEQ,
		fp.Facility_ID,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,		
		fp.FACILITY_PROF_ID, fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		sp.physician_id as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.Patient_last_name + ', ' + c.Patient_First_Name as PatientName,
		c.Medical_Record_Num,
		c.time_of_service,
		c.facility_chart_id,
		0 as WorkRVU,
		0 as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then 0
			when pb.BUSINESS_UNIT_NAME like '%5c%' then 0
			when  fp.role_id = 1  then 1
			else 1 end) PatientCount			
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		FACILITY_PROFESSIONAL fp3 WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where		sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
and		c.facility_id = @facilityID
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		c.physician_id = fp.FACILITY_PROF_ID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
--and		sp.facility_chart_id = epic.HSP_ACCOUNT_ID
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and		ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291')
									and		ep.QUANTITY > 1)
and		epic.CHARGE_ENTRY_ID not in (SELECT	fp2.EMPLOYEE_IDENTIFIER FROM FACILITY_PROFESSIONAL fp2 
								 WHERE		fp2.FACILITY_ID = @facilityID
								 AND		(fp2.INACTIVE_IND is NULL or fp2.INACTIVE_IND = 0))
and		fp3.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID and fp3.FACILITY_ID = @facilityID and (fp3.INACTIVE_IND is null or fp3.INACTIVE_IND = 0)
and		fp.FACILITY_ID = @facilityID
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		c.NURSE_PRACTITIONER_ID > 0
and		fp3.ROLE_ID = 1
--and		fp.FACILITY_PROF_ID = @FacilityProfID
	

	-- E&M - SENT_PROCEDURE with NO match on EPIC at account level use CCS Physician from Chart
	INSERT INTO #RVUReportingPreProcessSubreport
		select distinct 
		sp.SEQ,
		fp.Facility_ID,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,		
		fp.FACILITY_PROF_ID, fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		sp.physician_id as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.Patient_last_name + ', ' + c.Patient_First_Name as PatientName,
		c.Medical_Record_Num,
		c.time_of_service,
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when  fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then 0
			when pb.BUSINESS_UNIT_NAME like '%5c%' then 0
			when fp.role_id = 1  then 1
			else 1 end) PatientCount
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc
		--, RVU_REPORTING_BILLED_CHARTS pbc
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
and		c.facility_id = @facilityID
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		c.physician_id = fp.FACILITY_PROF_ID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
--and		sp.facility_chart_id = epic.HSP_ACCOUNT_ID
and     	(SELECT COUNT(*) from	ASA_PHYSICIAN_CHARGES epic
		 WHERE	epic.FACILITY_CHART_ID = sp.facility_chart_id 
		 AND	epic.CPT_CODE IN  ('99281','99282','99283','99284','99285','99291')) = 0
and		fp.FACILITY_ID = @facilityID
and		sp.PHYSICIAN_ID = fp.FACILITY_PROF_ID 
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		fp.FACILITY_PROF_ID = @FacilityProfID

-- E&M for MLPs
	INSERT INTO #RVUReportingPreProcessSubreport
		select distinct 
		sp.SEQ,
		fp.Facility_ID,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,		
		fp.FACILITY_PROF_ID, fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		sp.physician_id as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.Patient_last_name + ', ' + c.Patient_First_Name as PatientName,
		c.Medical_Record_Num,
		c.time_of_service,
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		fp.FACILITY_PROF_ID as NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then 0
			when pb.BUSINESS_UNIT_NAME like '%5c%' then 0
			when  fp.role_id = 1 then 1
			else 1 end) PatientCount				
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where		sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
--and		c.nurse_practitioner_id > 0 
and		c.facility_id = @facilityID
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
--and		c.nurse_practitioner_id = fp.facility_prof_id
and		fp.role_id = 1
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and	ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291'))
and		fp.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID and fp.FACILITY_ID = @facilityID 
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		fp.FACILITY_PROF_ID = @FacilityProfID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'


	-- Procedures - SENT_PROCEDURE match with EPIC on account and CPT code, use EPIC servicing provider
	INSERT INTO #RVUReportingPreProcessSubreport
		select distinct 
		sp.SEQ,
		fp.Facility_ID,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,		
		fp.FACILITY_PROF_ID, fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		sp.physician_id as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.Patient_last_name + ', ' + c.Patient_First_Name as PatientName,
		c.Medical_Record_Num,
		c.time_of_service,
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		0  as Quantity_PL,
		sp.quantity as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then 0
			when pb.BUSINESS_UNIT_NAME like '%5c%' then 0
			when fp.role_id = 1  then 1
			else 1 end) PatientCount				

from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic				
where		sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
and		c.facility_id = @facilityID
and		sp.class in ('PP')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		sp.chart_id = c.chart_id
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
		where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
		and	ep.CPT_CODE = sp.CPT_CODE)
and		fp.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID
and		fp.FACILITY_ID = @facilityID
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))								
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
--and		fp.FACILITY_PROF_ID = @FacilityProfID


	-- Procedures - SENT_PROCEDURE no match with EPIC on account and CPT code, CCS provider
	INSERT INTO #RVUReportingPreProcessSubreport
		select distinct 
		sp.SEQ,
		fp.Facility_ID,		
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,		
		fp.FACILITY_PROF_ID, fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		sp.physician_id as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.Patient_last_name + ', ' + c.Patient_First_Name as PatientName,
		c.Medical_Record_Num,
		c.time_of_service,
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		0  as Quantity_PL,
		sp.quantity as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then 0
			when pb.BUSINESS_UNIT_NAME like '%5c%' then 0
			when fp.role_id = 1  then 1
			else 1 end) PatientCount				

from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic				
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
and		c.facility_id = @facilityID
and		sp.class in ('PP')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		sp.chart_id = c.chart_id
--and		sp.facility_chart_id = epic.HSP_ACCOUNT_ID
and     	(select COUNT(*) from ASA_PHYSICIAN_CHARGES ep
		where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
		and		ep.CPT_CODE = sp.CPT_CODE) = 0
and		fp.FACILITY_PROF_ID = sp.physician_id
and		fp.FACILITY_ID = @facilityID									
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
--and		fp.FACILITY_PROF_ID = @FacilityProfID
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))


	-- Provider Adjustments table
	INSERT INTO #RVUReportingPreProcessSubreport
		select distinct 
		sp.SEQ,	
		fp.Facility_ID,	
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,		
		fp.FACILITY_PROF_ID, fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		sp.physician_id as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.Patient_last_name + ', ' + c.Patient_First_Name as PatientName,
		c.Medical_Record_Num,
		c.time_of_service,
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		0  as Quantity_PL,
		sp.quantity as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then 0
			when pb.BUSINESS_UNIT_NAME like '%5c%' then 0
			when fp.role_id = 1  then 1
			else 1 end) PatientCount				

from	PROVIDER_REPORTING_ADJUSTMENTS sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc
		--, RVU_REPORTING_BILLED_CHARTS pbc			
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
and		c.facility_id = @facilityID
and		sp.class in ('PP')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		sp.chart_id = c.chart_id
and		fp.FACILITY_PROF_ID = sp.physician_id
and		fp.FACILITY_ID = @facilityID									
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		fp.FACILITY_PROF_ID = @FacilityProfID

--) x
--where x.ReportCategory = @ReportCategory
--ORDER BY x.Time_Of_Service, x.Chart_ID

DELETE
FROM ReportProcessing.dbo.RVU_Reporting_PreProcess_Subreport
WHERE facility_ID = @FacilityID
-- Do not include criteria on @ControlID here so that the table will be kept as small as possible.  No historical records need to be preserved in this table.

INSERT INTO ReportProcessing.dbo.RVU_Reporting_PreProcess_Subreport
select distinct *	-- mimics the old UNION behavior
from #RVUReportingPreProcessSubreport


-- Now preprocess data to be used for the summary level of the report

/*
	Performance has been improved by replacing the UNIONs with separate INSERT statements.

	See notes above at the top of the subreport preprocessing section, regarding commented lines in the INSERT statements.
*/

-- E&M - No Nurse Practitioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider in the FACILITY_PROF table, use EPIC service provider
	insert into 	#RVUReportingPreProcessSummary
		select distinct		-- 122K reads, 1 sec, 5686 rows 
		c.facility_ID,
		sp.SEQ,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,
		fp.FACILITY_PROF_ID, 
		fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		fp.FACILITY_PROF_ID as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU  as WorkRVU,
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		(CASE when sp.class = 'PL' then 1 else 0 end) as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		1 as PatientCount,
		1 as ChargeCount			
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		c.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and		ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291'))
and		fp.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID 
and		fp.FACILITY_ID = @facilityID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		c.NURSE_PRACTITIONER_ID <= 0
and		fp.ROLE_ID <> 1
and		c.FACILITY_ID = @facilityID


-- E&M - With Nurse Practitioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider in the FACILITY_PROF table, use EPIC billing provider
	insert into 	#RVUReportingPreProcessSummary
		select distinct		-- 55K reads, 1 sec, 2525 rows
		c.facility_ID,
		sp.SEQ,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,
		fp.FACILITY_PROF_ID, 
		fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		fp.FACILITY_PROF_ID as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.facility_chart_id,
		--(CASE when fp.facility_prof_id = c.nurse_practitioner_id then sp.quantity * rvu.WORK_RVU else 0) as WorkRVU, 
		--(CASE when fp.facility_prof_id = c.nurse_practitioner_id then sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT else 0) as TotalRVU,
		0 as WorkRVU,
		0 as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.Facility_ID) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp2.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		1 as PatientCount,
		1 as ChargeCount				
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts	c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		FACILITY_PROFESSIONAL fp2 WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		c.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and		ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291'))
and		fp2.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID and fp2.FACILITY_ID = @facilityID and (fp2.INACTIVE_IND is null or fp2.INACTIVE_IND = 0)
and		fp.EMPLOYEE_IDENTIFIER = epic.CHARGE_ENTRY_ID
and		fp.FACILITY_ID = @facilityID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		c.NURSE_PRACTITIONER_ID > 0	
and		fp2.ROLE_ID = 1
and		c.FACILITY_ID = @facilityID


-- E&M - No Nurse Practioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider not in the FACILITY_PROF table, use CCS Physician from Chart
	insert into 	#RVUReportingPreProcessSummary
		select distinct 		-- 375k reads, 8 secs, 11 rows
		c.facility_ID,
		sp.SEQ,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,
		fp.FACILITY_PROF_ID, 
		fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		fp.FACILITY_PROF_ID as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		1 as PatientCount,
		1 as ChargeCount				
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts	c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		c.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		sp.physician_id = fp.FACILITY_PROF_ID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		sp.facility_chart_id = epic.FACILITY_CHART_ID
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and		ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291'))
and		epic.SERVICE_PROVIDER_ID not in (SELECT	fp2.EMPLOYEE_IDENTIFIER FROM FACILITY_PROFESSIONAL fp2 
								 WHERE		fp2.FACILITY_ID = @facilityID 
								 AND		(fp2.INACTIVE_IND is NULL or fp2.INACTIVE_IND = 0))
and		fp.FACILITY_ID = @facilityID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		c.NURSE_PRACTITIONER_ID <= 0
and		fp.ROLE_ID <> 1
and		c.FACILITY_ID = @facilityID


-- E&M - With Nurse Practioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider not in the FACILITY_PROF table, use CCS Physician from Chart
	insert into 	#RVUReportingPreProcessSummary
		select distinct			-- 1K reads, 1 sec, 0 rows
		c.facility_ID,
		sp.SEQ,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,
		fp.FACILITY_PROF_ID, 
		fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		fp.FACILITY_PROF_ID as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.facility_chart_id,
		0 as WorkRVU,
		0 as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		1 as PatientCount,		
		1 as ChargeCount			
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts	c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		FACILITY_PROFESSIONAL fp3 WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where		sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		c.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		c.physician_id = fp.FACILITY_PROF_ID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and		ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291')
									and		ep.QUANTITY > 1)
and		epic.CHARGE_ENTRY_ID not in (SELECT	fp2.EMPLOYEE_IDENTIFIER FROM FACILITY_PROFESSIONAL fp2 
								 WHERE		fp2.FACILITY_ID = @facilityID
								 AND		(fp2.INACTIVE_IND is NULL or fp2.INACTIVE_IND = 0))
and		fp3.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID and fp3.FACILITY_ID = @facilityID and (fp3.INACTIVE_IND is null or fp3.INACTIVE_IND = 0)
and		fp.FACILITY_ID = @facilityID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		c.NURSE_PRACTITIONER_ID > 0
and		fp3.ROLE_ID = 1
and		c.FACILITY_ID = @facilityID


-- E&M - SENT_PROCEDURE with NO match on EPIC at account level use CCS Physician from Chart
	insert into 	#RVUReportingPreProcessSummary
		select distinct			-- 24K reads, 3 secs, 0 rows
		c.facility_ID,
		sp.SEQ,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,
		fp.FACILITY_PROF_ID, 
		fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		fp.FACILITY_PROF_ID as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when  fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		1 as PatientCount,		
		1 as ChargeCount
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts	c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc
		--RVU_REPORTING_BILLED_CHARTS pbc
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		c.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		c.physician_id = fp.FACILITY_PROF_ID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
--and		sp.facility_chart_id = epic.HSP_ACCOUNT_ID
and     	(SELECT COUNT(*) from	ASA_PHYSICIAN_CHARGES epic
		 WHERE	epic.FACILITY_CHART_ID = sp.facility_chart_id 
		 AND	epic.CPT_CODE IN  ('99281','99282','99283','99284','99285','99291')) = 0
and		fp.FACILITY_ID = @facilityID
and		sp.PHYSICIAN_ID = fp.FACILITY_PROF_ID 
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
and		c.FACILITY_ID = @facilityID


-- E&M for MLPs
	insert into 	#RVUReportingPreProcessSummary
		select distinct			-- 134K reads, 4 secs, 2525 rows
		c.facility_ID,
		sp.SEQ,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,
		fp.FACILITY_PROF_ID, 
		fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		fp.FACILITY_PROF_ID as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		fp.FACILITY_PROF_ID as NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		sp.quantity  as Quantity_PL,
		0 as Quantity_PP,
		'(2) MD w/ MLP' as ReportCategory,		
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 				
			cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then 0
			when pb.BUSINESS_UNIT_NAME like '%5c%' then 0
			when c.NURSE_PRACTITIONER_ID > 0  then 1
			else 1 end) PatientCount,
		1 as ChargeCount			
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts	c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where		sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		c.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
--and		c.nurse_practitioner_id = fp.facility_prof_id
and		fp.role_id = 1
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and	ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291'))
and		fp.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID and fp.FACILITY_ID = @facilityID 
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		c.FACILITY_ID = @facilityID


-- Procedures - SENT_PROCEDURE match with EPIC on account and CPT code, use EPIC servicing provider
	insert into 	#RVUReportingPreProcessSummary
		select distinct			-- 118K reads, 1 sec, 550 rows
		c.facility_ID,
		sp.SEQ,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,
		fp.FACILITY_PROF_ID, 
		fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		fp.FACILITY_PROF_ID as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		0  as Quantity_PL,
		sp.quantity as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 		
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		0 as PatientCount,
		1 as ChargeCount			

from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts	c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic				
where		sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		c.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
and		sp.class in ('PP')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		sp.chart_id = c.chart_id
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
		where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
		and	ep.CPT_CODE = sp.CPT_CODE)
and		fp.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID
and		fp.FACILITY_ID = @facilityID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))							
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		c.FACILITY_ID = @facilityID


-- Procedures - SENT_PROCEDURE no match with EPIC on account and CPT code, CCS provider
	insert into 	#RVUReportingPreProcessSummary
		select distinct			-- 16K reads, 1 sec, 317 rows
		c.facility_ID,
		sp.SEQ,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,
		fp.FACILITY_PROF_ID, 
		fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		fp.FACILITY_PROF_ID as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		0  as Quantity_PL,
		sp.quantity as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 		
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		0 as PatientCount,
		1 as ChargeCount			

from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessCharts	c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic				
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		c.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
and		sp.class in ('PP')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and     	(select COUNT(*) from ASA_PHYSICIAN_CHARGES ep
		where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
		and		ep.CPT_CODE = sp.CPT_CODE) = 0
and		fp.FACILITY_PROF_ID = sp.physician_id
and		fp.FACILITY_ID = @facilityID									
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
and		c.FACILITY_ID = @facilityID


-- Adjustment table records (e.g. 99288 and 99292 )

-- Procedures - SENT_PROCEDURE no match with EPIC on account and CPT code, CCS provider
	insert into 	#RVUReportingPreProcessSummary
		select distinct		-- 2K reads, 0 secs, 0 rows
		c.facility_ID,
		sp.SEQ,
	  	fp.provider_business_unit_id AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME,
		fp.FACILITY_PROF_ID, 
		fp.LAST_NAME + ', ' + fp.FIRST_NAME name,  
		sp.class, 
		fp.FACILITY_PROF_ID as ProcPhysID, 
		sp.quantity, 
		c.chart_id, 
		c.facility_chart_id,
		sp.quantity * rvu.WORK_RVU as WorkRVU, 
		sp.quantity * rvu.FULLY_IMPLEMENTED_FAC_TOT as TotalRVU,
		c.NURSE_PRACTITIONER_ID, 
		cm.cpt_code, 
		cm.DESCRIPTION, 
		cm.CHARGE_AMOUNT,
		bc.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
		sp.quantity * cm.CHARGE_AMOUNT as TotalCharge,
		0  as Quantity_PL,
		sp.quantity as Quantity_PP,
		(case 
			when (select COUNT(*) from RVU_REPORTING_CPT_EXCLUSION cpe where 		
				cpe.CPT_CODE = sp.cpt_code and cpe.facility_id = sp.facility_id) > 0 then '(4) Excluded FX Care'
			when pb.BUSINESS_UNIT_NAME like '%5c%' then '(3) Plastics'
			when fp.role_id = 1 then '(2) MD w/ MLP'
			else '(1) MD Only' end) ReportCategory,		
		0 as PatientCount,
		1 as ChargeCount			

from	PROVIDER_REPORTING_ADJUSTMENTS sp WITH (NOLOCK),
		--chart c WITH (NOLOCK),	-- the old query was still joining here to CHART instead of the temp table (#Charts, or now #RVUReportingPreProcessCharts).  ds, 2/19/2016
		#RVUReportingPreProcessCharts as c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc
		--, RVU_REPORTING_BILLED_CHARTS pbc	
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
and		c.facility_id = @facilityID
and		sp.class in ('PP')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		sp.chart_id = c.chart_id
and		fp.FACILITY_PROF_ID = sp.physician_id
and		fp.FACILITY_ID = @facilityID									
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
and		c.FACILITY_ID = @facilityID


insert into 	#RVUReportingPreProcessSummary
	select		-- 3k reads, 0 secs, 1376 rows
	fp.facility_ID,
	1 as Seq, 
		pb.PROVIDER_BUSINESS_UNIT_ID as AttendingBusinessUnit, 
		pb.BUSINESS_UNIT_NAME as BUSINESS_UNIT_NAME,
		--pb.PROVIDER_BUSINESS_UNIT_ID as PerformingBusinessUnit, 
		fp.FACILITY_PROF_ID, 				
		fp.LAST_NAME + ', ' + fp.FIRST_NAME name,    
		'' as class, 
		0 as ProcPhysID, 
		0 as quantity, 
		0 as chart_id, 
		'' as facility_chart_id,
		0 as WorkRVU ,
		0 as TotalRVU,
		0 as NURSE_PRACTITIONER_ID, 
		'' as cpt_code, 
		'' as DESCRIPTION, 
		0 as CHARGE_AMOUNT,
		@ControlID as ControlID,
		0 as TotalCharge,
		0 as Quantity_PL,
		0 as Quantity_PP,
		tmp.tempCategory as ReportCategory, 
		0 as PatientCount,
		0 as ChargeCount
	from #tempCategory tmp,	
		FACILITY_PROFESSIONAL fp,
		PROVIDER_BUSINESS_UNIT pb,
		RVU_REPORTING_BILLING_CONTROL bc		
where	fp.FACILITY_ID = @facilityID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID	
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID


select distinct *	-- mimics old UNION behavior
into #DistinctSummary
from #RVUReportingPreProcessSummary

select	
		SUM(x.workrvu) as work_RVU_Sum, 
		SUM(x.TotalRVU) as Total_RVU_Sum,
		x.AttendingBusinessUnit, 
		x.BUSINESS_UNIT_NAME,
		x.name,
		x.ReportCategory,
		x.Facility_prof_id,
		sum(x.Quantity_PP) as CountProc,
		sum(x.Quantity_PL) as CountEM,
		x.ControlID,
		SUM(x.TotalCharge) as TotalCharges,
		SUM(x.ChargeCount) as CountCharges
from #DistinctSummary as x
where	
--x.facility_ID = @FacilityID		-- Not necessary since preprocessing already accomplished this filtering.
--and x.controlID = @ControlID		-- Not necessary since preprocessing already accomplished this filtering.
--and 
(x.AttendingBusinessUnit <> -1 
		or		x.AttendingBusinessUnit = -1 and (x.Quantity_PL > 0 or x.Quantity_PP > 0)
	)
group by x.ControlID, x.AttendingBusinessUnit,  x.BUSINESS_UNIT_NAME, x.FACILITY_PROF_ID, x.name,  x.ReportCategory
order by x.FACILITY_PROF_ID

end

GO
