SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[GetDiagnosisTypeDescription]
(	@diagnosisTypeID int, @isPrimary bit
)

RETURNS varchar(100)
AS 

BEGIN
	declare @diagnosisTypeDesc varchar(100)


SELECT @diagnosisTypeDesc = 
   CASE 
   WHEN @diagnosisTypeID = 1 and @isPrimary = 1 THEN 'Chief Complaint'
   WHEN @diagnosisTypeID = 1 and @isPrimary = 0 THEN 'Secondary Complaint'
   WHEN @diagnosisTypeID = 2 and @isPrimary = 1 THEN 'Primary Dx'
   WHEN @diagnosisTypeID = 2 and @isPrimary = 0 THEN 'Secondary Dx'
   WHEN @diagnosisTypeID = 3 and @isPrimary = 1 THEN 'Chief Complaint and Primary Dx'
   WHEN @diagnosisTypeID = 3 and @isPrimary = 0 THEN 'Chief Complaint and Secondary Dx'
   WHEN @diagnosisTypeID = 5  THEN 'Chief Complaint and Secondary Dx'
   ELSE 'Unknown'
   END 
	
   RETURN @diagnosisTypeDesc
END
GO
