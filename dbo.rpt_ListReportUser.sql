SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Laura Hotalling
-- Create date: 02/13/2013
-- Description:	Returns a list of Report Users.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListReportUser]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select ReportUser, User_Profile_ID  from
(
       SELECT ReportUser, User_Profile_ID 
  FROM (SELECT DISTINCT (up.LAST_NAME + ', ' + up.FIRST_NAME) ReportUser, up.USER_PROFILE_ID 
        FROM USER_PROFILE up, GROUP_RIGHTS gr
        WHERE 
              up.IS_ACTIVE = 'Y'
        AND gr.USER_GROUP_ID = up.USER_GROUP_ID
        AND (gr.DEFINED_RIGHT_ID = 34))x


  UNION

  SELECT ReportUser, User_Profile_ID 
  FROM (SELECT DISTINCT (up.LAST_NAME + ', ' + up.FIRST_NAME) ReportUser, up.USER_PROFILE_ID 
        FROM USER_PROFILE up, GROUP_RIGHTS gr
        WHERE 
              up.IS_ACTIVE = 'Y'
        AND gr.USER_GROUP_ID = up.USER_GROUP_ID
        AND (34 IN (SELECT gr2.DEFINED_RIGHT_ID
                       FROM USER_GROUP ug
                       INNER JOIN USER_GROUP_TO_USER_PROFILE ug2up 
                             ON ug.USER_GROUP_ID = ug2up.USER_GROUP_ID
                       INNER JOIN GROUP_RIGHTS gr2
                             ON gr2.USER_GROUP_ID = ug.USER_GROUP_ID
                       WHERE ug2up.USER_PROFILE_ID = up.USER_PROFILE_ID)))x
) as t
where user_profile_id in (select user_profile_id from FACILITY_USER_AUTHORIZATION)
  ORDER BY ReportUser, User_Profile_ID

END



GO
GRANT EXECUTE ON  [dbo].[rpt_ListReportUser] TO [dbx_ExecuteReportProcs]
GO
