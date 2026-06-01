SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[escapeFTSSearch] (
  @SearchParameter NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
  -- Declare the return variable here
  DECLARE @result NVARCHAR(MAX)

  SELECT @result = ' '+ REPLACE(REPLACE(@SearchParameter,' ',' '), ' ', '  AND  ') +' '

  -- Return the result of the function
  RETURN @result

END
GO
