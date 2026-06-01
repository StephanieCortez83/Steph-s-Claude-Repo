SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 8/6/2015
-- Description:	SQL for the Pushed Charts by Auditor and Vendor report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_PushedChartsByAuditorAndVendor]
	-- Add the parameters for the stored procedure here
	@StartDate DATETIME, 
	@EndDate DATETIME,
  @Vendor VARCHAR(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
DECLARE @m_StartDate DATETIME = @StartDate
    ,@m_EndDate DATETIME = @EndDate
    ,@m_Vendor VARCHAR(256) = @Vendor;

SELECT ApprovedBy
    ,Vendor
    ,SUM(ChartsPushed) ChartsPushed
FROM (
    SELECT CASE 
            WHEN coder.USER_GROUP_ID IN (
                    125
                    ,130
                    ,136
                    )
                THEN 'Omega'
            WHEN coder.USER_GROUP_ID IN (
                    164
                    ,165
                    ,166
                    )
                THEN 'Access'
            WHEN coder.USER_GROUP_ID IN (
                    129
                    ,133
                    ,137
                    )
                THEN 'e4e'
            WHEN coder.USER_GROUP_ID IN (
                    161
                    ,162
                    ,163
                    )
                THEN 'AGS'
            WHEN coder.USER_CLASS_CD = 1
                THEN 'Employee'
            ELSE 'Contractor'
            END Vendor
        ,UPPER(auditor.[LAST_NAME] + ', ' + auditor.[FIRST_NAME]) ApprovedBy
        ,COUNT(*) ChartsPushed
    FROM [dbo].[CHART] c WITH (NOLOCK)
    INNER JOIN [dbo].[SERVICE_AGREEMENT] sa WITH (NOLOCK) ON c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
    INNER JOIN [dbo].[USER_PROFILE] coder WITH (NOLOCK) ON coder.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
    INNER JOIN [dbo].[USER_PROFILE] auditor WITH (NOLOCK) ON auditor.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
    WHERE ISNULL(sa.DEMO_TEST_SITE_IND, 0) = 0
        AND sa.SERVICE_MODEL_CD = 'SVC'
        AND DATEADD(DAY, DATEDIFF(DAY, 0, c.APPROVED_DATE), 0) BETWEEN @m_StartDate AND @m_EndDate
        AND c.APPROVAL_REASON_CODE = 1
        AND CHART_STATUS_ID IN (
            4
            ,5
            )
    GROUP BY c.APPROVED_BY_USER_PROFILE_ID
        ,auditor.[LAST_NAME] + ', ' + auditor.[FIRST_NAME]
        ,auditor.USER_GROUP_ID
        ,auditor.USER_CLASS_CD
        ,coder.USER_GROUP_ID
        ,coder.USER_CLASS_CD
    ) x
WHERE EXISTS (
        SELECT *
        FROM [dbo].SplitString(@m_Vendor, ',')
        WHERE ITEMS = Vendor
        )
GROUP BY Vendor
    ,ApprovedBy
ORDER BY ApprovedBy
    ,Vendor
END
GO
