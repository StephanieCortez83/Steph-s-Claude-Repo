SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Laura Hotalling
-- Create date: 03/07/2013
-- Description:	Returns a list of 
--				Service Location Companies.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListServiceLocationCompany] 
	-- Add the parameters for the stored procedure here
	@ReportUser		int,
	--@ReportDate		datetime = null,
	--@OrganizationID	varchar(3000) = null,
	@AllowAll		bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT DISTINCT c.[COMPANY_ID]
				   ,c.[NAME] COMPANY_NAME
	FROM COMPANY c join SERVICE_LOCATION sl 
		on sl.COMPANY_ID = c.COMPANY_ID 
	--WHERE sl.SERVICE_LOCATION_ID in (SELECT SERVICE_LOCATION_ID 
	--								 FROM SERVICE_LOCATION_USER
	--								 WHERE USER_PROFILE_ID = @ReportUser
	--									or (SELECT [USER_CLASS_CD] FROM USER_PROFILE WHERE USER_PROFILE_ID = @ReportUser) = 1)
		--and (@OrganizationID is null or sa.organization_id IN (SELECT Value FROM [dbo].[SplitMultivaluedString](@OrganizationID,',')))
		
	UNION
	SELECT 0 COMPANY_ID, '*None' COMPANY_NAME
	
	UNION
	SELECT -1 COMPANY_ID, '*All' COMPANY_NAME
	WHERE (@AllowAll <> 0) 
	ORDER BY COMPANY_NAME

END








GO
GRANT EXECUTE ON  [dbo].[rpt_ListServiceLocationCompany] TO [dbx_ExecuteReportProcs]
GO
