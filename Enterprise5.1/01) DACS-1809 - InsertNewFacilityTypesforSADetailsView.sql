----------------------------------------------------------------
-- DACS-1809 
-- Add values to Facility Type dropdown for SADetailsView.aspx
----------------------------------------------------------------


USE [RevCycleDB]
GO

	INSERT INTO [dbo].[FACILITY_TYPE]
	(
		[FACILITY_TYPE_CD],
		[DESCRIPTION]
	)
	VALUES
	( 3, 'Inpatient' ),
	( 4, 'Specialty Clinic' ),
	( 5, 'Primary Care' ),
	( 6, 'Anesthesia' ),
	( 7, 'Surgery' ),
	( 8, 'Observation Only' ),
	( 9, 'Lab' ),
	(10, 'Radiology')

GO

