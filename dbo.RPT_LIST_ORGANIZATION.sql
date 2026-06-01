SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RPT_LIST_ORGANIZATION]
	@ReportUser int = 80
AS

--  Base script provided by SQL Team
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @StartDate date = DATEADD(day, -14, getdate());
declare @EndDate date  = getdate();

SELECT 
	DISTINCT 
	 c.[COMPANY_ID]
	,c.[NAME]
FROM 
	[dbo].[COMPANY] c WITH (NOLOCK)
	join [dbo].[SERVICE_AGREEMENT] sa WITH (NOLOCK) on sa.[COMPANY_ID] = c.[COMPANY_ID]
WHERE 
	sa.[FACILITY_ID] in (SELECT 
							[FACILITY_ID] 
                         FROM 
							[dbo].[FACILITY_USER_AUTHORIZATION] WITH (NOLOCK)
                         WHERE 
							getdate() between [EFFECTIVE_DATE] and [EXPIRATION_DATE]
							and [USER_PROFILE_ID]=@ReportUser)
	and sa.[DEMO_TEST_SITE_IND] = 0
	and ( @StartDate between sa.[EFFECTIVE_DATE] and sa.[EXPIRATION_DATE]
		or @EndDate between sa.[EFFECTIVE_DATE] and sa.[EXPIRATION_DATE] )

union select -1 [COMPANY_ID], '--Bypass Filter---' [NAME]

union select -2 [COMPANY_ID], '*Not Set' [NAME]

ORDER BY 
	[NAME]

GO
