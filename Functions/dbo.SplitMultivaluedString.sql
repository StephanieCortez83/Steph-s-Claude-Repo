SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Laura Hotalling
-- Create date: 03/06/2013
-- Description:	Splits any multivalued string
--				seperated by any delimiter into 
--				multiple rows
-- =============================================

CREATE FUNCTION [dbo].[SplitMultivaluedString]
(
   @DelimittedString [varchar](max),
   @Delimiter [varchar](1)
)
RETURNS @Table Table (Value [varchar](100))
BEGIN
   DECLARE @sTemp [varchar](max)
   SET @sTemp = ISNULL(@DelimittedString,'')
                + @Delimiter
   WHILE LEN(@sTemp) > 0
   BEGIN
      INSERT INTO @Table
      SELECT SubString(@sTemp,1,
             CharIndex(@Delimiter,@sTemp)-1)
     
      SET @sTemp = RIGHT(@sTemp,
        LEN(@sTemp)-CharIndex(@Delimiter,@sTemp))
   END
   RETURN
END
GO
GRANT SELECT ON  [dbo].[SplitMultivaluedString] TO [dbx_selecttablevaluedfunctions]
GO
