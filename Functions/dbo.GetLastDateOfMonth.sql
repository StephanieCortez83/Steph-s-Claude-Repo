SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[GetLastDateOfMonth]
(@InDate DateTime)
RETURNS DateTime
WITH EXEC AS CALLER
AS
BEGIN
	declare @endDate DateTime
    set @endDate = (SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@InDate)+1,0)))
	return @endDate
END
GO
