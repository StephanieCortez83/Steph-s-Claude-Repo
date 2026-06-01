SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GetSystemStopWords] ()
RETURNS table
AS
return (select ssw.stopword
        from sys.fulltext_system_stopwords ssw
             join sys.fulltext_languages slg
                  on slg.lcid = ssw.language_id
        where slg.[name] = 'British English')
GO
