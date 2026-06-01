SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[GetICD10CodeDescription]
(	@ICD10Code varchar(10)
)

RETURNS varchar(100)
AS 

BEGIN
	declare @diagnosisCodeDesc varchar(100)


SELECT @diagnosisCodeDesc = 
(SELECT top 1 cm.SHORT_DESCRIPTION from ICD10_CM cm where cm.ICD10_CM = REPLACE(@ICD10Code,'.',''))
	
RETURN @diagnosisCodeDesc
END
GO
