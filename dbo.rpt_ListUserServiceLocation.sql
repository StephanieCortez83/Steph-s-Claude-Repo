SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Laura Hotalling
-- Create date: 03/07/2013
-- Description:	Returns a list of User
--				Service Locations.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListUserServiceLocation] 
	-- Add the parameters for the stored procedure here
	--@ReportUser		int, 
	--@ReportDate		datetime = null,
	@CompanyID		varchar(3000) = null,
	@AllowAll		bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT DISTINCT sl.SERVICE_LOCATION_ID
				  , sl.NAME 'SERVICE_LOCATION_NAME'
	FROM     dbo.SERVICE_LOCATION sl INNER JOIN dbo.SERVICE_LOCATION_USER slu
		ON sl.SERVICE_LOCATION_ID = slu.SERVICE_LOCATION_ID
	WHERE sl.COMPANY_ID IN (SELECT Value FROM [dbo].[SplitMultivaluedString](@CompanyID,','))
	and sl.service_location_id not in ( 2,3,22) -- Added 08/15/2018 ACS-12485 DAH
	UNION
	SELECT 0 SERVICE_LOCATION_ID, '*None' SERVICE_LOCATION_NAME
	
	--TODO:
	--WHERE sa.FACILITY_ID in (SELECT FACILITY_ID 
	--						 FROM FACILITY_USER_AUTHORIZATION
	--						 WHERE USER_PROFILE_ID = @ReportUser)
	--	and (@OrganizationID is null or sa.organization_id IN (SELECT Value FROM [dbo].[SplitMultivaluedString](@OrganizationID,',')))
	
	UNION
	SELECT -1 SERVICE_LOCATION_ID, '*All' SERVICE_LOCATION_NAME
	WHERE (@AllowAll <> 0) 
	ORDER BY SERVICE_LOCATION_NAME

END










GO
GRANT EXECUTE ON  [dbo].[rpt_ListUserServiceLocation] TO [dbx_ExecuteReportProcs]
GO
