SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[ICD_10_Phrase_Search_All_Words_Incl_Synonyms_ReplacedByCDBT816]
(
	@parmWord1 varchar(50),
	@parmWord2 varchar(50),	
	@parmWord3 varchar(50),
	@parmWord4 varchar(50),
	@parmWord5 varchar(50)				
)
AS
BEGIN

declare @multiWord varchar(150)

declare @synTable table (syn_id int identity (1,1), syn_word varchar(1000), processed bit)
declare @resultTable table (ResultText varchar(250), ResultCode varchar(10), SelectionInd bit)
declare @id int
declare @synWord varchar(250)

-- Try searching for multi-word synonyms  

	if @parmWord5 <> ''
	BEGIN			
		set @multiWord = @parmWord4 + ' ' + @parmWord5
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @parmWord1, @parmWord2, @parmWord3, @multiWord, ''
		set @multiWord = @parmWord3 + ' ' + @parmWord4
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @parmWord1, @parmWord2, @multiWord, @parmWord5, ''
		set @multiWord = @parmWord2 + ' ' + @parmWord3
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @parmWord1, @multiWord, @parmWord4, @parmWord5, ''
		set @multiWord = @parmWord1 + ' ' + @parmWord2
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @multiWord, @parmWord3, @parmWord4, @parmWord5, ''		
		set @multiWord = @parmWord1 + ' ' + @parmWord2 + ' ' + @parmWord3
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @multiWord, @parmWord4, @parmWord5, '', ''		
		set @multiWord = @parmWord2 + ' ' + @parmWord3 + ' ' + @parmWord4
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @parmWord1, @multiWord, @parmWord5, '', ''	
		set @multiWord = @parmWord3 + ' ' + @parmWord4 + ' ' + @parmWord5
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @parmWord1, @parmWord2, @multiWord, '', ''						
	END
	ELSE
	if @parmWord4 <> ''
	BEGIN			
		set @multiWord = @parmWord3 + ' ' + @parmWord4
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @parmWord1, @parmWord2, @multiWord, '', ''
		set @multiWord = @parmWord2 + ' ' + @parmWord3
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @parmWord1, @multiWord, @parmWord4, '', ''
		set @multiWord = @parmWord1 + ' ' + @parmWord2
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @multiWord, @parmWord3, @parmWord4, '', ''		
		set @multiWord = @parmWord1 + ' ' + @parmWord2 + ' ' + @parmWord3
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @multiWord, @parmWord4, '', '', ''			
		set @multiWord = @parmWord2 + ' ' + @parmWord3 + ' ' + @parmWord4
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @parmWord1, @multiWord, '', '', ''				
	END	
	ELSE
	if @parmWord3 <> ''
	BEGIN			
		set @multiWord = @parmWord2 + ' ' + @parmWord3
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @parmWord1, @multiWord, '', '', ''
		set @multiWord = @parmWord1 + ' ' + @parmWord2
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @multiWord, @parmWord3, '', '', ''		
		set @multiWord = @parmWord1 + ' ' + @parmWord2 + ' ' + @parmWord3
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @multiWord, '', '', '', ''				
	END	
	ELSE
	if @parmWord2 <> ''
	BEGIN			
		set @multiWord = @parmWord1 + ' ' + @parmWord2
		insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @multiWord, '', '', '', ''		
	END		


-- Now do the search on all parameters as single words
insert into @resultTable exec ICD_10_PHRASE_SEARCH_ALL_WORDS @parmWord1, @parmWord2, @parmWord3, @parmWord4, @parmWord5

--select DISTINCT rt.ResultText, rt.ResultCode, ru.RELATIVE_VALUE  from @resultTable rt
--	LEFT OUTER JOIN ICD_10_RELATIVE_USAGE ru on ru.ICD10_CODE LIKE REPLACE(rt.ResultCode, '.','') + '%'		
--order by ru.RELATIVE_VALUE desc	

select DISTINCT rt.ResultText, rt.ResultCode, ru.RELATIVE_VALUE, rt.SelectionInd 
from @resultTable rt
LEFT OUTER JOIN ICD_10_RELATIVE_USAGE ru on ru.ICD10_CODE = REPLACE(rt.ResultCode, '.','') 		
order by ru.RELATIVE_VALUE desc	
END
GO
