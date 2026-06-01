USE [RevCycleDB]
GO

/****** Object:  Trigger [dbo].[UpdateChartDemographicHistory]    Script Date: 2/11/2022 12:31:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Chart Demographics
ALTER TRIGGER [dbo].[UpdateChartDemographicHistory] ON [dbo].[CHART]
WITH EXEC AS CALLER
AFTER UPDATE
AS
DECLARE @NewChartStatusID INT
DECLARE @OldChartStatusID INT
DECLARE @IsInHistoryTable INT
DECLARE @IsInSecondAuditHistoryTable INT
DECLARE @Count INT
SET @Count = (SELECT COUNT(*) FROM inserted)

IF @Count = 1
  BEGIN
    SELECT
    @NewChartStatusID = i.chart_status_id
    FROM
    inserted i
    SELECT
    @OldChartStatusID = d.Chart_Status_ID
    FROM
    deleted d
    SELECT
    @IsInHistoryTable = COUNT(*)
    FROM
    CHART_DEMOGRAPHIC_HISTORY cdh
    WHERE
    cdh.CHART_ID = (SELECT CHART_ID FROM inserted)

	SELECT @IsInSecondAuditHistoryTable = COUNT(*)
    FROM
    CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh
    WHERE
    cdh.CHART_ID = (SELECT CHART_ID FROM inserted)

    IF @OldChartStatusID IN (1, 2)
      BEGIN
        IF @NewChartStatusID IN (3)
          BEGIN
            IF @IsInHistoryTable IN (0)
              BEGIN
                INSERT INTO
                  CHART_DEMOGRAPHIC_HISTORY(
                    CHART_ID,
                    ADMISSION_DATE_TIME,
                    ARRIVAL_DATE_TIME,
                    MEDICAL_RECORD_NUM,
                    PATIENT_DISPOSITION_MAP_ID,
                    PHYSICIAN_ID,
                    SERVICE_AGREEMENT_ARRIVAL_MODE_ID,
                    SERVICE_AGREEMENT_TRIAGE_ACUITY_ID,
                    TIME_TO_ROOM,
                    GENDER,
                    RESIDENT_PARTICIPATED_IN_CARE,
                    FINANCIAL_CLASS_CD,
                    PATIENT_DOB,
                    NURSE_PRACTITIONER_ID,
                    TIME_OF_SERVICE,
                    PATIENT_DISPOSITION_ID,
                    FACILITY_ADMIN_CHART_ID,
                    TIME_OF_DIS,
                    CONDITION_OF_ACCIDENT_ID,
                    CLINIC_ID,
                    ATTESTATION_SIGNED_BY_ATTENDING,
                    SCRIBE_ID,
                    LAST_ENCOUNTER_DATE,
                    LAST_MENSTRUAL_PERIOD,
                    RESIDENT_ID,
                    PATIENT_AGE,
                    TIME_OF_PHYS_EVAL,
                    TIME_OF_TRIAGE,
                    MEDICAL_EXAMINER_NOTIFIED,
                    ORGAN_DONATION,
                    SEEN_IN_ED_WITHIN_48_HOURS_OF_OR,
                    PROVIDER_EVAL_PERFORMED_BY_IND,
					PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID,
					USE_TIME_BASED_CHARGE_CAPTURE,
					TIME_BASED_PHYSICIAN_LOS,
					USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE,
					PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID,
					NO_LCD_SERVICES
                    )
                  SELECT
                    CHART_ID,
                    ADMISSION_DATE_TIME,
                    ARRIVAL_DATE_TIME,
                    MEDICAL_RECORD_NUM,
                    PATIENT_DISPOSITION_MAP_ID,
                    PHYSICIAN_ID,
                    SERVICE_AGREEMENT_ARRIVAL_MODE_ID,
                    SERVICE_AGREEMENT_TRIAGE_ACUITY_ID,
                    TIME_TO_ROOM,
                    GENDER,
                    RESIDENT_PARTICIPATED_IN_CARE,
                    FINANCIAL_CLASS_CD,
                    PATIENT_DOB,
                    NURSE_PRACTITIONER_ID,
                    TIME_OF_SERVICE,
                    PATIENT_DISPOSITION_ID,
                    FACILITY_ADMIN_CHART_ID,
                    TIME_OF_DIS,
                    CONDITION_OF_ACCIDENT_ID,
                    CLINIC_ID,
                    ATTESTATION_SIGNED_BY_ATTENDING,
                    SCRIBE_ID,
                    LAST_ENCOUNTER_DATE,
                    LAST_MENSTRUAL_PERIOD,
                    RESIDENT_ID,
                    PATIENT_AGE,
                    TIME_OF_PHYS_EVAL,
                    TIME_OF_TRIAGE,
                    MEDICAL_EXAMINER_NOTIFIED,
                    ORGAN_DONATION,
                    SEEN_IN_ED_WITHIN_48_HOURS_OF_OR,
                    PROVIDER_EVAL_PERFORMED_BY_IND,
					PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID,
					USE_TIME_BASED_CHARGE_CAPTURE,
					TIME_BASED_PHYSICIAN_LOS,
					USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE,
					PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID,
					NO_LCD_SERVICES
                  FROM
                    inserted
              END
            ELSE
              BEGIN
                UPDATE CHART_DEMOGRAPHIC_HISTORY
                SET
                  ADMISSION_DATE_TIME = inserted.ADMISSION_DATE_TIME,
                  ARRIVAL_DATE_TIME = inserted.ARRIVAL_DATE_TIME,
                  MEDICAL_RECORD_NUM = inserted.MEDICAL_RECORD_NUM,
                  PATIENT_DISPOSITION_MAP_ID = inserted.PATIENT_DISPOSITION_MAP_ID,
                  PHYSICIAN_ID = inserted.PHYSICIAN_ID,
                  SERVICE_AGREEMENT_ARRIVAL_MODE_ID = inserted.SERVICE_AGREEMENT_ARRIVAL_MODE_ID,
                  SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = inserted.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID,
                  TIME_TO_ROOM = inserted.TIME_TO_ROOM,
                  GENDER = inserted.GENDER,
                  RESIDENT_PARTICIPATED_IN_CARE = inserted.RESIDENT_PARTICIPATED_IN_CARE,
                  FINANCIAL_CLASS_CD=inserted.FINANCIAL_CLASS_CD,
                  PATIENT_DOB=inserted.PATIENT_DOB,
                  NURSE_PRACTITIONER_ID=inserted.NURSE_PRACTITIONER_ID,
                  TIME_OF_SERVICE=inserted.TIME_OF_SERVICE,
                  PATIENT_DISPOSITION_ID=inserted.PATIENT_DISPOSITION_ID,
                  FACILITY_ADMIN_CHART_ID=inserted.FACILITY_ADMIN_CHART_ID,
                  TIME_OF_DIS=inserted.TIME_OF_DIS,
                  CONDITION_OF_ACCIDENT_ID=inserted.CONDITION_OF_ACCIDENT_ID,
                  CLINIC_ID=inserted.CLINIC_ID,
                  ATTESTATION_SIGNED_BY_ATTENDING=inserted.ATTESTATION_SIGNED_BY_ATTENDING,
                  SCRIBE_ID=inserted.SCRIBE_ID,
                  LAST_ENCOUNTER_DATE=inserted.LAST_ENCOUNTER_DATE,
                  LAST_MENSTRUAL_PERIOD=inserted.LAST_MENSTRUAL_PERIOD,
                  RESIDENT_ID=inserted.RESIDENT_ID,
                  PATIENT_AGE=inserted.PATIENT_AGE,
                  TIME_OF_PHYS_EVAL=inserted.TIME_OF_PHYS_EVAL,
                  TIME_OF_TRIAGE=inserted.TIME_OF_TRIAGE,
                  MEDICAL_EXAMINER_NOTIFIED=inserted.MEDICAL_EXAMINER_NOTIFIED,
                  ORGAN_DONATION=inserted.ORGAN_DONATION,
                  SEEN_IN_ED_WITHIN_48_HOURS_OF_OR=inserted.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR,
                  PROVIDER_EVAL_PERFORMED_BY_IND=inserted.PROVIDER_EVAL_PERFORMED_BY_IND,
				  PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID=inserted.PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID,
				  USE_TIME_BASED_CHARGE_CAPTURE=inserted.USE_TIME_BASED_CHARGE_CAPTURE,
				  TIME_BASED_PHYSICIAN_LOS=inserted.TIME_BASED_PHYSICIAN_LOS,
				  USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE=inserted.USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE,
				  PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID=inserted.PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID,
				  NO_LCD_SERVICES=inserted.NO_LCD_SERVICES
                FROM CHART_DEMOGRAPHIC_HISTORY
                JOIN inserted on inserted.CHART_ID = CHART_DEMOGRAPHIC_HISTORY.CHART_ID
                WHERE
                  CHART_DEMOGRAPHIC_HISTORY.CHART_ID = inserted.CHART_ID
              END
          END
      END

    IF @OldChartStatusID <> 8
      BEGIN
        IF @NewChartStatusID = 8
          BEGIN
            IF @IsInSecondAuditHistoryTable IN (0)
              BEGIN
                DECLARE @SecondChartID INT
                SELECT @SecondChartID = i.Chart_id
                FROM inserted i
				EXEC COPY_CHART_DATA_SECOND_LEVEL_AUDIT_HISTORY_TABLES @SecondChartID 
                INSERT INTO
                  CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY(
                    CHART_ID,
                    ADMISSION_DATE_TIME,
                    ARRIVAL_DATE_TIME,
                    MEDICAL_RECORD_NUM,
                    PATIENT_DISPOSITION_MAP_ID,
                    PHYSICIAN_ID,
                    SERVICE_AGREEMENT_ARRIVAL_MODE_ID,
                    SERVICE_AGREEMENT_TRIAGE_ACUITY_ID,
                    TIME_TO_ROOM,
                    GENDER,
                    RESIDENT_PARTICIPATED_IN_CARE,
                    FINANCIAL_CLASS_CD,
                    PATIENT_DOB,
                    NURSE_PRACTITIONER_ID,
                    TIME_OF_SERVICE,
                    PATIENT_DISPOSITION_ID,
                    FACILITY_ADMIN_CHART_ID,
                    TIME_OF_DIS,
                    CONDITION_OF_ACCIDENT_ID,
                    CLINIC_ID,
                    ATTESTATION_SIGNED_BY_ATTENDING,
                    SCRIBE_ID,
                    LAST_ENCOUNTER_DATE,
                    LAST_MENSTRUAL_PERIOD,
                    RESIDENT_ID,
                    PATIENT_AGE,
                    TIME_OF_PHYS_EVAL,
                    TIME_OF_TRIAGE,
                    MEDICAL_EXAMINER_NOTIFIED,
                    ORGAN_DONATION,
                    SEEN_IN_ED_WITHIN_48_HOURS_OF_OR,
                    PROVIDER_EVAL_PERFORMED_BY_IND,
					PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID,
					USE_TIME_BASED_CHARGE_CAPTURE,
					TIME_BASED_PHYSICIAN_LOS,
					USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE,
					PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID,
					NO_LCD_SERVICES
					)
                  SELECT
                    CHART_ID,
                    ADMISSION_DATE_TIME,
                    ARRIVAL_DATE_TIME,
                    MEDICAL_RECORD_NUM,
                    PATIENT_DISPOSITION_MAP_ID,
                    PHYSICIAN_ID,
                    SERVICE_AGREEMENT_ARRIVAL_MODE_ID,
                    SERVICE_AGREEMENT_TRIAGE_ACUITY_ID,
                    TIME_TO_ROOM,
                    GENDER,
                    RESIDENT_PARTICIPATED_IN_CARE,
                    FINANCIAL_CLASS_CD,
                    PATIENT_DOB,
                    NURSE_PRACTITIONER_ID,
                    TIME_OF_SERVICE,
                    PATIENT_DISPOSITION_ID,
                    FACILITY_ADMIN_CHART_ID,
                    TIME_OF_DIS,
                    CONDITION_OF_ACCIDENT_ID,
                    CLINIC_ID,
                    ATTESTATION_SIGNED_BY_ATTENDING,
                    SCRIBE_ID,
                    LAST_ENCOUNTER_DATE,
                    LAST_MENSTRUAL_PERIOD,
                    RESIDENT_ID,
                    PATIENT_AGE,
                    TIME_OF_PHYS_EVAL,
                    TIME_OF_TRIAGE,
                    MEDICAL_EXAMINER_NOTIFIED,
                    ORGAN_DONATION,
                    SEEN_IN_ED_WITHIN_48_HOURS_OF_OR,
                    PROVIDER_EVAL_PERFORMED_BY_IND,
					PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID,
					USE_TIME_BASED_CHARGE_CAPTURE,
					TIME_BASED_PHYSICIAN_LOS,
					USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE,
					PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID,
					NO_LCD_SERVICES
                  FROM
                    INSERTED
              END
          END
      END
  END
GO

ALTER TABLE [dbo].[CHART] ENABLE TRIGGER [UpdateChartDemographicHistory]
GO

