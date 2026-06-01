SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






-- =============================================
-- Author:		Laura Hotalling
-- Create date: 03/06/2013
-- Description:	Returns a list of eligible 
--				Client Companies a Reporting User 
--				has access to view.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListClientCompany] 
	-- Add the parameters for the stored procedure here
	@ReportUser		int, 
	@ReportDate		datetime = null,
	@OrganizationID	varchar(3000) = null,
	@AllowAll		bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT DISTINCT c.[COMPANY_ID]
				   ,c.[NAME] COMPANY_NAME
	FROM COMPANY c WITH (NOLOCK) join SERVICE_AGREEMENT sa WITH (NOLOCK)
		on sa.COMPANY_ID = c.COMPANY_ID 
	WHERE sa.FACILITY_ID in (SELECT FACILITY_ID 
							 FROM FACILITY_USER_AUTHORIZATION WITH (NOLOCK)
							 WHERE USER_PROFILE_ID = @ReportUser)
		and (@OrganizationID is null or sa.organization_id IN (SELECT Value FROM [dbo].[SplitMultivaluedString](@OrganizationID,',')))
		and sa.DEMO_TEST_SITE_IND <> 1
		and (@ReportDate is null or @ReportDate between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE)
	UNION
	SELECT -1 COMPANY_ID, '*All' COMPANY_NAME
	WHERE (@AllowAll <> 0) 
	ORDER BY COMPANY_NAME

	------ Add Report Date Filter
	--IF @ReportDate is not null
	--BEGIN
	--	SELECT @sql = @sql + 'and ''' + CONVERT(varchar(12), @ReportDate, 101) + ''' between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE '
	--	--' + CAST(@ReportDate AS DATETIME) + '
	--END

	---- Add "*All" option
	--IF @AllowAll <> 0
	--BEGIN
	--	SELECT @sql = @sql + 'union select -1 COMPANY_ID, ''*All'' COMPANY_NAME '
	--END

	--SELECT @sql = @sql + 'order by COMPANY_NAME'

	--EXECUTE(@sql);

END






GO
GRANT EXECUTE ON  [dbo].[rpt_ListClientCompany] TO [dbx_ExecuteReportProcs]
GO
