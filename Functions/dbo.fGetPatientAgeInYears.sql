SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   FUNCTION [dbo].[fGetPatientAgeInYears] (
	 @patientAge INT
	,@chartDos DATETIME
	,@patienDOB DATETIME
)
RETURNS INT
AS
BEGIN
	IF @chartDos IS NULL OR @chartDos <= Convert(datetime, '1900-01-01' )
		RETURN -1;
	
	IF @patientAge IS NULL
	BEGIN
		IF @patienDOB IS NULL
			RETURN -2;
			
		SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
	END;
		
	IF @patientAge < 0 OR @patientAge > 999 OR @patientAge IS NULL
		RETURN -3;

	RETURN @patientAge
END;

/*
-- testing:
SELECT dbo.fGetPatientAgeInYears(NULL,'01-12-2024','12-2-1971') AS SumResult; -- returns 54
SELECT dbo.fGetPatientAgeInYears(21,'01-12-2024','12-2-1971') AS SumResult; -- returns 21

*/
-- End of 07) DACS-3535 - CREATE or Alter FUNCTION - [dbo].[fGetPatientAgeInYears].SQL

GO
