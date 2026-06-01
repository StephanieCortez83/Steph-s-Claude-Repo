SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[MISMATCH_CHARGE_REPORT_OLD]
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
                         FROM SERVICE_AGREEMENT sa
                         WHERE sa.FACILITY_ID = @Facility_Local);
                         
DECLARE @LastUpdated DateTime; 
SET @LastUpdated = (SELECT MAX(CREATION_DATE_TIME)
                    FROM CHOA_ASAP_CHARGES cac
                    WHERE cac.LOC_ID = @Facility_Local)
                                                   
SELECT  * 
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
               z.MRN
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
            x.MRN
     FROM (SELECT ap.CLASS,
                  ap.CHART_STATUS_ID,
                  ap.CHART_ID, 
                  ap.FACILITY_CHART_ID, 
                  ap.SERVICE_AGREEMENT_ID, 
                  CONVERT(VARCHAR,ap.TIME_OF_SERVICE,110) AS DOS, 
                  CONVERT(VARCHAR,ap.SENT_DATE,110) AS SENT, 
                  ap.PATIENT_DISPOSITION_ID, 
                  (SELECT fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME 
                   FROM FACILITY_PROFESSIONAL fp with (NOLOCK)
                   WHERE fp.FACILITY_PROF_ID = ap.PHYSICIAN_ID) AS PHYSICIAN,
                  ap.PHYSICIAN_ID,
                  cac.PROC_CODE AS PHYSICIAN_BILLED,
                  cac.CPT_CODE AS PHYS_CPT_CODE,
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
                FROM CHART_RECONCILIATION_COMMENTS crc
                WHERE crc.FACILITY_CHART_ID = ap.FACILITY_CHART_ID
                AND crc.SERVICE_AGREEMENT_ID = ap.SERVICE_AGREEMENT_ID
                AND CONVERT(VARCHAR, crc.IBEX_CPT) = CASE WHEN cac.CPT_CODE IS NULL THEN ''
                                                          ELSE CONVERT(VARCHAR, cac.CPT_CODE) END
                AND CONVERT(VARCHAR, crc.CCS_CPT) = CASE WHEN ap.CPT_CODE IS NULL THEN ''
                                                         ELSE CONVERT(VARCHAR, ap.CPT_CODE) END) AS COMMENTS,
               c.MEDICAL_RECORD_NUM AS MRN
          FROM CCSTransactionSnapshot.dbo.ALL_PROCEDURES ap, CHOA_ASAP_CHARGES cac WITH (NOLOCK), chart c WITH (NOLOCK)
          WHERE ap.FACILITY_CHART_ID = cac.HSP_ACCOUNT_ID
          AND ap.CHART_ID = c.CHART_ID
          AND ap.CLASS IN ('PL')
          AND ap.CHART_STATUS_ID IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
          AND cac.CPT_CODE <> ap.CPT_CODE
          AND ap.CPT_CODE IN ('99281','99282','99283','99284','99285','99291','99292')
          AND convert(varchar,ap.time_of_service, 110) <= convert(varchar,cac.SERVICE_DATE, 110)
          AND ap.FACILITY_ID = @Facility_Local)x
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
           y.MRN
    FROM (SELECT ap.CLASS,
                 ap.CHART_STATUS_ID,
                 ap.CHART_ID, 
                 ap.FACILITY_CHART_ID, 
                 ap.SERVICE_AGREEMENT_ID, 
                 CONVERT(VARCHAR,ap.TIME_OF_SERVICE,110) AS DOS, 
                 CONVERT(VARCHAR,ap.SENT_DATE,110) AS SENT, 
                 ap.PATIENT_DISPOSITION_ID, 
                 (SELECT fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME 
                  FROM FACILITY_PROFESSIONAL fp with (NOLOCK)
                  WHERE fp.FACILITY_PROF_ID = ap.PHYSICIAN_ID) AS PHYSICIAN,
                 ap.PHYSICIAN_ID,
                 cac.PROC_CODE AS PHYSICIAN_BILLED,
                 cac.CPT_CODE AS PHYS_CPT_CODE,
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
                 FROM CHART_RECONCILIATION_COMMENTS crc
                 WHERE crc.FACILITY_CHART_ID = ap.FACILITY_CHART_ID
                 AND crc.SERVICE_AGREEMENT_ID = ap.SERVICE_AGREEMENT_ID
                 AND CONVERT(VARCHAR, crc.IBEX_CPT) = CASE WHEN cac.CPT_CODE IS NULL THEN ''
                                                           ELSE CONVERT(VARCHAR, cac.CPT_CODE) END
                 AND CONVERT(VARCHAR, crc.CCS_CPT) = CASE WHEN ap.CPT_CODE IS NULL THEN ''
                                                          ELSE CONVERT(VARCHAR, ap.CPT_CODE) END) AS COMMENTS,
                 c.MEDICAL_RECORD_NUM AS MRN 
    FROM CCSTransactionSnapshot.dbo.ALL_PROCEDURES ap, CHOA_ASAP_CHARGES cac WITH (NOLOCK), chart c WITH (NOLOCK)
    WHERE ap.facility_chart_id = cac.HSP_ACCOUNT_ID
         AND ap.facility_chart_id = c.FACILITY_CHART_ID
         AND ap.CLASS IN ('PP')
         AND CONVERT(VARCHAR,ap.CHART_STATUS_ID) IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
         AND cac.CPT_CODE NOT IN
            (SELECT CPT_CODE 
             FROM CCSTransactionSnapshot.dbo.ALL_PROCEDURES
             WHERE CPT_CODE = cac.CPT_CODE
             AND FACILITY_CHART_ID = cac.HSP_ACCOUNT_ID)
         AND ap.CPT_CODE NOT IN ('99281','99282','99283','99284','99285','99291','99292')
         AND convert(varchar,ap.time_of_service, 110) = convert(varchar,cac.SERVICE_DATE, 110)
         AND ap.facility_id = @Facility_Local)y
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
           (SELECT fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME 
            FROM FACILITY_PROFESSIONAL fp with (NOLOCK)
            WHERE fp.FACILITY_PROF_ID = c.PHYSICIAN_ID) AS PHYSICIAN,
           c.PHYSICIAN_ID,
           cac2.PROC_CODE AS PHYSICIAN_BILLED,
           NULL AS CCS_BILLED,
           cac2.CPT_CODE AS PHYS_CPT_CODE,
           NULL AS CPT_CODE,
           cac2.QUANTITY AS QUANTITY,
           @Facility_Local AS FACILITY_ID,
           (SELECT [NAME] FROM FACILITY WHERE FACILITY_ID = @Facility_Local) AS FACILITY,
           '' AS PATIENT_CLASS_ID,
           '' AS ADJUSTMENT_IND,
           c.DATE_RECEIVED AS DATE_RECEIVED, 
          (SELECT MAX(COMMENTS)
           FROM CHART_RECONCILIATION_COMMENTS crc
           WHERE crc.FACILITY_CHART_ID = c.FACILITY_CHART_ID
           AND crc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
           AND CONVERT(VARCHAR, crc.IBEX_CPT) = CASE WHEN cac2.CPT_CODE IS NULL THEN ''
                                                     ELSE CONVERT(VARCHAR, cac2.CPT_CODE) END
           AND CONVERT(VARCHAR, crc.CCS_CPT) = '') AS COMMENTS,
           cac2.CREATION_DATE_TIME,
           c.MEDICAL_RECORD_NUM AS MRN
    FROM CHOA_ASAP_CHARGES cac2, CHART c WITH (NOLOCK)
    WHERE cac2.HSP_ACCOUNT_ID = c.FACILITY_CHART_ID
    AND cac2.LOC_ID = c.FACILITY_ID
    AND cac2.CPT_CODE <> '' AND cac2.CPT_CODE IS NOT NULL
    AND cac2.LOC_ID = @Facility_Local
    AND CONVERT(VARCHAR,c.CHART_STATUS_ID) IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
    AND CASE WHEN cac2.CPT_CODE <> '' AND cac2.CPT_CODE IS NOT NULL THEN cac2.CPT_CODE
             ELSE (SELECT MAX(cm.CPT_CODE) 
                   FROM CHARGE_MASTER cm with (NOLOCK)
                   WHERE cm.BILLING_CODE = cac2.PROC_CODE
                   AND cm.SERVICE_AGREEMENT_ID = @ServiceAgreement) END 
                       NOT IN (SELECT CPT_CODE
                       FROM CCSTransactionSnapshot.dbo.ALL_PROCEDURES
                       WHERE FACILITY_CHART_ID = cac2.HSP_ACCOUNT_ID)
    AND NOT EXISTS (SELECT * FROM CCSTransactionSnapshot.dbo.ALL_PROCEDURES ap
                    WHERE ap.facility_chart_id = cac2.HSP_ACCOUNT_ID
                    AND ap.CLASS IN ('PP')
                    AND CONVERT(VARCHAR,ap.CHART_STATUS_ID) IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
                    AND convert(varchar,ap.time_of_service, 110) <= convert(varchar,cac2.SERVICE_DATE, 110)
                    AND CASE WHEN cac2.CPT_CODE <> '' AND cac2.CPT_CODE IS NOT NULL THEN cac2.CPT_CODE
                             ELSE (SELECT MAX(cm.CPT_CODE) 
                                   FROM CHARGE_MASTER cm with (NOLOCK)
                                   WHERE cm.BILLING_CODE = cac2.PROC_CODE
                                   AND cm.SERVICE_AGREEMENT_ID = @ServiceAgreement) END = ap.CPT_CODE
                    AND ap.FACILITY_ID = @Facility_Local)
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
                               FROM (SELECT ap.CHART_STATUS_ID,
                                            ap.CHART_ID, 
                                            ap.FACILITY_CHART_ID, 
                                            ap.SERVICE_AGREEMENT_ID, 
                                            CONVERT(VARCHAR,ap.TIME_OF_SERVICE,110) AS DOS, 
                                            CONVERT(VARCHAR,ap.SENT_DATE,110) AS SENT, 
                                            (SELECT fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME 
                                                  FROM FACILITY_PROFESSIONAL fp with (NOLOCK)
                                                  WHERE fp.FACILITY_PROF_ID = ap.PHYSICIAN_ID) AS PHYSICIAN,
                                                ap.PHYSICIAN_ID,
                                                CASE WHEN cac.CPT_CODE <> '' AND cac.CPT_CODE IS NOT NULL 
                                                     THEN cac.CPT_CODE 
                                                     ELSE (SELECT MAX(cm.CPT_CODE) 
                                                           FROM CHARGE_MASTER cm with (NOLOCK)
                                                           WHERE cm.BILLING_CODE = cac.PROC_CODE
                                                           AND cm.SERVICE_AGREEMENT_ID = ap.SERVICE_AGREEMENT_ID) 
                                                           END AS PHYS_CPT_CODE,
                                                ap.CPT_CODE,
                                                ap.QUANTITY, 
                                                ap.FACILITY_ID,
                                                (SELECT f.[NAME] 
                                                 FROM FACILITY f WITH (NOLOCK) 
                                                 WHERE f.FACILITY_ID = ap.facility_id) AS FACILITY
                                    FROM CCSTransactionSnapshot.dbo.ALL_PROCEDURES ap, CHOA_ASAP_CHARGES cac WITH (NOLOCK)
                                    WHERE ap.facility_chart_id = cac.HSP_ACCOUNT_ID
                                        AND ap.CLASS IN ('PP')
                                        AND CONVERT(VARCHAR,ap.CHART_STATUS_ID) IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
                                        AND convert(varchar,ap.time_of_service, 110) <= convert(varchar,cac.SERVICE_DATE, 110)
                                        AND ap.facility_id = @Facility_Local)x
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
                                    FROM (SELECT ap.CHART_STATUS_ID,
                                                ap.CHART_ID, 
                                                ap.FACILITY_CHART_ID, 
                                                ap.SERVICE_AGREEMENT_ID, 
                                                CONVERT(VARCHAR,ap.TIME_OF_SERVICE,110) AS DOS, 
                                                CONVERT(VARCHAR,ap.SENT_DATE,110) AS SENT, 
                                                (SELECT fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME 
                                                  FROM FACILITY_PROFESSIONAL fp with (NOLOCK)
                                                  WHERE fp.FACILITY_PROF_ID = ap.PHYSICIAN_ID) AS PHYSICIAN,
                                                ap.PHYSICIAN_ID,
                                                CASE WHEN cac.CPT_CODE <> '' 
                                                     AND cac.CPT_CODE IS NOT NULL THEN cac.CPT_CODE 
                                                     ELSE (SELECT MAX(cm.CPT_CODE) 
                                                           FROM CHARGE_MASTER cm with (NOLOCK)
                                                           WHERE cm.BILLING_CODE = cac.PROC_CODE
                                                           AND cm.SERVICE_AGREEMENT_ID = ap.SERVICE_AGREEMENT_ID) 
                                                           END AS PHYS_CPT_CODE,
                                                ap.CPT_CODE,
                                                ap.QUANTITY, 
                                                ap.FACILITY_ID,
                                                (SELECT f.[NAME] 
                                                 FROM FACILITY f WITH (NOLOCK) 
                                                 WHERE f.FACILITY_ID = ap.facility_id) AS FACILITY
                                    FROM CCSTransactionSnapshot.dbo.ALL_PROCEDURES ap, CHOA_ASAP_CHARGES cac WITH (NOLOCK)
                                    WHERE ap.facility_chart_id = cac.HSP_ACCOUNT_ID
                                        AND ap.CLASS IN ('PP')
                                        AND CONVERT(VARCHAR,ap.CHART_STATUS_ID) IN (SELECT * FROM dbo.SplitString(@ChartStatusList_Local, ','))
                                        AND convert(varchar,ap.time_of_service, 110) <= convert(varchar,cac.SERVICE_DATE, 110)
                                        AND ap.facility_id = @Facility_Local)y
                                    WHERE y.CPT_CODE <> y.PHYS_CPT_CODE)z
                                    WHERE z.CPT_CODE NOT IN ('99281','99282','99283','99284','99285','99291','99292') 
                                          AND z.PHYS_CPT_CODE NOT IN ('99281','99282','99283','99284','99285','99291','99292'))z2
                                          WHERE cac2.HSP_ACCOUNT_ID = z2.FACILITY_CHART_ID
                                          AND (cac2.CPT_CODE = z2.PHYS_CPT_CODE or
                                           CASE WHEN cac2.CPT_CODE <> '' 
                                                AND cac2.CPT_CODE IS NOT NULL THEN cac2.CPT_CODE
                                                ELSE (SELECT MAX(cm.CPT_CODE) 
                                                      FROM CHARGE_MASTER cm with (NOLOCK)
                                                      WHERE cm.BILLING_CODE = cac2.PROC_CODE
                                                      AND cm.SERVICE_AGREEMENT_ID = @ServiceAgreement) END 
                                              NOT IN (SELECT ap.CPT_CODE
                                                      FROM CCSTransactionSnapshot.dbo.ALL_PROCEDURES ap
                                                      WHERE ap.CHART_ID = z2.CHART_ID)))
    AND cac2.CPT_CODE NOT IN ('99281','99282','99283','99284','99285','99291','99292')
    AND convert(varchar,cac2.SERVICE_DATE, 110) BETWEEN @StartDate_Local AND @EndDate_Local)a
WHERE a.CHART_ID = CASE WHEN @ChartID_Local IS NOT NULL THEN @ChartID_Local
                   ELSE a.CHART_ID END
ORDER BY a.PHYSICIAN, a.FACILITY_CHART_ID, a.DOS
GO
EXEC sp_addextendedproperty N'MS_Description', N'Results for a specific chart ID', 'SCHEMA', N'dbo', 'PROCEDURE', N'MISMATCH_CHARGE_REPORT_OLD', 'PARAMETER', N'@ChartID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'String list of chart status to include in the search.', 'SCHEMA', N'dbo', 'PROCEDURE', N'MISMATCH_CHARGE_REPORT_OLD', 'PARAMETER', N'@ChartStatusList'
GO
EXEC sp_addextendedproperty N'MS_Description', N'To date of service', 'SCHEMA', N'dbo', 'PROCEDURE', N'MISMATCH_CHARGE_REPORT_OLD', 'PARAMETER', N'@EndDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Facility ID', 'SCHEMA', N'dbo', 'PROCEDURE', N'MISMATCH_CHARGE_REPORT_OLD', 'PARAMETER', N'@Facility'
GO
EXEC sp_addextendedproperty N'MS_Description', N'From date of service', 'SCHEMA', N'dbo', 'PROCEDURE', N'MISMATCH_CHARGE_REPORT_OLD', 'PARAMETER', N'@StartDate'
GO
