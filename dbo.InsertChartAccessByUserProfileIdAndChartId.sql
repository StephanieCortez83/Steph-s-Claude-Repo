SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartAccessByUserProfileIdAndChartId]
	 @ChartId INT	
    ,@UserProfileId INT	
AS
BEGIN
	INSERT INTO 
		CHART_ACCESS (
			 USER_PROFILE_ID
			,CHART_ID
			,ACCESS_DATE_TIME
		)
	VALUES( 
		 @UserProfileId
        ,@ChartId
        ,GETDATE()
	)
	
	SELECT SCOPE_IDENTITY();
	
/*
replaces the following inline SQL:
sql = "INSERT INTO CHART_ACCESS (USER_PROFILE_ID, CHART_ID, ACCESS_DATE_TIME)"
			+ " VALUES(" 
            +    userProfileID.ToString()
            + "," + chartID.ToString()
            + "," + quote + dt.ToShortDateString() + " " + dt.ToLongTimeString() + quote
			+ ")SELECT SCOPE_IDENTITY()";
*/	
END; -- end SPROC
GO
