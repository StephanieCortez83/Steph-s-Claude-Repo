SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 11/20/2015
-- Description:	SQL for the CDI Detail Report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_CDIDetailReport]
    -- Add the parameters for the stored procedure here
    @ReportUser INT
    ,@Organization INT
    ,@Facility VARCHAR(MAX)
    ,@DateType INT
    ,@StartDate DATETIME
    ,@EndDate DATETIME
    ,@Provider VARCHAR(MAX)
    ,@Chapter VARCHAR(MAX)
    ,@ICD10From VARCHAR(10) = NULL
    ,@ICD10To VARCHAR(10) = NULL
    ,@ShowPassInDetail BIT = 0
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @m_ReportUser INT = @ReportUser
        ,@m_Organization INT = @Organization
        ,@m_Facility VARCHAR(MAX) = @Facility
        ,@m_DateType INT = @DateType
        ,@m_StartDate DATETIME = @StartDate
        ,@m_EndDate DATETIME = @EndDate
        ,@m_Provider VARCHAR(MAX) = @Provider
        ,@m_Chapter VARCHAR(MAX) = @Chapter
        ,@m_ICD10From VARCHAR(10) = @ICD10From
        ,@m_ICD10To VARCHAR(10) = @ICD10To
        ,@m_ShowPassInDetail BIT = @ShowPassInDetail;

    -- Remove "." from ICD-10 from and to parameters
    IF (@m_ICD10From IS NOT NULL)
    BEGIN
      SET @m_ICD10From = REPLACE(@m_ICD10From, '.', '')
    END

    IF (@m_ICD10To IS NOT NULL)
    BEGIN
      SET @m_ICD10To = REPLACE(@m_ICD10To, '.', '')
    END

    IF OBJECT_ID('TempDB..#CDIChart', 'U') IS NOT NULL
    BEGIN
        DROP TABLE #CDIChart
    END;

    IF OBJECT_ID('TempDB..#CDIResults', 'U') IS NOT NULL
    BEGIN
        DROP TABLE #CDIResults
    END;

    SELECT *
    INTO #CDIChart
    FROM (
        SELECT DISTINCT c.CHART_ID
            ,c.FACILITY_ID
            ,c.FACILITY_CHART_ID [Account]
            ,c.TIME_OF_SERVICE
            ,UPPER(fp.LAST_NAME + ', ' + FP.FIRST_NAME) [Physician]
            ,cdi.ICD10_CODE [ICD-10]
            ,cdi.COMMENT [Comment]
            ,fp.FACILITY_PROF_ID
            ,[CHART_CDI_RESULT_ID]
            ,s.REPORTING_DESCRIPTION [Score]
            ,s.CDI_SCORE_ID
        FROM [dbo].[CHART_CDI_RESULT] cdi WITH (NOLOCK)
        INNER JOIN [dbo].[CDI_SCORE] s WITH (NOLOCK) ON s.CDI_SCORE_ID = cdi.SCORE_ID
        INNER JOIN [dbo].[CHART] c WITH (NOLOCK) ON c.CHART_ID = cdi.CHART_ID
        INNER JOIN [dbo].[SERVICE_AGREEMENT] sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
        INNER JOIN [dbo].[FACILITY_PROFESSIONAL] fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = CASE 
                WHEN c.NURSE_PRACTITIONER_ID > 0
                    AND COALESCE(c.PROVIDER_EVAL_PERFORMED_BY_IND, 1) = 1
                    THEN c.NURSE_PRACTITIONER_ID
                ELSE c.PHYSICIAN_ID
                END
        WHERE sa.COMPANY_ID = @m_Organization
            AND sa.FACILITY_ID IN (
                SELECT *
                FROM [dbo].[SplitString](@m_Facility, ',')
                )
            AND c.CHART_STATUS_ID = 5
            AND DATEADD(DAY, DATEDIFF(DAY, 0, CASE @m_DateType
                        WHEN 0
                            THEN c.TIME_OF_SERVICE
                        ELSE c.SENT_DATE
                        END), 0) BETWEEN @m_StartDate AND @m_EndDate
            AND fp.FACILITY_PROF_ID IN (
                SELECT *
                FROM [dbo].[SplitString](@m_Provider, ',')
                )
        ) AS c

    SELECT *
    INTO #CDIResults
    FROM (
        SELECT DISTINCT cdi.FACILITY_ID
            ,cdi.CHART_ID
            ,cdi.[Account]
            ,cdi.[Physician]
            ,cdi.[ICD-10]
            ,cm.SHORT_DESCRIPTION [CodeDescriptor]
            ,[Score]
            ,(
                SELECT STUFF((
                            SELECT ';' + fr.DESCRIPTION
                            FROM [dbo].[CHART_CDI_RESULT_FAILURE_REASON] cfr WITH (NOLOCK)
                            INNER JOIN [dbo].[CDI_FAILURE_REASON] fr WITH (NOLOCK) ON fr.[CDI_FAILURE_REASON_ID] = cfr.[CDI_FAILURE_REASON_ID]
                            WHERE cfr.[CHART_CDI_RESULT_ID] = cdi.[CHART_CDI_RESULT_ID]
                            ORDER BY DESCRIPTION
                            FOR XML PATH('')
                            ), 1, 1, '')
                ) [Reason]
            ,cdi.COMMENT [Comment]
            ,CASE cdi.CDI_SCORE_ID
                WHEN 0
                    THEN 'Unspecified'
                ELSE 'Specified'
                END [Unspecified]
            ,chap.CHAPTER_NUM [ChapterNumber]
            ,chap.SHORT_DESCRIPTION [ChapterDescription]
            ,cdi.FACILITY_PROF_ID
        FROM #CDIChart cdi
        LEFT JOIN [dbo].[ICD_10_CM] cm WITH (NOLOCK) ON cm.ICD_10_CODE = REPLACE(cdi.[ICD-10], '.', '')
            AND DATEADD(DAY, DATEDIFF(DAY, 0, cdi.TIME_OF_SERVICE), 0) BETWEEN cm.EFFECTIVE_DATE AND cm.EXPIRATION_DATE
        LEFT JOIN [dbo].[ICD_10_CHAPTER] chap WITH (NOLOCK) ON cm.ICD_10_CODE BETWEEN chap.FIRST_CODE AND chap.LAST_CODE + '.9'
        WHERE chap.CHAPTER_NUM IN (
                SELECT *
                FROM [dbo].[SplitString](@m_Chapter, ',')
                )
            AND CASE
                WHEN @m_ICD10From IS NOT NULL
                  AND @m_ICD10To IS NULL
                  AND cm.ICD_10_CODE = @m_ICD10From
                    then 1
                WHEN @m_ICD10From IS NULL
                    THEN 1
                WHEN cm.ICD_10_CODE BETWEEN (@m_ICD10From) AND (@m_ICD10To)
                    THEN 1
                END = 1
        ) AS t

    SELECT [Account]
        ,[Physician]
        ,[ICD-10]
        ,[CodeDescriptor]
        ,[Score]
        ,[Reason]
        ,[Comment]
        ,[Unspecified]
        ,[ChapterNumber]
        ,[ChapterDescription]
        ,(
            SELECT SUM(TOTAL)
            FROM (
                SELECT COUNT(*) TOTAL
                FROM #CDIResults
                WHERE [ICD-10] = cdi.[ICD-10]
                    AND FACILITY_PROF_ID = cdi.FACILITY_PROF_ID
                    AND @m_ShowPassInDetail = 0
                    AND [Unspecified] = 'Unspecified'
                
                UNION
                
                SELECT COUNT(*) TOTAL
                FROM #CDIResults
                WHERE [ICD-10] = cdi.[ICD-10]
                    AND FACILITY_PROF_ID = cdi.FACILITY_PROF_ID
                    AND @m_ShowPassInDetail = 1
                ) x
            ) COUNT_ICD10_PHYSICIAN
        ,(
            SELECT SUM(TOTAL)
            FROM (
                SELECT COUNT(*) TOTAL
                FROM #CDIResults
                WHERE [ICD-10] = cdi.[ICD-10]
                    AND @m_ShowPassInDetail = 0
                    AND [Unspecified] = 'Unspecified'
                
                UNION
                
                SELECT COUNT(*) TOTAL
                FROM #CDIResults
                WHERE [ICD-10] = cdi.[ICD-10]
                    AND @m_ShowPassInDetail = 1
                ) y
            ) COUNT_ICD10
        ,(
            SELECT TOP 1 CPT_CODE
            FROM [dbo].SENT_PROCEDURE WITH (NOLOCK)
            WHERE CHART_ID = cdi.CHART_ID
                AND CLASS = 'FL'
            ) FL
        ,(
            SELECT STUFF((
                        SELECT ',' + CPT_CODE
                        FROM [dbo].SENT_PROCEDURE WITH (NOLOCK)
                        WHERE CHART_ID = cdi.CHART_ID
                            AND CLASS = 'FP'
                        ORDER BY CPT_CODE
                        FOR XML PATH('')
                        ), 1, 1, '')
            ) FP
        ,(
            SELECT TOP 1 CPT_CODE
            FROM [dbo].SENT_PROCEDURE WITH (NOLOCK)
            WHERE CHART_ID = cdi.CHART_ID
                AND CLASS = 'PL'
            ) PL
        ,(
            SELECT STUFF((
                        SELECT ',' + CPT_CODE
                        FROM [dbo].SENT_PROCEDURE WITH (NOLOCK)
                        WHERE CHART_ID = cdi.CHART_ID
                            AND CLASS = 'PP'
                        ORDER BY CPT_CODE
                        FOR XML PATH('')
                        ), 1, 1, '')
            ) PP
        ,cdi.FACILITY_PROF_ID
    FROM #CDIResults cdi
    WHERE EXISTS (
            SELECT *
            FROM FACILITY_USER_AUTHORIZATION WITH (NOLOCK)
            WHERE FACILITY_ID = cdi.FACILITY_ID
                AND USER_PROFILE_ID = @m_ReportUser
            )
    ORDER BY Account
        ,[ICD-10]
END

GO
GRANT EXECUTE ON  [dbo].[rpt_CDIDetailReport] TO [dbx_ExecuteReportProcs]
GO
