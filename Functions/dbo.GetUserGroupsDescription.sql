SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[GetUserGroupsDescription]
(	@user_profile_id int
)

RETURNS varchar(1000)
AS 

BEGIN
	declare @list varchar(1000)


    set @list = substring((SELECT ( ', ' + ug.name )           
	FROM User_Group ug, USER_GROUP_TO_USER_PROFILE u2g           
	WHERE ug.USER_GROUP_ID = u2g.USER_GROUP_ID           
	AND u2g.USER_PROFILE_ID = @user_profile_id           
	ORDER BY ug.name           
	FOR XML PATH( '' )          ), 3, 1000 )
		return @list
END
GO
