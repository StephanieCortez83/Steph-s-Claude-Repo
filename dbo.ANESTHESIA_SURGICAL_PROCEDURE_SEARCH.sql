SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




 CREATE PROC [dbo].[ANESTHESIA_SURGICAL_PROCEDURE_SEARCH] 
 ( 
 @parmWord1 varchar(50), 
 @parmWord2 varchar(50), 
 @parmWord3 varchar(50), 
 @parmWord4 varchar(50), 
 @parmWord5 varchar(50) 
 ) 
 AS 
 BEGIN 

 declare @containsParmWord1 nvarchar(3000) 
 declare @containsParmWord2 nvarchar(3000) 
 declare @containsParmWord3 nvarchar(3000) 
 declare @containsParmWord4 nvarchar(3000) 
 declare @containsParmWord5 nvarchar(3000) 

 set @containsParmWord1 = null 
 set @containsParmWord2 = null 
 set @containsParmWord3 = null 
 set @containsParmWord4 = null 
 set @containsParmWord5 = null 

 declare @escParmWord1 nvarchar(3000) 
 declare @escParmWord2 nvarchar(3000) 
 declare @escParmWord3 nvarchar(3000) 
 declare @escParmWord4 nvarchar(3000) 
 declare @escParmWord5 nvarchar(3000) 

 set @escParmWord1 = null 
 set @escParmWord2 = null 
 set @escParmWord3 = null 
 set @escParmWord4 = null 
 set @escParmWord5 = null 


 declare @synTable table (syn_id int identity (1,1), syn_word varchar(1000), processed bit) 
 declare @id int 
 declare @synWord varchar(250) 

 -- Try searching for multi-word synonyms first 
 if @parmWord2 <> '' 
 BEGIN 
 insert into @synTable (syn_word, processed) select PHRASE_WORD, 0 from ANESTHESIA_CODE_SURGICAL_PROCEDURE_SYNONYM sy where sy.SYNONYM_WORD = @parmWord1 + ' ' + @parmWord2 

 set @containsParmWord1 = ' FormsOf(INFLECTIONAL, "' + @parmWord1 + '") ' 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord1 = @containsParmWord1 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 
 END 

 insert into @synTable (syn_word, processed) select PHRASE_WORD, 0 from ANESTHESIA_CODE_SURGICAL_PROCEDURE_SYNONYM sy where sy.SYNONYM_WORD = @parmWord1 

 set @containsParmWord1 = '"' + @parmWord1 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord1 + '") ' 
 set @escParmWord1 = dbo.escapeFTSSearch (@parmWord1) 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord1 = @containsParmWord1 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 if (@escParmWord1 IS NOT NULL) 
 BEGIN 
 set @escParmWord1 = @escParmWord1 + ' OR ' 
 END 
 set @escParmWord1 = @escParmWord1 + ' (' + dbo.escapeFTSSearch (@synWord) +' )' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 

 if @parmWord2 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord2) > 1 insert into @synTable (syn_word, processed) select PHRASE_WORD, 0 from ANESTHESIA_CODE_SURGICAL_PROCEDURE_SYNONYM sy where sy.SYNONYM_WORD = @parmWord2 

 set @containsParmWord2 = '"' + @parmWord2 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord2 + '") ' 
 set @escParmWord2 = dbo.escapeFTSSearch (@parmWord2) 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord2 = @containsParmWord2 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 if (@escParmWord2 IS NOT NULL) 
 BEGIN 
 set @escParmWord2 = @escParmWord2 + ' OR ' 
 END 
 set @escParmWord2 = @escParmWord2 + ' (' + dbo.escapeFTSSearch (@synWord) +' )' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 

 END 

 if @parmWord3 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord3) > 1 insert into @synTable (syn_word, processed) select PHRASE_WORD, 0 from ANESTHESIA_CODE_SURGICAL_PROCEDURE_SYNONYM sy where sy.SYNONYM_WORD = @parmWord3 

 set @containsParmWord3 = '"' + @parmWord3 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord3 + '") ' 
 set @escParmWord3 = dbo.escapeFTSSearch (@parmWord3) 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord3 = @containsParmWord3 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 if (@escParmWord3 IS NOT NULL) 
 BEGIN 
 set @escParmWord3 = @escParmWord3 + ' OR ' 
 END 
 set @escParmWord3 = @escParmWord3 + ' (' + dbo.escapeFTSSearch (@synWord) +' )' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 
 END 

 if @parmWord4 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord4) > 1 insert into @synTable (syn_word, processed) select PHRASE_WORD, 0 from ANESTHESIA_CODE_SURGICAL_PROCEDURE_SYNONYM sy where sy.SYNONYM_WORD = @parmWord4 

 set @containsParmWord4 = '"' + @parmWord4 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord4 + '") ' 
 set @escParmWord4 = dbo.escapeFTSSearch (@parmWord4) 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord4 = @containsParmWord4 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 if (@escParmWord4 IS NOT NULL) 
 BEGIN 
 set @escParmWord4 = @escParmWord4 + ' OR ' 
 END 
 set @escParmWord4 = @escParmWord4 + ' (' + dbo.escapeFTSSearch (@synWord) +' )' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 
 END 

 if @parmWord5 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord5) > 1 insert into @synTable (syn_word, processed) select PHRASE_WORD, 0 from ANESTHESIA_CODE_SURGICAL_PROCEDURE_SYNONYM sy where sy.SYNONYM_WORD = @parmWord5 

 set @containsParmWord5 = '"' + @parmWord5 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord5 + '") ' 
 set @escParmWord5 = dbo.escapeFTSSearch (@parmWord5) 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord5 = @containsParmWord5 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 if (@escParmWord5 IS NOT NULL) 
 BEGIN 
 set @escParmWord5 = @escParmWord5 + ' OR ' 
 END 
 set @escParmWord5 = @escParmWord5 + ' (' + dbo.escapeFTSSearch (@synWord) +' )' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 
 END 

 if @containsParmWord5 is not null 
 BEGIN 
 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 FROM 
 ( 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord1) AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord2) 
 AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord3) AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord4) AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord5) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord3)) 
 AND (@escParmWord4 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord4)) 
 AND (@escParmWord5 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord5)) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL
 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord1) AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord2) 
 AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord3) AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord4) AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord5) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord3)) 
 AND (@escParmWord4 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord4)) 
 AND (@escParmWord5 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord5)) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 
 
 ) x 
 where x.ResultCode <> '' 
 order by x.ResultCode 
 END 

 ELSE 
 if @containsParmWord4 is not null 
 BEGIN 
 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 FROM 
 ( 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord1) AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord2) 
 AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord3) AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord4) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord3)) 
 AND (@escParmWord4 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord4)) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 
 
 UNION ALL 
  select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord1) AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord2) 
 AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord3) AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord4) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord3)) 
 AND (@escParmWord4 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord4)) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 
 ) x 
 where x.ResultCode <> '' 
 order by x.ResultCode 
 END 
 ELSE 

 if @containsParmWord3 is not null 
 BEGIN 
 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 FROM 
 ( 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord1) AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord2) 
 AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord3) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord3)) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
  select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord1) AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord2) 
 AND (CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord3) or cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION like + '%' + @parmWord3 + '%')
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord3)) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 
 
 ) x 
 where x.ResultCode <> '' 
 order by x.ResultCode 
 END 

 ELSE 

 if @containsParmWord2 is not null 
 BEGIN 
 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 FROM 
 ( 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord1) 
 AND (CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord2) or cm.SURGICAL_PROCEDURE_DESCRIPTION like @containsParmWord2 + '%')
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE (SURGICAL_PROCEDURE_DESCRIPTION is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord2)) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
  select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord1) 
 AND (CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord2) or cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION like + '%' + @parmWord2 + '%')
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE (SURGICAL_PROCEDURE_LONG_DESCRIPTION is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord1)) 
 AND (@escParmWord2 is not null 
 AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord2))
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 ) x 
 where x.ResultCode <> '' 
 order by x.ResultCode 
 END 

 ELSE 

 if @containsParmWord1 is not null 
 BEGIN 
 declare @codeWord varchar(15) 

 
 if (LEN(@parmWord1) < 7 AND LEN(@parmWord1) > 2) 
 BEGIN 
 if (LEN(@parmWord1) = 3) 
 BEGIN 
 set @codeWord = @parmWord1 
 END 
 ELSE 
 set @codeWord = SUBSTRING(@parmWord1, 1, 3) + '.' + SUBSTRING(@parmWord1, 4, LEN(@parmWord1) - 3) 
 END 

 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 FROM 
 ( 

 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @containsParmWord1) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE @escParmWord1 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_DESCRIPTION, @escParmWord1) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE cm.SURGICAL_PROCEDURE_CODE LIKE @codeWord + '%' 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE cm.SURGICAL_PROCEDURE_CODE LIKE @parmWord1 + '%' 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE cm.SURGICAL_PROCEDURE_DESCRIPTION LIKE '%' + @parmWord1 + '%' 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @containsParmWord1) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE @escParmWord1 is not null AND CONTAINS(cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, @escParmWord1) 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 UNION ALL 
 select cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION as ResultText, cm.SURGICAL_PROCEDURE_CODE as ResultCode from ANESTHESIA_SURGICAL_PROCEDURE cm with (NOLOCK) 
 WHERE cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION LIKE '%' + @parmWord1 + '%' 
 GROUP by cm.SURGICAL_PROCEDURE_LONG_DESCRIPTION, cm.SURGICAL_PROCEDURE_CODE 

 ) x 
 where x.ResultCode <> '' 
 order by x.ResultCode 
 END 

 END 




GO
