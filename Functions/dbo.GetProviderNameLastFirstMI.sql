SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[GetProviderNameLastFirstMI]
(	@providerID int
)

RETURNS varchar(100)
AS 

BEGIN
	declare @returnName varchar(100)


SELECT @returnName = 
(SELECT top 1 p.LAST_NAME + ', ' + p.FIRST_NAME + ' ' + SUBSTRING(p.MIDDLE_NAME,1,1) from FACILITY_PROFESSIONAL p where p.FACILITY_PROF_ID = @providerID)
	
RETURN @returnName
END
GO
