SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveStageDelete] (@ChartList		udt_int READONLY
															 , @DeleteAllStaged bit = 0)
AS
	BEGIN
		SET NOCOUNT ON;

		IF @DeleteAllStaged = 1
			BEGIN
				TRUNCATE TABLE dbo.FacilityChartArchiveChartFacilityLOS;

				TRUNCATE TABLE dbo.FacilityChartArchiveChartPhysicianLOS;

				TRUNCATE TABLE dbo.FacilityChartArchiveChargeMaster;

				TRUNCATE TABLE dbo.FacilityChartArchiveChartInfusionResults;

				TRUNCATE TABLE dbo.FacilityChartArchiveChartPhysicianProcedures;

				TRUNCATE TABLE dbo.FacilityChartArchiveChartAdditionalProcedures;

				TRUNCATE TABLE dbo.FacilityChartArchiveChartFacilityProcedures;

				TRUNCATE TABLE dbo.FacilityChartArchiveChartFacilityProfessionals;

				TRUNCATE TABLE dbo.FacilityChartArchiveChartAdjustments;

				TRUNCATE TABLE dbo.FacilityChartArchiveChartMetadata;

				TRUNCATE TABLE dbo.FacilityChartArchiveStageCharts;
			END;
		ELSE
			BEGIN
				--  delete Facility LOS
				DELETE	x
				FROM	dbo.FacilityChartArchiveChartFacilityLOS x
				WHERE	EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  x.CHART_ID);
				--  delete Physician LOS
				DELETE	x
				FROM	dbo.FacilityChartArchiveChartPhysicianLOS x
				WHERE	EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  x.CHART_ID);

				--  delete infusion results
				DELETE	x
				FROM	dbo.FacilityChartArchiveChartInfusionResults x
				WHERE	EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  x.CHART_ID);

				--  delete additional procedures
				DELETE	x
				FROM	dbo.FacilityChartArchiveChartAdditionalProcedures x
				WHERE	EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  x.CHART_ID);

				--  delete physician procedures
				DELETE	x
				FROM	dbo.FacilityChartArchiveChartPhysicianProcedures x
				WHERE	EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  x.CHART_ID);

				-- delete facility procedures
				DELETE	x
				FROM	dbo.FacilityChartArchiveChartFacilityProcedures x
				WHERE	EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  x.CHART_ID);

				--delete professionals
				DELETE	fp
				FROM	dbo.FacilityChartArchiveChartFacilityProfessionals fp
				WHERE	(EXISTS (SELECT 1
								 FROM	@ChartList								c
										INNER JOIN dbo.FacilityChartArchiveItem i
											ON c.x = i.FacilityChartArchiveFileId
								 WHERE	i.FacilityId = fp.FACILITY_ID)
						 AND NOT EXISTS (SELECT 1
										 FROM	dbo.FacilityChartArchiveItem i
										 WHERE	i.FacilityId = fp.FACILITY_ID
												AND NOT EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  i.ChartId))); --we need to make sure we are not deleting a FACILITY_PROF_ID that is used on another chart that has been staged but not yet archived

				-- delete adjustments
				DELETE	x
				FROM	dbo.FacilityChartArchiveChartAdjustments x
				WHERE	EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  x.CHART_ID);

				-- delete metadata
				DELETE	x
				FROM	dbo.FacilityChartArchiveChartMetadata x
				WHERE	EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  x.CHART_ID);

				-- delete staged charts
				DELETE	x
				FROM	dbo.FacilityChartArchiveStageCharts		x
						INNER JOIN dbo.FacilityChartArchiveItem i
							ON i.FacilityId = x.FacilityId
							   AND i.ChartDOS BETWEEN x.DateFrom AND x.DateThru
				WHERE	EXISTS (SELECT 1  FROM @ChartList  c WHERE c.x =  i.ChartId);
			END;
	END;
GO
