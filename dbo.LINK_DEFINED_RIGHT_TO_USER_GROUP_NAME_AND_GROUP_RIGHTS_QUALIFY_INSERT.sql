SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LINK_DEFINED_RIGHT_TO_USER_GROUP_NAME_AND_GROUP_RIGHTS_QUALIFY_INSERT]
	 @DEFINED_RIGHT_ID int
	,@USER_GROUP_NAME varchar(35)
	,@CREATING_USER_ID int = 10149 -- 12072 -- William Pippin, 10149 -- Marcus Ferrell
	,@USER_GROUP_ID int OUTPUT
	,@GROUP_RIGHTS_ID int OUTPUT
AS

IF @DEFINED_RIGHT_ID <= 0
	BEGIN
		PRINT('@DEFINED_RIGHT_ID is invalid.  No operation performed.')
		RETURN
	END;

-- Process USER_GROUP table insert
DECLARE @FOUND_USER_GROUP_ID int;

SELECT @FOUND_USER_GROUP_ID = [USER_GROUP_ID]
	FROM
		[dbo].[USER_GROUP] with (NOLOCK)
	WHERE
		(RTRIM([NAME]) = RTRIM(@USER_GROUP_NAME));

if @FOUND_USER_GROUP_ID IS NULL
	BEGIN

		INSERT INTO [RevCycleDB].[dbo].[USER_GROUP]
		  (
			 [NAME]
			,[CREATION_DATE_TIME]
			,[CREATING_USER_PROFILE_ID]
			,[CHANGED_DATE_TIME]
			,[CHANGING_USER_PROFILE_ID]
			,[USER_ADMIN_CAN_ASSIGN]
			,[FORCE_CHART_SORT_BY_DOS]
			,[CHART_WORK_QUEUE_ID]
			,[INCLUDE_IN_CHARTS_COMPLETED_BY_USER_GROUP_DROPDOWN]
			,[IS_MFA_ENABLED]
		  )
		VALUES
		  (
			 @USER_GROUP_NAME      	--name
			,GETDATE()				--creation date time
			,@CREATING_USER_ID		--creating user profile id		
			,GETDATE()				--changed date time
			,@CREATING_USER_ID		--changing user profile id
			,1						--user admin can assign
			,0						--force chart sort by dos
			,-1						--chart work queue id
			,0						--include in charts completed by user group dropdown
			,0						--is mfa enabled		
		  );

		SET @USER_GROUP_ID = @@IDENTITY;
	END
ELSE
	BEGIN
		PRINT('@FOUND_USER_GROUP_ID already exists for @USER_GROUP_NAME = `' + @USER_GROUP_NAME + '`');
		SET @USER_GROUP_ID = @FOUND_USER_GROUP_ID
	END;

PRINT('@USER_GROUP_ID = ' + CAST(@USER_GROUP_ID AS VARCHAR(32)));

-- Process GROUP_RIGHTS table insert
DECLARE @FOUND_GROUP_RIGHT_ID int;

SELECT @FOUND_GROUP_RIGHT_ID = [GROUP_RIGHT_ID]
	FROM
		[dbo].[GROUP_RIGHTS] with (NOLOCK)
	WHERE
		([USER_GROUP_ID] = @USER_GROUP_ID) AND ([DEFINED_RIGHT_ID] = @DEFINED_RIGHT_ID);

if @FOUND_GROUP_RIGHT_ID IS NULL
	BEGIN

		INSERT INTO [RevCycleDB].[dbo].[GROUP_RIGHTS]
		  (
			 [DEFINED_RIGHT_ID]
			,[USER_GROUP_ID]
			,[CREATION_DATE_TIME]
			,[CREATING_USER_PROFILE_ID]
			,[CHANGED_DATE_TIME]
			,[CHANGING_USER_PROFILE_ID]
		  )
		VALUES
		  (
			 @DEFINED_RIGHT_ID		--defined right id
			,@USER_GROUP_ID			--user group id
			,GETDATE()				--creation date time	
			,@CREATING_USER_ID		--creating user profile id
			,GETDATE()				--changed date time
			,@CREATING_USER_ID		--changing user profile id
		  );

		SET @GROUP_RIGHTS_ID = @@IDENTITY;
	END
ELSE
	BEGIN
		PRINT('@FOUND_GROUP_RIGHT_ID already exists for (@USER_GROUP_ID,@DEFINED_RIGHT_ID) :: (' + CAST(@USER_GROUP_ID AS VARCHAR(32)) + ',' + CAST(@DEFINED_RIGHT_ID AS VARCHAR(32)) + ')');
		SET @GROUP_RIGHTS_ID = @FOUND_GROUP_RIGHT_ID
	END;

PRINT('@GROUP_RIGHT_ID = ' + CAST(@GROUP_RIGHTS_ID AS VARCHAR(32)));

GO
