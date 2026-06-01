SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE procedure [dbo].[ExtractPEMAOnlyMonthlyBillingSummaryWithDetail]
	@FacilityID int
as
begin

declare @ControlID int
set @ControlID = (select RVU_REPORTING_BILLING_CONTROL_ID from RVU_REPORTING_BILLING_CONTROL where DATEADD(DD, -10, GetDate()) between PERIOD_BEGIN_DATE and PERIOD_END_DATE)

exec dbo.RVU_REPORTING_BILLED_CHART_UPDATE @ControlID, @FacilityID


if object_id('TempDB..#RVUReportingPreProcessChartsPEMA', 'U') is not null
begin
	drop table #RVUReportingPreProcessChartsPEMA
end;


if object_id('TempDB..#RVUReportingPreProcessSubreportPEMAExtract', 'U') is not null
begin
	drop table #RVUReportingPreProcessSubreportPEMAExtract
end;


CREATE TABLE #RVUReportingPreProcessSubreportPEMAExtract
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
	[PatientCount] [int] NOT NULL,
	[Sent_date] [datetime] null, 
	[Patient_DOB] [datetime] null,
	[Chief_Complaint] varchar(10) null,
	[Diagnosis_Codes] varchar(250) null,
	[Disposition] varchar(50) null
)

DELETE
FROM ReportProcessing.dbo.RVU_Reporting_PreProcess_Subreport_PEMA_Extract
WHERE facility_ID = @FacilityID

if object_id('TempDB..#tempCategory', 'U') is not null
begin
	drop table #tempCategory
end;

declare @EHC_BusinessUnitID int
set @EHC_BusinessUnitID = 76

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
	c.facility_ID, c.patient_first_name, c.patient_last_name, c.medical_record_num, c.time_of_service, c.patient_dob,
	pbc.RVU_REPORTING_BILLING_CONTROL_ID,
	(select top 1 UPPER(cdc.icd10_code) from chart_diagnosis_code_icd10 cdc where c.chart_id = cdc.chart_id 
		and cdc.diagnosis_type_id in (1,3,5) and cdc.is_primary = 1) as Chief_Complaint, 
	(STUFF((SELECT ',' + UPPER(cdc2.ICD10_CODE)  AS [text()]
				FROM CHART_DIAGNOSIS_CODE_ICD10 cdc2
				WHERE cdc2.CHART_ID = c.CHART_ID
				AND   (cdc2.DIAGNOSIS_TYPE_ID <> 1 or (cdc2.DIAGNOSIS_TYPE_ID = 1 AND cdc2.IS_PRIMARY = 0))					
				For XML Path ('')),1,1,'')) as Diagnosis_Codes,
	pd.description as Disposition
into #RVUReportingPreProcessChartsPEMA
from chart c, dbo.RVU_REPORTING_BILLED_CHARTS pbc, patient_disposition pd 
where c.chart_id = pbc.CHART_ID and pbc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
and c.facility_id = @facilityID
and c.patient_disposition_id = pd.patient_disposition_id
--and (c.facility_id = 277 
--or (c.facility_id = 276 and (select fp.provider_business_unit_id
--							from  facility_professional fp 
--							where c.PHYSICIAN_ID = fp.FACILITY_PROF_ID) = @EHC_BusinessUnitID))


CREATE NONCLUSTERED INDEX ix_missing1
ON #RVUReportingPreProcessChartsPEMA (chart_id, physician_id, facility_ID)
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
	INSERT INTO #RVUReportingPreProcessSubreportPEMAExtract
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
			else 1 end) PatientCount,
		sp.sent_date, 
		c.patient_dob,
		c.chief_complaint,
		c.diagnosis_codes,
		c.disposition
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessChartsPEMA c WITH (NOLOCK),
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
--and		c.facility_id = @facilityID
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
and		fp.FACILITY_ID = c.FACILITY_ID
and (fp.facility_id = 277 or (fp.facility_id = 276 and fp.provider_business_unit_id = @EHC_BusinessUnitID))
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		c.NURSE_PRACTITIONER_ID <= 0
and		fp.ROLE_ID <> 1
--and		fp.FACILITY_PROF_ID = @FacilityProfID


	-- E&M - With Nurse Practitioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider in the FACILITY_PROF table, use EPIC billing provider
	INSERT INTO #RVUReportingPreProcessSubreportPEMAExtract
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
			else 1 end) PatientCount,
		sp.sent_date, 
		c.patient_dob,
		c.chief_complaint,
		c.diagnosis_codes,
		c.disposition
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessChartsPEMA c WITH (NOLOCK),
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
--and		c.facility_id = @facilityID
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
and		fp2.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID and fp2.FACILITY_ID = c.FACILITY_ID and (fp2.INACTIVE_IND is null or fp2.INACTIVE_IND = 0)
and		fp.EMPLOYEE_IDENTIFIER = epic.CHARGE_ENTRY_ID
and		fp.FACILITY_ID = c.FACILITY_ID
and (fp.facility_id = 277 or (fp.facility_id = 276 and fp.provider_business_unit_id = @EHC_BusinessUnitID))
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		c.NURSE_PRACTITIONER_ID > 0	
and		fp2.ROLE_ID = 1
--and		fp.FACILITY_PROF_ID = @FacilityProfID

	-- E&M - No Nurse Practioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider not in the FACILITY_PROF table, use CCS Physician from Chart
	INSERT INTO  #RVUReportingPreProcessSubreportPEMAExtract
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
			else 1 end) PatientCount,
		sp.sent_date, 
		c.patient_dob,
		c.chief_complaint,
		c.diagnosis_codes,
		c.disposition						
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessChartsPEMA c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = @ControlID
and		c.facility_id = @facilityID
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		sp.physician_id = fp.FACILITY_PROF_ID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		sp.facility_chart_id = epic.FACILITY_CHART_ID
and     epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and		ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291'))
and		epic.SERVICE_PROVIDER_ID not in (SELECT	fp2.EMPLOYEE_IDENTIFIER FROM FACILITY_PROFESSIONAL fp2 
								 WHERE		fp2.FACILITY_ID = @facilityID
								 AND		(fp2.INACTIVE_IND is NULL or fp2.INACTIVE_IND = 0))
and		fp.FACILITY_ID = @facilityID
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
and		fp.ROLE_ID <> 1	
and		(fp.facility_id = 277 or (fp.facility_id = 276 and fp.provider_business_unit_id = @EHC_BusinessUnitID))

-- E&M - With Nurse Practioner, SENT_PROCEDURE with match on EPIC at account level and EPIC provider not in the FACILITY_PROF table, use CCS Physician from Chart
	INSERT INTO  #RVUReportingPreProcessSubreportPEMAExtract
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
		c.RVU_REPORTING_BILLING_CONTROL_ID as ControlID,
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
			else 1 end) PatientCount,
		sp.sent_date, 
		c.patient_dob,
		c.chief_complaint,
		c.diagnosis_codes,
		c.disposition						
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessChartsPEMA c WITH (NOLOCK),
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
and		c.facility_id = @facilityID
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		c.physician_id = fp.FACILITY_PROF_ID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and     epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
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
	INSERT INTO  #RVUReportingPreProcessSubreportPEMAExtract
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
			else 1 end) PatientCount,
		sp.sent_date, 
		c.patient_dob,
		c.chief_complaint,
		c.diagnosis_codes,
		c.disposition
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessChartsPEMA c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc
		--, RVU_REPORTING_BILLED_CHARTS pbc
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = c.RVU_REPORTING_BILLING_CONTROL_ID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
--and		c.facility_id = @facilityID
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
and		fp.FACILITY_ID = c.FACILITY_ID
and (fp.facility_id = 277 or (fp.facility_id = 276 and fp.provider_business_unit_id = @EHC_BusinessUnitID))
and		sp.PHYSICIAN_ID = fp.FACILITY_PROF_ID 
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		fp.FACILITY_PROF_ID = @FacilityProfID

-- E&M for MLPs
	INSERT INTO  #RVUReportingPreProcessSubreportPEMAExtract
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
			else 1 end) PatientCount,
		sp.sent_date,  
		c.patient_dob,
		c.chief_complaint,
		c.diagnosis_codes,
		c.disposition							
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessChartsPEMA c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic
where		sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = c.RVU_REPORTING_BILLING_CONTROL_ID
and		sp.class in ('PL')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		fp.role_id = 1
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
									where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
									and	ep.CPT_CODE in ('99281','99282','99283','99284','99285','99291'))
and		fp.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID 
and fp.FACILITY_ID = c.FACILITY_ID 
and (fp.facility_id = 277 or (fp.facility_id = 276 and fp.provider_business_unit_id = @EHC_BusinessUnitID))
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))
--and		fp.FACILITY_PROF_ID = @FacilityProfID
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'


	-- Procedures - SENT_PROCEDURE match with EPIC on account and CPT code, use EPIC servicing provider
	INSERT INTO  #RVUReportingPreProcessSubreportPEMAExtract
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
			else 1 end) PatientCount,
		sp.sent_date,  
		c.patient_dob,
		c.chief_complaint,
		c.diagnosis_codes,
		c.disposition							

from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessChartsPEMA c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic				
where		sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = c.RVU_REPORTING_BILLING_CONTROL_ID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
--and		c.facility_id = @facilityID
and		sp.class in ('PP')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		sp.chart_id = c.chart_id
and     	epic.ASA_PHYSICIAN_CHARGES_ID = (select MIN(ep.ASA_PHYSICIAN_CHARGES_ID) from ASA_PHYSICIAN_CHARGES ep
		where	ep.FACILITY_CHART_ID = sp.FACILITY_CHART_ID 
		and	ep.CPT_CODE = sp.CPT_CODE)
and		fp.EMPLOYEE_IDENTIFIER = epic.SERVICE_PROVIDER_ID
and		fp.FACILITY_ID = c.FACILITY_ID
and (fp.facility_id = 277 or (fp.facility_id = 276 and fp.provider_business_unit_id = @EHC_BusinessUnitID))
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))								
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
--and		fp.FACILITY_PROF_ID = @FacilityProfID


	-- Procedures - SENT_PROCEDURE no match with EPIC on account and CPT code, CCS provider
	INSERT INTO  #RVUReportingPreProcessSubreportPEMAExtract
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
			else 1 end) PatientCount,				
		sp.sent_date,  
		c.patient_dob,
		c.chief_complaint,
		c.diagnosis_codes,
		c.disposition
from	sent_procedure sp WITH (NOLOCK),
		#RVUReportingPreProcessChartsPEMA c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc,
		--RVU_REPORTING_BILLED_CHARTS pbc,
		ASA_PHYSICIAN_CHARGES epic				
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = c.RVU_REPORTING_BILLING_CONTROL_ID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
--and		c.facility_id = @facilityID
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
and		fp.FACILITY_ID = c.FACILITY_ID									
and (fp.facility_id = 277 or (fp.facility_id = 276 and fp.provider_business_unit_id = @EHC_BusinessUnitID))
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
--and		fp.FACILITY_PROF_ID = @FacilityProfID
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))


	-- Provider Adjustments table
	INSERT INTO  #RVUReportingPreProcessSubreportPEMAExtract
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
			else 1 end) PatientCount,
		sp.sent_date, 
		c.patient_dob,
		c.chief_complaint,
		c.diagnosis_codes,
		c.disposition							

from	PROVIDER_REPORTING_ADJUSTMENTS sp WITH (NOLOCK),
		#RVUReportingPreProcessChartsPEMA c WITH (NOLOCK),
		charge_master cm WITH (NOLOCK), 
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		PROVIDER_BUSINESS_UNIT pb WITH (NOLOCK),
		CMS_PHYSICIAN_RVU rvu WITH (NOLOCK),
		RVU_REPORTING_BILLING_CONTROL bc
		--, RVU_REPORTING_BILLED_CHARTS pbc			
where	sp.chart_id = c.chart_id
and		bc.RVU_REPORTING_BILLING_CONTROL_ID = c.RVU_REPORTING_BILLING_CONTROL_ID
--and		pbc.RVU_REPORTING_BILLING_CONTROL_ID = bc.RVU_REPORTING_BILLING_CONTROL_ID 
--and		c.chart_id = pbc.chart_id
--and		c.facility_id = @facilityID
and		sp.class in ('PP')
and		cm.charge_master_id = sp.charge_master_id 
and		cm.cpt_code = rvu.hcpcs
and		bc.period_end_date BETWEEN rvu.effective_dt and rvu.expiration_dt
and		sp.chart_id = c.chart_id
and		fp.FACILITY_PROF_ID = sp.physician_id
and		fp.FACILITY_ID = c.FACILITY_ID									
and (fp.facility_id = 277 or (fp.facility_id = 276 and fp.provider_business_unit_id = @EHC_BusinessUnitID))
and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
and		pb.BUSINESS_UNIT_NAME <> '(4) Staff'
and		((fp.INACTIVE_IND is NULL or fp.INACTIVE_IND = 0) AND (fp.EXPIRATION_DATE is NULL or fp.EXPIRATION_DATE > bc.PERIOD_BEGIN_DATE))

--DELETE
--FROM ReportProcessing.dbo.RVU_Reporting_PreProcess_Subreport_PEMA_Extract
--WHERE facility_ID in (276,277)
-- Do not include criteria on @ControlID here so that the table will be kept as small as possible.  No historical records need to be preserved in this table.

INSERT INTO ReportProcessing.dbo.RVU_Reporting_PreProcess_Subreport_PEMA_Extract
select distinct * from #RVUReportingPreProcessSubreportPEMAExtract


end





GO
