SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[MISMATCH_CHARGE_REPORT]
@Facility int, @StartDate datetime = '1-1-1990 12:00:00 AM', @EndDate datetime = '12-31-2099 11:59:59 PM', @ChartID int = null, @ChartStatusList varchar(13) = '3,4,5'
WITH EXEC AS CALLER
AS
DECLARE @Facility_Local int;
DECLARE @StartDate_Local datetime;
DECLARE @EndDate_Local datetime;
DECLARE @ChartID_Local int;
DECLARE @ChartStatusList_Local varchar(13);

SET @Facility_Local = @Facility;
SET @StartDate_Local = @StartDate;
SET @EndDate_Local = @EndDate;
SET @ChartID_Local = @ChartID;
SET @ChartStatusList_Local = @ChartStatusList;

DECLARE @ServiceAgreement int; 
SET @ServiceAgreement = (SELECT sa.SERVICE_AGREEMENT_ID 
                         FROM SERVICE_AGREEMENT sa WITH (NOLOCK)
                         WHERE sa.FACILITY_ID = @Facility_Local);
                         
DECLARE @LastUpdated DateTime; 
SET @LastUpdated = (SELECT MAX(CREATION_DATE_TIME)
                    FROM ASA_PHYSICIAN_CHARGES apc WITH (NOLOCK)
                    WHERE apc.FACILITY_ID = @Facility_Local)
                                                   
SELECT a.CLASS,
       a.CHART_STATUS,
       a.CHART_ID,
       a.FACILITY_CHART_ID,
       a.SERVICE_AGREEMENT_ID, 
       a.DOS,
       a.SENT,
       a.PATIENT_DISPOSITION_ID, 
       a.PHYSICIAN,
       a.PHYSICIAN_ID,
       a.PHYSICIAN_BILLED,
       a.CCS_BILLED,
       a.PHYS_CPT_CODE,
       a.CPT_CODE,
       CAST(a.QUANTITY AS int) QUANTITY, 
       a.FACILITY_ID,
       a.FACILITY,
       a.PATIENT_CLASS_ID,
       a.ADJUSTMENT_IND,
       a.DATE_RECEIVED,
       a.COMMENTS,                                     
       a.LAST_UPDATED,
       a.MRN,
       a.PHYSICIAN_HISTORY,  
       a.PHYSICIAN_EXAM, 
       a.PHYSICIAN_MDM
FROM  (SELECT  z.CLASS,
               z.CHART_STATUS,
               z.CHART_ID,
               z.FACILITY_CHART_ID,
               z.SERVICE_AGREEMENT_ID, 
               z.DOS,
               z.SENT,
               z.PATIENT_DISPOSITION_ID, 
               z.PHYSICIAN,
               z.PHYSICIAN_ID,
               z.PHYSICIAN_BILLED,
               z.CCS_BILLED,
               z.PHYS_CPT_CODE,
               z.CPT_CODE,
               z.QUANTITY, 
               z.FACILITY_ID,
               z.FACILITY,
               z.PATIENT_CLASS_ID,
               z.ADJUSTMENT_IND,
               z.DATE_RECEIVED,
               z.COMMENTS,                                     
               @LastUpdated AS LAST_UPDATED,
               z.MRN,
			   z.PHYSICIAN_HISTORY,  
			   z.PHYSICIAN_EXAM, 
			   z.PHYSICIAN_MDM
      FROM(SELECT x.CLASS,
           (SELECT DESCRIPTION 
            FROM CHART_STATUS WITH (NOLOCK) 
            WHERE CHART_STATUS_ID = x.CHART_STATUS_ID) AS CHART_STATUS,
            x.CHART_ID,
            x.FACILITY_CHART_ID,
            x.SERVICE_AGREEMENT_ID, 
            x.DOS, 
            CASE WHEN x.SENT = '' or x.SENT IS NULL THEN 'N/A' ELSE x.SENT END AS SENT,
            x.PATIENT_DISPOSITION_ID, 
            x.PHYSICIAN,
            x.PHYSICIAN_ID,
            x.PHYSICIAN_BILLED,
            x.PHYS_CPT_CODE,
            x.CCS_BILLED,
            x.CPT_CODE, 
            x.QUANTITY, 
            x.FACILITY_ID,
            x.FACILITY,
            x.PATIENT_CLASS_ID, 
            x.ADJUSTMENT_IND, 
            x.DATE_RECEIVED,
            x.COMMENTS,
            x.MRN,
            x.PHYSICIAN_HISTORY,  
			x.PHYSICIAN_EXAM, 
			x.PHYSICIAN_MDM
     FROM (SELECT ap.CLASS,
                  '5' as CHART_STATUS_ID,
                  ap.CHART_ID, 
                  ap.FACILITY_CHART_ID, 
                  ap.SERVICE_AGREEMENT_ID, 
                  CONVERT(VARCHAR,ap.TIME_OF_SERVICE,110) AS DOS, 
                  CONVERT(VARCHAR,ap.SENT_DATE,110) AS SENT, 
                  ap.PATIENT_DISPOSITION_ID,
                  isnull(apc.SERVICE_PROVIDER_NAME,
                  (SELECT fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME 
                   FROM FACILITY_PROFESSIONAL fp with (NOLOCK)
                   WHERE fp.FACILITY_PROF_ID = ap.PHYSICIAN_ID)) AS PHYSICIAN,
                  ap.PHYSICIAN_ID,
                  REPLACE(apc.PROCEDURE_CODE, 'X', '') AS PHYSICIAN_BILLED,
                  apc.CPT_CODE AS PHYS_CPT_CODE,
                  ap.BILLING_CODE AS CCS_BILLED,
                  ap.CPT_CODE,                                                                                      
                  ap.QUANTITY, 
                  ap.FACILITY_ID,
                  (SELECT f.[NAME] 
                   FROM FACILITY f WITH (NOLOCK) 
                   WHERE f.FACILITY_ID = ap.facility_id) AS FACILITY,
                 ap.PATIENT_CLASS_ID, 
               ap.ADJUSTMENT_IND,
               c.DATE_RECEIVED,
               (SELECT MAX(COMMENTS)
                FROM CHART_RECONCILIATION_COMMENTS crc WITH (NOLOCK)
                WHERE crc.FACILITY_CHART_ID = ap.FACILITY_CHART_ID
                AND crc.SERVICE_AGREEMENT_ID = ap.SERVICE_AGREEMENT_ID
                AND CONVERT(VARCHAR, crc.IBEX_CPT) = CASE WHEN apc.CPT_CODE IS NULL THEN ''
                                                          ELSE CONVERT(VARCHAR, apc.CPT_CODE) END
                AND CONVERT(VARCHAR, crc.CCS_CPT) = CASE WHEN ap.CPT_CODE IS NULL THEN ''
                                                         ELSE CONVERT(VARCHAR, ap.CPT_CODE) END) AS COMMENTS,
               c.MEDICAL_RECORD_NUM AS MRN,

				(SELECT psrc.DESCRIPTION 
				FROM 
				PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
				PATIENT_CLASS pc WITH (NOLOCK)
				WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1		-- History
				AND   pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND   psrc.PHYSICIAN_SERVICE_CLASS_CD = pc.PHYSICIAN_SERVICE_CLASS_CD
				AND   psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1 -- this is specific for CHOA
				AND   c.time_of_service between psrc.EFFECTIVE_DATE and psrc.EXPIRATION_DATE
				AND   psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_HISTORY_ID ) as PHYSICIAN_HISTORY ,

				(SELECT psrc.DESCRIPTION 
				FROM 
				PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
				PATIENT_CLASS pc WITH (NOLOCK)
				WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2		-- EXAM
				AND   pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND   psrc.PHYSICIAN_SERVICE_CLASS_CD = pc.PHYSICIAN_SERVICE_CLASS_CD
				AND   psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1 -- this is specific for CHOA
				AND   c.time_of_service between psrc.EFFECTIVE_DATE and psrc.EXPIRATION_DATE
				AND   psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID ) as PHYSICIAN_EXAM ,

				(SELECT psrc.DESCRIPTION 
				FROM 
				PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
				PATIENT_CLASS pc WITH (NOLOCK)
				WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 3		-- MDM
				AND   pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND   psrc.PHYSICIAN_SERVICE_CLASS_CD = pc.PHYSICIAN_SERVICE_CLASS_CD
				AND   psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1 -- this is specific for CHOA
				AND   c.time_of_service between psrc.EFFECTIVE_DATE and psrc.EXPIRATION_DATE
				AND   psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_MDM_ID ) as PHYSICIAN_MDM

          FROM SENT_PROCEDURE ap WITH (NOLOCK), ASA_PHYSICIAN_CHARGES apc WITH (NOLOCK), chart c WITH (NOLOCK)
          WHERE ap.CHART_ID = CASE WHEN @ChartID_Local IS NOT NULL THEN @ChartID_Local
                              ELSE ap.CHART_ID END
          AND ap.FACILITY_ID = @Facility_Local
          AND c.CHART_ID = ap.CHART_ID
          AND ap.CLASS = 'PL'
          --AND ap.CHART_STATUS_ID IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
          AND ap.CPT_CODE IN ('99281','99282','99283','99284','99285','99291','99292')
          AND apc.FACILITY_CHART_ID = ap.FACILITY_CHART_ID
          AND apc.CPT_CODE <> ap.CPT_CODE
          AND convert(varchar,ap.time_of_service, 110) <= convert(varchar,apc.DATE_OF_SERVICE, 110))x
    WHERE x.PHYS_CPT_CODE IN ('99281','99282','99283','99284','99285','99291','99292')
    UNION ALL
    SELECT y.CLASS,
           (SELECT DESCRIPTION 
            FROM CHART_STATUS WITH (NOLOCK) 
            WHERE CHART_STATUS_ID = y.CHART_STATUS_ID) AS CHART_STATUS,
           y.CHART_ID, 
           y.FACILITY_CHART_ID,
           y.SERVICE_AGREEMENT_ID, 
           y.DOS, 
           case when y.SENT = '' or y.SENT is null then 'N/A' else y.SENT end AS SENT,
           y.PATIENT_DISPOSITION_ID, 
           y.PHYSICIAN,
           y.PHYSICIAN_ID,
           y.PHYSICIAN_BILLED,
           y.PHYS_CPT_CODE,
           y.CCS_BILLED,
           y.CPT_CODE, 
           y.QUANTITY, 
           y.FACILITY_ID,
           y.FACILITY,
           y.PATIENT_CLASS_ID, 
           y.ADJUSTMENT_IND,
           y.DATE_RECEIVED,
           y.COMMENTS,
           y.MRN,
		   y.PHYSICIAN_HISTORY,  
           y.PHYSICIAN_EXAM, 
           y.PHYSICIAN_MDM  
    FROM (SELECT ap.CLASS,
                 '5' as CHART_STATUS_ID,
                 ap.CHART_ID, 
                 ap.FACILITY_CHART_ID, 
                 ap.SERVICE_AGREEMENT_ID, 
                 CONVERT(VARCHAR,ap.TIME_OF_SERVICE,110) AS DOS, 
                 CONVERT(VARCHAR,ap.SENT_DATE,110) AS SENT, 
                 ap.PATIENT_DISPOSITION_ID,
                 isnull(apc.SERVICE_PROVIDER_NAME,
                 (SELECT fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME 
                  FROM FACILITY_PROFESSIONAL fp with (NOLOCK)
                  WHERE fp.FACILITY_PROF_ID = ap.PHYSICIAN_ID)) AS PHYSICIAN,
                 ap.PHYSICIAN_ID,
                 REPLACE(apc.PROCEDURE_CODE, 'X', '') AS PHYSICIAN_BILLED,
                 apc.CPT_CODE AS PHYS_CPT_CODE,
                 ap.BILLING_CODE AS CCS_BILLED, 
                 ap.CPT_CODE,
                 ap.QUANTITY, 
                 ap.FACILITY_ID,
                 (SELECT f.[NAME] 
                  FROM FACILITY f WITH (NOLOCK) 
                  WHERE f.FACILITY_ID = ap.facility_id) AS FACILITY,
                 ap.PATIENT_CLASS_ID, 
                 ap.ADJUSTMENT_IND,
                 c.DATE_RECEIVED,
                (SELECT MAX(COMMENTS)
                 FROM CHART_RECONCILIATION_COMMENTS crc WITH (NOLOCK)
                 WHERE crc.FACILITY_CHART_ID = ap.FACILITY_CHART_ID
                 AND crc.SERVICE_AGREEMENT_ID = ap.SERVICE_AGREEMENT_ID
                 AND CONVERT(VARCHAR, crc.IBEX_CPT) = CASE WHEN apc.CPT_CODE IS NULL THEN ''
                                                           ELSE CONVERT(VARCHAR, apc.CPT_CODE) END
                 AND CONVERT(VARCHAR, crc.CCS_CPT) = CASE WHEN ap.CPT_CODE IS NULL THEN ''
                                                          ELSE CONVERT(VARCHAR, ap.CPT_CODE) END) AS COMMENTS,
                 c.MEDICAL_RECORD_NUM AS MRN,

				(SELECT psrc.DESCRIPTION 
				FROM 
				PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
				PATIENT_CLASS pc WITH (NOLOCK)
				WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1		-- History
				AND   pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND   psrc.PHYSICIAN_SERVICE_CLASS_CD = pc.PHYSICIAN_SERVICE_CLASS_CD
				AND   psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1 -- this is specific for CHOA
				AND   c.time_of_service between psrc.EFFECTIVE_DATE and psrc.EXPIRATION_DATE
				AND   psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_HISTORY_ID ) as PHYSICIAN_HISTORY ,

				(SELECT psrc.DESCRIPTION 
				FROM 
				PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
				PATIENT_CLASS pc WITH (NOLOCK)
				WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2		-- EXAM
				AND   pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND   psrc.PHYSICIAN_SERVICE_CLASS_CD = pc.PHYSICIAN_SERVICE_CLASS_CD
				AND   psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1 -- this is specific for CHOA
				AND   c.time_of_service between psrc.EFFECTIVE_DATE and psrc.EXPIRATION_DATE
				AND   psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID ) as PHYSICIAN_EXAM ,

				(SELECT psrc.DESCRIPTION 
				FROM 
				PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
				PATIENT_CLASS pc WITH (NOLOCK)
				WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 3		-- MDM
				AND   pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND   psrc.PHYSICIAN_SERVICE_CLASS_CD = pc.PHYSICIAN_SERVICE_CLASS_CD
				AND   psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1 -- this is specific for CHOA
				AND   c.time_of_service between psrc.EFFECTIVE_DATE and psrc.EXPIRATION_DATE
				AND   psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_MDM_ID ) as PHYSICIAN_MDM

    FROM SENT_PROCEDURE ap WITH (NOLOCK), ASA_PHYSICIAN_CHARGES apc WITH (NOLOCK), chart c WITH (NOLOCK)
    WHERE ap.facility_id = @Facility_Local
         AND ap.CHART_ID = CASE WHEN @ChartID_Local IS NOT NULL THEN @ChartID_Local
                           ELSE ap.CHART_ID END
         AND c.CHART_ID = ap.CHART_ID                        
         AND ap.CLASS = 'PP'
         --AND CONVERT(VARCHAR,ap.CHART_STATUS_ID) IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
         AND ap.CPT_CODE NOT IN ('99281','99282','99283','99284','99285','99291','99292')
         AND apc.facility_chart_id = ap.FACILITY_CHART_ID
         AND apc.CPT_CODE NOT IN
            (SELECT sp2.CPT_CODE 
             FROM SENT_PROCEDURE sp2 WITH (NOLOCK)
             WHERE sp2.facility_id = @Facility_Local
             AND sp2.FACILITY_CHART_ID = apc.FACILITY_CHART_ID
             AND sp2.CPT_CODE = apc.CPT_CODE)
         AND convert(varchar,ap.time_of_service, 110) = convert(varchar,apc.DATE_OF_SERVICE, 110))y
    WHERE y.PHYS_CPT_CODE NOT IN ('99281','99282','99283','99284','99285','99291','99292'))z
    WHERE z.DOS BETWEEN @StartDate_Local AND @EndDate_Local
    UNION ALL
    SELECT 'N/A' AS CLASS,
           (SELECT DESCRIPTION 
            FROM CHART_STATUS WITH (NOLOCK) 
            WHERE CHART_STATUS_ID =  c.CHART_STATUS_ID) AS CHART_STATUS,
            c.CHART_ID,
           c.FACILITY_CHART_ID,
           @ServiceAgreement AS SERVICE_AGREEMENT_ID,
           c.TIME_OF_SERVICE AS DOS, 
           CASE WHEN CONVERT(VARCHAR,c.SENT_DATE,110) IS NOT NULL 
                     AND CONVERT(VARCHAR,c.SENT_DATE,110) <> '' 
                THEN CONVERT(VARCHAR,c.SENT_DATE,110)
                ELSE 'N/A' END AS SENT,
           c.PATIENT_DISPOSITION_ID,
           isnull(apc2.SERVICE_PROVIDER_NAME,
           (SELECT fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME 
            FROM FACILITY_PROFESSIONAL fp with (NOLOCK)
            WHERE fp.FACILITY_PROF_ID = c.PHYSICIAN_ID)) AS PHYSICIAN,
           c.PHYSICIAN_ID,
           REPLACE(apc2.PROCEDURE_CODE, 'X', '') AS PHYSICIAN_BILLED,
           NULL AS CCS_BILLED,
           apc2.CPT_CODE AS PHYS_CPT_CODE,
           NULL AS CPT_CODE,
           apc2.QUANTITY AS QUANTITY,
           @Facility_Local AS FACILITY_ID,
           (SELECT [NAME] FROM FACILITY  WITH (NOLOCK) WHERE FACILITY_ID = @Facility_Local) AS FACILITY,
           '' AS PATIENT_CLASS_ID,
           '' AS ADJUSTMENT_IND,
           c.DATE_RECEIVED AS DATE_RECEIVED, 
          (SELECT MAX(COMMENTS)
           FROM CHART_RECONCILIATION_COMMENTS crc WITH (NOLOCK)
           WHERE crc.FACILITY_CHART_ID = c.FACILITY_CHART_ID
           AND crc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
           AND CONVERT(VARCHAR, crc.IBEX_CPT) = CASE WHEN apc2.CPT_CODE IS NULL THEN ''
                                                     ELSE CONVERT(VARCHAR, apc2.CPT_CODE) END
           AND CONVERT(VARCHAR, crc.CCS_CPT) = '') AS COMMENTS,
           apc2.CREATION_DATE_TIME,
           c.MEDICAL_RECORD_NUM AS MRN,

		   (SELECT psrc.DESCRIPTION 
			FROM 
			PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
			PATIENT_CLASS pc WITH (NOLOCK)
			WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 1		-- History
			AND   pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND   psrc.PHYSICIAN_SERVICE_CLASS_CD = pc.PHYSICIAN_SERVICE_CLASS_CD
			AND   psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1 -- this is specific for CHOA
			AND   c.time_of_service between psrc.EFFECTIVE_DATE and psrc.EXPIRATION_DATE
			AND   psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_HISTORY_ID ) as PHYSICIAN_HISTORY ,

		   (SELECT psrc.DESCRIPTION 
			FROM 
			PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
			PATIENT_CLASS pc WITH (NOLOCK)
			WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 2		-- EXAM
			AND   pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND   psrc.PHYSICIAN_SERVICE_CLASS_CD = pc.PHYSICIAN_SERVICE_CLASS_CD
			AND   psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1 -- this is specific for CHOA
			AND   c.time_of_service between psrc.EFFECTIVE_DATE and psrc.EXPIRATION_DATE
			AND   psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_EXAM_ID ) as PHYSICIAN_EXAM ,

		   (SELECT psrc.DESCRIPTION 
			FROM 
			PHYSICIAN_SERVICE_RATING_CODE psrc WITH (NOLOCK),
			PATIENT_CLASS pc WITH (NOLOCK)
			WHERE psrc.PHYSICIAN_SERVICE_CATEGORY_ID = 3		-- MDM
			AND   pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND   psrc.PHYSICIAN_SERVICE_CLASS_CD = pc.PHYSICIAN_SERVICE_CLASS_CD
			AND   psrc.PHYSICIAN_SERVICE_GUIDELINE_ID = 1 -- this is specific for CHOA
			AND   c.time_of_service between psrc.EFFECTIVE_DATE and psrc.EXPIRATION_DATE
			AND   psrc.PHYSICIAN_SERVICE_CATEGORY_RATING = c.PHYSICIAN_MDM_ID ) as PHYSICIAN_MDM

    FROM ASA_PHYSICIAN_CHARGES apc2 WITH (NOLOCK), CHART c WITH (NOLOCK)
    WHERE apc2.FACILITY_ID = @Facility_Local
    AND apc2.FACILITY_CHART_ID = CASE WHEN @ChartID_Local IS NOT NULL THEN (SELECT FACILITY_CHART_ID 
                                                                            FROM CHART WITH (NOLOCK)
                                                                            WHERE CHART_ID = @ChartID_Local)
                                 ELSE apc2.FACILITY_CHART_ID END
    AND c.FACILITY_CHART_ID = apc2.FACILITY_CHART_ID
    AND c.FACILITY_ID = apc2.FACILITY_ID
    AND apc2.CPT_CODE <> '' AND apc2.CPT_CODE IS NOT NULL
    --AND CONVERT(VARCHAR,c.CHART_STATUS_ID) IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
    AND CASE WHEN apc2.CPT_CODE <> '' AND apc2.CPT_CODE IS NOT NULL THEN apc2.CPT_CODE
             ELSE (SELECT MAX(cm.CPT_CODE) 
                   FROM CHARGE_MASTER cm with (NOLOCK)
                   WHERE cm.BILLING_CODE = REPLACE(apc2.PROCEDURE_CODE, 'X', '')
                   AND cm.SERVICE_AGREEMENT_ID = @ServiceAgreement) END 
                       NOT IN (SELECT CPT_CODE sp2
                       FROM SENT_PROCEDURE sp2 WITH (NOLOCK)
                       WHERE sp2.facility_id = @Facility_Local
                       AND   sp2.FACILITY_CHART_ID = apc2.FACILITY_CHART_ID)
    AND NOT EXISTS (SELECT * FROM SENT_PROCEDURE ap WITH (NOLOCK)
                    WHERE ap.facility_id = @Facility_Local
                    AND ap.facility_chart_id = apc2.FACILITY_CHART_ID
                    AND ap.CLASS IN ('PP')
                    --AND CONVERT(VARCHAR,ap.CHART_STATUS_ID) IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
                    AND convert(varchar,ap.time_of_service, 110) <= convert(varchar,apc2.DATE_OF_SERVICE, 110)
                    AND CASE WHEN apc2.CPT_CODE <> '' AND apc2.CPT_CODE IS NOT NULL THEN apc2.CPT_CODE
                             ELSE (SELECT MAX(cm.CPT_CODE) 
                                   FROM CHARGE_MASTER cm with (NOLOCK)
                                   WHERE cm.BILLING_CODE = REPLACE(apc2.PROCEDURE_CODE, 'X', '')
                                   AND cm.SERVICE_AGREEMENT_ID = @ServiceAgreement) END = ap.CPT_CODE
                    )
    AND NOT EXISTS (SELECT * 
                    FROM (SELECT *
                          FROM(SELECT (SELECT DESCRIPTION 
                                       FROM CHART_STATUS WITH (NOLOCK) 
                                       WHERE CHART_STATUS_ID = x.CHART_STATUS_ID) AS CHART_STATUS,
                                       x.CHART_ID, 
                                       x.FACILITY_CHART_ID, 
                                       x.SERVICE_AGREEMENT_ID, 
                                       x.DOS, 
                                       x.SENT, 
                                       x.PHYSICIAN,
                                       x.PHYSICIAN_ID,
                                       x.PHYS_CPT_CODE,
                                       x.CPT_CODE, 
                                       x.QUANTITY, 
                                       x.FACILITY_ID,
                                       x.FACILITY
                               FROM (SELECT '5' AS CHART_STATUS_ID,
                                            ap.CHART_ID, 
                                            ap.FACILITY_CHART_ID, 
                                            ap.SERVICE_AGREEMENT_ID, 
                                            CONVERT(VARCHAR,ap.TIME_OF_SERVICE,110) AS DOS, 
                                            CONVERT(VARCHAR,ap.SENT_DATE,110) AS SENT,
                                            isnull(apc.SERVICE_PROVIDER_NAME,
                                            (SELECT fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME 
                                                  FROM FACILITY_PROFESSIONAL fp with (NOLOCK)
                                                  WHERE fp.FACILITY_PROF_ID = ap.PHYSICIAN_ID)) AS PHYSICIAN,
                                                ap.PHYSICIAN_ID,
                                                CASE WHEN apc.CPT_CODE <> '' AND apc.CPT_CODE IS NOT NULL 
                                                     THEN apc.CPT_CODE 
                                                     ELSE (SELECT MAX(cm.CPT_CODE) 
                                                           FROM CHARGE_MASTER cm with (NOLOCK)
                                                           WHERE cm.BILLING_CODE = REPLACE(apc.PROCEDURE_CODE, 'X', '')
                                                           AND cm.SERVICE_AGREEMENT_ID = ap.SERVICE_AGREEMENT_ID) 
                                                           END AS PHYS_CPT_CODE,
                                                ap.CPT_CODE,
                                                ap.QUANTITY, 
                                                ap.FACILITY_ID,
                                                (SELECT f.[NAME] 
                                                 FROM FACILITY f WITH (NOLOCK) 
                                                 WHERE f.FACILITY_ID = ap.facility_id) AS FACILITY
                                    FROM SENT_PROCEDURE ap WITH (NOLOCK), ASA_PHYSICIAN_CHARGES apc WITH (NOLOCK)
                                    WHERE ap.facility_id = @Facility_Local
                                    AND   ap.CHART_ID = CASE WHEN @ChartID_Local IS NOT NULL THEN @ChartID_Local
                                                        ELSE ap.CHART_ID END
                                    AND   ap.CLASS IN ('PP')
                                    --AND CONVERT(VARCHAR,ap.CHART_STATUS_ID) IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
                                    AND   apc.facility_chart_id = ap.FACILITY_CHART_ID
                                    AND   convert(varchar,ap.time_of_service, 110) <= convert(varchar,apc.DATE_OF_SERVICE, 110))x
                                    WHERE x.CPT_CODE <> x.PHYS_CPT_CODE
                                    UNION
                                    SELECT(SELECT DESCRIPTION 
                                           FROM CHART_STATUS WITH (NOLOCK) 
                                           WHERE CHART_STATUS_ID = y.CHART_STATUS_ID) AS CHART_STATUS,
                                          y.CHART_ID, 
                                          y.FACILITY_CHART_ID, 
                                          y.SERVICE_AGREEMENT_ID, 
                                          y.DOS, 
                                          y.SENT, 
                                          y.PHYSICIAN,
                                          y.PHYSICIAN_ID,
                                          y.PHYS_CPT_CODE,
                                          y.CPT_CODE,
                                          y.QUANTITY, 
                                          y.FACILITY_ID,
                                          y.FACILITY
                                    FROM (SELECT '5' as CHART_STATUS_ID,
                                                ap.CHART_ID, 
                                                ap.FACILITY_CHART_ID, 
                                                ap.SERVICE_AGREEMENT_ID, 
                                                CONVERT(VARCHAR,ap.TIME_OF_SERVICE,110) AS DOS, 
                                                CONVERT(VARCHAR,ap.SENT_DATE,110) AS SENT,
                                                isnull(apc.SERVICE_PROVIDER_NAME,
                                                (SELECT fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME 
                                                  FROM FACILITY_PROFESSIONAL fp with (NOLOCK)
                                                  WHERE fp.FACILITY_PROF_ID = ap.PHYSICIAN_ID)) AS PHYSICIAN,
                                                ap.PHYSICIAN_ID,
                                                CASE WHEN apc.CPT_CODE <> '' 
                                                     AND apc.CPT_CODE IS NOT NULL THEN apc.CPT_CODE 
                                                     ELSE (SELECT MAX(cm.CPT_CODE) 
                                                           FROM CHARGE_MASTER cm with (NOLOCK)
                                                           WHERE cm.BILLING_CODE = REPLACE(apc.PROCEDURE_CODE, 'X', '')
                                                           AND cm.SERVICE_AGREEMENT_ID = ap.SERVICE_AGREEMENT_ID) 
                                                           END AS PHYS_CPT_CODE,
                                                ap.CPT_CODE,
                                                ap.QUANTITY, 
                                                ap.FACILITY_ID,
                                                (SELECT f.[NAME] 
                                                 FROM FACILITY f WITH (NOLOCK) 
                                                 WHERE f.FACILITY_ID = ap.facility_id) AS FACILITY
                                    FROM SENT_PROCEDURE ap WITH (NOLOCK), ASA_PHYSICIAN_CHARGES apc WITH (NOLOCK)
                                    WHERE ap.facility_id = @Facility_Local
                                        AND ap.CHART_ID = CASE WHEN @ChartID_Local IS NOT NULL THEN @ChartID_Local
                                                          ELSE ap.CHART_ID END
                                        AND ap.CLASS IN ('PP')
                                        AND apc.facility_chart_id = ap.FACILITY_CHART_ID
                                        --AND CONVERT(VARCHAR,ap.CHART_STATUS_ID) IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
                                        AND convert(varchar,ap.time_of_service, 110) <= convert(varchar,apc.DATE_OF_SERVICE, 110))y
                                    WHERE y.CPT_CODE <> y.PHYS_CPT_CODE)z
                                    WHERE z.CPT_CODE NOT IN ('99281','99282','99283','99284','99285','99291','99292') 
                                          AND z.PHYS_CPT_CODE NOT IN ('99281','99282','99283','99284','99285','99291','99292'))z2
                                          WHERE apc2.FACILITY_CHART_ID = z2.FACILITY_CHART_ID
                                          AND (apc2.CPT_CODE = z2.PHYS_CPT_CODE or
                                           CASE WHEN apc2.CPT_CODE <> '' 
                                                AND apc2.CPT_CODE IS NOT NULL THEN apc2.CPT_CODE
                                                ELSE (SELECT MAX(cm.CPT_CODE) 
                                                      FROM CHARGE_MASTER cm with (NOLOCK)
                                                      WHERE cm.BILLING_CODE = REPLACE(apc2.PROCEDURE_CODE, 'X', '')
                                                      AND cm.SERVICE_AGREEMENT_ID = @ServiceAgreement) END 
                                              NOT IN (SELECT ap.CPT_CODE
                                                      FROM SENT_PROCEDURE ap WITH (NOLOCK)
                                                      WHERE ap.CHART_ID = z2.CHART_ID)))
    AND apc2.CPT_CODE NOT IN ('99281','99282','99283','99284','99285','99291','99292')
    AND convert(varchar,apc2.DATE_OF_SERVICE, 110) BETWEEN @StartDate_Local AND @EndDate_Local)a
WHERE a.CHART_ID = CASE WHEN @ChartID_Local IS NOT NULL THEN @ChartID_Local
                   ELSE a.CHART_ID END
ORDER BY a.PHYSICIAN, a.FACILITY_CHART_ID, a.DOS



GO
GRANT EXECUTE ON  [dbo].[MISMATCH_CHARGE_REPORT] TO [dbx_ExecuteReportProcs]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Results for a specific chart ID', 'SCHEMA', N'dbo', 'PROCEDURE', N'MISMATCH_CHARGE_REPORT', 'PARAMETER', N'@ChartID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'String list of chart status to include in the search.', 'SCHEMA', N'dbo', 'PROCEDURE', N'MISMATCH_CHARGE_REPORT', 'PARAMETER', N'@ChartStatusList'
GO
EXEC sp_addextendedproperty N'MS_Description', N'To date of service', 'SCHEMA', N'dbo', 'PROCEDURE', N'MISMATCH_CHARGE_REPORT', 'PARAMETER', N'@EndDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Facility ID', 'SCHEMA', N'dbo', 'PROCEDURE', N'MISMATCH_CHARGE_REPORT', 'PARAMETER', N'@Facility'
GO
EXEC sp_addextendedproperty N'MS_Description', N'From date of service', 'SCHEMA', N'dbo', 'PROCEDURE', N'MISMATCH_CHARGE_REPORT', 'PARAMETER', N'@StartDate'
GO
