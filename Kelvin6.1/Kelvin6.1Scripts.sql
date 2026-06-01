USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-3655 - (Service Agreement ID = 2594, Facility ID = 2657, San Antonio Regional Hospital - SARH) Update Observation Exclusions for NEW Facility.SQL

----------------------------------------
-- 01) DACS-3655 - (Service Agreement ID = 2594, Facility ID = 2657, San Antonio Regional Hospital - SARH) Update Observation Exclusions for NEW Facility.SQL
----------------------------------------
GO
-- begin tran; -- testing

------------------------------
-- backup the original table
------------------------------
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'OBSERVATION_EXCLUSION_HOURS_REASON', @DestTable = 'OBSERVATION_EXCLUSION_HOURS_REASON_DACS-3655';
GO

---------------------------------------------------------------------------------------------------------------
-- Step 1)  Get the needed variables in order to perform the task
--   Some tools are listed at the bottom of this file to help find the required information.
---------------------------------------------------------------------------------------------------------------
DECLARE @CHANGING_USER_PROFILE_ID int =								10149; -- Mr. Ferrell.
DECLARE @SERVICE_AGREEMENT_ID_TARGET int =							2594;  
DECLARE @FACILITY_ID_TARGET int =									2657;  
DECLARE @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED int;

-- Use this to see what OBS reasons already exist for this SA.
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
    @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

/*
OBS List provided by client
SARH Monitored Procedure Carve Out List
Description	Time (in minutes)
---------------------
Ablation	360
Angioplasty	120
Barium Swallow	50
Blood Product Administration (per unit)	120
Bronchoscopy	120
Cardiac Cath (includes recovery on nsg unit)	240     
Central Line Placement	90
Chemotherapy Administration	60-360 
Colonoscopy	150
Dialysis	240
EGD	120
Endoscopy	180
Flexible Sigmoidoscopy	150
Interventional Radiology	120
Pacemaker Placement	360
PEG Insertion	150
PTCA	360
PT/OT Treatment (per treatment)	30
Radiation Therapy Initial Set up	120
Radiation Therapy Treatment 	30
Respiratory Treatment	15-45
Speech Therapy Treatment	30-60 
Stress Test	90
Surgical Procedure (includes recovery)	Varies    
Thallium Stress Test	240
Trans-Esophageal Echo Tee	90


*/


---------------------------------------------------------------------------------------------------------------
-- Step 2)  Insert new OBSERVATION_EXCLUSION_HOURS_REASON entries
-- (Repeat the for each unique Description required)
---------------------------------------------------------------------------------------------------------------
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Ablation (360min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Angioplasty (120min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Barium Swallow (50min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Blood Product Administration (per unit) (120min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Bronchoscopy (120min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	     
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Cardiac Cath (includes recovery on nsg unit) (240min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Central Line Placement (90min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
 
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Chemotherapy Administration	 (60-360min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Colonoscopy (150min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Dialysis (240min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'EGD (120min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Endoscopy (180min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Flexible Sigmoidoscopy (150min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Interventional Radiology (120min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Pacemaker Placement (360min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PEG Insertion (150min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PTCA (360min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PT/OT Treatment (per treatment) (30min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Radiation Therapy Initial Set up (120min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
 	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Radiation Therapy Treatment (30min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Respiratory Treatment (15-45min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Speech Therapy Treatment (30-60min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Stress Test (90min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	    
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Surgical Procedure (includes recovery) (Varies min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Thallium Stress Test (240min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;
	
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Trans-Esophageal Echo Tee (90min)'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;


---------------------------------------------------------------------------------------------------------------
-- Use this to see what reasons exist for this SA after inserts.  Check that they all inserted correctly.
---------------------------------------------------------------------------------------------------------------
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
    @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

--============================================================--
-- Step 3) Replacing [CHART].[EXCLUSION_HOURS_REASON_ID] columns that use the default codes 
--    with the Service Agreement Id Specific OBSERVATION_EXCLUSION_HOURS_REASON_ID values.
--    default codes are: 16, 17, 18, 19 and 20 
--   these replacement values can be found by using the tools below and 
--   asking the customer for their specific descriptions (use tools below to find their specific codes) and make logical determination.
--   if nothing replaces a given value, set it to 0 (zero) the script will not process a replacement value of 0.
--============================================================--
--============================================================--
--------------------------------------------
-- -1	16	Blood Transfusion
-- -1	17	GI Lab Procedures
-- -1	18	Cath Lab Procedures
-- -1	19	Surgery
-- -1	20	Monitored Infusions
DECLARE @OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT_FOR_ID_16 INT = (SELECT TOP 1 [EXCLUSION_HOURS_REASON_ID] FROM [OBSERVATION_EXCLUSION_HOURS_REASON] WHERE SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET AND [DESCRIPTION] = 'Blood Product Administration (per unit) (120min)'); --2151; 
DECLARE @OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT_FOR_ID_17 INT = (SELECT TOP 1 [EXCLUSION_HOURS_REASON_ID] FROM [OBSERVATION_EXCLUSION_HOURS_REASON] WHERE SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET AND [DESCRIPTION] = 'Colonoscopy (150min)'); --2149;
DECLARE @OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT_FOR_ID_18 INT = (SELECT TOP 1 [EXCLUSION_HOURS_REASON_ID] FROM [OBSERVATION_EXCLUSION_HOURS_REASON] WHERE SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET AND [DESCRIPTION] LIKE 'Cardiac Cath (includes recovery on ns%'); --2148;
DECLARE @OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT_FOR_ID_19 INT = (SELECT TOP 1 [EXCLUSION_HOURS_REASON_ID] FROM [OBSERVATION_EXCLUSION_HOURS_REASON] WHERE SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET AND [DESCRIPTION] LIKE 'Surgical Procedure (includes reco%'); --2144;
DECLARE @OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT_FOR_ID_20 INT = (SELECT TOP 1 [EXCLUSION_HOURS_REASON_ID] FROM [OBSERVATION_EXCLUSION_HOURS_REASON] WHERE SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET AND [DESCRIPTION] = 'Chemotherapy Administration	60-360'); --2139;
DECLARE @CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED INT;

-- Process OBSERVATION_EXCLUSION_HOURS_REASON_ID = 16 replacement
exec [dbo].[CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_UPDATE_BY_EXCLUSION_HOURS_REASON_IDS]
	 @OBSERVATION_EXCLUSION_HOURS_REASON_ID_EXISTING = 		16
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT =	@OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT_FOR_ID_16
	,@FACILITY_ID = 										@FACILITY_ID_TARGET
	,@CHANGING_USER_PROFILE_ID = 							@CHANGING_USER_PROFILE_ID
	,@SHOW_STATS_ONLY = 									0
	,@ROWS_AFFECTED = 										@CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED OUTPUT;
PRINT('COEEH 16 Replace Count Processed = ' + CAST(@CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED as VARCHAR(32)));

-- Process OBSERVATION_EXCLUSION_HOURS_REASON_ID = 17 replacement
exec [dbo].[CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_UPDATE_BY_EXCLUSION_HOURS_REASON_IDS]
	 @OBSERVATION_EXCLUSION_HOURS_REASON_ID_EXISTING = 		17
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT =	@OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT_FOR_ID_17
	,@FACILITY_ID = 										@FACILITY_ID_TARGET
	,@CHANGING_USER_PROFILE_ID = 							@CHANGING_USER_PROFILE_ID
	,@SHOW_STATS_ONLY = 									0
	,@ROWS_AFFECTED = 										@CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED OUTPUT;
PRINT('COEEH 17 Replace Count Processed = ' + CAST(@CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED as VARCHAR(32)));

-- Process OBSERVATION_EXCLUSION_HOURS_REASON_ID = 18 replacement
exec [dbo].[CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_UPDATE_BY_EXCLUSION_HOURS_REASON_IDS]
	 @OBSERVATION_EXCLUSION_HOURS_REASON_ID_EXISTING = 		18
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT =	@OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT_FOR_ID_18
	,@FACILITY_ID = 										@FACILITY_ID_TARGET
	,@CHANGING_USER_PROFILE_ID = 							@CHANGING_USER_PROFILE_ID
	,@SHOW_STATS_ONLY = 									0
	,@ROWS_AFFECTED = 										@CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED OUTPUT;
PRINT('COEEH 18 Replace Count Processed = ' + CAST(@CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED as VARCHAR(32)));

-- Process OBSERVATION_EXCLUSION_HOURS_REASON_ID = 19 replacement
exec [dbo].[CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_UPDATE_BY_EXCLUSION_HOURS_REASON_IDS]
	 @OBSERVATION_EXCLUSION_HOURS_REASON_ID_EXISTING = 		19
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT =	@OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT_FOR_ID_19
	,@FACILITY_ID = 										@FACILITY_ID_TARGET
	,@CHANGING_USER_PROFILE_ID = 							@CHANGING_USER_PROFILE_ID
	,@SHOW_STATS_ONLY = 									0
	,@ROWS_AFFECTED = 										@CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED OUTPUT;
PRINT('COEEH 19 Replace Count Processed = ' + CAST(@CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED as VARCHAR(32)));

-- Process OBSERVATION_EXCLUSION_HOURS_REASON_ID = 20 replacement
exec [dbo].[CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_UPDATE_BY_EXCLUSION_HOURS_REASON_IDS]
	 @OBSERVATION_EXCLUSION_HOURS_REASON_ID_EXISTING = 		20
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT =	@OBSERVATION_EXCLUSION_HOURS_REASON_ID_REPLACEMENT_FOR_ID_20
	,@FACILITY_ID = 										@FACILITY_ID_TARGET
	,@CHANGING_USER_PROFILE_ID = 							@CHANGING_USER_PROFILE_ID
	,@SHOW_STATS_ONLY = 									0
	,@ROWS_AFFECTED = 										@CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED OUTPUT;
PRINT('COEEH 20 Replace Count Processed = ' + CAST(@CHART_OBSERVATION_ENCOUNTER_EXCLUSION_HOURS_COUNT_ROWS_PROCESSED as VARCHAR(32)));



-- rollback tran; -- testing
-- commit tran; -- testing
GO

/*
testing:
DESCRIPTION
DACS-3275
SERVICE_AGREEMENT_ID
555367
FACILITY_ID
555288
*/
-- End of 01) DACS-3655 - (Service Agreement ID = 2594, Facility ID = 2657, San Antonio Regional Hospital - SARH) Update Observation Exclusions for NEW Facility.SQL
GO

-- Start of 01) DACS-3687 - Script - CMS_PQRI_MEASURE - updates titles.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3687 - Script - CMS_PQRI_MEASURE - updates titles.SQL
------------------------------------------------------------------------------------
GO
-- begin tran; -- testing

	--------------------------------------------
	-- Backup our data to be worked upon
	--------------------------------------------
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE', @DestTable = 'CMS_PQRI_MEASURE_DACS-3687';

	----------------
	-- set parameters
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- fill our update source data
	----------------
	DROP TABLE IF EXISTS #mipsTitleData;

	CREATE TABLE #mipsTitleData(
		 [PQRS#] varchar(30) NULL
		,[MEASURE_TITLE] varchar(4000) NULL
	);
	
	INSERT INTO #mipsTitleData ([PQRS#], [MEASURE_TITLE])
	VALUES
		 ('001',		'MIPS# 001 :  Diabetes: Hemoglobin A1c (HbA1c) Poor Control (>9%) : Percentage of patients 18-75 years of age with diabetes who had hemoglobin A1c > 9.0% during the measurement period.' )
		,('005-A',		'MIPS# 005-A : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) <= 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period: (SUBMISSION CRITERIA 1: All patients with a diagnosis of HF assessed during an outpatient encounter). ' )
		,('005-B',		'MIPS# 005-B : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) <= 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period: (SUBMISSION CRITERIA 2: All patients with a diagnosis of HF and discharged from hospital). ' )
		,('007-A',		'MIPS# 007-A : Coronary Artery Disease (CAD): Beta-Blocker Therapy – Prior Myocardial Infarction (MI) or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) : (SUBMISSION CRITERIA 1): All patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have a current or prior LVEF less than or equal to 40% : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have a prior MI or a current or prior LVEF less than or equal to 40% who were prescribed beta-blocker therapy. ' )
		,('007-B',		'MIPS# 007-B : Coronary Artery Disease (CAD): Beta-Blocker Therapy – Prior Myocardial Infarction (MI) or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) : (SUBMISSION CRITERIA 2): All patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have prior (within the past 3 years) MI : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have a prior MI or a current or prior LVEF less than or equal to 40% who were prescribed beta-blocker therapy. ' )
		,('008-A',		'MIPS# 008-A : Heart Failure (HF): Beta-Blocker Therapy for Left Ventricular Systolic Dysfunction (LVSD) : All patients with a diagnosis of HF seen in the outpatient setting. ' )
		,('008-B',		'MIPS# 008-B : Heart Failure (HF): Beta-Blocker Therapy for Left Ventricular Systolic Dysfunction (LVSD) : All patients with a diagnosis of HF and discharged from hospital. ' )
		,('047',		'MIPS# 047 : Advance Care Plan : Percentage of patients aged 65 years and older who have an advance care plan or surrogate decision maker documented in the medical record or documentation in the medical record that an advance care plan was discussed but the patient did not wish or was not able to name a surrogate decision maker or provide an advance care plan. ' )
		,('066',		'MIPS# 066 : Appropriate Testing for Pharyngitis : The percentage of episodes for patients 3 years and older with a diagnosis of pharyngitis that resulted in an antibiotic order on or within 3 days after the episode date and a group A Streptococcus (Strep) test in the seven-day period from three days prior to the episode date through three days after the episode date. ' )
		,('1',			'MIPS# 1 Diabetes: Hemoglobin A1c Poor Control ' )
		,('116',		'MIPS# 116 : Avoidance of Antibiotic Treatment for Acute Bronchitis/Bronchiolitis : The percentage of episodes for patients ages 3 months and older with a diagnosis of acute bronchitis/bronchiolitis that did not result in an antibiotic dispensing event. ' )
		,('118-A',		'MIPS# 118-A : Coronary Artery Disease (CAD): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) Therapy - Diabetes or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) : (SUBMISSION CRITERIA 1: ALL PATIENTS WITH A DIAGNOSIS OF CAD WITH LVEF less than or equal to 40% (WITHOUT A DIAGNOSIS OF DIABETES)) : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have diabetes OR a current or prior Left Ventricular Ejection Fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB therapy. ' )
		,('118-B',		'MIPS# 118-B : Coronary Artery Disease (CAD): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) Therapy - Diabetes or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) : (SUBMISSION CRITERIA 2: ALL PATIENTS WITH A DIAGNOSIS OF CAD WHO HAVE DIABETES) : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have diabetes OR a current or prior Left Ventricular Ejection Fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB therapy. ' )
		,('128',		'PQRS# 128 Preventive Care and Screening: Body Mass Index (BMI) Screening and Follow-Up Plan ' )
		,('130',		'MIPS# 130 : Documentation of Current Medications in the Medical Record : Percentage of visits for patients aged 18 years and older for which the eligible clinician attests to documenting a list of current medications using all immediate resources available on the date of the encounter. ' )
		,('134',		'MIPS# 134 : Preventive Care and Screening: Screening for Depression and Follow-Up Plan : Percentage of patients aged 12 years and older screened for depression on the date of the encounter or up to 14 days prior to the date of the encounter using an age-appropriate standardized depression screening tool AND if positive, a follow-up plan is documented on the date of or up to two days after the date of the qualifying encounter. ' )
		,('145',		'MIPS# 145 Radiology: Exposure Dose Indices or Exposure Time and Number of Images Reported for Procedures Using Fluoroscopy ' )
		,('178',		'MIPS# 178 Rheumatoid Arthritis (RA): Functional Status Assessment ' )
		,('187',		'MIPS# 187 : Stroke and Stroke Rehabilitation: Thrombolytic Therapy : Percentage of patients aged 18 years and older with a diagnosis of acute ischemic stroke who arrive at the hospital within 3.5 hours of time last known well and for whom IV thrombolytic therapy was initiated within 4.5 hours of time last known well. ' )
		,('226',		'MIPS# 226 : Tobacco Use: Screening and Cessation ' )
		,('226-1',		'PQRS# 226-1 Tobacco Use: Screening and Cessation ' )
		,('226-2',		'PQRS# 226-2 Tobacco Use: Screening and Cessation ' )
		,('236',		'PQRS# 236 Controlling High Blood Pressure ' )
		,('254',		'MIPS# 254 Ultrasound Determination of Pregnancy Location for Pregnant Patients with Abdominal Pain ' )
		,('317',		'PQRS# 317 Preventive Care and Screening: Screening for Blood Pressure and Follow-Up Documented (2017) ' )
		,('326',		'MIPS# 326 : Atrial Fibrillation and Atrial Flutter: Chronic Anticoagulation Therapy : Percentage of patients aged 18 years and older with atrial fibrillation (AF) or atrial flutter who were prescribed an FDA-approved oral anticoagulant drug for the prevention of thromboembolism during the measurement period. ' )
		,('331',		'MIPS# 331 : Adult Sinusitis: Antibiotic Prescribed for Acute Viral Sinusitis (Overuse) : Percentage of patients, aged 18 years and older, with a diagnosis of acute viral sinusitis who were prescribed an antibiotic within 10 days after onset of symptoms. ' )
		,('332',		'MIPS# 332 :  Adult Sinusitis: Appropriate Choice of Antibiotic: Amoxicillin With or Without Clavulanate Prescribed for Patients with Acute Bacterial Sinusitis (Appropriate Use) : Percentage of patients aged 18 years and older with a diagnosis of acute bacterial sinusitis that were prescribed amoxicillin, with or without clavulanate, as a first line antibiotic at the time of diagnosis. ' )
		,('364',		'MIPS# 364 Optimizing Patient Exposure to Ionizing Radiation:  Appropriateness:  Follow-Up CT Imaging for Incidentally Detected Pulmonary Nodules According to Recommended Guidelines ' )
		,('405',		'MIPS# 405 Appropriate Follow-up Imaging for Incidental Abdominal Lesions ' )
		,('406',		'MIPS# 406 Appropriate Follow-up Imaging for Incidental Thyroid Nodules in Patients ' )
		,('415',		'MIPS# 415 : Emergency Medicine: Emergency Department Utilization of CT for Minor Blunt Head Trauma for Patients Aged 18 Years and Older : Percentage of emergency department visits for patients aged 18 years and older who presented with a minor blunt head trauma who had a head CT for trauma ordered by an emergency care provider who have an indication for a head CT. ' )
		,('416',		'MIPS# 416 : Emergency Medicine: Emergency Department Utilization of CT for Minor Blunt Head Trauma for Patients Aged 2 Through 17 Years : Percentage of emergency department visits for patients aged 2 through 17 years who presented with a minor blunt head trauma who had a head CT for trauma ordered by an emergency care provider who are classified as low risk according to the Pediatric Emergency Care Applied Research Network (PECARN) prediction rules for traumatic brain injury.    <p><strong>Definition:</strong></p> <p><strong>Low Risk for Traumatic Brain Injury according to PECARN prediction rules –</strong></p> <p>Patients can be classified as low risk if ALL of the following are met: <ul><li>No signs of altered mental status (e.g., agitation, somnolence, repetitive questioning, slow response to verbal communication) OR no GCS < 15</li><li>No signs of basilar skull fracture (signs include haemotympanum, “raccoon” eyes, cerebrospinal fluid leakage from the ear or nose, Battle’s sign)</li><li>No loss of consciousness</li><li>No vomiting</li><li>No severe mechanism of injury (i.e., motor vehicle crash with patient ejection, death of another passenger, or rollover; pedestrian or bicyclist without helmet struck by a motorized vehicle; falls of more than 5 feet; or head struck by a high-impact object)</li><li>No severe headache</li></ul></p> ' )
		,('436',		'MIPS# 436 Radiation Consideration for Adult CT: Utilization of Dose Lowering Techniques ' )
		,('47',			'MIPS# 47 Advance Care Plan ' )
		,('48',			'MIPS# 48 Urinary Incontinence: Assessment of Presence or Absence of Urinary Incontinence in Women Aged 65 Years and Older ' )
		,('5-1',		'MIPS# 5-1 Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) ' )
		,('5-2',		'MIPS# 5-2 Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) ' )
		,('50',			'MIPS# 50 Urinary Incontinence: Plan of Care for Urinary Incontinence in Women Aged 65 Years and Older ' )
		,('65',			'MIPS# 65 Appropriate Treatment for Children with Upper Respiratory Infection ' )
		,('66',			'MIPS# 66 Appropriate Testing for Pharyngitis ' )
		-- not updating the following as 007 and 008 variants replace these
		--,('7-A',		'PQRS# 7-A [Requires 7-B also be added to Service Agreement for full MIPS functionality] Coronary Artery Disease (CAD): Beta-Blocker Therapy – Prior Myocardial Infarction (MI) or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) ' )
		--,('7-B',		'PQRS# 7-B [Requires 7-A also be added to Service Agreement for full MIPS functionality] Coronary Artery Disease (CAD): Beta-Blocker Therapy – Prior Myocardial Infarction (MI) or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) ' )
		--,('8-1',		'MIPS# 8-1  Heart Failure (HF): Beta-Blocker Therapy for Left Ventricular Systolic  Dysfunction (LVSD) ' )
		--,('8-2',		'MIPS# 8-2  Heart Failure (HF): Beta-Blocker Therapy for Left Ventricular Systolic  Dysfunction (LVSD) ' )
		--,('8-A',		'PQRS# 8-A [Requires 8-B also be added to Service Agreement for full MIPS functionality] Heart Failure (HF): Beta-Blocker Therapy for Left Ventricular Systolic Dysfunction (LVSD) ' )
		--,('8-B',		'PQRS# 8-B [Requires 8-A also be added to Service Agreement for full MIPS functionality] Heart Failure (HF): Beta-Blocker Therapy for Left Ventricular Systolic Dysfunction (LVSD) ' )
		,('ACEP60',		'ACEP60 Syncope – Avoidance of admission for adult patients with low-risk syncope: Percentage of emergency department (ED) visits for patients aged 18-50 years with a diagnosis of low-risk syncope who were discharged. ' )
		,('ACEP61',		'ACEP61 Avoidance of Chest X-ray in pediatric patients with Asthma, Bronchiolitis or Croup: Percentage of ED visits for pediatric patients with Asthma, Bronchiolitis or Croup for whom a Chest X-ray was ordered/performed.. ' )
		,('ACEP64',		'ACEP64 Avoidance of admission for adult patients in Emergency Department with low-risk Deep Vein Thrombosis (DVT): Percentage of patients 18 years and older who present to the Emergency Department with low-risk Deep Vein Thrombosis (DVT) and are discharged home. ' )
		,('ECPR39',		'ECPR39 : Avoid Head CT for Patients with Uncomplicated Syncope : Percentage of Adult Syncope Patients Who Did Not Receive a Head CT Scan Ordered by the Provider. ' )
		,('ECPR46',		'ECPR46 : Avoidance of Opiate Prescriptions for Low Back Pain or Migraines : Percentage of Patients with Low Back Pain and/or Migraines Who Were Not Prescribed an Opiate. ' )
		,('ECPR51',		'ECPR51 : Discharge Prescription of Naloxone after Opioid Poisoning or Overdose : Percentage of Opioid Poisoning or Overdose Patients Presenting to An Acute Care Facility Who Were Prescribed Naloxone at Discharge. ' )
		,('HCPR24',		'HCPR24 : Appropriate Utilization of Vancomycin for Cellulitis: Percentage of patients with Cellulitis who did not receive Vancomycin unless MRSA Infection or risk for MRSA Infection was identified. ' )
		,('HCPR27',		'HCPR27 : Point-of-Care Ultrasound: Evaluation for Pneumothorax after Central Venous Catheter (CVC) Placement : Percentage of patients aged 18 years and older who undergo central venous catheter (CVC) insertion for whom Point-of-Care Ultrasound was performed to evaluate for pneumothorax. ' )
		,('PQRANES1',	'PQRANES1  Use of Peripheral Nerve Block within the Emergency Department in Patients Admitted with Low Energy Hip Fracture:  Percentage of patients that receive a peripheral nerve block for analgesia following diagnosis of isolated hip fracture within the emergency department. ' )
		,('THEPQR1',	'THEPQR1 : High Intensity Statin Prescribed for Acute and Subacute Ischemic Stroke and Transient Ischemic Attack (TIA) : Acute and subacute ischemic stroke and confirmed Transient Ischemic Attack (TIA) patients prescribed or continuing to take a high intensity statin at time of hospital discharge. ' )
		,('THEPQR2',	'THEPQR2 : Deprescribing Proton Pump Inhibitors for patients who do not meet criteria for long-term utilization : The percentage of patients on a Proton Pump Inhibitor with an appropriately documented indication or an order for discontinuation for not meeting criteria for long-term utilization. ' )
		,('THEPQR3',	'THEPQR3 : SGLT-2 inhibitors for patients with HFrEF with or without Type 2 Diabetes : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) less than or equal to 40% who were prescribed SGLT-2 Inhibitors with or without Type 2 diabetes during their SNF stay or discharge from either the hospital (inpatient or observation) or SNF. ' )
		,('THEPQR4',	'THEPQR4 : Consultation to Palliative Care for Patients with End Stage Conditions : The measure will identify patients with end stage diagnoses who meet any of the listed criteria for a palliative care consult. ' )
	;

	-- SELECT * FROM #mipsTitleData ORDER BY [PQRS#]; -- testing expect 60

	----------------
	-- get a list of whom we are working on and backup prior to the change
	----------------
	SELECT 
		*
	INTO 
		[CMS_PQRI_MEASURE_DACS-3687actions]
	FROM 
		[CMS_PQRI_MEASURE]
	WHERE
		([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] < GETDATE())
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
		AND [PQRS#] IN (SELECT DISTINCT [PQRS#] FROM #mipsTitleData)
	ORDER BY
		[PQRS#]
	;

	-- SELECT * FROM [CMS_PQRI_MEASURE_DACS-3687actions] ORDER BY [PQRS#]; -- testing expect 60
	
	----------------
	-- perform the update
	----------------
	UPDATE [CMS_PQRI_MEASURE]
		SET [MEASURE_TITLE] = #mipsTitleData.[MEASURE_TITLE]
	FROM 
		[CMS_PQRI_MEASURE] 
		JOIN #mipsTitleData ON [CMS_PQRI_MEASURE].[PQRS#] = [#mipsTitleData].[PQRS#]
	WHERE
		([CMS_PQRI_MEASURE].[EFFECTIVE_DATE] IS NULL OR [CMS_PQRI_MEASURE].[EFFECTIVE_DATE] < GETDATE())
		AND ([CMS_PQRI_MEASURE].[EXPIRATION_DATE] IS NULL OR [CMS_PQRI_MEASURE].[EXPIRATION_DATE] >= GETDATE())
		AND [CMS_PQRI_MEASURE].[PQRS#] IN (SELECT DISTINCT [PQRS#] FROM [#mipsTitleData])
		AND [CMS_PQRI_MEASURE].[MEASURE_TITLE] <> [#mipsTitleData].[MEASURE_TITLE]
	;
	
	----------------
	-- check our results by looking at the change list
	----------------
	SELECT 
		 [CMS_PQRI_MEASURE].[PQRS#]
		,[CMS_PQRI_MEASURE_DACS-3687actions].[MEASURE_TITLE] AS OldTitle
		,[CMS_PQRI_MEASURE].[MEASURE_TITLE] AS NewTitle
	FROM 
		[CMS_PQRI_MEASURE]
		JOIN [CMS_PQRI_MEASURE_DACS-3687actions] ON [CMS_PQRI_MEASURE].CMS_PQRI_MEASURE_ID = [CMS_PQRI_MEASURE_DACS-3687actions].CMS_PQRI_MEASURE_ID 
	WHERE 
		([CMS_PQRI_MEASURE].[EFFECTIVE_DATE] IS NULL OR [CMS_PQRI_MEASURE].[EFFECTIVE_DATE] < GETDATE())
		AND ([CMS_PQRI_MEASURE].[EXPIRATION_DATE] IS NULL OR [CMS_PQRI_MEASURE].[EXPIRATION_DATE] >= GETDATE())
		AND [CMS_PQRI_MEASURE].[PQRS#] IN (SELECT DISTINCT [PQRS#] FROM #mipsTitleData)
		AND [CMS_PQRI_MEASURE].[MEASURE_TITLE] <> [CMS_PQRI_MEASURE_DACS-3687actions].[MEASURE_TITLE]
	;

	DROP TABLE IF EXISTS #mipsTitleData;

-- rollback tran; -- testing
-- commit tran; -- testing

GO
-- End of 01) DACS-3687 - Script - CMS_PQRI_MEASURE - updates titles.SQL
GO

-- Start of 01) DACS-3697 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3697 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'AreAny2024MipsRuleSatisfiedByChart', @DestProc = 'AreAny2024MipsRuleSatisfiedByChart_DACS-3697';
GO

CREATE OR ALTER PROCEDURE [dbo].[AreAny2024MipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@ShowDebug BIT = 0
	,@TestAll BIT = 0
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0 
		RETURN;
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @serviceAgreementId INT;
	DECLARE @dateOfService DATETIME;
	
	SELECT 
		 @serviceAgreementId = [SERVICE_AGREEMENT_ID]
		,@dateOfService = [TIME_OF_SERVICE]
	FROM 
		[dbo].[chart] 
	WHERE
		[CHART_ID] = @ChartId;

	IF @serviceAgreementId IS NULL OR @serviceAgreementId <= 0 OR @dateOfService IS NULL 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad data returned for chart ' = @ChartId;
		RETURN;
	END;

	--PRINT('serviceAgreementId = ' + CAST(@serviceAgreementId AS VARCHAR(64)));
	--PRINT('dateOfService = ' + CAST(@dateOfService AS VARCHAR(64)));

	
	-----------------------------------
	-- get a list of MIPS to process
	-----------------------------------
	DECLARE @activeSAMipsRulesTable TABLE ( [NAME] VARCHAR(32) );
	
	INSERT INTO 
		@activeSAMipsRulesTable
	EXEC [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] @SaId=@serviceAgreementId, @Dos=@dateOfService

	DECLARE @countSaMips INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF @countSaMips <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No SA Mips for chart ' = @ChartId;
		RETURN;
	END;
	
	-----------------------------------
	-- load our single criteria MIPS for testing
	-----------------------------------
	DECLARE @active2024MipsRules1CTable TABLE ( [name] VARCHAR(32) );
	
	INSERT INTO 
		@active2024MipsRules1CTable ([NAME]) 
	VALUES 
		 ('THEPQR4')
		,('THEPQR3')
		,('THEPQR2')
		,('THEPQR1')
		,('HCPR27')
		,('HCPR24')							-- DACS-3593 - pippin - added
		,('ECPR39')
		,('ECPR46')
		,('ECPR51')
		,('187')
		,('116')
		,('134')
		,('066')
		,('416')
		,('415')
		,('332')
		,('326')
		,('001')
		,('047')
		,('007-A')
		,('007-B')
		,('118-A')
		,('118-B')
	;
	
	IF @TestAll <> 1 DELETE FROM @active2024MipsRules1CTable WHERE [NAME] NOT IN (SELECT [NAME] FROM @activeSAMipsRulesTable);

	DECLARE @count1CMips INT = (SELECT COUNT(*) FROM @active2024MipsRules1CTable);
	IF @count1CMips <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No 2024 1 criteria Mips for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT '@count1CMips = ' = @count1CMips;
	IF @ShowDebug = 1 SELECT * FROM @active2024MipsRules1CTable;

	----------------
	-- setup fetch loop to process each batch id in the list
	----------------
	DECLARE @ProcessCount INT = 1;
	DECLARE @TotalToProcessCount INT = @count1CMips;
	DECLARE @haveException INT = 0;

	DECLARE @FetchMipsName VARCHAR(32);
	DECLARE @FetchResultsTable TABLE ( [RESULT] VARCHAR(32), [QUESTION] VARCHAR(1024), [CODE] VARCHAR(32));
	
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT [NAME] FROM @active2024MipsRules1CTable;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName)
			);
	
		IF @FetchMipsName IS NOT NULL 
		BEGIN
			DELETE FROM @FetchResultsTable;
			
			DECLARE @SQL NVARCHAR(512) = N'EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type' + REPLACE(@FetchMipsName,'-','') + '] @ChartId=@fCId,@PqrsNum=@fPqrs,@Dos=@fDos;';
			DECLARE @ParmDefinition NVARCHAR(512) = N'@fCId INT, @fPqrs VARCHAR(32), @fDos DATETIME';

			IF @ShowDebug = 1 PRINT('  --> @SQL = ' + @SQL);
			SET @haveException = 0;
			
			BEGIN TRY 
				INSERT INTO 
					@FetchResultsTable
				EXEC sp_executesql @SQL, @ParmDefinition, @fCId=@ChartId, @fPqrs=@FetchMipsName, @fDos=@dateOfService;			
			END TRY
			BEGIN CATCH
				PRINT(' Exception Calling --> @SQL = ' + @SQL);
				SET @haveException = 1;
			END CATCH  

			IF @ShowDebug = 1 SELECT * FROM @FetchResultsTable;

			IF @haveException = 0 AND EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
			BEGIN
				IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @FetchMipsName;

				IF @TestAll <> 1 
				BEGIN 
				-- cleanup our cursor
					CLOSE cursorTempRows;  
					DEALLOCATE cursorTempRows; 
				END;

				SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
				IF @TestAll <> 1 RETURN;
			END;
		END;

		PRINT('-------------------');		
		
		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 
	
	-----------------------------------
	-- load our dual criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '005') OR @TestAll = 1
	BEGIN
		--PRINT('Processing: 005-A');
		DELETE FROM @FetchResultsTable;

		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A @ChartId=@ChartId,@PqrsNum='005-A',@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A');
			SET @haveException = 1;
		END CATCH  

		
		IF @haveException = 0 AND EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='005-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
		
		--PRINT('-------------------');		
		--PRINT('Processing: 005-B');
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B @ChartId=@ChartId,@PqrsNum='005-B',@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B');
			SET @haveException = 1;
		END CATCH  
		
		IF @haveException = 0 AND EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '005-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;
	
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '008') OR @TestAll = 1
	BEGIN
		--PRINT('-------------------');		
		--PRINT('Processing: 008-A');
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A @ChartId=@ChartId,@PqrsNum='008-A',@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A');
			SET @haveException = 1;
		END CATCH  

		IF @haveException = 0 AND EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='008-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
		
		--PRINT('-------------------');		
		--PRINT('Processing: 008-B');
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B @ChartId=@ChartId,@PqrsNum='008-B',@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B');
			SET @haveException = 1;
		END CATCH  
		
		IF @haveException = 0 AND EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '008-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;
	
	-----------------------------------
	-- load our PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	DECLARE @MipsNameToTest VARCHAR(32) = 'PQRANES1';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		--PRINT('-------------------');		
		--PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1');
			SET @haveException = 1;
		END CATCH  

		IF @haveException = 0 AND EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP60';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		--PRINT('-------------------');		
		--PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60');
			SET @haveException = 1;
		END CATCH  

		IF @haveException = 0 AND EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP61';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		--PRINT('-------------------');		
		--PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61');
			SET @haveException = 1;
		END CATCH  

		IF @haveException = 0 AND EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP64';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		--PRINT('-------------------');		
		--PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64');
			SET @haveException = 1;
		END CATCH  

		IF @haveException = 0 AND EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	-----------------------------------
	-- all done
	-----------------------------------
	--PRINT('-------------------');		
	IF @ShowDebug = 1 AND @TestAll <> 1 SELECT 'NO 2024 Mips satisfied for chart ' = @ChartId;
	RETURN;
END; -- end of SPROC

GO
/*
testing: 
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=126223457;
*/

-- End of 01) DACS-3697 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
GO

-- Start of 01) DACS-3625 - CREATE OR ALTER PROCEDURE - [dbo].[InsertChargeMasterQuickAdd].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3625 - CREATE OR ALTER PROCEDURE - [dbo].[InsertChargeMasterQuickAdd].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[InsertChargeMasterQuickAdd]
      @SaId INT
	, @Uid INT
	, @CptCode VARCHAR(5)
	, @BillingCode VARCHAR(20)
	, @Description VARCHAR(100)
	, @CMCategoryId INT 
	, @CMDepartmentId INT
	, @CMUsageCode INT
	, @PatientClassId INT
	, @EffectiveDate DATETIME = NULL
	, @ExpirationDate DATETIME= NULL
AS
BEGIN

	IF @SaId IS NULL OR @SaId <= 0
	BEGIN
		PRINT('Service Agreement Id is Invalid');
		RETURN -1;
	END;
	
	IF @Uid IS NULL OR @Uid <= 0
	BEGIN
		PRINT('User Profile Id is Invalid');
		RETURN -1;
	END;
	
	IF @EffectiveDate IS NULL
	BEGIN
		PRINT('Effective Date is Invalid');
		RETURN -3;
	END;

	IF @ExpirationDate IS NULL
	BEGIN
		PRINT('Expiration Date is Invalid');
		RETURN -4;
	END;
	

	DECLARE @DOS DATETIME = GETDATE();

	INSERT INTO [dbo].[CHARGE_MASTER]
		(	 
			 [SERVICE_AGREEMENT_ID]
			,[CPT_CODE]
            ,[BILLING_CODE]
            ,[DESCRIPTION]
            ,[CHARGE_MASTER_CATEGORY_ID]
            ,[CHARGE_MASTER_DEPT_ID]
            ,[CHARGE_MASTER_USAGE_CODE]
            ,[PATIENT_CLASS_ID]
            ,[EFFECTIVE_DATE]
            ,[EXPIRATION_DATE]
            ,[CREATION_DATE_TIME]
            ,[CREATING_USER_PROFILE_ID]
            ,[CHANGED_DATE_TIME]
            ,[CHANGING_USER_PROFILE_ID]
		)
	VALUES
		(
			 @SaId
			,@CptCode
            ,@BillingCode
            ,@Description
            ,@CMCategoryId
            ,@CMDepartmentId
            ,@CMUsageCode
            ,@PatientClassId
            ,@EffectiveDate
            ,@ExpirationDate
            ,@DOS
            ,@Uid
            ,@DOS
            ,@Uid
		)
		
	PRINT('CM Insert complete for ' + CAST(@SaId AS VARCHAR(32))+ ' : ' + @CptCode + ' : ' + + @BillingCode + ' : ' + @Description);
	RETURN SCOPE_IDENTITY();
END
GO
-- End of 01) DACS-3625 - CREATE OR ALTER PROCEDURE - [dbo].[InsertChargeMasterQuickAdd].SQL
GO

-- Start of 01) DACS-3662 - Script - CMS_PQRI_MEASURE_CODE - updating table data to improve UI to meet customer feedback.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3662 - Script - CMS_PQRI_MEASURE_CODE - updating table data to improve UI to meet customer feedback.SQL
------------------------------------------------------------------------------------
GO
-- begin tran; -- testing
	----------------
	/*

	todo list: (* = handled in this Script)
	*THEPQR1 - re order list 
	*415 - remove not from exclusion item and add definitions at bottom
	
	*/
	----------------
	
	--------------------------------------------
	-- Backup our data to be worked upon
	--------------------------------------------
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE', @DestTable = 'CMS_PQRI_MEASURE_DACS-3662';
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3662';


	--------------------------------------------
	-- Setup Script
	--------------------------------------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @measureId INT;
	DECLARE @measureName VARCHAR(32);
	
	DECLARE @foundRecordId INT;

	----------------
	-- THEPQR1  : remove the "not"
	----------------
	SET @measureName = 'THEPQR1';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
		DROP TABLE IF EXISTS #TempTHEPQR1Table;
		
		SELECT 
			*
		INTO 
			#TempTHEPQR1Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempTHEPQR1Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempTHEPQR1Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempTHEPQR1Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','DG848',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patient has any of the following: <ul><li>Chronic stroke</li><li>Enrolled in clinical trial</li><li>Transferred</li><li>Eloped or left AMA</li><li>Expired</li><li>Comfort measures documented</li><li>Discharged to hospice</li></ul> ')
				,(@measureId,'HCPCS','DG036',NULL,'2024-01-01','Performance Met: High-Intensity Statin prescribed or currently being taken. ')
				,(@measureId,'HCPCS','DG037',NULL,'2024-01-01','Performance Not Met: High-Intensity Statin neither prescribed or active - Reason not given. ')
				,(@measureId,'HCPCS','DG038',NULL,'2024-01-01','Denominator Exception: Documented medical reason for exclusion - Patient Refusal. <p><strong>HIGH-Intensity STATIN Medication List and Dosage:</strong><ul><li>Atorvastatin or Lipitor >= 40mg per day, OR</li><li>Rosuvastatin or Crestor or Ezallor >= 20 mg per day</li></ul></p> ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				--,(@measureId,'DQ411','ffff',NULL,'2024-01-01',' ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 415  : remove the "not"
	----------------
	SET @measureName = '415';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
		DROP TABLE IF EXISTS #Temp415Table;
		
		SELECT 
			*
		INTO 
			#Temp415Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp415Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp415Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp415Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9531',NULL,'2024-01-01','(DENOMINATOR EXCLUSION): Patient has documentation with ventricular shunt, brain tumor, multisystem trauma, or is currently taking an antiplatelet medication including: abciximab, anagrelide, cangrelor, cilostazol, clopidogrel, dipyridamole, eptifibatide, prasugrel, ticlopidine, ticagrelor, tirofiban, or vorapaxar? ')
				,(@measureId,'HCPCS','G9529',NULL,'2024-01-01','Performance Met: Patient with minor blunt head trauma had an appropriate indication(s) for a head CT. ')
				,(@measureId,'HCPCS','G9533',NULL,'2024-01-01','Performance Not Met: Patient with minor blunt head trauma did not have an appropriate indication(s) for a head CT. ')
				--,(@measureId,'HCPCS','ggg',NULL,'2024-01-01',' ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','G9530',NULL,'2024-01-01','Was Patient presented with a minor blunt head trauma and had a head CT ordered for trauma by an emergency care provider: (G9530)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
				
		-- before changes
		SELECT '415 MEASURE_HOTSHEET_URI before update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: null

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_HOTSHEET_URI] = '<p><img src="/WebPages/Images/MIPS/MIPS_415_definitions.png" alt="MIPS_415_definitions image" style="width: 400px;"></p> '
			, [MEASURE_TOOLTIP] = null
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '415 MEASURE_HOTSHEET_URI after update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
				
				
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';

-- rollback tran; -- testing
-- commit tran; -- testing

GO

-- End of 01) DACS-3662 - Script - CMS_PQRI_MEASURE_CODE - updating table data to improve UI to meet customer feedback.SQL
GO

-- Start of 01) DACS-3669 - Script - CMS_PQRI_MEASURE_CODE - updates start and end dates from associated entries within the CMS_PQRI_MEASURE table.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3669 - Script - CMS_PQRI_MEASURE_CODE - updates start and end dates from associated entries within the CMS_PQRI_MEASURE table.SQL
------------------------------------------------------------------------------------
GO
-- begin tran; -- testing

	--------------------------------------------
	-- Backup our data to be worked upon
	--------------------------------------------
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3669';

	----------------
	-- set parameters
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	----------------
	-- get a list of whom we are working on and backup prior to the change
	----------------
	DROP TABLE IF EXISTS #CMS_PQRI_MEASURE_CODE_DACS3669actions;
	
	SELECT top 100000
		 [CMS_PQRI_MEASURE_CODE_ID]
		--,[EFFECTIVE_DATE]
		--,[START_DATE]
		,[EXPIRATION_DATE]
		--,[END_DATE]
		,[PQRS#]
		--,cpmc.[CMS_PQRI_MEASURE_ID] AS cpmc_MEASURE_ID
	INTO 
		[#CMS_PQRI_MEASURE_CODE_DACS3669actions]
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		([END_DATE] IS NULL OR [END_DATE] > [EXPIRATION_DATE])
		AND [EFFECTIVE_DATE] < GETDATE()
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
		AND [EXPIRATION_DATE] <> [END_DATE] 
	ORDER BY
		cpm.[PQRS#] ASC
	;

	-- SELECT * FROM [#CMS_PQRI_MEASURE_CODE_DACS3669actions] ORDER BY [PQRS#]; -- testing expect 60
	
	DECLARE @countToProcess INT = (SELECT COUNT(*) FROM [#CMS_PQRI_MEASURE_CODE_DACS3669actions]);
	
	IF @countToProcess <= 0
	BEGIN 
		DROP TABLE IF EXISTS #CMS_PQRI_MEASURE_CODE_DACS3669actions;
		PRINT('No table records to process.  Exiting.');
		SELECT 'Exiting.' = 'No table records to process'
		RETURN;
	END;
	
	----------------
	-- perform the update
	----------------
	UPDATE [CMS_PQRI_MEASURE_CODE]
		SET [END_DATE] = tt.[EXPIRATION_DATE]
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		JOIN #CMS_PQRI_MEASURE_CODE_DACS3669actions tt ON cpmc.[CMS_PQRI_MEASURE_CODE_ID] = tt.[CMS_PQRI_MEASURE_CODE_ID]
	WHERE
		(cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > tt.[EXPIRATION_DATE])
		--AND tt.[EFFECTIVE_DATE] < GETDATE()
		AND (tt.[EXPIRATION_DATE] IS NULL OR tt.[EXPIRATION_DATE] >= GETDATE())
		AND tt.[EXPIRATION_DATE] <> cpmc.[END_DATE]
		AND cpmc.[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT DISTINCT [CMS_PQRI_MEASURE_CODE_ID] FROM #CMS_PQRI_MEASURE_CODE_DACS3669actions)
	;

	PRINT('Update Complete.  Done.');
	SELECT 'Done. Updated count' = CAST(@@ROWCOUNT AS VARCHAR(50));

-- rollback tran; -- testing
-- commit tran; -- testing
-- SELECT top 1000 * FROM [CMS_PQRI_MEASURE_CODE];  --testing
GO
-- End of 01) DACS-3669 - Script - CMS_PQRI_MEASURE_CODE - updates start and end dates from associated entries within the CMS_PQRI_MEASURE table.SQL
GO

-- Start of 02) DACS-3669 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3669 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
------------------------------------------------------------------------------------
GO

GO

GO
	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule

	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
		AND NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO


-- End of 02) DACS-3669 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
GO

-- Start of 03) DACS-3669 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3669 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
------------------------------------------------------------------------------------
GO

GO

GO
	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule

	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')) 
		AND NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;
	
	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	-- satisfied enough to at least ask a question at this point.

	-- do we have a Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
		SELECT TOP 5
			'411' AS 'RESULT' 
			, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
			, tdl.[Code] AS 'CODE'
		FROM 
			@tempDenominatorList tdl
		WHERE 
			tdl.[CodingSystem] = 'DQ411'
			AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
		ORDER BY
			tdl.[Code];
	ELSE
		SELECT 'RESULT'='411', 'QUESTION'=' ', 'CODE'='00001';


END -- end procedure

GO


-- End of 03) DACS-3669 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
GO

-- Start of 05) DACS-3669 - create or alter stored procedure - [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3669 - create or alter stored procedure - [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'AreAnyOriginalMipsRuleSatisfiedByChart', @DestProc = 'AreAnyOriginalMipsRuleSatisfiedByChart_DACS-3669';
GO

CREATE OR ALTER PROCEDURE [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@ShowDebug BIT = 0
	,@TestAll BIT = 0
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0 
		RETURN;

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Chart info
	----------------
	DECLARE @MipsChartMinimumInfo tMipsChartMinimumInfo;
	/*
	 ChartId INT
	,ServiceAgreementId INT
	,TimeOfService DATETIME NULL
	,Gender VARCHAR(32) NULL
	,PatientDob DATETIME NULL
	,PatientAge INT NULL
	,PatientClassId
	,UseTelehealth BIT NULL
	*/
	INSERT INTO @MipsChartMinimumInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug = 1 SELECT * FROM @MipsChartMinimumInfo
	
	IF NOT EXISTS (SELECT 1 FROM @MipsChartMinimumInfo)
	BEGIN 
		IF @ShowDebug = 1 SELECT 'Returned chart count is empty for ' = @ChartId;
		RETURN;
	END;

	DECLARE @chartServiceAgreementId INT;
	DECLARE @chartDateOfService DATETIME;
	DECLARE @chartGender VARCHAR(32) ;
	DECLARE @chartPatientDob DATETIME;
	DECLARE @chartPatientAge INT;
	DECLARE @chartPatientClassId INT;
	DECLARE @chartUseTelehealth BIT;
	
	SELECT TOP 1
		 @chartServiceAgreementId = [ServiceAgreementId]
		,@chartDateOfService = [TimeOfService] 
		,@chartGender = [Gender] 
		,@chartPatientDob = [PatientDob] 
		,@chartPatientAge = [PatientAge] 
		,@chartPatientClassId = [PatientClassId] 
		,@chartUseTelehealth = [UseTelehealth] 
	FROM 
		@MipsChartMinimumInfo;

	--PRINT('chartserviceAgreementId = ' + CAST(@chartServiceAgreementId AS VARCHAR(64)));
	--PRINT('chartdateOfService = ' + CAST(@chartDateOfService AS VARCHAR(64)));
	--PRINT('chartgender = ' + CAST(@chartGender AS VARCHAR(64)));
	--PRINT('chartpatientDob = ' + CAST(@chartPatientDob AS VARCHAR(64)));
	--PRINT('chartpatientAge = ' + CAST(@chartPatientAge AS VARCHAR(64)));
	--PRINT('chartPatientClassId = ' + CAST(@chartPatientClassId AS VARCHAR(64)));
	--PRINT('chartUseTelehealth = ' + CAST(@chartUseTelehealth AS VARCHAR(64)));

	IF @chartServiceAgreementId IS NULL OR @chartServiceAgreementId <= 0 OR @chartDateOfService IS NULL 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad data returned for chart ' = @ChartId;
		RETURN;
	END;


	---------------------------------
	-- get procedure codes for this chart
	---------------------------------
	DECLARE @TempFoundProcedureCodes t2xString32;
	INSERT INTO 
		@TempFoundProcedureCodes ( 
			 [Value1]
			,[Value2] 
		)
		SELECT * FROM [dbo].[udfMIPSSelectPresentProcedureCodesByChartId](@ChartId, @chartServiceAgreementId);
	
	IF NOT EXISTS (SELECT 1 FROM @TempFoundProcedureCodes)
	BEGIN
		-- if no procedure codes, then no MIPS will be satisfied
		IF @ShowDebug = 1 SELECT 'No procedure codes found for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT * FROM @TempFoundProcedureCodes;

	---------------------------------
	-- get diagnostic codes for this chart
	---------------------------------
	DECLARE @TempFoundDiagnosticCodes tIntString32;
	INSERT INTO 
		@TempFoundDiagnosticCodes ( 
			 [Id]
			,[Value] 
		)
		SELECT * FROM [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId](@ChartId);
	
	IF @ShowDebug = 1 SELECT * FROM @TempFoundDiagnosticCodes;

	-----------------------------------
	-- get a list of MIPS to process
	-----------------------------------
	DECLARE @activeSAMipsRulesTable TABLE ( [NAME] VARCHAR(32) );
	
	INSERT INTO 
		@activeSAMipsRulesTable
	EXEC [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] @SaId=@chartServiceAgreementId, @Dos=@chartDateOfService

	DECLARE @countSaMips INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF NOT EXISTS (SELECT 1 FROM @activeSAMipsRulesTable)
	BEGIN
		IF @ShowDebug = 1 SELECT 'No SA Mips for chart ' = @ChartId;
		RETURN;
	END;
	
	-----------------------------------
	-- remove the MIPS 2024 entries from the list since they are checked by another SPROC of a similar name separately
	-----------------------------------
	DECLARE @active2024MipsRulesTable TABLE ( [name] VARCHAR(32) );
	
	INSERT INTO 
		@active2024MipsRulesTable ([NAME]) 
	VALUES 
		 ('THEPQR4')
		,('THEPQR3')
		,('THEPQR2')
		,('THEPQR1')
		,('HCPR27')
		,('ECPR39')
		,('ECPR46')
		,('ECPR51')
		,('187')
		,('116')
		,('134')
		,('066')
		,('416')
		,('415')
		,('332')
		,('326')
		,('001')
		,('047')
		,('007-A')
		,('007-B')
		,('118-A')
		,('118-B')
		,('005-A')
		,('005-B')
		,('008-A')
		,('008-B')
		,('PQRANES1')
		,('ACEP60')
		,('HCPR24')
		,('ACEP61')
		,('ACEP64')
	;
	
	DELETE FROM @activeSAMipsRulesTable WHERE [NAME] IN (SELECT [NAME] FROM @active2024MipsRulesTable);

	DECLARE @TotalToProcessCount INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF @TotalToProcessCount <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No Original Mips for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1
	BEGIN
		SELECT '@TotalToProcessCount = ' = @TotalToProcessCount;
		SELECT * FROM @activeSAMipsRulesTable;
	END;

	----------------
	-- setup fetch loop to process each batch id in the list
	----------------
	DECLARE @ProcessCount INT = 1;

	DECLARE @FetchMeasureId INT;
	DECLARE @FetchMipsName VARCHAR(32);
	DECLARE @FetchGender VARCHAR(32);
	DECLARE @FetchFromAgeYears INT;
	DECLARE @FetchToAgeYears INT;
	DECLARE @FetchRequiresEmOnly BIT;
	
	DECLARE @FetchMipsMeasureInfo tMipsMeasureInfo;
	DECLARE @FetchMipsDiagCodes tIntString32;
	DECLARE @FetchMipsProcCodes tIntString32;
	
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT DISTINCT [NAME] FROM @activeSAMipsRulesTable;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): MIPS Name ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName)
			);
	
		IF @FetchMipsName IS NULL OR LEN(LTRIM(RTRIM(@FetchMipsName))) <= 0
		BEGIN
			PRINT('  --> FetchMipsName is invalid ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName));
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;
		
		SET @FetchMeasureId = -1;
		DELETE FROM @FetchMipsMeasureInfo;
		DELETE FROM @FetchMipsDiagCodes;
		DELETE FROM @FetchMipsProcCodes;

		----------------
		-- Measure info
		----------------
		INSERT INTO @FetchMipsMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@FetchMipsName, @ChartDateOfService);
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsMeasureInfo

		----------------
		-- none of the original (pre 2024) MIPS will have [Req2DxOr3Cpt] set to a 1.
		----------------
		SET @FetchMeasureId = (SELECT TOP 1 [MeasureId] FROM @FetchMipsMeasureInfo WHERE ([Req2DxOr3Cpt] IS NULL OR [Req2DxOr3Cpt] = 0));
			
		IF @FetchMeasureId IS NULL OR @FetchMeasureId <= 0
		BEGIN 
			PRINT('  --> FetchMeasureId failed [Req2DxOr3Cpt] check for ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName));
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;

		SELECT TOP 1
			 @FetchMipsName = [MeasureName]
			,@FetchGender = [Gender] 
			,@FetchFromAgeYears = [FromAge] 
			,@FetchToAgeYears = [ToAge] 
			,@FetchRequiresEmOnly = [RequiresEmOnly] 
		FROM 
			@FetchMipsMeasureInfo;
			
		--PRINT(' --> FetchMeasureId = ' + CAST(@FetchMeasureId AS VARCHAR(64)));
		--PRINT(' --> FetchMipsName = ' + CAST(@FetchMipsName AS VARCHAR(64)));
		--PRINT(' --> FetchGender = ' + CAST(@FetchGender AS VARCHAR(64)));
		--PRINT(' --> FetchFromAgeYears = ' + CAST(@FetchFromAgeYears AS VARCHAR(64)));
		--PRINT(' --> FetchToAgeYears = ' + CAST(@FetchToAgeYears AS VARCHAR(64)));
		--PRINT(' --> FetchRequiresEmOnly = ' + CAST(@FetchRequiresEmOnly AS VARCHAR(64)));

		/*  -- does not work quite right.  might need to use the pat class id and or the location of service fields instead
		IF @FetchRequiresEmOnly = 1 
			AND EXISTS (SELECT 1 FROM @TempFoundProcedureCodes WHERE [Value1] IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395'))
		BEGIN 
			-- to maintain compatibility, the original MIPS only check the following if the field is SET
			-- may update later to check the PATIENT_CLASS_ID or LOCATION_OF_SERVICE instead, but for compatibility leave as is.
			IF @TestAll <> 1
			BEGIN
				SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
				-- cleanup our cursor
				CLOSE cursorTempRows;  
				DEALLOCATE cursorTempRows;
				RETURN 1;
			END
			ELSE
				PRINT('!!!! Satisfied MIPS (EM Only test) = ' + CAST(@FetchMipsName AS VARCHAR(64)));
		END;
		*/
		
		----------------
		-- check Gender = gender: U,X,F,M
		----------------
		IF @FetchGender IS NOT NULL 
			AND @FetchGender <> 'B' 
			AND (
					@ChartGender IS NULL
					OR (@ChartGender IS NOT NULL AND @ChartGender IN ('M','F') AND (@ChartGender <> @FetchGender))	
				)
		BEGIN
			PRINT(' --> Gender check failed for ' + @FetchMipsName + '[' + IIF(@FetchGender IS NULL, 'NULL', @FetchGender) + ':' + IIF(@ChartGender IS NULL, 'NULL', @ChartGender) + ']');
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;
		
		----------------
		-- check age
		----------------
		IF @FetchFromAgeYears IS NOT NULL OR @FetchToAgeYears IS NOT NULL
		BEGIN
			IF @chartDateOfService IS NULL
			BEGIN 
				PRINT(' --> chartDateOfService is invalid for age test.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;

			IF @chartPatientAge IS NULL OR @chartPatientAge < 0
				SET @chartpatientAge = dbo.fGetPatientAgeInYears(@chartpatientAge, @chartDateOfService, @chartPatientDob);

			IF @chartPatientAge IS NULL OR @chartPatientAge < 0 OR @chartPatientAge > 999
			BEGIN 
				PRINT(' --> chartPatientAge is invalid for age test.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;

			-- check the age constraints
			IF @FetchFromAgeYears IS NULL SET @FetchFromAgeYears = 0;
			IF @FetchToAgeYears IS NULL SET @FetchToAgeYears = 999;
			
			IF @chartPatientAge < @FetchFromAgeYears OR @chartPatientAge > @FetchToAgeYears
			BEGIN 
				PRINT(' --> chartPatientAge does not fall within the valid MIPS range.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;	

	
		----------------
		-- get the C4 data
		----------------
		INSERT INTO @FetchMipsProcCodes SELECT * FROM [dbo].[udfMipsSelectCodeTableByCodingSystem](@FetchMeasureId,'C4');
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsProcCodes;

		IF EXISTS (SELECT 1 FROM @FetchMipsProcCodes)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM @TempFoundProcedureCodes WHERE [Value1] IN (SELECT [Value] FROM @FetchMipsProcCodes))
			BEGIN
				PRINT(' --> No Procedure Codes are within C4 test list.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;


		----------------
		-- get the I10 data
		----------------
		INSERT INTO @FetchMipsDiagCodes SELECT * FROM [dbo].[udfMipsSelectCodeTableByCodingSystem](@FetchMeasureId,'I10');
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsDiagCodes;

		IF EXISTS (SELECT 1 FROM @FetchMipsDiagCodes)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM @TempFoundDiagnosticCodes WHERE [Value] IN (SELECT [Value] FROM @FetchMipsDiagCodes))
			BEGIN
				PRINT(' --> No Diagnostic Codes are within I10 test list.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;


		----------------
		-- MIPS passes if we make it all the way here
		----------------
		--PRINT('!!!! MIPS [' + @FetchMipsName + '] Satisfied for Cid: ' + CAST(@ChartId AS VARCHAR(32)));

		IF @TestAll <> 1
		BEGIN
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
			-- cleanup our cursor
			CLOSE cursorTempRows;  
			DEALLOCATE cursorTempRows;
			RETURN 1;
		END;

		PRINT('-------------------');		
		
		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 
	
	IF @ShowDebug = 1 AND @TestAll <> 1 SELECT 'NO Original Mips satisfied for chart ' = @ChartId;

END; -- end of SPROC

GO


-- End of 05) DACS-3669 - create or alter stored procedure - [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart].SQL
GO

-- Start of 01) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A', @DestProc = 'PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A_DACS-3607';
GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 005, there are 2 valid decision paths.  the data is stored by PQRS# '005-A' and '005-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @ChartId', 'Code' = 'ERR-1';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @MeasureId', 'Code' = 'ERR-1';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	


	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid time of service to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient Age to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test', 'Code' = 'ERR-2';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;
	

	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis in our inclusive diagnosis listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD10))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A] @ChartId=2100113717,@PqrsNum='005-A',@Dos='7/28/2024'--,@ShowDebug=1
EXEC [PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A_DACS-3607] @ChartId=2100113717,@PqrsNum='005-A',@Dos='7/28/2024'--,@ShowDebug=1
*/
-- End of 01) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A].SQL
GO

-- Start of 02) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B', @DestProc = 'PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B_DACS-3607';
GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 005, there are 2 valid decision paths.  the data is stored by PQRS# '005-A' and '005-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @ChartId', 'Code' = 'ERR-1';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;


	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @MeasureId', 'Code' = 'ERR-1';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid time of service to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient Age to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test', 'Code' = 'ERR-2';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;
	

	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis in our inclusive diagnosis listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD10))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B] @ChartId=2100113717,@PqrsNum='005-B',@Dos='7/28/2024'--,@ShowDebug=1
EXEC [PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B_DACS-3607] @ChartId=2100113717,@PqrsNum='005-B',@Dos='7/28/2024'--,@ShowDebug=1
*/


-- End of 02) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B].SQL
GO

-- Start of 03) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A', @DestProc = 'PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A_DACS-3607';
GO

CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 008, there are 2 valid decision paths.  the data is stored by PQRS# '008-A' and '008-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @ChartId', 'Code' = 'ERR-1';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @MeasureId', 'Code' = 'ERR-1';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid time of service to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient Age to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test', 'Code' = 'ERR-2';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------
	-- do we have a Diagnosis in our inclusive diagnosis listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD10))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;
	

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A] @ChartId=2100113749,@PqrsNum='008-A',@Dos='6/17/2024'--,@ShowDebug=1
EXEC [PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A_DACS-3607] @ChartId=2100113749,@PqrsNum='008-A',@Dos='6/17/2024'--,@ShowDebug=1
*/
-- End of 03) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A].SQL
GO

-- Start of 04) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B', @DestProc = 'PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B_DACS-3607';
GO

CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 008, there are 2 valid decision paths.  the data is stored by PQRS# '008-A' and '008-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @ChartId', 'Code' = 'ERR-1';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	

	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @MeasureId', 'Code' = 'ERR-1';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid time of service to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient Age to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test', 'Code' = 'ERR-2';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------
	-- do we have a Diagnosis in our inclusive diagnosis listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD10))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B] @ChartId=2100113749,@PqrsNum='008-B',@Dos='6/17/2024'--,@ShowDebug=1
EXEC [PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B_DACS-3607] @ChartId=2100113749,@PqrsNum='008-B',@Dos='6/17/2024'--,@ShowDebug=1
*/
-- End of 04) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B].SQL
GO

-- Start of 05) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60', @DestProc = 'PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60_DACS-3607';
GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of ACEP60, there is 1 valid decision path.  This script is designed around this example.
	-- checks chart age within range of 18 to 50
	-- checks that the chart patient class is Emergency department (ED)
	-- requires one CPT code within the DG1P1 GROUP 
	-- requires one ICD10 code within the DG1P2 GROUP 
	-- and EXCLUDES a CPT code within the DG2P1 GROUP
	
	-- Modified to only return 1 result value (1 "one") to speed up the process
	-- Modified to not perform gender check since affects all genders
	
	-- returns 1 on Satisfaction of Rule - Now needs ACS human selection of Performance status
	
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors, or not an ED patient class
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @ChartId', 'Code' = 'ERR-1';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;


	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @MeasureId', 'Code' = 'ERR-1';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS 
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid time of service to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient Age to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test', 'Code' = 'ERR-2';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient class id to test', 'Code' = 'ERR-2';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1','23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does NOT have a Physician service class of (1) or Location of Service value of (23)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;
	
	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------
	-- do we have Patient had a diagnosis of syncope (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient had a diagnosis of syncope (ICD10))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met. :', 'Code' = '????';

END -- end procedure

GO
/*
testing:
EXEC [PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60] @ChartId=2100113935,@PqrsNum='ACEP60',@Dos='6/17/2024'--,@ShowDebug=1
EXEC [PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60_DACS-3607] @ChartId=2100113935,@PqrsNum='ACEP60',@Dos='6/17/2024'--,@ShowDebug=1
*/
-- End of 05) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60].SQL
GO

-- Start of 06) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61', @DestProc = 'PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61_DACS-3607';
GO

CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of ACEP61, there is 1 valid decision path.  This script is designed around this example.
	-- checks chart age within range of 0 to 18
	-- checks that the chart patient class is Emergency department (ED) = "Place of Service: 23"
	-- requires one CPT code within the DG1P1 GROUP 
	-- requires one ICD10 code within the DG1P2 GROUP 
	
	-- Only return 1 result value (1 "one") to speed up the process
	
	-- returns 1 on Satisfaction of Rule - Now needs ACS human selection of Performance status
	
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors, or not an ED patient class
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @ChartId', 'Code' = 'ERR-1';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;


	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @MeasureId', 'Code' = 'ERR-1';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	 
	----------------
	-- check for age CONSTRAINTS ex Patients aged 0 to < 18 years on date of encounter.  these will be used for defaults but overridable by database settings due to customer wants.
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid time of service to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient Age to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test', 'Code' = 'ERR-2';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient class id to test', 'Code' = 'ERR-2';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1','23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does NOT have a Physician service class of (1) or Location of Service value of (23)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------
	-- do we have Patient had a diagnosis of Asthma, Bronchiolitis or Croup (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient had a diagnosis of Asthma, Bronchiolitis or Croup (ICD10))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met. :', 'Code' = '????';

END -- end procedure

GO
/*
testing:
EXEC [PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61] @ChartId=2100113936,@PqrsNum='ACEP61',@Dos='6/17/2024'--,@ShowDebug=1
EXEC [PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61_DACS-3607] @ChartId=2100113936,@PqrsNum='ACEP61',@Dos='6/17/2024'--,@ShowDebug=1
*/
-- End of 06) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61].SQL
GO

-- Start of 07) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64].SQL

------------------------------------------------------------------------------------
-- 07) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64', @DestProc = 'PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64_DACS-3607';
GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of ACEP64, there is 1 valid decision path.  This script is designed around this example.
	-- checks chart age within range of 18 years or older
	-- checks that the chart patient class is Emergency department (ED) = "Place of Service: 23"
	-- requires one CPT code within the DG1P1 GROUP 
	-- requires one ICD10 code within the DG1P2 GROUP 
	
	-- Only return 1 result value (1 "one") to speed up the process
	
	-- returns 1 on Satisfaction of Rule - Now needs ACS human selection of Performance status
	
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors, or not an ED patient class
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @ChartId', 'Code' = 'ERR-1';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;


	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @MeasureId', 'Code' = 'ERR-1';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	 
	----------------
	-- check for age CONSTRAINTS ex Patients aged 0 to < 18 years on date of encounter.  these will be used for defaults but overridable by database settings due to customer wants.
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid time of service to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient Age to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test', 'Code' = 'ERR-2';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient class id to test', 'Code' = 'ERR-2';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1','23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does NOT have a Physician service class of (1) or Location of Service value of (23)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------
	-- do we have Patient had a diagnosis of DVT (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient had a diagnosis of DVT (ICD10))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met. :', 'Code' = '????';

END -- end procedure

GO
/*
testing:
EXEC [PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64] @ChartId=2100113936,@PqrsNum='ACEP64',@Dos='6/17/2024'--,@ShowDebug=1
EXEC [PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64_DACS-3607] @ChartId=2100113936,@PqrsNum='ACEP64',@Dos='6/17/2024'--,@ShowDebug=1
*/
-- End of 07) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64].SQL
GO

-- Start of 08) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1].SQL

------------------------------------------------------------------------------------
-- 08) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1', @DestProc = 'PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1_DACS-3607';
GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of PQRANES1, there is 1 valid decision path.  This script is designed around this example.
	-- checks chart age within range of 65 years or older
	-- checks that the chart patient class is Emergency department (ED) = "Place of Service: 23"
	-- requires one CPT code within the DG1P1 GROUP 
	-- requires one ICD10 code within the DG1P2 GROUP 
	
	-- Only return 1 result value (1 "one") to speed up the process
	
	-- returns 1 on Satisfaction of Rule - Now needs ACS human selection of Performance status
	
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors, or not an ED patient class
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @ChartId', 'Code' = 'ERR-1';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;


	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @MeasureId', 'Code' = 'ERR-1';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	 
	----------------
	-- check for age CONSTRAINTS ex Patients aged 0 to < 18 years on date of encounter.  these will be used for defaults but overridable by database settings due to customer wants.
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid time of service to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient Age to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test', 'Code' = 'ERR-2';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient class id to test', 'Code' = 'ERR-2';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1','23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does NOT have a Physician service class of (1) or Location of Service value of (23)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------
	-- do we have diagnosis of hip fracture (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (diagnosis of hip fracture (ICD10))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met. :', 'Code' = '????';

END -- end procedure

GO
/*
testing:
EXEC [PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1] @ChartId=2100113944,@PqrsNum='PQRANES1',@Dos='6/17/2024'--,@ShowDebug=1
EXEC [PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1_DACS-3607] @ChartId=2100113944,@PqrsNum='PQRANES1',@Dos='6/17/2024'--,@ShowDebug=1
*/
-- End of 08) DACS-3607 - create or alter stored procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1].SQL
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
