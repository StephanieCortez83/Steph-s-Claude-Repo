-----------------------------------------------------
-- 01) DACS-2807 - Create OR Alter Procedure - [dbo].[SelectDefinedRightsByUserGroupId].sql
-----------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[SelectDefinedRightsByUserGroupId]
	@UserGroupId INT
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @UserGroupId < 0
	BEGIN
		print('Invalid User Group Id');
		RETURN;
	END;

	SELECT 
		DR.DEFINED_RIGHT_ID
		, DR.NAME
		, GR.GROUP_RIGHT_ID
		, DR.IS_ADMIN
    FROM 
		DEFINED_RIGHT DR 
		LEFT OUTER JOIN GROUP_RIGHTS GR ON DR.DEFINED_RIGHT_ID = GR.DEFINED_RIGHT_ID
        AND (GR.USER_GROUP_ID = @UserGroupId OR USER_GROUP_ID IS NULL)

GO

/*
begin tran;
exec [dbo].[SelectDefinedRightsByUserGroupId] @UserGroupId= 12;
*/