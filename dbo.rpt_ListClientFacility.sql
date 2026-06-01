SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Laura Hotalling
-- Create date: 03/06/2013
-- Description:	Returns a list of eligible 
--				Client Facilities a Reporting User
--				has access to view.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListClientFacility]  
	-- Add the parameters for the stored procedure here
	@ReportUser int, 
	@ReportDate datetime = null,
	@CompanyID	varchar(3000) = null,
	@AllowAll	bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT	f.FACILITY_ID
		   ,f.NAME as FACILITY_NAME
	FROM	FACILITY f WITH (NOLOCK), FACILITY_USER_AUTHORIZATION fua WITH (NOLOCK), SERVICE_AGREEMENT sa WITH (NOLOCK)
	WHERE	fua.FACILITY_ID = f.FACILITY_ID
		and sa.facility_id=f.facility_id 
		and fua.USER_PROFILE_ID = @ReportUser 
		and (@CompanyID is null or sa.company_id IN (SELECT Value FROM [dbo].[SplitMultivaluedString](@CompanyID,',')))
		and (@ReportDate is null or @ReportDate between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE)
		and sa.DEMO_TEST_SITE_IND <> 1
	UNION
	SELECT -1 FACILITY_ID, '*All' FACILITY_NAME 
	WHERE (@AllowAll <> 0) 
	ORDER BY FACILITY_NAME

END





GO
GRANT EXECUTE ON  [dbo].[rpt_ListClientFacility] TO [dbx_ExecuteReportProcs]
GO
