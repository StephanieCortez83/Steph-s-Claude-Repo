SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =============================================
-- Author:		Don Hutton
-- Create date: 8/04/2016
-- Description:	Query too large for report
-- =============================================


CREATE PROCEDURE [dbo].[rpt_ERONE_ProviderDeficiencyReport] 

@StartDate date,
@ThruDate date,
@Organization int,
@facility int,
@Provider varchar(max)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


if object_id('TempDB..#ChartSubset', 'U') is not null DROP TABLE #ChartSubset

select 
	c.FACILITY_ID,
	c.SERVICE_AGREEMENT_ID,
	c.CHART_ID,
	c.MEDICAL_RECORD_NUM,
	c.FACILITY_ADMIN_CHART_ID,
	c.PATIENT_DISPOSITION_ID,
	c.SCRIBE_ID,
	c.primary_complaint,
	c.COMPLETED_BY_USER_PROFILE_ID,
	c.PHYSICIAN_HISTORY_ID,
	c.Time_Of_Service,
	c.EDITED_BY_EXPERT,
	c.OVERRIDE_PHYS_HIST_ID,
	c.PHYSICIAN_EXAM_ID,
	c.OVERRIDE_PHYS_EXAM_ID,
	c.patient_class_ID,
	c.PHYSICIAN_MDM_ID,
	c.FACILITY_CHART_ID,
	c.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID,
	c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE,
	c.Sent_Date,
	c.PHYSICIAN_SERVICE_PROC_ID,
	c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID,
	c.PROVIDER_EVAL_PERFORMED_BY_IND,
	c.NURSE_PRACTITIONER_ID,
	c.FINANCIAL_CLASS_CD,
	c.CHART_STATUS_ID,
	c.physician_ID,
	c.No_Physician_Services
 INTO #ChartSubset
from Chart as c with (NOLOCK) join service_agreement as sa with (NOLOCK) on c.service_agreement_ID = sa.service_agreement_ID
where 
	c.sent_date between @StartDate and DateAdd(Day, 1, @ThruDate)
	And sa.Facility_Id IN (
	  	  SELECT facility_id
	  	  FROM service_agreement
	  	  WHERE company_id = @Organization
	  	  )
	  AND (
	  	  @facility = - 1
	  	  OR sa.Facility_Id = @facility
	  	  )

--*/

-- #ProviderDocDefs is substituted for vw_ProviderDocumentationDeficiencies to improve performance
if object_id('TempDB..#ProviderDocDefs', 'U') is not null DROP TABLE #ProviderDocDefs

select *
into #ProviderDocDefs
from
(
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
            FROM PATIENT_DISPOSITION pd  with (NOLOCK)
            WHERE c.PATIENT_DISPOSITION_ID = pd.PATIENT_DISPOSITION_ID
            ) 'PatientDisposition',
        (
            SELECT scribe.LAST_NAME + ', ' + scribe.FIRST_NAME
            FROM FACILITY_PROFESSIONAL scribe  with (NOLOCK)
            WHERE scribe.FACILITY_PROF_ID = c.SCRIBE_ID
            ) AS 'Scribe',
        (
            SELECT TOP 1 icd.medium_desc
            FROM ICD_9_CM icd  with (NOLOCK)
            WHERE c.primary_complaint = icd.icd9_code
            ) AS 'Diagnosis',
        (
            SELECT TOP 1 up.LAST_NAME + ', ' + up.FIRST_NAME
            FROM user_profile up  with (NOLOCK)
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
                FROM physician_service_rating_code psrc  with (NOLOCK),
                    physician_service_eval pse  with (NOLOCK),
                    physician_service ps  with (NOLOCK)
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
                FROM physician_service_rating_code psrc  with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK),
                    physician_service_eval pse with (NOLOCK),
                    physician_service ps with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK)                  
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
                FROM physician_service_rating_code psrc with (NOLOCK),
                    physician_service_eval pse with (NOLOCK),
                    physician_service ps with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK),
                    physician_service_eval pse with (NOLOCK),
                    physician_service ps with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK)
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
                FROM PHYSICIAN_SERVICE_RATING_CODE psrc with (NOLOCK),
                    physician_service_eval pse with (NOLOCK),
                    physician_service ps with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK)
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
            FROM documentation_inequity di with (NOLOCK)
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
            FROM FACILITY_PROFESSIONAL_ROLE fpr with (NOLOCK)
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
            FROM PHYSICIAN_SERVICE_PROCEDURE with (NOLOCK)
            WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                AND CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE		
            ) PotentialLevel,
        psp.CPT_CODE CPTCode,
        c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE PotentialCPT,

case when charged.CHARGE_AMOUNT is null then 
					case when chargedD.[PAYMENT_RATE] is null then 
					             case when charged_2.CHARGE_AMOUNT is null then chargedD_2.CHARGE_AMOUNT
								 else charged_2.CHARGE_AMOUNT end
					else chargedD.[PAYMENT_RATE] end 	
else charged.CHARGE_AMOUNT end as Charged,
 
case when potential.CHARGE_AMOUNT is null then 
					case when potentialD.[PAYMENT_RATE] is null then 
					             case when potential_2.CHARGE_AMOUNT is null then potentialD_2.CHARGE_AMOUNT
								 else potential_2.CHARGE_AMOUNT end
					else potentialD.[PAYMENT_RATE] end 	
else potential.CHARGE_AMOUNT end as PotentialCharge,

--        isnull(charged.CHARGE_AMOUNT, chargedD.PAYMENT_RATE) Charged,
--        isnull(potential.CHARGE_AMOUNT, potentialD.PAYMENT_RATE) PotentialCharge,

        (
            SELECT TOP 1 sap.FACILITY_PAYOR_NAME
            FROM CHART_PAYOR cp with (NOLOCK)
            INNER JOIN SERVICE_AGREEMENT_PAYOR sap with (NOLOCK) ON sap.SERVICE_AGREEMENT_PAYOR_ID = cp.SERVICE_AGREEMENT_PAYOR_ID
            WHERE cp.CHART_ID = c.CHART_ID
                AND dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) BETWEEN sap.EFFECTIVE_DATE AND sap.EXPIRATION_DATE
            ) Insurance,
        dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) SentDate,
        dateadd(day, 0, datediff(day, 0, c.TIME_OF_SERVICE)) DOS
    FROM 
	#ChartSubset as c
    INNER JOIN SERVICE_AGREEMENT sa with (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    INNER JOIN FACILITY f with (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID		
    INNER JOIN PHYSICIAN_SERVICE_PROCEDURE psp with (NOLOCK) ON (
            psp.PHYSICIAN_SERVICE_PROC_ID = c.PHYSICIAN_SERVICE_PROC_ID
            AND nullif(c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID, - 1) IS NULL		
            )
    INNER JOIN PATIENT_CLASS pcl with (NOLOCK) ON c.PATIENT_CLASS_ID = pcl.PATIENT_CLASS_ID
    LEFT JOIN CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT cphrid with (NOLOCK) ON cphrid.CHART_ID = c.CHART_ID
    LEFT JOIN PHYSICIAN_HISTORY_REASON_IF_DIFFERENT phrid with (NOLOCK) ON phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID = cphrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_RATING_CODE examDoc with (NOLOCK) ON examDoc.PHYSICIAN_SERVICE_CLASS_CD = 1
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
        AND examDoc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID
        AND examDoc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
    LEFT JOIN PHYSICIAN_SERVICE_RATING_CODE examExp ON examExp.PHYSICIAN_SERVICE_CLASS_CD = 1
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_ID = 2
        AND examExp.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_EXAM_ID
        AND examExp.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
    LEFT JOIN FACILITY_PROFESSIONAL fp1 with (NOLOCK) ON fp1.FACILITY_PROF_ID = CASE 
            WHEN c.NURSE_PRACTITIONER_ID > 0		
                AND (
                    c.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
                    OR c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                    )
                THEN c.NURSE_PRACTITIONER_ID
            ELSE c.PHYSICIAN_ID
            END
    LEFT JOIN FACILITY_PROFESSIONAL fp2 with (NOLOCK) ON fp2.FACILITY_PROF_ID = c.PHYSICIAN_ID
    LEFT JOIN FACILITY_FINANCIAL_CLASS ffc with (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
        AND ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD


    LEFT JOIN CHARGE_MASTER cmc with (nolock) ON cmc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      AND cmc.CHARGE_MASTER_USAGE_CODE = 4
      AND cmc.CPT_CODE = psp.CPT_CODE
      AND cmc.BILLING_CODE = psp.BILLING_CODE
      AND cmc.PATIENT_CLASS_ID in (-1, psp.PATIENT_CLASS_ID)
      AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cmc.EFFECTIVE_DATE AND cmc.EXPIRATION_DATE
    LEFT JOIN CHARGE_MASTER_CHARGE_AMOUNT charged with (nolock) ON charged.CHARGE_MASTER_ID = cmc.CHARGE_MASTER_ID
      AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN charged.EFFECTIVE_DATE AND COALESCE(charged.EXPIRATION_DATE, '12/31/9999')
    LEFT JOIN CMS_ADDENDUM_B chargedD with (nolock) ON chargedD.HCPCS_CPT_CODE = psp.CPT_CODE


    LEFT JOIN CHARGE_MASTER cmp with (nolock) ON cmp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      AND cmp.CHARGE_MASTER_USAGE_CODE = 4
      AND cmp.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
      AND cmp.MODIFIER_REQUIRED = psp.[PROCEDURES]
      AND cmp.PATIENT_CLASS_ID in (-1, psp.PATIENT_CLASS_ID)
      AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cmp.EFFECTIVE_DATE AND cmp.EXPIRATION_DATE
    LEFT JOIN CHARGE_MASTER_CHARGE_AMOUNT potential with (nolock) ON potential.CHARGE_MASTER_ID = cmp.CHARGE_MASTER_ID
      AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN potential.EFFECTIVE_DATE AND COALESCE(potential.EXPIRATION_DATE, '12/31/9999')
    LEFT JOIN CMS_ADDENDUM_B potentialD with (nolock) ON potentialD.HCPCS_CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE		

	LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE charged_2 with (nolock) ON charged_2.CPT_CODE = psp.CPT_CODE
									AND c.TIME_OF_SERVICE BETWEEN charged_2.EFFECTIVE_DATE AND charged_2.EXPIRATION_DATE
									AND charged_2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE chargedD_2 with (nolock) ON chargedD_2.CPT_CODE = psp.CPT_CODE
									AND c.TIME_OF_SERVICE BETWEEN chargedD_2.EFFECTIVE_DATE AND chargedD_2.EXPIRATION_DATE
									AND chargedD_2.SERVICE_AGREEMENT_ID = - 1
	LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potential_2 with (nolock) ON potential_2.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
									AND c.TIME_OF_SERVICE BETWEEN potential_2.EFFECTIVE_DATE AND potential_2.EXPIRATION_DATE
									AND potential_2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potentialD_2 with (nolock) ON potentialD_2.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
									AND c.TIME_OF_SERVICE BETWEEN potentialD_2.EFFECTIVE_DATE AND potentialD_2.EXPIRATION_DATE
									AND potentialD_2.SERVICE_AGREEMENT_ID = - 1

				
--    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE charged with (NOLOCK) ON charged.CPT_CODE = psp.CPT_CODE
--        AND c.TIME_OF_SERVICE BETWEEN charged.EFFECTIVE_DATE AND charged.EXPIRATION_DATE
--        AND charged.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
--    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE chargedD with (NOLOCK) ON chargedD.CPT_CODE = psp.CPT_CODE
--        AND c.TIME_OF_SERVICE BETWEEN chargedD.EFFECTIVE_DATE AND chargedD.EXPIRATION_DATE
--        AND chargedD.SERVICE_AGREEMENT_ID = - 1
--    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potential with (NOLOCK) ON potential.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
--        AND c.TIME_OF_SERVICE BETWEEN potential.EFFECTIVE_DATE AND potential.EXPIRATION_DATE
--        AND potential.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
--    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potentialD with (NOLOCK) ON potentialD.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
--        AND c.TIME_OF_SERVICE BETWEEN potentialD.EFFECTIVE_DATE AND potentialD.EXPIRATION_DATE
--        AND potentialD.SERVICE_AGREEMENT_ID = - 1
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
            FROM PHYSICIAN_SERVICE_PROCEDURE with (NOLOCK)
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
            FROM PATIENT_DISPOSITION pd with (NOLOCK)
            WHERE c.PATIENT_DISPOSITION_ID = pd.PATIENT_DISPOSITION_ID
            ) 'PatientDisposition',
        (
            SELECT scribe.LAST_NAME + ', ' + scribe.FIRST_NAME
            FROM FACILITY_PROFESSIONAL scribe with (NOLOCK)
            WHERE scribe.FACILITY_PROF_ID = c.SCRIBE_ID
            ) AS 'Scribe',
        (
            SELECT TOP 1 icd.medium_desc
            FROM ICD_9_CM icd with (NOLOCK)
            WHERE c.primary_complaint = icd.icd9_code
            ) AS 'Diagnosis',
        (
            SELECT TOP 1 up.LAST_NAME + ', ' + up.FIRST_NAME
            FROM user_profile up with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK),
                    physician_service_eval pse with (NOLOCK),
                    physician_service ps with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK),
                    physician_service_eval pse with (NOLOCK),
                    physician_service ps with (NOLOCK)
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
                 FROM physician_service_rating_code psrc with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK),
                    physician_service_eval pse with (NOLOCK),
                    physician_service ps with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK),
                    physician_service_eval pse with (NOLOCK),
                    physician_service ps with (NOLOCK)
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
                FROM physician_service_rating_code psrc with (NOLOCK)
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
                FROM PHYSICIAN_SERVICE_RATING_CODE psrc with (NOLOCK),
                    physician_service_eval pse with (NOLOCK),
                    physician_service ps with (NOLOCK)
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
               FROM physician_service_rating_code psrc with (NOLOCK)
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
            FROM documentation_inequity di with (NOLOCK)
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
            FROM FACILITY_PROFESSIONAL_ROLE fpr with (NOLOCK)
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
            FROM PHYSICIAN_SERVICE_PROCEDURE with (NOLOCK)
            WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                AND CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
            ) PotentialLevel,
        psp.CPT_CODE CPTCode,
        c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE PotentialCPT,


case when charged.CHARGE_AMOUNT is null then 
					case when chargedD.[PAYMENT_RATE] is null then 
					             case when charged_2.CHARGE_AMOUNT is null then chargedD_2.CHARGE_AMOUNT
								 else charged_2.CHARGE_AMOUNT end
					else chargedD.[PAYMENT_RATE] end 	
else charged.CHARGE_AMOUNT end as Charged,
 
case when potential.CHARGE_AMOUNT is null then 
					case when potentialD.[PAYMENT_RATE] is null then 
					             case when potential_2.CHARGE_AMOUNT is null then potentialD_2.CHARGE_AMOUNT
								 else potential_2.CHARGE_AMOUNT end
					else potentialD.[PAYMENT_RATE] end 	
else potential.CHARGE_AMOUNT end as PotentialCharge,

--        isnull(charged.CHARGE_AMOUNT, chargedD.PAYMENT_RATE) Charged,
--        isnull(potential.CHARGE_AMOUNT, potentialD.PAYMENT_RATE) PotentialCharge,


        (
            SELECT TOP 1 sap.FACILITY_PAYOR_NAME
            FROM CHART_PAYOR cp with (NOLOCK)
            INNER JOIN SERVICE_AGREEMENT_PAYOR sap with (NOLOCK) ON sap.SERVICE_AGREEMENT_PAYOR_ID = cp.SERVICE_AGREEMENT_PAYOR_ID
            WHERE cp.CHART_ID = c.CHART_ID
                AND dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) BETWEEN sap.EFFECTIVE_DATE AND sap.EXPIRATION_DATE
            ) Insurance,
        dateadd(day, 0, datediff(day, 0, c.SENT_DATE)) SentDate,
        dateadd(day, 0, datediff(day, 0, c.TIME_OF_SERVICE)) DOS
    FROM 
	#ChartSubset as c
    INNER JOIN SERVICE_AGREEMENT sa with (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    INNER JOIN FACILITY f with (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
    INNER JOIN PHYSICIAN_SERVICE_PROCEDURE psp with (NOLOCK) ON psp.PHYSICIAN_SERVICE_PROC_ID = c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
    INNER JOIN PATIENT_CLASS pcl with (NOLOCK) ON c.PATIENT_CLASS_ID = pcl.PATIENT_CLASS_ID
    LEFT JOIN CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT cphrid with (NOLOCK) ON cphrid.CHART_ID = c.CHART_ID
    LEFT JOIN PHYSICIAN_HISTORY_REASON_IF_DIFFERENT phrid with (NOLOCK) ON phrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID = cphrid.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_RATING_CODE examDoc with (NOLOCK) ON examDoc.PHYSICIAN_SERVICE_CLASS_CD = 1
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_ID = 2
        AND examDoc.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
        AND examDoc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID
        AND examDoc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
    LEFT JOIN PHYSICIAN_SERVICE_RATING_CODE examExp with (NOLOCK) ON examExp.PHYSICIAN_SERVICE_CLASS_CD = 1
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_ID = 2
        AND examExp.PHYSICIAN_SERVICE_CLASS_CD = pcl.PHYSICIAN_SERVICE_CLASS_CD
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_RATING > 0
        AND examExp.PHYSICIAN_SERVICE_CATEGORY_RATING = c.OVERRIDE_PHYS_EXAM_ID
        AND examExp.PHYSICIAN_SERVICE_GUIDELINE_ID = 1
    LEFT JOIN FACILITY_PROFESSIONAL fp1 with (NOLOCK) ON fp1.FACILITY_PROF_ID = CASE 
            WHEN c.NURSE_PRACTITIONER_ID > 0
                AND (
                    c.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
                    OR c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                    )
                THEN c.NURSE_PRACTITIONER_ID
            ELSE c.PHYSICIAN_ID
            END
    LEFT JOIN FACILITY_PROFESSIONAL fp2 with (NOLOCK) ON fp2.FACILITY_PROF_ID = c.PHYSICIAN_ID
    LEFT JOIN FACILITY_FINANCIAL_CLASS ffc with (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
        AND ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD

    LEFT JOIN CHARGE_MASTER cmc with (nolock) ON cmc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      AND cmc.CHARGE_MASTER_USAGE_CODE = 4
      AND cmc.CPT_CODE = psp.CPT_CODE
      AND cmc.BILLING_CODE = psp.BILLING_CODE
      AND cmc.PATIENT_CLASS_ID in (-1, psp.PATIENT_CLASS_ID)
      AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cmc.EFFECTIVE_DATE AND cmc.EXPIRATION_DATE
    LEFT JOIN CHARGE_MASTER_CHARGE_AMOUNT charged with (nolock) ON charged.CHARGE_MASTER_ID = cmc.CHARGE_MASTER_ID
      AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN charged.EFFECTIVE_DATE AND COALESCE(charged.EXPIRATION_DATE, '12/31/9999')
    LEFT JOIN CMS_ADDENDUM_B chargedD with (nolock) ON chargedD.HCPCS_CPT_CODE = psp.CPT_CODE


	 LEFT JOIN CHARGE_MASTER cmp with (nolock) ON cmp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      AND cmp.CHARGE_MASTER_USAGE_CODE = 4
      AND cmp.CPT_CODE = psp.CPT_CODE
      AND cmp.BILLING_CODE = psp.BILLING_CODE
      AND cmp.PATIENT_CLASS_ID in (-1, psp.PATIENT_CLASS_ID)
      AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cmp.EFFECTIVE_DATE AND cmp.EXPIRATION_DATE

    LEFT JOIN CHARGE_MASTER_CHARGE_AMOUNT potential with (nolock) ON potential.CHARGE_MASTER_ID = cmp.CHARGE_MASTER_ID
      AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN potential.EFFECTIVE_DATE AND COALESCE(potential.EXPIRATION_DATE, '12/31/9999')
    LEFT JOIN CMS_ADDENDUM_B potentialD with (nolock) ON potentialD.HCPCS_CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE 


	LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE charged_2 with (nolock) ON charged_2.CPT_CODE = psp.CPT_CODE
									AND c.TIME_OF_SERVICE BETWEEN charged_2.EFFECTIVE_DATE AND charged_2.EXPIRATION_DATE
									AND charged_2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE chargedD_2 with (nolock) ON chargedD_2.CPT_CODE = psp.CPT_CODE
									AND c.TIME_OF_SERVICE BETWEEN chargedD_2.EFFECTIVE_DATE AND chargedD_2.EXPIRATION_DATE
									AND chargedD_2.SERVICE_AGREEMENT_ID = - 1
	LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potential_2 with (nolock) ON potential_2.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
									AND c.TIME_OF_SERVICE BETWEEN potential_2.EFFECTIVE_DATE AND potential_2.EXPIRATION_DATE
									AND potential_2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potentialD_2 with (nolock) ON potentialD_2.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
									AND c.TIME_OF_SERVICE BETWEEN potentialD_2.EFFECTIVE_DATE AND potentialD_2.EXPIRATION_DATE
									AND potentialD_2.SERVICE_AGREEMENT_ID = - 1



    
--	LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE charged with (NOLOCK) ON charged.CPT_CODE = psp.CPT_CODE
--        AND c.TIME_OF_SERVICE BETWEEN charged.EFFECTIVE_DATE AND charged.EXPIRATION_DATE
--        AND charged.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
--    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE chargedD with (NOLOCK) ON chargedD.CPT_CODE = psp.CPT_CODE
--        AND c.TIME_OF_SERVICE BETWEEN chargedD.EFFECTIVE_DATE AND chargedD.EXPIRATION_DATE
--        AND chargedD.SERVICE_AGREEMENT_ID = - 1
--    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potential with (NOLOCK) ON potential.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
--        AND c.TIME_OF_SERVICE BETWEEN potential.EFFECTIVE_DATE AND potential.EXPIRATION_DATE
--        AND potential.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
--    LEFT JOIN PHYSICIAN_SERVICE_PROCEDURE_CHARGE_VALUE potentialD with (NOLOCK) ON potentialD.CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
--        AND c.TIME_OF_SERVICE BETWEEN potentialD.EFFECTIVE_DATE AND potentialD.EXPIRATION_DATE
--        AND potentialD.SERVICE_AGREEMENT_ID = - 1


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
            FROM PHYSICIAN_SERVICE_PROCEDURE with (NOLOCK)
            WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                AND CPT_CODE = c.POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE
            )
    ) x
WHERE x.di_Status IS NULL
    OR x.di_Status <> 8 -- Exclude contested deficiencies
) as x



SELECT DISTINCT [FacilityId] 'facility_id'
	  ,[FacilityName] 'fname'
	  ,[AttendingProvider] 'Provider'
	  ,[AttendingProviderType] 'ProviderType'
	  ,[Account] 'Chart'
	  ,[MRN] 'MRN'
	  ,convert(VARCHAR, [DOS], 110) 'DOS'
	  ,[PatientDisposition] 'Disposition'
	  ,[Scribe] 'Scribe'
	  ,[CPTCode] 'CPT_CD'
	  ,[ChartID] 'chart_ID'
	  ,[PotentialCPT] 'POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE'
	  ,[Charged] 'AmountCharged'
	  ,[PotentialCharge] 'AmountPotential'
	  ,[HistoryReason]
	  ,[Diagnosis]
	  ,[Coder]
	  ,[HistDoc]
	  ,[HistExp]
	  ,[HistReason]
	  ,[ExamDoc]
	  ,[ExamExp]
	  ,[MDMDoc]
	  ,[di_Status]
FROM #ProviderDocDefs
WHERE 
	-- No need to use criteria here on FacilityID and SentDate since that criteria is now used at the beginning to create #ChartSubset
	  (
	  	  [di_Status] <> 8
	  	  OR [di_Status] IS NULL
	  	  )
	  AND (
	  	  @Provider = 'all'
	  	  OR [AttendingProviderID] IN (
	  	  	  SELECT FACILITY_PROF_ID
	  	  	  FROM FACILITY_PROFESSIONAL
	  	  	  WHERE SECONDARY_EMPLOYEE_ID = @Provider
	  	  	  )
	  	  )
ORDER BY [FacilityId]
	  ,[AttendingProvider]
	  ,[DOS]
	  ,[Account]

 OPTION (RECOMPILE);
END




GO
GRANT EXECUTE ON  [dbo].[rpt_ERONE_ProviderDeficiencyReport] TO [dbx_ExecuteReportProcs]
GO
