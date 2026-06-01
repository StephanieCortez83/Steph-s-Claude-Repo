----------------------------------------------
-- 02) DACS-1671 - Qualify Insert into PHYSICIAN_SERVICE_TIME_BASED_CALCULATION.sql
-----------------------------------------------
USE [RevCycleDB]
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-----------------------------------------------
-- Set some variables
-----------------------------------------------
DECLARE @MDM2023EffectiveDate datetime = '2023-01-01'
DECLARE @MDM2023ExpirationDate datetime = '2099-12-31'

-- at this time there should be 0 (zero) records unless this script has already been processed.
DECLARE @countPresent INT = 
	(
		SELECT 
			COUNT(*) 
		FROM 
			[dbo].[PHYSICIAN_SERVICE_TIME_BASED_CALCULATION] 
		WHERE 
			[GOVT_COMMERCIAL_IND] = 'A'
	);

IF @countPresent > 0
BEGIN
	PRINT('Alternate data already present [' + CAST(@countPresent AS varchar(20)) + '].  Skipping inserts.');
	RETURN;
END

-- perform insert
INSERT INTO [dbo].[PHYSICIAN_SERVICE_TIME_BASED_CALCULATION] 
	(
	 [PHYSICIAN_SERVICE_CLASS_CD]
     ,[FROM_MINUTES]
     ,[TO_MINUTES]
     ,[SERVICE_LEVEL_CD]
     ,[ADDITIONAL_MINUTES_SPAN]
     ,[EACH_ADDITIONAL_MINUTES_SPAN_CPT_CODE]
     ,[EFFECTIVE_DATE]
     ,[EXPIRATION_DATE]
     ,[GOVT_COMMERCIAL_IND]
	) 
VALUES
-- PHYSICIAN_SERVICE_CLASS_CD	FROM_MINUTES	TO_MINUTES	SERVICE_LEVEL_CD	ADDITIONAL_MINUTES_SPAN	EACH_ADDITIONAL_MINUTES_SPAN_CPT_CODE	EFFECTIVE_DATE	EXPIRATION_DATE	GOVT_COMMERCIAL_IND

--        [EnumDescription("Consultation Inpatient")]  
--        InpatientConsultation = 10,
(10, 35, 44 , 2 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(10, 45, 59 , 3 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(10, 60, 79 , 4 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(10, 80, 94 , 5 , 15, 	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),


--        [EnumDescription("Consultation Outpatient")]  
--        OutPatientConsultation = 11,
(11, 20, 29 , 2 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(11, 30, 39 , 3 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(11, 40, 54 , 4 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(11, 55, 69 , 5 , 15, 	'99417', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),


-----------------------------------------------------------------------------------------

--        [EnumDescription("Office or Other Outpatient Services - New")]
--        OfficeOtherOutPatientNew = 2,
(2 , 15, 29	, 2	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(2 , 30, 44	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(2 , 45, 59	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(2 , 60, 88	, 5	, 15,	'99417', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Office or Other Outpatient Services - Established")]
--        OfficeOtherOutPatientEstablished = 3,
(3 , 10, 19	, 2	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(3 , 20, 29	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(3 , 30, 39	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(3 , 40, 68	, 5	, 15,	'99417', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("ED Observation")]
--        EdObs = 5,
(5 , 40, 54	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(5 , 55, 74	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(5 , 75, 104, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Inpatient Admission/Discharge Same Day ")]
--        InpatientAdmissionDischargeSameDay = 7,
(7 , 45, 69	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(7 , 70, 84	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(7 , 85, 114, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Inpatient Initial Day ")]
--        InpatientInitialDay = 8,
(8 , 40, 54	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(8 , 55, 74	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(8 , 75, 104, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Inpatient Subsequent Day/Discharge Day ")]
--        InpatientSubsequentDischargeSameDay = 9,
(9 , 25, 34	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(9 , 35, 49	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(9 , 50, 79	, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Nursing Home-Initial Day")]
--        NursingHomeInitialDay = 12,
(12, 25, 34	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(12, 35, 44	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(12, 45, 94	, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Nursing Home-Subsequent Day")]
--        NursingHomeSubsequentDay = 13,
(13, 10, 14	, 2	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(13, 15, 29	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(13, 30, 44	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(13, 45, 84	, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Observation - Initial Day")]
--        ObservationInitialDay = 16,
(16, 40, 54	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(16, 55, 74	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(16, 75, 104, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Observation - Subsequent/Discharge Day")]
--        ObservationSubsequentDischargeDay = 17,
(17, 25, 34	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(17, 35, 49	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(17, 50, 79	, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A')



