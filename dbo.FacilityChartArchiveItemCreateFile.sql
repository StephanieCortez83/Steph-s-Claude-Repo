SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveItemCreateFile] (@FacilityChartArchiveId	 int
															   , @CreatedByUserProfileId	 int
															   , @LastUpdatedByUserProfileId int
															   , @ArchivedToPath			 varchar(500)
															   , @FileDateOfService			 date
															   , @ChartList					 udt_int READONLY)
AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @FacilityChartArchiveFileId int
		BEGIN TRY
			BEGIN TRAN;


			--create the file
			INSERT	dbo.FacilityChartArchiveFile (FacilityChartArchiveId
												, CreatedByUserProfileId
												, LastUpdatedByUserProfileId
												, ArchivedToPath
												, FileDateOfService
												, IsDestroyed)
			VALUES (@FacilityChartArchiveId, @CreatedByUserProfileId, @LastUpdatedByUserProfileId, @ArchivedToPath, @FileDateOfService, 0);
			SET @FacilityChartArchiveFileId=@@identity

			--add the charts to th*e file
			UPDATE	i
			SET		i.FacilityChartArchiveFileId = @FacilityChartArchiveFileId
			FROM	dbo.FacilityChartArchiveItem i
			WHERE	EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  i.ChartId);

			--update the facility last archive date
			UPDATE	dbo.FacilityChartArchive
			SET		DateTimeLastUpdated = SYSDATETIME()
				  , LastUpdatedByUserProfileId = @LastUpdatedByUserProfileId
				  , LastDOSProcessed = @FileDateOfService
			WHERE	FacilityChartArchiveId = @FacilityChartArchiveId;

			COMMIT TRAN;
		END TRY
		BEGIN CATCH
			DECLARE @err varchar(MAX) = ERROR_MESSAGE();

			RAISERROR(@err, 16, 1);

			IF @@trancount <> 1 ROLLBACK;

			RETURN;
		END CATCH;

	SELECT @FacilityChartArchiveFileId;
	END;
GO
