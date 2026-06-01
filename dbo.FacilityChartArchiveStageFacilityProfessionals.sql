SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE    PROCEDURE [dbo].[FacilityChartArchiveStageFacilityProfessionals] (@UniqueID uniqueidentifier)
AS
	BEGIN
		SET NOCOUNT ON;

		INSERT	dbo.FacilityChartArchiveChartFacilityProfessionals (FACILITY_PROF_ID
																 , FACILITY_ID
																 , TITLE
																 , FIRST_NAME
																 , MIDDLE_NAME
																 , LAST_NAME
																 , NAME_SUFFIX)
				

		SELECT	FACILITY_PROF_ID
					  , fp.FACILITY_ID
					  , fp.TITLE
					  , fp.FIRST_NAME
					  , fp.MIDDLE_NAME
					  , fp.LAST_NAME
					  , fp.NAME_SUFFIX
				FROM	FACILITY_PROFESSIONAL fp WITH (NOLOCK)
				WHERE	exists (SELECT	1
										   FROM		dbo.FacilityChartArchiveStageCharts i
										   WHERE	i.FacilityId = fp.FACILITY_ID AND i.UniqueID=@UniqueID)
						AND NOT EXISTS (SELECT	1
										FROM	dbo.FacilityChartArchiveChartFacilityProfessionals x
										WHERE	x.FACILITY_PROF_ID = fp.FACILITY_PROF_ID);	--need the not exists as this row could already exist for another chart that has been staged but not yet archived
	

		
	
	END;
GO
