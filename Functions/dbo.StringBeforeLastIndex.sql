SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 CREATE FUNCTION [dbo].[StringBeforeLastIndex](@source varchar(100), @pattern char)
RETURNS varchar(100)
BEGIN  
       DECLARE @lastIndex int
       SET @lastIndex = (LEN(@source)) -  CHARINDEX(@pattern, REVERSE(@source)) 

     RETURN SUBSTRING(@source, 0, @lastindex + 1) 
     -- +1 because index starts at 0, but length at 1, so to get up to 11th index, we need LENGTH 11+1=12
END;  
GO
