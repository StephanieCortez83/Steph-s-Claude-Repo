SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-3283 SPROC variant within FacilityLevelDAO.cs'))
	INSERT INTO 
		[TYPE_CODE]
		(
			[NAME]
		   ,[KEY]
		   ,[VALUE]
		   ,[DISPLAY_NAME]
		   ,[SHORT_NAME]
		   ,[DESCRIPTION]
		)
		VALUES
		(
			'ApplicationFeatureTypeCode'                                      		--NAME
		   ,'CAB_3283'                                                    			--KEY
		   ,20                                                                		--VALUE
		   ,'CAB_3283'                                                    			--DISPLAY_NAME
		   ,'CAB_3283'                                                        		--SHORT_NAME
		   ,'Enable/Disables DACS-3283 SPROC variant within FacilityLevelDAO.cs' 	--DESCRIPTION
		)
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 20)
	INSERT INTO 
		[dbo].[ApplicationFeature]
		(
			 [DateTimeCreated]
			,[CreatedByUserProfileId]
			,[DateTimeLastUpdated]
			,[LastUpdatedByUserProfileId]
			,[ApplicationFeatureDomainObjectTypeCode]
			,[DomainObjectId]
			,[ApplicationFeatureTypeCode]
		)
	VALUES
		(
			 @dtCreated
			,@Uid
			,@dtCreated
			,@Uid
			,5
			,2147483647															--ALL
			,20
		)
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFacilityLevelByFacilityLevelId]
	 @FacilityLevelId INT
	,@ColumnName SYSNAME
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

	DECLARE @SQL NVARCHAR(MAX);

    -- Build dynamic SQL
    SET @SQL = N'SELECT CAST(' + QUOTENAME(@ColumnName) + N' AS VARCHAR(256)) ' + @ColumnName + ' FROM [FACILITY_LEVEL] WHERE [FACILITY_LEVEL_ID] = ' + CAST(@FacilityLevelId AS NVARCHAR(256));

	PRINT(N'@SQL = ' + @SQL)

    -- Execute safely
    EXEC sp_executesql @SQL;

/*
replaces:
file: "\CCSBusinessObjects\DAO\Facility\FacilityLevelDAO.cs"
procedure: "public string GetValueByID(int facilityLevelID, string dbColumnName)"

sql = "SELECT " + dbColumnName
	+ " FROM FACILITY_LEVEL WITH (NOLOCK) "
	+ " WHERE FACILITY_LEVEL_ID = " + facilityLevelID;
*/
END
GO
