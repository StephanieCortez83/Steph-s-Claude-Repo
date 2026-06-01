SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RPT_LIST_FACILITY]
	@ReportUser int = 80,
	@Organization varchar(200) = '-1'
AS

--  Base script provided by SQL Team
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @StartDate date = DATEADD(day, -14, getdate());
declare @EndDate date  = getdate();

SELECT      
	 f.[NAME] as Name
	,f.[facility_id] as Facility_ID
FROM         
	 [dbo].[facility] f WITH (NOLOCK)
	,[dbo].[facility_user_authorization] fua WITH (NOLOCK)
	,[dbo].[service_agreement] sa WITH (NOLOCK)
WHERE  
	fua.[FACILITY_ID] = f.[FACILITY_ID]
	AND sa.[facility_id]=f.[facility_id]
	AND fua.[USER_PROFILE_ID] = @ReportUser
	AND (-1 in (@Organization) OR sa.[company_id] in (@Organization) )
	AND sa.[DEMO_TEST_SITE_IND] = 0
	AND ( @StartDate between sa.[EFFECTIVE_DATE] AND sa.[EXPIRATION_DATE]
		OR @EndDate between sa.[EFFECTIVE_DATE] AND sa.[EXPIRATION_DATE] )
	AND getdate() between fua.[EFFECTIVE_DATE] AND fua.[EXPIRATION_DATE]

union -- AAR-1694 allow Tenet Practice Charts

SELECT      
	 f.[NAME] as Name
	,f.[facility_id] as Facility_ID
FROM         
	 [dbo].[facility] f WITH (NOLOCK)
	,[dbo].[facility_user_authorization] fua WITH (NOLOCK)
	,[dbo].[service_agreement] sa WITH (NOLOCK)
WHERE  
	fua.[FACILITY_ID] = f.[FACILITY_ID]
	AND sa.[facility_id]=f.[facility_id]
	AND fua.[USER_PROFILE_ID] = @ReportUser
	AND sa.[company_id] = 19
	AND ( -1 in (@Organization) OR sa.[company_id] in (@Organization) )
	AND ( @StartDate between sa.[EFFECTIVE_DATE] AND sa.[EXPIRATION_DATE]
		OR @EndDate between sa.[EFFECTIVE_DATE] AND sa.[EXPIRATION_DATE] )
	AND getdate() between fua.[EFFECTIVE_DATE] AND fua.[EXPIRATION_DATE]

union 

SELECT '---Bypass Filter---' as [Name], -1 as [Facility_ID]

union 

SELECT '*Not Set' as [Name], -2 as [Facility_ID] where (-2 in (@Organization)) 

ORDER BY  
	 f.[name]
	,f.[Facility_ID]

GO
