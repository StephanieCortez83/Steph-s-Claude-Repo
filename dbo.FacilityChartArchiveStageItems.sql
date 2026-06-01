SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveStageItems] (@UniqueID uniqueidentifier)
AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @ChartList udt_int;

		INSERT	@ChartList (x)
				SELECT	ChartId
				FROM	dbo.FacilityChartArchiveItem i
				WHERE	EXISTS (SELECT	1
								FROM	dbo.FacilityChartArchiveStageCharts s
								WHERE	s.UniqueID = @UniqueID
										AND i.FacilityId = s.FacilityId
										AND i.ChartDOS BETWEEN s.DateFrom AND s.DateThru);

		-- chart data
		EXECUTE dbo.FacilityChartArchiveStageChartMetadata @UniqueID = @UniqueID;

		-- adjustments
		EXEC dbo.FacilityChartArchiveStageAdjustments @UniqueID = @UniqueID;

		-- professionals
		EXEC dbo.FacilityChartArchiveStageFacilityProfessionals @UniqueID = @UniqueID;

		--facility procedures
		EXEC dbo.FacilityChartArchiveStageFacilityProcedures @UniqueID = @UniqueID;

		-- additonal procedures
		EXEC dbo.FacilityChartArchiveStageAdditionalProcedures @ChartList = @ChartList;

		-- physician procedures
		EXEC dbo.FacilityChartArchiveStagePhysicianProcedures @ChartList = @ChartList;

		-- infusion results
		EXEC dbo.FacilityChartArchiveStageInfusionResults @UniqueID = @UniqueID;

		-- charge master
		EXEC dbo.FacilityChartArchiveStageChargeMaster;

		-- Facility LOS
		EXEC dbo.FacilityChartArchiveStageFacilityLOS @UniqueID = @UniqueID;

		-- Physician LOS
		EXEC dbo.FacilityChartArchiveStagePhysicianLOS @UniqueID = @UniqueID;

	END;
GO
