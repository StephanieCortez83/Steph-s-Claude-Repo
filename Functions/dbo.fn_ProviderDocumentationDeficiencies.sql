SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[fn_ProviderDocumentationDeficiencies]
	(@SentFrom date, @SentThru date)

RETURNS table
AS
Return

SELECT x.*,
    CASE 
        WHEN x.ReasonId > 0
            THEN substring(x.PotentialCPT, 4, 2) + substring(x.CPTCode, 4, 2) + CASE 
                    WHEN x.ReasonId = 1
                        THEN 'h'
                    WHEN x.ReasonId = 2
                        THEN 'r'
                    WHEN x.ReasonId = 3
                        THEN 'x'
                    WHEN x.ReasonId = 4
                        THEN 'e'
                    END
        ELSE NULL
        END DeficiencyCode
FROM (
    SELECT c.FACILITY_ID 'FacilityId',
        f.NAME 'FacilityName',
        c.SERVICE_AGREEMENT_ID 'ServiceAgreementId',
        sa.COMPANY_ID 'CompanyId',
        c.CHART_ID 'ChartID',
        c.[MEDICAL_RECORD_NUM] 'MRN',
        c.FACILITY_ADMIN_CHART_ID 'AltChartID',
        (
            SELECT pd.DESCRIPTION
            FROM PATIENT_DISPOSITION pd WITH (NOLOCK)
            WHERE c.PATIENT_DISPOSITION_ID = pd.PATIENT_DISPOSITION_ID
            ) 'PatientDisposition',
        (
            SELECT scribe.LAST_NAME + ', ' + scribe.FIRST_NAME
            FROM FACILITY_PROFESSIONAL scribe WITH (NOLOCK)
            WHERE scribe.FACILITY_PROF_ID = c.SCRIBE_ID
            ) AS 'Scribe',
        (
            SELECT TOP 1 icd.medium_desc
            FROM ICD_9_CM icd WITH (NOLOCK)
            WHERE c.primary_complaint = icd.icd9_code
            ) AS 'Diagnosis',
        (
            SELECT TOP 1 up.LAST_NAME + ', ' + up.FIRST_NAME
            FROM user_profile up WITH (NOLOCK)
            WHERE up.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
            ) 'Coder',
        (
            SELECT dbo.GetPhysicianServiceReasonDescription(c.chart_ID)
            ) 'HistoryReason',
        (
            SELECT TOP 1 t.DESCRIPTION
            FROM (
                SELECT TOP 1 1 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK),
                    physician_service_eval pse WITH (NOLOCK),
                    physician_service ps WITH (NOLOCK)
                WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_HISTORY_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                    AND pcl.PHYSICIAN_SERVICE_CLASS_CD = psrc.PHYSICIAN_SERVICE_CLASS_CD
                    AND pse.CHART_ID = c.CHART_ID
                    AND ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID
                    AND psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = ps.PHYSICIAN_SERVICE_GUIDELINE_ID
                
                UNION
                
                SELECT TOP 1 2 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK)
                WHERE c.EDITED_BY_EXPERT = 1
                    AND psrc.[PHYSICIAN_SERVICE_GUIDELINE_ID] = (select [dbo].[GetPhysicianServiceGuidelineID](c.CHART_ID))
                    AND psrc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_HISTORY_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                ORDER BY SEQ
                ) t
            ) 'HistDoc',
        (
            SELECT TOP 1 t.DESCRIPTION
            FROM (
                SELECT TOP 1 1 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK),
                    physician_service_eval pse WITH (NOLOCK),
                    physician_service ps WITH (NOLOCK)
                WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_HIST_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                    AND pcl.PHYSICIAN_SERVICE_CLASS_CD = psrc.PHYSICIAN_SERVICE_CLASS_CD
                    AND pse.CHART_ID = c.CHART_ID
                    AND ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID
                    AND psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = ps.PHYSICIAN_SERVICE_GUIDELINE_ID
                
                UNION
                
                SELECT TOP 1 2 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK)                  
                WHERE c.EDITED_BY_EXPERT = 1
                    AND psrc.[PHYSICIAN_SERVICE_GUIDELINE_ID] = (select [dbo].[GetPhysicianServiceGuidelineID](c.CHART_ID))
                    AND psrc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_HIST_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                ORDER BY SEQ
                ) t
            ) 'HistExp',
        (
            SELECT dbo.GetPhysicianServiceReasonDescription(c.chart_ID)
            ) 'HistReason',
        (
            SELECT TOP 1 t.DESCRIPTION
            FROM (
                SELECT TOP 1 1 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK),
                    physician_service_eval pse WITH (NOLOCK),
                    physician_service ps WITH (NOLOCK)
                WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                    AND pcl.PHYSICIAN_SERVICE_CLASS_CD = psrc.PHYSICIAN_SERVICE_CLASS_CD
                    AND pse.CHART_ID = c.CHART_ID
                    AND ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID
                    AND psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = ps.PHYSICIAN_SERVICE_GUIDELINE_ID
                
                UNION
                
                SELECT TOP 1 2 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK)
                WHERE c.EDITED_BY_EXPERT = 1
                    AND psrc.[PHYSICIAN_SERVICE_GUIDELINE_ID] = (select [dbo].[GetPhysicianServiceGuidelineID](c.CHART_ID))
                    AND psrc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                ORDER BY SEQ
                ) t
            ) 'ExamDoc',
        (
            SELECT TOP 1 t.DESCRIPTION
            FROM (
                SELECT TOP 1 1 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK),
                    physician_service_eval pse WITH (NOLOCK),
                    physician_service ps WITH (NOLOCK)
                WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_EXAM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                    AND c.PATIENT_CLASS_ID = pcl.PATIENT_CLASS_ID
                    AND pcl.PHYSICIAN_SERVICE_CLASS_CD = psrc.PHYSICIAN_SERVICE_CLASS_CD
                    AND pse.CHART_ID = c.CHART_ID
                    AND ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID
                    AND psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = ps.PHYSICIAN_SERVICE_GUIDELINE_ID
                
                UNION
                
                SELECT TOP 1 2 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK)
                WHERE c.EDITED_BY_EXPERT = 1
                    AND psrc.[PHYSICIAN_SERVICE_GUIDELINE_ID] = (select [dbo].[GetPhysicianServiceGuidelineID](c.CHART_ID))
                    AND psrc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_EXAM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                ORDER BY SEQ
                ) t
            ) 'ExamExp'
        ,
        (
            SELECT TOP 1 t.DESCRIPTION
            FROM (
                SELECT TOP 1 1 SEQ,
                    psrc.DESCRIPTION
                FROM PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
                    physician_service_eval pse WITH (NOLOCK),
                    physician_service ps WITH (NOLOCK)
                WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 3
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_MDM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                    AND c.PATIENT_CLASS_ID = pcl.PATIENT_CLASS_ID
                    AND pcl.PHYSICIAN_SERVICE_CLASS_CD = psrc.PHYSICIAN_SERVICE_CLASS_CD
                    AND pse.CHART_ID = c.CHART_ID
                    AND ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID
                    AND psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = ps.PHYSICIAN_SERVICE_GUIDELINE_ID
                
                UNION
                
                SELECT TOP 1 2 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK)
                WHERE c.EDITED_BY_EXPERT = 1
                    AND psrc.[PHYSICIAN_SERVICE_GUIDELINE_ID] = (select [dbo].[GetPhysicianServiceGuidelineID](c.CHART_ID))
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 3
                    AND psrc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_MDM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                ORDER BY SEQ
                ) t
            ) 'MDMDoc',
        (
            SELECT MAX([DEFICIENCY_STATUS_ID])
            FROM documentation_inequity di WITH (NOLOCK)
            WHERE di.CHART_ID = c.CHART_ID
            ) 'di_Status' --<< NEED THIS, find charts that aren't status=8 for EROne/NetMD
        ,
        fp1.FACILITY_PROF_ID AttendingProviderID,
        fp1.EMPLOYEE_IDENTIFIER AttendingProviderEID,
        CASE 
            WHEN fp1.FACILITY_PROF_ID IS NULL
                THEN 'UNKNOWN'
            ELSE upper(fp1.LAST_NAME)
            END AttendingProviderLastName,
        CASE 
            WHEN fp1.FACILITY_PROF_ID IS NULL
                THEN 'UNKNOWN'
            ELSE upper(fp1.FIRST_NAME)
            END AttendingProviderFirstName,
        CASE 
            WHEN fp1.FACILITY_PROF_ID IS NULL
                THEN 'UNKNOWN'
            ELSE upper(fp1.LAST_NAME + ', ' + fp1.FIRST_NAME)
            END AttendingProvider,
        (
            SELECT isnull(fpr.[DESCRIPTION], 'Physician')
            FROM FACILITY_PROFESSIONAL_ROLE fpr WITH (NOLOCK)
            WHERE fpr.FACILITY_PROF_ROLE_ID = fp1.ROLE_ID
            ) AS AttendingProviderType,
        fp2.FACILITY_PROF_ID PerformingProviderID,
        CASE 
            WHEN fp2.FACILITY_PROF_ID IS NULL
                THEN 'UNKNOWN'
            ELSE upper(fp2.LAST_NAME + ', ' + fp2.FIRST_NAME)
            END PerformingProvider,
        c.FACILITY_CHART_ID Account,
        f.CLIENT_FACILITY_NUMBER Facility,
        CASE 
            WHEN examDoc.PHYSICIAN_SERVICE_RATING_CODE_ID IS NOT NULL
                AND examDoc.PHYSICIAN_SERVICE_RATING_CODE_ID <> isnull(examExp.PHYSICIAN_SERVICE_RATING_CODE_ID, 4)
                THEN 4 -- PE
            WHEN cphrid.HISTORY_REASON_ID IS NOT NULL -- History (HPI,ROS,PFSH)
                THEN CASE 
                        WHEN charindex('HPI', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0
                            THEN 1
                        WHEN charindex('ROS', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0
                            THEN 2
                        WHEN charindex('PFSH', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0
                            THEN 3
                        ELSE - 1 -- no reason if different selected
                        END
            WHEN c.PHYSICIAN_HISTORY_ID <> c.OVERRIDE_PHYS_HIST_ID
                THEN CASE 
                        WHEN c.PHYSICIAN_HISTORY_ID <= 0
                            THEN c.OVERRIDE_PHYS_HIST_ID
                        ELSE c.PHYSICIAN_HISTORY_ID
                        END
            ELSE c.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID
            END 'ReasonID',
        psp.SERVICE_LEVEL_CD [Level],
        (
            SELECT max(SERVICE_LEVEL_CD)
            FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
            WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                AND CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
            ) PotentialLevel,
        psp.CPT_CODE CPTCode,
        c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE PotentialCPT,
        isnull(charged.CHARGE_AMOUNT, chargedD.CHARGE_AMOUNT) Charged,
        isnull(potential.CHARGE_AMOUNT, potentialD.CHARGE_AMOUNT) PotentialCharge,
        (
            SELECT TOP 1 sap.FACILITY_PAYOR_NAME
            FROM CHART_PAYOR cp WITH (NOLOCK)
            INNER JOIN SERVICE_AGREEMENT_PAYOR sap ON sap.SERVICE_AGREEMENT_PAYOR_ID = cp.SERVICE_AGREEMENT_PAYOR_ID
            WHERE cp.CHART_ID = c.CHART_ID
                AND dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) BETWEEN sap.EFFECTIVE_DATE AND sap.EXPIRATION_DATE
            ) Insurance,
        dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) SentDate,
        dateadd(day, 0, datediff(day, 0, c.TIME_OF_SERVICE)) DOS
    FROM CHART c WITH (NOLOCK)
    INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
    INNER JOIN PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK) ON (
            psp.PHYSICIAN_SERVICE_PROC_ID = c.PHYSICIAN_SERVICE_PROC_ID
            AND nullif(c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID, - 1) IS NULL
            )
    INNER JOIN PATIENT_CLASS pcl WITH (NOLOCK) ON c.PATIENT_CLASS_ID = pcl.PATIENT_CLASS_ID
    LEFT JOIN CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT cphrid WITH (NOLOCK) ON cphrid.CHART_ID = c.CHART_ID
    LEFT JOIN PHYSICIAN_HISTORY_REASON_IF_DIFFERENT phrid WITH (NOLOCK) ON phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID = cphrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_RATING_CODE examDoc WITH (NOLOCK) ON examDoc.PHYSICIAN_SERVICE_CLASS_CD = 1
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
        AND examDoc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID
        AND examDoc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
    LEFT JOIN PHYSICIAN_SERVICE_RATING_CODE examExp WITH (NOLOCK) ON examExp.PHYSICIAN_SERVICE_CLASS_CD = 1
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_ID = 2
        AND examExp.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_EXAM_ID
        AND examExp.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
    LEFT JOIN FACILITY_PROFESSIONAL fp1 WITH (NOLOCK) ON fp1.FACILITY_PROF_ID = CASE 
            WHEN c.NURSE_PRACTITIONER_ID > 0
                AND (
                    c.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
                    OR c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                    )
                THEN c.NURSE_PRACTITIONER_ID
            ELSE c.PHYSICIAN_ID
            END
    LEFT JOIN FACILITY_PROFESSIONAL fp2 WITH (NOLOCK) ON fp2.FACILITY_PROF_ID = c.PHYSICIAN_ID
    LEFT JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
        AND ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE charged WITH (NOLOCK) ON charged.CPT_CODE = psp.CPT_CODE
        AND c.TIME_OF_SERVICE BETWEEN charged.EFFECTIVE_DATE AND charged.EXPIRATION_DATE
        AND charged.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE chargedD WITH (NOLOCK) ON chargedD.CPT_CODE = psp.CPT_CODE
        AND c.TIME_OF_SERVICE BETWEEN chargedD.EFFECTIVE_DATE AND chargedD.EXPIRATION_DATE
        AND chargedD.SERVICE_AGREEMENT_ID = - 1
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potential WITH (NOLOCK) ON potential.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
        AND c.TIME_OF_SERVICE BETWEEN potential.EFFECTIVE_DATE AND potential.EXPIRATION_DATE
        AND potential.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potentialD WITH (NOLOCK) ON potentialD.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
        AND c.TIME_OF_SERVICE BETWEEN potentialD.EFFECTIVE_DATE AND potentialD.EXPIRATION_DATE
        AND potentialD.SERVICE_AGREEMENT_ID = - 1
    WHERE c.CHART_STATUS_ID = 5
        AND isnull(sa.EVALUATE_PHYSICIAN_SVC, 0) = 1
        AND isnull(NO_PHYSICIAN_SERVICES, 0) = 0
        AND (
            isnull(sa.CONDITION_PHYSICIAN_SERVICES_ON_DATE_OF_SERVICE, 0) = 0
            OR dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) BETWEEN sa.PHYSICIAN_SERVICES_START_DATE_OF_SERVICE AND isnull(PHYSICIAN_SERVICES_END_DATE_OF_SERVICE, getdate())
            )
        AND nullif(c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE, '') IS NOT NULL
        AND c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE <> psp.CPT_CODE
        AND c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <= 0
        AND psp.SERVICE_LEVEL_CD < (
            SELECT max(SERVICE_LEVEL_CD)
            FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
            WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                AND CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
            )
    ) x
WHERE x.di_Status IS NULL
    OR x.di_Status <> 8 -- Exclude contested deficiencies

UNION ALL

SELECT x.*,
    CASE 
        WHEN x.ReasonId > 0
            THEN substring(x.PotentialCPT, 4, 2) + substring(x.CPTCode, 4, 2) + CASE 
                    WHEN x.ReasonId = 1
                        THEN 'h'
                    WHEN x.ReasonId = 2
                        THEN 'r'
                    WHEN x.ReasonId = 3
                        THEN 'x'
                    WHEN x.ReasonId = 4
                        THEN 'e'
                    END
        ELSE NULL
        END DeficiencyCode
FROM (
    SELECT c.FACILITY_ID 'FacilityId',
        f.NAME 'FacilityName',
        c.SERVICE_AGREEMENT_ID 'ServiceAgreementId',
        sa.COMPANY_ID 'CompanyId',
        c.CHART_ID 'ChartID',
        c.[MEDICAL_RECORD_NUM] 'MRN',
        c.FACILITY_ADMIN_CHART_ID 'AltChartID',
        (
            SELECT pd.DESCRIPTION
            FROM PATIENT_DISPOSITION pd WITH (NOLOCK)
            WHERE c.PATIENT_DISPOSITION_ID = pd.PATIENT_DISPOSITION_ID
            ) 'PatientDisposition',
        (
            SELECT scribe.LAST_NAME + ', ' + scribe.FIRST_NAME
            FROM FACILITY_PROFESSIONAL scribe WITH (NOLOCK)
            WHERE scribe.FACILITY_PROF_ID = c.SCRIBE_ID
            ) AS 'Scribe',
        (
            SELECT TOP 1 icd.medium_desc
            FROM ICD_9_CM icd WITH (NOLOCK)
            WHERE c.primary_complaint = icd.icd9_code
            ) AS 'Diagnosis',
        (
            SELECT TOP 1 up.LAST_NAME + ', ' + up.FIRST_NAME
            FROM user_profile up WITH (NOLOCK)
            WHERE up.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
            ) 'Coder',
        (
            SELECT dbo.GetPhysicianServiceReasonDescription(c.chart_ID)
            ) 'HistoryReason',
        (
            SELECT TOP 1 t.DESCRIPTION
            FROM (
                SELECT TOP 1 1 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK),
                    physician_service_eval pse WITH (NOLOCK),
                    physician_service ps WITH (NOLOCK)
                WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_HISTORY_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                    AND pcl.PHYSICIAN_SERVICE_CLASS_CD = psrc.PHYSICIAN_SERVICE_CLASS_CD
                    AND pse.CHART_ID = c.CHART_ID
                    AND ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID
                    AND psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = ps.PHYSICIAN_SERVICE_GUIDELINE_ID
                
                UNION
                
                SELECT TOP 1 2 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK)
                WHERE c.EDITED_BY_EXPERT = 1
                    AND psrc.[PHYSICIAN_SERVICE_GUIDELINE_ID] = (select [dbo].[GetPhysicianServiceGuidelineID](c.CHART_ID))
                    AND psrc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_HISTORY_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                ORDER BY SEQ
                ) t
            ) 'HistDoc',
        (
            SELECT TOP 1 t.DESCRIPTION
            FROM (
                SELECT TOP 1 1 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK),
                    physician_service_eval pse WITH (NOLOCK),
                    physician_service ps WITH (NOLOCK)
                WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_HIST_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                    AND pcl.PHYSICIAN_SERVICE_CLASS_CD = psrc.PHYSICIAN_SERVICE_CLASS_CD
                    AND pse.CHART_ID = c.CHART_ID
                    AND ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID
                    AND psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = ps.PHYSICIAN_SERVICE_GUIDELINE_ID
                
                UNION
                
                SELECT TOP 1 2 SEQ,
                    psrc.DESCRIPTION
                 FROM physician_service_rating_code psrc WITH (NOLOCK)
                WHERE c.EDITED_BY_EXPERT = 1
                    AND psrc.[PHYSICIAN_SERVICE_GUIDELINE_ID] = (select [dbo].[GetPhysicianServiceGuidelineID](c.CHART_ID))
                    AND psrc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_HIST_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                ORDER BY SEQ
                ) t
            ) 'HistExp',
        (
            SELECT dbo.GetPhysicianServiceReasonDescription(c.chart_ID)
            ) 'HistReason',
        (
            SELECT TOP 1 t.DESCRIPTION
            FROM (
                SELECT TOP 1 1 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK),
                    physician_service_eval pse WITH (NOLOCK),
                    physician_service ps WITH (NOLOCK)
                WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                    AND pcl.PHYSICIAN_SERVICE_CLASS_CD = psrc.PHYSICIAN_SERVICE_CLASS_CD
                    AND pse.CHART_ID = c.CHART_ID
                    AND ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID
                    AND psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = ps.PHYSICIAN_SERVICE_GUIDELINE_ID
                
                UNION
                
                SELECT TOP 1 2 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK)
                WHERE c.EDITED_BY_EXPERT = 1
                    AND psrc.[PHYSICIAN_SERVICE_GUIDELINE_ID] = (select [dbo].[GetPhysicianServiceGuidelineID](c.CHART_ID))
                    AND psrc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                ORDER BY SEQ
                ) t
            ) 'ExamDoc',
        (
            SELECT TOP 1 t.DESCRIPTION
            FROM (
                SELECT TOP 1 1 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK),
                    physician_service_eval pse WITH (NOLOCK),
                    physician_service ps WITH (NOLOCK)
                WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_EXAM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                    AND pcl.PHYSICIAN_SERVICE_CLASS_CD = psrc.PHYSICIAN_SERVICE_CLASS_CD
                    AND pse.CHART_ID = c.CHART_ID
                    AND ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID
                    AND psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = ps.PHYSICIAN_SERVICE_GUIDELINE_ID
                
                UNION
                
                SELECT TOP 1 2 SEQ,
                    psrc.DESCRIPTION
                FROM physician_service_rating_code psrc WITH (NOLOCK)
                WHERE c.EDITED_BY_EXPERT = 1
                    AND psrc.[PHYSICIAN_SERVICE_GUIDELINE_ID] = (select [dbo].[GetPhysicianServiceGuidelineID](c.CHART_ID))
                    AND psrc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_EXAM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                ORDER BY SEQ
                ) t
            ) 'ExamExp'
        ,
        (
            SELECT TOP 1 t.DESCRIPTION
            FROM (
                SELECT TOP 1 1 SEQ,
                    psrc.DESCRIPTION
                FROM PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
                    physician_service_eval pse WITH (NOLOCK),
                    physician_service ps WITH (NOLOCK)
                WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 3
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_MDM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                    AND pcl.PHYSICIAN_SERVICE_CLASS_CD = psrc.PHYSICIAN_SERVICE_CLASS_CD
                    AND pse.CHART_ID = c.CHART_ID
                    AND ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID
                    AND psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = ps.PHYSICIAN_SERVICE_GUIDELINE_ID
                
                UNION
                
                SELECT TOP 1 2 SEQ,
                    psrc.DESCRIPTION
               FROM physician_service_rating_code psrc WITH (NOLOCK)
                WHERE c.EDITED_BY_EXPERT = 1
                    AND psrc.[PHYSICIAN_SERVICE_GUIDELINE_ID] = (select [dbo].[GetPhysicianServiceGuidelineID](c.CHART_ID))
                    AND psrc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 3
                    AND psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_MDM_ID
                    AND c.TIME_OF_SERVICE >= psrc.EFFECTIVE_DATE
                    AND c.TIME_OF_SERVICE <= psrc.EXPIRATION_DATE
                ORDER BY SEQ
                ) t
            ) 'MDMDoc',
        (
            SELECT MAX([DEFICIENCY_STATUS_ID])
            FROM documentation_inequity di WITH (NOLOCK)
            WHERE di.CHART_ID = c.CHART_ID
            ) 'di_Status' --<< NEED THIS, find charts that aren't status=8 for EROne/NetMD
        ,
        fp1.FACILITY_PROF_ID AttendingProviderID,
        fp1.EMPLOYEE_IDENTIFIER AttendingProviderEID,
        CASE 
            WHEN fp1.FACILITY_PROF_ID IS NULL
                THEN 'UNKNOWN'
            ELSE upper(fp1.LAST_NAME)
            END AttendingProviderLastName,
        CASE 
            WHEN fp1.FACILITY_PROF_ID IS NULL
                THEN 'UNKNOWN'
            ELSE upper(fp1.FIRST_NAME)
            END AttendingProviderFirstName,
        CASE 
            WHEN fp1.FACILITY_PROF_ID IS NULL
                THEN 'UNKNOWN'
            ELSE upper(fp1.LAST_NAME + ', ' + fp1.FIRST_NAME)
            END AttendingProvider,
        (
            SELECT isnull(fpr.[DESCRIPTION], 'Physician')
            FROM FACILITY_PROFESSIONAL_ROLE fpr WITH (NOLOCK)
            WHERE fpr.FACILITY_PROF_ROLE_ID = fp1.ROLE_ID
            ) AS AttendingProviderType,
        fp2.FACILITY_PROF_ID PerformingProviderID,
        CASE 
            WHEN fp2.FACILITY_PROF_ID IS NULL
                THEN 'UNKNOWN'
            ELSE upper(fp2.LAST_NAME + ', ' + fp2.FIRST_NAME)
            END PerformingProvider,
        c.FACILITY_CHART_ID Account,
        f.CLIENT_FACILITY_NUMBER Facility,
        CASE 
            WHEN examDoc.PHYSICIAN_SERVICE_RATING_CODE_ID IS NOT NULL
                AND examDoc.PHYSICIAN_SERVICE_RATING_CODE_ID <> isnull(examExp.PHYSICIAN_SERVICE_RATING_CODE_ID, 4)
                THEN 4 -- PE
            WHEN cphrid.HISTORY_REASON_ID IS NOT NULL -- History (HPI,ROS,PFSH)
                THEN CASE 
                        WHEN charindex('HPI', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0
                            THEN 1
                        WHEN charindex('ROS', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0
                            THEN 2
                        WHEN charindex('PFSH', phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC) > 0
                            THEN 3
                        ELSE - 1 -- no reason if different selected
                        END
            WHEN c.PHYSICIAN_HISTORY_ID <> c.OVERRIDE_PHYS_HIST_ID
                THEN CASE 
                        WHEN c.PHYSICIAN_HISTORY_ID <= 0
                            THEN c.OVERRIDE_PHYS_HIST_ID
                        ELSE c.PHYSICIAN_HISTORY_ID
                        END
            ELSE c.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID
            END 'ReasonID',
        psp.SERVICE_LEVEL_CD [Level],
        (
            SELECT max(SERVICE_LEVEL_CD)
            FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
            WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                AND CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
            ) PotentialLevel,
        psp.CPT_CODE CPTCode,
        c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE PotentialCPT,
        isnull(charged.CHARGE_AMOUNT, chargedD.CHARGE_AMOUNT) Charged,
        isnull(potential.CHARGE_AMOUNT, potentialD.CHARGE_AMOUNT) PotentialCharge,
        (
            SELECT TOP 1 sap.FACILITY_PAYOR_NAME
            FROM CHART_PAYOR cp WITH (NOLOCK)
            INNER JOIN SERVICE_AGREEMENT_PAYOR sap ON sap.SERVICE_AGREEMENT_PAYOR_ID = cp.SERVICE_AGREEMENT_PAYOR_ID
            WHERE cp.CHART_ID = c.CHART_ID
                AND dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) BETWEEN sap.EFFECTIVE_DATE AND sap.EXPIRATION_DATE
            ) Insurance,
        dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) SentDate,
        dateadd(day, 0, datediff(day, 0, c.TIME_OF_SERVICE)) DOS
    FROM CHART c WITH (NOLOCK)
    INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
    INNER JOIN PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK) ON psp.PHYSICIAN_SERVICE_PROC_ID = c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
    INNER JOIN PATIENT_CLASS pcl WITH (NOLOCK) ON c.PATIENT_CLASS_ID = pcl.PATIENT_CLASS_ID
    LEFT JOIN CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT cphrid WITH (NOLOCK) ON cphrid.CHART_ID = c.CHART_ID
    LEFT JOIN PHYSICIAN_HISTORY_REASON_IF_DIFFERENT phrid WITH (NOLOCK) ON phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID = cphrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_RATING_CODE examDoc WITH (NOLOCK) ON examDoc.PHYSICIAN_SERVICE_CLASS_CD = 1
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
        AND examDoc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID
        AND examDoc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
    LEFT JOIN PHYSICIAN_SERVICE_RATING_CODE examExp WITH (NOLOCK) ON examExp.PHYSICIAN_SERVICE_CLASS_CD = 1
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_ID = 2
        AND examExp.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_EXAM_ID
        AND examExp.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
    LEFT JOIN FACILITY_PROFESSIONAL fp1 WITH (NOLOCK) ON fp1.FACILITY_PROF_ID = CASE 
            WHEN c.NURSE_PRACTITIONER_ID > 0
                AND (
                    c.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
                    OR c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                    )
                THEN c.NURSE_PRACTITIONER_ID
            ELSE c.PHYSICIAN_ID
            END
    LEFT JOIN FACILITY_PROFESSIONAL fp2 WITH (NOLOCK) ON fp2.FACILITY_PROF_ID = c.PHYSICIAN_ID
    LEFT JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
        AND ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE charged WITH (NOLOCK) ON charged.CPT_CODE = psp.CPT_CODE
        AND c.TIME_OF_SERVICE BETWEEN charged.EFFECTIVE_DATE AND charged.EXPIRATION_DATE
        AND charged.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE chargedD WITH (NOLOCK) ON chargedD.CPT_CODE = psp.CPT_CODE
        AND c.TIME_OF_SERVICE BETWEEN chargedD.EFFECTIVE_DATE AND chargedD.EXPIRATION_DATE
        AND chargedD.SERVICE_AGREEMENT_ID = - 1
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potential WITH (NOLOCK) ON potential.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
        AND c.TIME_OF_SERVICE BETWEEN potential.EFFECTIVE_DATE AND potential.EXPIRATION_DATE
        AND potential.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potentialD WITH (NOLOCK) ON potentialD.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
        AND c.TIME_OF_SERVICE BETWEEN potentialD.EFFECTIVE_DATE AND potentialD.EXPIRATION_DATE
        AND potentialD.SERVICE_AGREEMENT_ID = - 1
    WHERE c.CHART_STATUS_ID = 5
        AND isnull(sa.EVALUATE_PHYSICIAN_SVC, 0) = 1
        AND isnull(NO_PHYSICIAN_SERVICES, 0) = 0
        AND (
            isnull(sa.CONDITION_PHYSICIAN_SERVICES_ON_DATE_OF_SERVICE, 0) = 0
            OR dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) BETWEEN sa.PHYSICIAN_SERVICES_START_DATE_OF_SERVICE AND isnull(PHYSICIAN_SERVICES_END_DATE_OF_SERVICE, getdate())
            )
        AND nullif(c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE, '') IS NOT NULL
        AND c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE <> psp.CPT_CODE
        AND c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <= 0
        AND psp.SERVICE_LEVEL_CD < (
            SELECT max(SERVICE_LEVEL_CD)
            FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
            WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                AND CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
            )
    ) x
WHERE x.di_Status IS NULL
    OR x.di_Status <> 8 -- Exclude contested deficiencies
GO
