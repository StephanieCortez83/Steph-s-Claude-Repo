SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ICD_10_PHRASE_SEARCH_ALL_WORDS] 
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

 if object_id('TempDB..#Results', 'U') is not null DROP TABLE #Results;
 create table #Results (ResultText varchar(250), ResultCode varchar(10));

 -- Try searching for multi-word synonyms first 
 if @parmWord2 <> '' 
 BEGIN 
 insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord1 + ' ' + @parmWord2 
 insert into @synTable (syn_word, processed) select rtrim(REPLACE(DRUG_CLASSIFCATION,',','')), 0 from DRUG sy where sy.DRUG_GENERIC_NAME = @parmWord1 + ' ' + @parmWord2 
 insert into @synTable (syn_word, processed) select rtrim(REPLACE(DRUG_CLASSIFCATION,',','')), 0 from DRUG sy where sy.DRUG_TRADE_NAME = @parmWord1 + ' ' + @parmWord2 

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

 insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord1 
 insert into @synTable (syn_word, processed) select rtrim(REPLACE(DRUG_CLASSIFCATION,',','')), 0 from DRUG sy where sy.DRUG_GENERIC_NAME like @parmWord1 +'%' and len(@parmWord1) > 3 
 insert into @synTable (syn_word, processed) select rtrim(REPLACE(DRUG_CLASSIFCATION,',','')), 0 from DRUG sy where sy.DRUG_TRADE_NAME like @parmWord1 +'%' and len(@parmWord1) > 3 

 set @containsParmWord1 = '"' + @parmWord1 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord1 + '") ' 
 set @escParmWord1 = dbo.escapeFTSSearch (rtrim(@parmWord1)) 
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
  
 -- ACS-15364 Remove orphan "AND" from search text
  declare @testResult1 varchar(100)
 if (LEN(@escParmWord1) > 2 AND SUBSTRING(@escParmWord1, len(@escParmWord1) -3, 3) = '   ')
 BEGIN
  set @testResult1 = dbo.StringBeforeLastIndex(@escParmWord1, 'AND') + ')'
  set @escParmWord1 = @testResult1;
 END

 END 

 if @parmWord2 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord2) > 1 insert into @synTable (syn_word, processed) select CM_WORD, 0 from [ICD_10_SYNONYMS] sy where sy.SYNONYM_WORD = @parmWord2 
 if LEN(@parmWord2) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_GENERIC_NAME like @parmWord2 +'%' and len(@parmWord2) > 3 
 if LEN(@parmWord2) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_TRADE_NAME like @parmWord2 +'%' and len(@parmWord2) > 3 

 set @containsParmWord2 = '"' + @parmWord2 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord2 + '") ' 
 set @escParmWord2 = dbo.escapeFTSSearch (rtrim(@parmWord2)) 
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
 
 -- ACS-15364 Remove orphan "AND" from search text
  declare @testResult2 varchar(100)
 if (LEN(@escParmWord2) > 2 AND SUBSTRING(@escParmWord2, len(@escParmWord2) -3, 3) = '   ')
 BEGIN
  set @testResult2 = dbo.StringBeforeLastIndex(@escParmWord2, 'AND') + ')'
  set @escParmWord2 = @testResult2;
 END

 END 

 if @parmWord3 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord3) > 1 insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord3 
 if LEN(@parmWord3) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_GENERIC_NAME like @parmWord3 +'%' and len(@parmWord3) > 3 
 if LEN(@parmWord3) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_TRADE_NAME like @parmWord3 +'%' and len(@parmWord3) > 3 
 set @containsParmWord3 = '"' + @parmWord3 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord3 + '") ' 
 set @escParmWord3 = dbo.escapeFTSSearch (rtrim(@parmWord3)) 
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
 
 -- ACS-15364 Remove orphan "AND" from search text
  declare @testResult3 varchar(100)
 if (LEN(@escParmWord3) > 2 AND SUBSTRING(@escParmWord3, len(@escParmWord3) -3, 3) = '   ')
 BEGIN
  set @testResult3 = dbo.StringBeforeLastIndex(@escParmWord3, 'AND') + ')'
  set @escParmWord3 = @testResult3;
 END

 END 

 if @parmWord4 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord4) > 1 insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord4 
 if LEN(@parmWord4) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_GENERIC_NAME like @parmWord4 +'%' and len(@parmWord4) > 3 
 if LEN(@parmWord4) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_TRADE_NAME like @parmWord4 +'%' and len(@parmWord4) > 3 
 set @containsParmWord4 = '"' + @parmWord4 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord4 + '") ' 
 set @escParmWord4 = dbo.escapeFTSSearch (rtrim(@parmWord4)) 
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
  
 -- ACS-15364 Remove orphan "AND" from search text
  declare @testResult4 varchar(100)
 if (LEN(@escParmWord4) > 2 AND SUBSTRING(@escParmWord4, len(@escParmWord4) -3, 3) = '   ')
 BEGIN
  set @testResult4 = dbo.StringBeforeLastIndex(@escParmWord4, 'AND') + ')'
  set @escParmWord4 = @testResult4;
 END

 END 

 if @parmWord5 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord5) > 1 insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord5 
 if LEN(@parmWord5) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_GENERIC_NAME like @parmWord5 +'%' and len(@parmWord5) > 3 
 if LEN(@parmWord5) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_TRADE_NAME like @parmWord5 +'%' and len(@parmWord5) > 3 
 set @containsParmWord5 = '"' + @parmWord5 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord5 + '") ' 
 set @escParmWord5 = dbo.escapeFTSSearch (rtrim(@parmWord5)) 
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
   
 -- ACS-15364 Remove orphan "AND" from search text
  declare @testResult5 varchar(100)
 if (LEN(@escParmWord5) > 2 AND SUBSTRING(@escParmWord5, len(@escParmWord5) -3, 3) = '   ')
 BEGIN
  set @testResult5 = dbo.StringBeforeLastIndex(@escParmWord5, 'AND') + ')'
  set @escParmWord5 = @testResult5;
 END

 END 

 if @containsParmWord5 is not null 
 BEGIN 
 -- *** begin edit 1/11/2018 dsexton ***
 insert into #Results (ResultText, ResultCode)
 --SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 --select *
 --FROM 
 --( 
 -- *** end edit 1/11/2018 dsexton ***
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2) 
 AND CONTAINS(cm.[DESCRIPTION], @containsParmWord3) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord4) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord5) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord3)) 
 AND (@escParmWord4 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord4)) 
 AND (@escParmWord5 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord5)) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 -- begin dsexton modification 11/20/2015 (if @containsParmWord5) ----------------------------- 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @containsParmWord1) 
 and CONTAINS(DESCRIPTION, @containsParmWord2) 
 and CONTAINS(DESCRIPTION, @containsParmWord3) 
 and CONTAINS(DESCRIPTION, @containsParmWord4) 
 and CONTAINS(DESCRIPTION, @containsParmWord5) 
 GROUP by CodeDescription, ICD_10_CODE 

 /* -- Old version did not include UNION for @escParmWord in this section. Not needed? 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @escParmWord1) 
 and CONTAINS(DESCRIPTION, @escParmWord2) 
 and CONTAINS(DESCRIPTION, @escParmWord3) 
 and CONTAINS(DESCRIPTION, @escParmWord4) 
 and CONTAINS(DESCRIPTION, @escParmWord5) 
 AND @escParmWord1 is not null 
 AND @escParmWord2 is not null 
 AND @escParmWord3 is not null 
 AND @escParmWord4 is not null 
 AND @escParmWord5 is not null 
 GROUP by CodeDescription, ICD_10_CODE 
 */ 

 union all 
 SELECT DESCRIPTION as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_InclusionTerm_Map with (NOLOCK) 
 WHERE CONTAINS(INCLUSION_TERM_DESC, @containsParmWord1) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord2) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord3) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord4) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord5) 
 GROUP by DESCRIPTION, ICD_10_CODE 
 -- end dsexton modification 11/20/2015 (if @containsParmWord5) ----------------------------- 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) AND CONTAINS(cm.TITLE, @containsParmWord5) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) AND CONTAINS(cm.TITLE, @containsParmWord5) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 --UNION ALL 
 --select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK) 
 --WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 --AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) AND CONTAINS(cm.TITLE, @containsParmWord5) 
 --and cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID 
 --and cd.COLUMN_NUMBER = 1 and cd.CODE <> '--' 
--GROUP by cm.TITLE, cd.CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_generic_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_GENERIC_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord3) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord4) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord5) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_GENERIC_NAME, cm.ICD_10_PCS_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_TRADE_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord4) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord5) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_TRADE_NAME, cm.ICD_10_PCS_CODE 
-- *** begin edit 1/11/2018 dsexton ***
 --) x 

 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText 
	   ,x.ResultCode 
	   ,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
 FROM #Results as x
 LEFT JOIN [ICD_10_CM]
		ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
 -- *** end edit 1/11/2018 dsexton ***
 WHERE x.ResultCode <> ''
 order by x.ResultCode 
 END 

 ELSE 
 if @containsParmWord4 is not null 
 BEGIN 
 -- *** begin edit 1/11/2018 dsexton ***
insert into #Results (ResultText, ResultCode)
 --SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 --Select *
 --FROM 
 --( 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2) 
 AND CONTAINS(cm.[DESCRIPTION], @containsParmWord3) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord4) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord3)) 
 AND (@escParmWord4 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord4)) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 -- begin dsexton modification 11/20/2015 (if @containsParmWord4) ----------------------------- 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @containsParmWord1) 
 and CONTAINS(DESCRIPTION, @containsParmWord2) 
 and CONTAINS(DESCRIPTION, @containsParmWord3) 
 and CONTAINS(DESCRIPTION, @containsParmWord4) 
 GROUP by CodeDescription, ICD_10_CODE 

 /* -- Old version did not include UNION for @escParmWord in this section. Not needed? 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @escParmWord1) 
 and CONTAINS(DESCRIPTION, @escParmWord2) 
 and CONTAINS(DESCRIPTION, @escParmWord3) 
 and CONTAINS(DESCRIPTION, @escParmWord4) 
 AND @escParmWord1 is not null 
 AND @escParmWord2 is not null 
 AND @escParmWord3 is not null 
 AND @escParmWord4 is not null 
 GROUP by CodeDescription, ICD_10_CODE 
 */ 

 union all 
 SELECT DESCRIPTION as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_InclusionTerm_Map with (NOLOCK) 
 WHERE CONTAINS(INCLUSION_TERM_DESC, @containsParmWord1) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord2) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord3) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord4) 
 GROUP by DESCRIPTION, ICD_10_CODE 
 -- end dsexton modification 11/20/2015 (if @containsParmWord4) ----------------------------- 


 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 --UNION ALL 
 --select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK) 
 --WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 --AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) 
 --and cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID 
 --and cd.COLUMN_NUMBER = 1 and cd.CODE <> '--' 
--GROUP by cm.TITLE, cd.CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_generic_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_GENERIC_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord3) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord4) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_GENERIC_NAME, cm.ICD_10_PCS_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_TRADE_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord4) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_TRADE_NAME, cm.ICD_10_PCS_CODE 

 UNION ALL 
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord3) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord4) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord2))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord2) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord3) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord4) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord3))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord3) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord4) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord4))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord4) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord3) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 
 -- *** begin edit 1/11/2018 dsexton ***
 --) x 

 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText 
	   ,x.ResultCode 
	   ,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
 FROM #Results as x
 LEFT JOIN [ICD_10_CM]
		ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
 -- *** end edit 1/11/2018 dsexton ***
 WHERE x.ResultCode <> ''
 order by x.ResultCode 
 END 
 ELSE 

 if @containsParmWord3 is not null 
 BEGIN 
-- *** begin edit 1/11/2018 dsexton ***
insert into #Results (ResultText, ResultCode)
--SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 --FROM 
 --( 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2) 
 AND CONTAINS(cm.[DESCRIPTION], @containsParmWord3) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord3)) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 -- begin dsexton modification 11/20/2015 (if @containsParmWord3) ----------------------------- 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @containsParmWord1) 
 and CONTAINS(DESCRIPTION, @containsParmWord2) 
 and CONTAINS(DESCRIPTION, @containsParmWord3) 
 GROUP by CodeDescription, ICD_10_CODE 


 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @escParmWord1) 
 and CONTAINS(DESCRIPTION, @escParmWord2) 
 and CONTAINS(DESCRIPTION, @escParmWord3) 
 AND @escParmWord1 is not null 
 AND @escParmWord2 is not null 
 AND @escParmWord3 is not null 
 GROUP by CodeDescription, ICD_10_CODE 


 union all 
 SELECT DESCRIPTION as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_InclusionTerm_Map with (NOLOCK) 
 WHERE CONTAINS(INCLUSION_TERM_DESC, @containsParmWord1) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord2) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord3) 
 GROUP by DESCRIPTION, ICD_10_CODE 
 -- end dsexton modification 11/20/2015 (if @containsParmWord3) ----------------------------- 


 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 --UNION ALL 
 --select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK) 
 --WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 --AND CONTAINS(cm.TITLE, @containsParmWord3) 
 --and cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID 
 --and cd.COLUMN_NUMBER = 1 and cd.CODE <> '--' 
--GROUP by cm.TITLE, cd.CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_generic_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_GENERIC_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord3) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_GENERIC_NAME, cm.ICD_10_PCS_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_TRADE_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_TRADE_NAME, cm.ICD_10_PCS_CODE 

 UNION ALL 
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord3) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
 IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord3))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord3) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord2))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord2) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord3) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

 -- *** begin edit 1/11/2018 dsexton ***
 --) x 

 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText
	   ,x.ResultCode 
	   ,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
 FROM #Results as x
 LEFT JOIN [ICD_10_CM]
		ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
 -- *** end edit 1/11/2018 dsexton ***
 WHERE x.ResultCode <> ''
 order by x.ResultCode 
 END 

 ELSE 

 if @containsParmWord2 is not null 
 BEGIN 
 -- *** begin edit 1/11/2018 dsexton ***
 insert into #Results (ResultText, ResultCode)
 --SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 --FROM 
 --( 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord2)) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 


 -- begin dsexton modification 11/20/2015 (if @containsParmWord2) ----------------------------- 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @containsParmWord1) 
 and CONTAINS(DESCRIPTION, @containsParmWord2) 
 GROUP by CodeDescription, ICD_10_CODE 

 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @escParmWord1) 
 and CONTAINS(DESCRIPTION, @escParmWord2) 
 AND @escParmWord1 is not null 
 AND @escParmWord2 is not null 
 GROUP by CodeDescription, ICD_10_CODE 

 union all 
 SELECT DESCRIPTION as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_InclusionTerm_Map with (NOLOCK) 
 WHERE CONTAINS(INCLUSION_TERM_DESC, @containsParmWord1) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord2) 
 GROUP by DESCRIPTION, ICD_10_CODE 
 -- end dsexton modification 11/20/2015 (if @containsParmWord2) ----------------------------- 


 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 --UNION ALL 
 --select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK) 
 --WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 --and cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID 
 --and cd.COLUMN_NUMBER = 1 and cd.CODE <> '--' 
--GROUP by cm.TITLE, cd.CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_generic_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_GENERIC_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_GENERIC_NAME, cm.ICD_10_PCS_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_TRADE_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_TRADE_NAME, cm.ICD_10_PCS_CODE 

 UNION ALL 
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord2))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord2) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

 -- *** begin edit 1/11/2018 dsexton ***
 --) x 
 
SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText 
	  ,x.ResultCode 
	  ,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
 FROM #Results as x
 LEFT JOIN [ICD_10_CM]
		ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
			AND CAST(getdate() as date) <= EXPIRATION_DATE AND CAST(getdate() as date) >= EFFECTIVE_DATE
-- *** end edit 1/11/2018 dsexton ***
 WHERE x.ResultCode <> ''
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

 -- *** begin edit 1/11/2018 dsexton ***
 insert into #Results (ResultText, ResultCode)
 --SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 --FROM 
 --( 
 -- *** end edit 1/11/2018 dsexton ***
 -- Check if a 7th digit code 
 select cm.LONG_DESCRIPTION as ResultText, SUBSTRING(cm.ICD10_CM,1,3) + '.' + SUBSTRING(cm.ICD10_CM,4,4) as ResultCode from ICD10_CM cm with (NOLOCK) 
 WHERE cm.ICD10_CM = REPLACE(@parmWord1,'.','')
 AND LEN(REPLACE(@parmWord1,'.','')) = 7 
 AND CAST(getdate() as date) <= cm.EXPIRATION_DATE AND CAST(getdate() as date) >= cm.EFFECTIVE_DATE
 GROUP by cm.LONG_DESCRIPTION, cm.ICD10_CM 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 LEFT OUTER JOIN ICD_10_RELATIVE_USAGE ru on ru.ICD10_CODE like REPLACE(cm.ICD_10_CODE, '.','') + '%' 
 WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1)
 AND CAST(getdate() as date) <= cm.EXPIRATION_DT AND CAST(getdate() as date) >= cm.EFFECTIVE_DT
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 


 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 LEFT OUTER JOIN ICD_10_RELATIVE_USAGE ru on ru.ICD10_CODE like REPLACE(cm.ICD_10_CODE, '.','') + '%' 
 WHERE @escParmWord1 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord1)
 AND CAST(getdate() as date) <= cm.EXPIRATION_DT AND CAST(getdate() as date) >= cm.EFFECTIVE_DT
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 LEFT OUTER JOIN ICD_10_RELATIVE_USAGE ru on ru.ICD10_CODE like REPLACE(cm.ICD_10_CODE, '.','') + '%' 
 WHERE cm.ICD_10_CODE LIKE @codeWord + '%'
 AND CAST(getdate() as date) <= cm.EXPIRATION_DT AND CAST(getdate() as date) >= cm.EFFECTIVE_DT
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE cm.DESCRIPTION LIKE '%' + @parmWord1 + '%' 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 


 -- begin dsexton modification 11/20/2015 (if @containsParmWord1) ----------------------------- 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @containsParmWord1) 
 GROUP by CodeDescription, ICD_10_CODE 

 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @escParmWord1) 
 AND @escParmWord1 is not null 
 GROUP by CodeDescription, ICD_10_CODE 

 union all 
 SELECT DESCRIPTION as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_InclusionTerm_Map with (NOLOCK) 
 WHERE CONTAINS(INCLUSION_TERM_DESC, @containsParmWord1)
 GROUP by DESCRIPTION, ICD_10_CODE 
 -- end dsexton modification 11/20/2015 (if @containsParmWord1) ----------------------------- 


 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE AND CAST(getdate() as date) <= i10.EXPIRATION_DT AND CAST(getdate() as date) >= i10.EFFECTIVE_DT
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CAST(getdate() as date) <= cm.EXPIRATION_DT AND CAST(getdate() as date) >= cm.EFFECTIVE_DT
 GROUP by i10.DESCRIPTION, cm.CODE 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE AND CAST(getdate() as date) <= i10.EXPIRATION_DT AND CAST(getdate() as date) >= i10.EFFECTIVE_DT
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CAST(getdate() as date) <= cm.EXPIRATION_DT AND CAST(getdate() as date) >= cm.EFFECTIVE_DT
 GROUP by i10.DESCRIPTION, cm.CODE 

 --UNION ALL 
 --select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK) 
 --WHERE CONTAINS(cm.TITLE, @containsParmWord1) 
 --and cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID 
 --and cd.COLUMN_NUMBER = 1 and cd.CODE <> '--' 
--GROUP by cm.TITLE, cd.CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_generic_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_GENERIC_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) 
 AND cm.ICD_10_CODE is not null and CAST(getdate() as date) <= cm.EXPIRATION_DTTM and CAST(getdate() as date) >= cm.EFFECTIVE_DTTM
 GROUP by cm.DRUG_GENERIC_NAME, cm.ICD_10_PCS_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_TRADE_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CAST(getdate() as date) <= cm.EXPIRATION_DTTM AND CAST(getdate() as date) >= cm.EFFECTIVE_DTTM
 GROUP by cm.DRUG_TRADE_NAME, cm.ICD_10_PCS_CODE 

 UNION ALL 
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord1) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient'
 AND CAST(getdate() as date) <= d.EXPIRATION_DTTM AND CAST(getdate() as date) >= d.EFFECTIVE_DTTM
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

 -- *** begin edit 1/11/2018 dsexton ***
 --) x 
 
 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText 
				,x.ResultCode 
				,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
 FROM #Results as x
-- *** end edit 1/11/2018 dsexton ***
 LEFT JOIN [ICD_10_CM]
		ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
		AND CAST(getdate() as date) <= EXPIRATION_DATE AND CAST(getdate() as date) >= EFFECTIVE_DATE
 WHERE x.ResultCode <> '' 
 order by x.ResultCode
 END 

 END
GO
