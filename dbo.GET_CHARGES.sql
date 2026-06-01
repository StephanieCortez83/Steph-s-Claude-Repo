SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_CHARGES]
@m_Code int, @m_ChartID varchar(50), @m_Status int, @m_Facility varchar(MAX)
WITH EXEC AS CALLER
AS
SELECT sa.[DESCRIPTION] [Service Agreement],
     cl.[DESCRIPTION] [Clinic],
     c.FACILITY_CHART_ID [Patient ID],
	   c.FACILITY_ADMIN_CHART_ID [EMPI],
	   c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME [Patient Name],
	   c.TIME_OF_SERVICE [DOS],
     pdm.FACILITY_PATIENT_DISPOSITION [Disposition],
	   CASE c.CHART_STATUS_ID
      WHEN 2 THEN cs.[DESCRIPTION] + ' - ' + pr.[DESCRIPTION]
      WHEN 5 THEN cs.[DESCRIPTION] + ' ' + CONVERT(VARCHAR, c.SENT_DATE, 101)
      ELSE cs.[DESCRIPTION]
      END [ACS Status],
      
	 (
		  SELECT TOP 1 CASE 
				  WHEN @m_Code = 0 AND (ADJUSTMENT_IND <> 'Y' OR QUANTITY > 0) -- Handle adjustment where the level is removed
					  THEN CPT_CODE
				  WHEN @m_Code = 1 AND (ADJUSTMENT_IND <> 'Y' OR QUANTITY > 0) THEN BILLING_CODE
          ELSE NULL
				  END
		  FROM SENT_PROCEDURE
		  WHERE CHART_ID = c.CHART_ID
			  AND CLASS = 'FL'
      ORDER BY ADJUSTMENT_IND DESC
		  ) [Facility Level],
      
	  LTRIM(STUFF((
				  SELECT ', ' + CASE @m_Code
						            WHEN 0 THEN CPT_CODE
                        ELSE BILLING_CODE END-- + '-' + QUANTITY
				  FROM SENT_PROCEDURE
				  WHERE CHART_ID = c.CHART_ID
					  AND CLASS = 'FP'
				  ORDER BY CPT_CODE
				  FOR XML PATH(''),
					  TYPE
				  ).value('.', 'VARCHAR(MAX)'), 1, 1, '')) [Facility Procedure],
          
	  (
		  SELECT TOP 1 CASE 
				  WHEN @m_Code = 0 AND (ADJUSTMENT_IND <> 'Y' OR QUANTITY > 0) -- Handle adjustment where the level is removed
					  THEN CPT_CODE
				  WHEN @m_Code = 1 AND (ADJUSTMENT_IND <> 'Y' OR QUANTITY > 0) THEN BILLING_CODE
          ELSE NULL
				  END
		  FROM SENT_PROCEDURE
		  WHERE CHART_ID = c.CHART_ID
			  AND CLASS = 'PL'
      ORDER BY ADJUSTMENT_IND DESC
		  ) [Physician Level],
      
	  LTRIM(STUFF((
				  SELECT ', ' + CASE @m_Code
						            WHEN 0 THEN CPT_CODE
                        ELSE BILLING_CODE END-- + '-' + QUANTITY
				  FROM SENT_PROCEDURE
				  WHERE CHART_ID = c.CHART_ID
					  AND CLASS = 'PP'
				  ORDER BY CPT_CODE
				  FOR XML PATH(''),
					  TYPE
				  ).value('.', 'VARCHAR(MAX)'), 1, 1, '')) [Physician Procedure],
          
	  LTRIM(STUFF((
				  SELECT ', ' + CASE @m_Code
						            WHEN 0 THEN CPT_CODE
                        ELSE BILLING_CODE END-- + '-' + QUANTITY
				  FROM SENT_PROCEDURE
				  WHERE CHART_ID = c.CHART_ID
					  AND CLASS = 'IP'
				  ORDER BY CPT_CODE
				  FOR XML PATH(''),
					  TYPE
				  ).value('.', 'VARCHAR(MAX)'), 1, 1, '')) [Infusion-Injection],
          
    LTRIM(STUFF((
          SELECT ', ' + CASE @m_Code
						            WHEN 0 THEN cm.CPT_CODE
                        ELSE cm.BILLING_CODE END-- + '-' coer.UNITS
          FROM CHARGE_MASTER cm INNER JOIN CHART_OBSERVATION_ENCOUNTER_RESULT coer
            ON cm.CHARGE_MASTER_ID = coer.CHARGE_MASTER_ID
          WHERE coer.CHART_ID = c.CHART_ID
          ORDER BY cm.CPT_CODE DESC
          FOR XML PATH(''),
            TYPE
          ).value('.', 'VARCHAR(MAX)'), 1, 1, '')) [Observation],

    LTRIM(STUFF((
				  SELECT ', ' + ICD9_CODE
				  FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
				  WHERE CHART_ID = c.CHART_ID
				  ORDER BY CASE WHEN POSTING_ORDER IS NULL THEN 1
                        ELSE 0 END, POSTING_ORDER
				  FOR XML PATH(''),
					  TYPE
				  ).value('.', 'VARCHAR(MAX)'), 1, 1, '')) [Diagnoses],
          
	   fp.EMPLOYEE_IDENTIFIER [Provider],
     coder.LAST_NAME + ', ' + coder.FIRST_NAME [Coder],
	   auditor.LAST_NAME + ', ' + auditor.FIRST_NAME [Auditor],
     c.CODER_COMMENT [Comments]
				
FROM (((((((PENDING_REASON pr WITH (NOLOCK)
			RIGHT OUTER JOIN CHART c WITH (NOLOCK) ON (pr.PENDING_REASON_ID = c.PENDING_REASON_ID))
			LEFT OUTER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON (fp.FACILITY_PROF_ID = c.PHYSICIAN_ID))
			LEFT OUTER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON (cl.CLINIC_ID = c.CLINIC_ID))
			LEFT OUTER JOIN USER_PROFILE auditor WITH (NOLOCK) ON (auditor.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID))
			LEFT OUTER JOIN USER_PROFILE coder WITH (NOLOCK) ON (coder.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID))
      LEFT OUTER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON (sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID))
      LEFT OUTER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON (pdm.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID))
			LEFT OUTER JOIN CHART_STATUS cs WITH (NOLOCK) ON (cs.CHART_STATUS_ID = c.CHART_STATUS_ID)
      
WHERE (c.SERVICE_AGREEMENT_ID IN (SELECT * FROM SPLITSTRING(@m_Facility, ','))) AND
	    (c.FACILITY_CHART_ID LIKE @m_ChartID) AND
      (c.CHART_STATUS_ID = CASE @m_Status
                            WHEN 0
                            THEN c.CHART_STATUS_ID
                            ELSE @m_Status
                            END);
GO
