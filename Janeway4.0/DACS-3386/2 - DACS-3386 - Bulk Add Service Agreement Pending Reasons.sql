DECLARE @IsTesting bit = 0

IF OBJECT_ID('tempdb..#tmp') IS NOT NULL
BEGIN
    DROP TABLE #tmp
END

CREATE TABLE #tmp
(
	[SERVICE_AGREEMENT_ID] INT NULL,
	[NAME] VARCHAR(50) NOT NULL,
	[EFFECTIVE_DATE] DATETIME NULL,
	[EXPIRATION_DATE] DATETIME NULL,
	[IS_ACTIVE] bit DEFAULT 0
)

INSERT INTO #tmp
(
	[NAME]
)
SELECT 'Buchanan General Hospital' UNION ALL
SELECT 'CHOA - Arthur M Blank' UNION ALL
SELECT 'CHOA - Transport' UNION ALL
SELECT 'CHOA-EHC' UNION ALL
SELECT 'CHOA-RHC' UNION ALL
SELECT 'CHOA-UC Chamblee Brookhaven' UNION ALL
SELECT 'CHOA-UC Cherokee' UNION ALL
SELECT 'CHOA-UC Forsyth' UNION ALL
SELECT 'CHOA-UC Hamilton Creek' UNION ALL
SELECT 'CHOA-UC Hudson Bridge' UNION ALL
SELECT 'CHOA-UC North Point' UNION ALL
SELECT 'CHOA-UC Satellite Blvd' UNION ALL
SELECT 'CHOA-UC Town Center' UNION ALL
SELECT 'CHOP - King of Prussia Behavioral Health' UNION ALL
SELECT 'CHOP - King of Prussia ED' UNION ALL
SELECT 'CHOP - Philadelphia Campus Behavioral Health' UNION ALL
SELECT 'CHOP - Philadelphia Campus ED' UNION ALL
SELECT 'Clarinda - Cardiology' UNION ALL
SELECT 'Clarinda - Family Medicine' UNION ALL
SELECT 'Clarinda - OB GYN' UNION ALL
SELECT 'Clarinda- Ambulance' UNION ALL
SELECT 'Clarinda- Behavioral Health' UNION ALL
SELECT 'Clarinda- Hand Surgery' UNION ALL
SELECT 'Clarinda- Internal Medicine' UNION ALL
SELECT 'Clarinda- Observation' UNION ALL
SELECT 'Clarinda- Pro-Inpatient - Swing Bed' UNION ALL
SELECT 'Clarinda- Psych' UNION ALL
SELECT 'Clarinda- Same Day Surgery' UNION ALL
SELECT 'Clarinda- Urology' UNION ALL
SELECT 'Clarinda- Walk-In Clinic' UNION ALL
SELECT 'Claxton-Hepburn Medical Center' UNION ALL
SELECT 'CMH - ADHD TH Home' UNION ALL
SELECT 'CMH - Adolescent Med INPT' UNION ALL
SELECT 'CMH - Allergy Clinic' UNION ALL
SELECT 'CMH - Allergy Outreach' UNION ALL
SELECT 'CMH - Allergy TH Home' UNION ALL
SELECT 'CMH - Beacon Clinic' UNION ALL
SELECT 'CMH - Beacon TH' UNION ALL
SELECT 'CMH - Beacon TH Home' UNION ALL
SELECT 'CMH - Blue Valley Urgent Care' UNION ALL
SELECT 'CMH - Cardiology Outreach' UNION ALL
SELECT 'CMH - Cardiology TH Home' UNION ALL
SELECT 'CMH - Cardiology-CV Clinic' UNION ALL
SELECT 'CMH - Dermatology Clinic' UNION ALL
SELECT 'CMH - Dermatology INPT' UNION ALL
SELECT 'CMH - Dermatology Outreach' UNION ALL
SELECT 'CMH - Dermatology TH Home' UNION ALL
SELECT 'CMH - Diabetes Endo Clinic' UNION ALL
SELECT 'CMH - East Urgent Care' UNION ALL
SELECT 'CMH - ED Consultations' UNION ALL
SELECT 'CMH - Endocrine INPT' UNION ALL
SELECT 'CMH - Endocrine Outreach' UNION ALL
SELECT 'CMH - Endocrine TH Home' UNION ALL
SELECT 'CMH - ENT Clinic' UNION ALL
SELECT 'CMH - Gastroenterology Clinic' UNION ALL
SELECT 'CMH - Gastroenterology Outreach' UNION ALL
SELECT 'CMH - Gastroenterology TH Home' UNION ALL
SELECT 'CMH - General Surgery' UNION ALL
SELECT 'CMH - Genetics Clinic' UNION ALL
SELECT 'CMH - HEM ONC Clinic' UNION ALL
SELECT 'CMH - HEM ONC Outreach' UNION ALL
SELECT 'CMH - HEM ONC TH Home' UNION ALL
SELECT 'CMH - Infectious Disease' UNION ALL
SELECT 'CMH - Infectious Disease Outreach' UNION ALL
SELECT 'CMH - Infectious Disease TH Home' UNION ALL
SELECT 'CMH - Kansas ED' UNION ALL
SELECT 'CMH - Kidney Clinic' UNION ALL
SELECT 'CMH - Kidney Outreach' UNION ALL
SELECT 'CMH - Kidney TH' UNION ALL
SELECT 'CMH - Kidney TH Home' UNION ALL
SELECT 'CMH - Main' UNION ALL
SELECT 'CMH - Neurology Clinic' UNION ALL
SELECT 'CMH - Neurology INPT' UNION ALL
SELECT 'CMH - Neurology Outreach' UNION ALL
SELECT 'CMH - Neurology TH Home' UNION ALL
SELECT 'CMH - Neurosurgery Clinic' UNION ALL
SELECT 'CMH - Northland Urgent Care' UNION ALL
SELECT 'CMH - Operation Breakthrough' UNION ALL
SELECT 'CMH - Operation Breakthrough TH Home' UNION ALL
SELECT 'CMH - Ophthalmology Clinic' UNION ALL
SELECT 'CMH - Ortho SportMed Outreach' UNION ALL
SELECT 'CMH - Ortho SportMed TH Home' UNION ALL
SELECT 'CMH - Orthopedic Clinic' UNION ALL
SELECT 'CMH - OT-PT' UNION ALL
SELECT 'CMH - Pain Management Clinic' UNION ALL
SELECT 'CMH - Pain Management TH Home' UNION ALL
SELECT 'CMH - Palliative' UNION ALL
SELECT 'CMH - Palliative TH Home' UNION ALL
SELECT 'CMH - PCC ADHD' UNION ALL
SELECT 'CMH - PCC Clinic' UNION ALL
SELECT 'CMH - PCC Down Syndrome' UNION ALL
SELECT 'CMH - PCC Weight' UNION ALL
SELECT 'CMH - Pulmonology Clinic' UNION ALL
SELECT 'CMH - Pulmonology Outreach' UNION ALL
SELECT 'CMH - Pulmonology TH Home' UNION ALL
SELECT 'CMH - Radiology' UNION ALL
SELECT 'CMH - Radiology INTERVENTIONAL' UNION ALL
SELECT 'CMH - RADOUT' UNION ALL
SELECT 'CMH - Rehab Medicine Clinic' UNION ALL
SELECT 'CMH - Rehab Outreach' UNION ALL
SELECT 'CMH - Rehab TH Home' UNION ALL
SELECT 'CMH - Rheumatology Clinic' UNION ALL
SELECT 'CMH - Rheumatology Outreach' UNION ALL
SELECT 'CMH - Rheumatology TH Home' UNION ALL
SELECT 'CMH - Sleep Clinic' UNION ALL
SELECT 'CMH - Sleep Outreach' UNION ALL
SELECT 'CMH - Special Care Clinic' UNION ALL
SELECT 'CMH - Surgery Outreach' UNION ALL
SELECT 'CMH - Surgery TH Home' UNION ALL
SELECT 'CMH - Teen Adolescent Clinic' UNION ALL
SELECT 'CMH - Teen Eating Disorder' UNION ALL
SELECT 'CMH - Teen Primary Care' UNION ALL
SELECT 'CMH - Urology Clinic' UNION ALL
SELECT 'CMH - Urology Outreach' UNION ALL
SELECT 'CMH - Urology TH Home' UNION ALL
SELECT 'CMH - Weight Mgmt Outreach' UNION ALL
SELECT 'CMH - Weight Mgmt TH Home' UNION ALL
SELECT 'Community Med Ctr Falls City, NE - Cardiology' UNION ALL
SELECT 'Community Med Ctr Falls City, NE - ED OBS' UNION ALL
SELECT 'Community Med Ctr Falls City, NE - EMG' UNION ALL
SELECT 'Community Med Ctr Falls City, NE - ENT' UNION ALL
SELECT 'Community Med Ctr Falls City, NE - Inpatient' UNION ALL
SELECT 'Community Med Ctr Falls City, NE - OBGYN' UNION ALL
SELECT 'Community Med Ctr Falls City, NE - Oncology' UNION ALL
SELECT 'Community Med Ctr Falls City, NE - Surgery' UNION ALL
SELECT 'Community Med Ctr Falls City, NE - Urology' UNION ALL
SELECT 'Community Medical Center - Falls City,NE - UroGyn' UNION ALL
SELECT 'Cone Health - Alamance EPIC' UNION ALL
SELECT 'Cone Health - Annie Penn' UNION ALL
SELECT 'Cone Health - Cone Memorial Hospital' UNION ALL
SELECT 'Cone Health - Drawbridge' UNION ALL
SELECT 'Cone Health - MedCenter High Point' UNION ALL
SELECT 'Cone Health - OBS Surgical Accounts' UNION ALL
SELECT 'Cone Health - Wesley Long' UNION ALL
SELECT 'Gottlieb Memorial Hospital' UNION ALL
SELECT 'Grady Memorial Hospital' UNION ALL
SELECT 'Grady Memorial Hospital - OBED' UNION ALL
SELECT 'Griffin Hospital' UNION ALL
SELECT 'Heart of the Rockies' UNION ALL
SELECT 'Hollywood Presbyterian Medical Center' UNION ALL
SELECT 'Jackson County Memorial Hospital - Anesthesia' UNION ALL
SELECT 'Kell West- Inpatient' UNION ALL
SELECT 'MedStar - Georgetown University Hospital' UNION ALL
SELECT 'MedStar - Medicine Clinics - Facility Only' UNION ALL
SELECT 'MedStar - Psychiatry Clinics - Facility Only' UNION ALL
SELECT 'Mountain Health - Cabell Huntington Hospital' UNION ALL
SELECT 'Mountain Health - Ironton' UNION ALL
SELECT 'MultiCare Good Samaritan Hospital - Parkland' UNION ALL
SELECT 'MultiCare Mary Bridge Childrens Hospital' UNION ALL
SELECT 'MultiCare Valley Hospital' UNION ALL
SELECT 'MultiCare Yakima ED Profee' UNION ALL
SELECT 'Nemours Childrens Hospital - Florida' UNION ALL
SELECT 'Nemours Childrens Narcoosee Urgent Care' UNION ALL
SELECT 'Nemours Childrens Urgent Care Osceola' UNION ALL
SELECT 'Nemours Childrens Urgent Care Waterford Lakes' UNION ALL
SELECT 'NW - Central DuPage' UNION ALL
SELECT 'NW - Delnor-Community Hospital' UNION ALL
SELECT 'NW - Huntley' UNION ALL
SELECT 'NW - Kishwaukee' UNION ALL
SELECT 'NW - Lake Forest' UNION ALL
SELECT 'NW - Lake Forest - Grayslake' UNION ALL
SELECT 'NW - McHenry' UNION ALL
SELECT 'NW - Northwestern Memorial' UNION ALL
SELECT 'NW - Palos' UNION ALL
SELECT 'NW - Valley West' UNION ALL
SELECT 'Onslow Memorial Hospital' UNION ALL
SELECT 'Pipeline - Coast Plaza Hospital CPH' UNION ALL
SELECT 'Pipeline - Community Hospital of Huntington Park' UNION ALL
SELECT 'Pipeline - East LA Doctors Hospital ELA' UNION ALL
SELECT 'Pipeline - Memorial Hospital of Gardena' UNION ALL
SELECT 'Port Lavaca Memorial Medical Center - Facility' UNION ALL
SELECT 'Putnam County Hospital - Surgery' UNION ALL
SELECT 'Resilience Weiss Memorial' UNION ALL
SELECT 'Resilience West Suburban' UNION ALL
SELECT 'Roane - Arnoldsburg Medical Clinic' UNION ALL
SELECT 'Roane - Southern Roane Clinic' UNION ALL
SELECT 'Roane - Walton Clinic' UNION ALL
SELECT 'Roane General - Surgery' UNION ALL
SELECT 'Roane General Clinical DX' UNION ALL
SELECT 'Roane General Clinical OP - EMG' UNION ALL
SELECT 'Roane General Clinical OP - OR' UNION ALL
SELECT 'Roane General Hospital' UNION ALL
SELECT 'Roane General Hospital - Inpatient' UNION ALL
SELECT 'Roane General Hospital - Profee Observation' UNION ALL
SELECT 'Roane General Med Center Walk-in Clinic' UNION ALL
SELECT 'Roane General Medical Clinic' UNION ALL
SELECT 'Roane General Recurring Encounters' UNION ALL
SELECT 'Roane Oncology Infusion Clinic' UNION ALL
SELECT 'RRH-Clifton Springs Hosp' UNION ALL
SELECT 'RRH-Newark-Wayne Comm  Hosp' UNION ALL
SELECT 'RRH-Rochester General Hospital' UNION ALL
SELECT 'RRH-STL-Canton Potsdam EPIC' UNION ALL
SELECT 'RRH-STL-Gouverneur EPIC' UNION ALL
SELECT 'RRH-STL-Massena EPIC' UNION ALL
SELECT 'RRH-United Memorial Medical Center' UNION ALL
SELECT 'SMMC - Urology' UNION ALL
SELECT 'University of Missouri UC - Providence' UNION ALL
SELECT 'Valley Presbyterian Hospital' UNION ALL
SELECT 'Washington County Regional of GA' UNION ALL
SELECT 'Wells ER' UNION ALL
SELECT 'Williamson Health - ED - Interface' UNION ALL
SELECT 'WVU Medicine - Thomas Health' UNION ALL
SELECT 'York Berwick Walk-In Clinic' UNION ALL
SELECT 'York Hospital' UNION ALL
SELECT 'York Kittery Walk-In Clinic' UNION ALL
SELECT 'York Sanford Walk-In Clinic' UNION ALL
SELECT 'York Walk-In Care'

UPDATE #tmp
SET #tmp.[SERVICE_AGREEMENT_ID] = [SERVICE_AGREEMENT].[SERVICE_AGREEMENT_ID]
   ,#tmp.[EFFECTIVE_DATE] = [SERVICE_AGREEMENT].[EFFECTIVE_DATE]
   ,#tmp.[EXPIRATION_DATE] = [SERVICE_AGREEMENT].[EXPIRATION_DATE]
FROM [SERVICE_AGREEMENT]
INNER JOIN [FACILITY]
		ON [FACILITY].[FACILITY_ID] = [SERVICE_AGREEMENT].[FACILITY_ID]
INNER JOIN #tmp
		ON #tmp.[NAME] = [FACILITY].[NAME]

-- uncomment to show missing SAs
--SELECT * FROM #tmp 
--WHERE [SERVICE_AGREEMENT_ID] IS NULL

-- uncomment to show inactive SAs
--SELECT * FROM #tmp
--WHERE [SERVICE_AGREEMENT_ID] IS NOT NULL
--  AND [EFFECTIVE_DATE] > GETDATE()
--   OR [EXPIRATION_DATE] < GETDATE()

-- find active SAs
UPDATE #tmp
  SET [IS_ACTIVE] = 1
WHERE [SERVICE_AGREEMENT_ID] IS NOT NULL
  AND [EFFECTIVE_DATE] <= GETDATE()
  AND [EXPIRATION_DATE] >= GETDATE()

-- uncomment to show active SAs
SELECT * FROM #tmp 
WHERE [IS_ACTIVE] = 1

------------------------------------------------------------
-- add the new pending reason
------------------------------------------------------------ 
-- comment this section out if the update to the service
-- agreement pending reasons fail for some reason and 
-- hardcode the new pending reason id
------------------------------------------------------------
DECLARE @DESCRIPTION VARCHAR(100)
DECLARE @DEFAULT_PENDING_REASON_CATEGORY_ID INT
DECLARE @DEFAULT_RANK_VALUE INT
DECLARE @DEFICIENCY_CODE VARCHAR(10) = NULL
DECLARE	@EXTENDED_DESCRIPTION VARCHAR(4000)  = NULL
DECLARE @PENDING_REASON_ID INT

SELECT @DESCRIPTION = 'Global Managerial Review'
	  ,@DEFAULT_PENDING_REASON_CATEGORY_ID = 3 -- Awaiting Management Action; this can be found in PENDING_REASON_CATEGORY
	  ,@DEFAULT_RANK_VALUE = 5000

BEGIN TRY
	BEGIN TRANSACTION

	INSERT INTO [dbo].[PENDING_REASON]
	(
		[DESCRIPTION]
	   ,[DEFAULT_PENDING_REASON_CATEGORY_ID]
	   ,[DEFAULT_RANK_VALUE]
	)
	VALUES
	(
		@DESCRIPTION
	   ,@DEFAULT_PENDING_REASON_CATEGORY_ID
	   ,@DEFAULT_RANK_VALUE
	);

	SELECT @PENDING_REASON_ID = @@IDENTITY

	IF @IsTesting = 1
	BEGIN
		ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		COMMIT TRANSACTION
	END

END TRY
BEGIN CATCH
    -- Rollback the transaction if an error occurs
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    -- Print the error message
    PRINT 'An error occurred adding a new pending reason: ' + ERROR_MESSAGE()
END CATCH

PRINT 'New Pending Reason Id: ' + CAST(@PENDING_REASON_ID AS VARCHAR)

------------------------------------------------------------
-- start updating the service agreement pending reasons
------------------------------------------------------------
DECLARE @SERVICE_AGREEMENT_ID INT
DECLARE @NAME VARCHAR(50)
DECLARE @COUNT INT = 0
DECLARE @EFFECTIVE_DATE DATETIME

SELECT @COUNT = COUNT(*)
FROM #tmp
WHERE [IS_ACTIVE] = 1

PRINT 'Expecting to update ' + CAST(@COUNT AS VARCHAR) + ' Service Agreements'

DECLARE ServiceAgreementCursor CURSOR FOR
SELECT DISTINCT [SERVICE_AGREEMENT_ID]
			   ,[NAME]
			   ,[EFFECTIVE_DATE]
FROM #tmp
WHERE [IS_ACTIVE] = 1

-- open the cursor
OPEN ServiceAgreementCursor

-- fetch the first row
FETCH NEXT FROM ServiceAgreementCursor INTO @SERVICE_AGREEMENT_ID, @NAME, @EFFECTIVE_DATE

BEGIN TRY
BEGIN TRANSACTION

	-- loop through the rows and insert
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Print the fetched values
		PRINT 'Inserting pending reason(s) for SERVICE_AGREEMENT_ID: ' + CAST(@SERVICE_AGREEMENT_ID AS VARCHAR) + ', NAME: ' + @NAME
	
		INSERT INTO [SERVICE_AGREEMENT_PENDING_REASON]
		(
			[SERVICE_AGREEMENT_ID]
		   ,[PENDING_REASON_ID]
		   ,[EFFECTIVE_DATE]
		   ,[EXPIRATION_DATE]
		   ,[PENDING_REASON_CATEGORY_ID]
		   ,[RANK_VALUE]
		)
		SELECT @SERVICE_AGREEMENT_ID
			  ,@PENDING_REASON_ID
			  ,@EFFECTIVE_DATE
			  ,'2099-12-31'
			  ,3
			  ,5000

		FETCH NEXT FROM ServiceAgreementCursor INTO @SERVICE_AGREEMENT_ID, @NAME, @EFFECTIVE_DATE
	END

	IF @IsTesting = 1
	BEGIN
		ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		COMMIT TRANSACTION
	END

	-- close and deallocate the cursor
	CLOSE ServiceAgreementCursor
	DEALLOCATE ServiceAgreementCursor
END TRY
BEGIN CATCH
    -- rollback the transaction if an error occurs
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    -- print the error message
    PRINT 'An error occurred adding pending reason(s) to the service agreement: ' + ERROR_MESSAGE()
END CATCH

-- drop the #tmp table
IF @IsTesting = 0
BEGIN
	DROP TABLE #tmp
END