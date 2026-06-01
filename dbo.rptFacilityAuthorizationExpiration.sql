SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 5/10/2013
-- Description:	Facility Authorization Expiration Report
-- =============================================



CREATE PROCEDURE [dbo].[rptFacilityAuthorizationExpiration]
	-- Add the parameters for the stored procedure here
  @AccountManager int = -1,
  @Company VARCHAR(MAX),
  @From date = null,
  @Expires date = null,
  @ReportUser int
AS
BEGIN



	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
/*
-- Test Parameters ******************************
declare @AccountManager int = -1, -- -1 All
        @Company int = 19,        -- -1 All
		@From date = '01/01/2024',
		@Expires date = '01/15/2024',
		@ReportUser int = 80;
*/
  
  IF @From is null
    SET @From = getdate();

  IF @Expires is null
    SET @Expires = getdate()+7;

  declare @m_AccountManager int = @AccountManager;
  declare @m_Company VARCHAR(MAX) = @Company;
  declare @m_From date = @From;
  declare @m_Expires date = @Expires;
  declare @m_ReportUser int = @ReportUser;

  --Facility Authorization Expiration
  select case when up.USER_CLASS_CD=4 then 'Client' else 'Non-Client' end Class,
         up.SIGN_ON_ID UserID,
         up.LAST_NAME + ', ' + up.FIRST_NAME + ' ' + up.MIDDLE_NAME UserName,
         f.NAME FacilityName,		 
         fua.EFFECTIVE_DATE EffectiveDate,
         fua.EXPIRATION_DATE ExpirationDate
  from USER_PROFILE up with(nolock)
    join FACILITY_USER_AUTHORIZATION fua with (nolock) on fua.USER_PROFILE_ID=up.USER_PROFILE_ID
    join FACILITY f with (nolock) on f.FACILITY_ID=fua.FACILITY_ID
    join SERVICE_AGREEMENT sa with (nolock) on sa.FACILITY_ID=f.FACILITY_ID
  where getdate() between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
    and sa.DEMO_TEST_SITE_IND=0
    and @m_From between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
    and datediff(day, @m_From, fua.EXPIRATION_DATE) <= datediff(day, @m_From, @m_Expires)
    and f.FACILITY_ID in (select fua2.FACILITY_ID
                          from FACILITY_USER_AUTHORIZATION fua2 with (nolock)
                          where fua2.USER_PROFILE_ID=@m_ReportUser)
    and up.IS_ACTIVE = 'Y'
    AND (@m_AccountManager =-1 or sa.[SERVICE_AGREEMENT_ID] IN (SELECT [SERVICE_AGREEMENT_ID] 
															    FROM [dbo].[SERVICE_AGREEMENT_MANAGEMENT_TEAM] with(nolock)
															    WHERE [USER_PROFILE_ID] = @m_AccountManager))   

	AND  ( sa.company_id in (SELECT * FROM SPLITSTRING(@m_Company, ','))
            OR	'-1' in (SELECT * FROM SPLITSTRING(@m_Company, ',')) )

  order by case when up.USER_CLASS_CD=4 then 'Client' else 'Non-Client' end, 
  up.LAST_NAME, up.FIRST_NAME, up.MIDDLE_NAME, f.NAME


 END

GO
GRANT EXECUTE ON  [dbo].[rptFacilityAuthorizationExpiration] TO [dbx_ExecuteReportProcs]
GO
