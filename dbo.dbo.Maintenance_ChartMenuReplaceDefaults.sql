SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[dbo.Maintenance_ChartMenuReplaceDefaults]
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @countDefaultEntries INT = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = -1);
	
	IF @countDefaultEntries > 0
	BEGIN
		PRINT('Default Chart Menu items already present: ' + CAST(@countDefaultEntries AS VARCHAR(20)));
		RETURN;
	END;
		
	DECLARE @insertDate DATE = GETDATE();

	INSERT INTO CHART_MENU
		(SERVICE_AGREEMENT_ID, MENU_ID, DISPLAY_SEQ, CREATION_DATE_TIME, CREATING_USER_PROFILE_ID, CHANGED_DATE_TIME, CHANGING_USER_PROFILE_ID)
	VALUES
		(-1, 0	 ,1	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 1	 ,2	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 13	 ,3	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 2	 ,4	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 18	 ,5	 ,@insertDate, 1	,@insertDate, 1),
		(-1, 3	 ,6	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 12	 ,7	 ,@insertDate, 1	,@insertDate, 1),
		(-1, 4	 ,8	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 5	 ,9	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 6	 ,10 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 7	 ,11 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 14	 ,12 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 17	 ,13 ,@insertDate, 1	,@insertDate, 1),
		(-1, 8	 ,14 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 9	 ,15 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 10	 ,16 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 11	 ,17 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 15	 ,18 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 16	 ,19 ,@insertDate, 1	,@insertDate, 1);

	SET @countDefaultEntries = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = -1);
	
	IF @countDefaultEntries > 0
	BEGIN
		PRINT('Default Chart Menu items now present: ' + CAST(@countDefaultEntries AS VARCHAR(20)));
		RETURN;
	END;
GO
