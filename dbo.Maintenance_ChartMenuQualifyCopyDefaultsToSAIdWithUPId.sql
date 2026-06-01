SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[Maintenance_ChartMenuQualifyCopyDefaultsToSAIdWithUPId]
	 @SAId INT
	,@UPId INT
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'Result' = 'Error: SA Id is invalid.';
		RETURN;
	END;

	IF @UPId IS NULL OR @UPId <= 0
	BEGIN
		SELECT 'Result' = 'Error: UP Id is invalid.';
		RETURN;
	END;

	DECLARE @countDefaultEntries INT = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = -1);
	DECLARE @countTargetEntries INT = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = @SAId);
	
	IF @countDefaultEntries <= 0
	BEGIN
		PRINT('Default Chart Menu items not present.  attempting to correct... ');
		EXEC [dbo].[dbo.Maintenance_ChartMenuReplaceDefaults];
		SET @countDefaultEntries  = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = -1);
		
		IF @countDefaultEntries <= 0
		BEGIN
			SELECT 'Result' = 'Error: Failed to correct missing default Chart Menu items.';
			RETURN;
		END;
	END;
		
	IF @countTargetEntries > 0
	BEGIN
		SELECT 'Result' = 'SUCCESS: Chart Menu items already present for SA Id: ' + CAST(@SAId AS VARCHAR(20)) + ' = ' + CAST(@countTargetEntries AS VARCHAR(20));
		RETURN;
	END;

	DECLARE @insertDate DATE = GETDATE();
	
	IF OBJECT_ID('tempdb..#TempRows') IS NOT NULL
	BEGIN
		DROP TABLE #TempRows
	END;
	
	-- Fill temp table with our data
	SELECT TOP (30)
		  [SERVICE_AGREEMENT_ID]
		 ,[MENU_ID]
		 ,[DISPLAY_SEQ]
		 ,[CREATION_DATE_TIME]
		 ,[CREATING_USER_PROFILE_ID]
		 ,[CHANGED_DATE_TIME]
		 ,[CHANGING_USER_PROFILE_ID]
	INTO #TempRows
	FROM
		(	
			SELECT 
				 @SAId AS [SERVICE_AGREEMENT_ID]
				,[MENU_ID]
				,[DISPLAY_SEQ]
				,@insertDate AS [CREATION_DATE_TIME]
				,@UPId AS [CREATING_USER_PROFILE_ID]
				,@insertDate AS [CHANGED_DATE_TIME]
				,@UPId AS [CHANGING_USER_PROFILE_ID]
			FROM
				[CHART_MENU] src WITH (NOLOCK)
			WHERE 
				[SERVICE_AGREEMENT_ID] = -1
		) AS sourceList

	DECLARE @countTempEntries INT = (SELECT count(*) FROM #TempRows);
	print('temp table count Org: ' + CAST(@countTempEntries AS VARCHAR(20)));
	
	IF @countTempEntries <> @countDefaultEntries
	BEGIN
		SELECT 'Result' = 'Error: Chart Menu Default count does not match Temporary count : ' + CAST(@countDefaultEntries AS VARCHAR(20)) + ' :: ' + CAST(@countTempEntries AS VARCHAR(20));
		RETURN;
	END;


	INSERT INTO CHART_MENU
		(SERVICE_AGREEMENT_ID, MENU_ID, DISPLAY_SEQ, CREATION_DATE_TIME, CREATING_USER_PROFILE_ID, CHANGED_DATE_TIME, CHANGING_USER_PROFILE_ID)
	SELECT
			 #TempRows.[SERVICE_AGREEMENT_ID]
			,#TempRows.[MENU_ID]
			,#TempRows.[DISPLAY_SEQ]
			,#TempRows.[CREATION_DATE_TIME]
			,#TempRows.[CREATING_USER_PROFILE_ID]
			,#TempRows.[CHANGED_DATE_TIME]
			,#TempRows.[CHANGING_USER_PROFILE_ID]
		FROM #TempRows;	
	

	SET @countTargetEntries = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = @SAId);
	
	IF @countTargetEntries <> @countTempEntries
		SELECT 'Result' = 'Error: Chart Menu count does not match Temporary count : ' + CAST(@countTargetEntries AS VARCHAR(20)) + ' :: ' + CAST(@countTempEntries AS VARCHAR(20));
	ELSE
		SELECT 'Result' = 'SUCCESS: Chart Menu for SA Id : ' + CAST(@SAId AS VARCHAR(20)) + ' = ' + CAST(@countTargetEntries AS VARCHAR(20));

GO
