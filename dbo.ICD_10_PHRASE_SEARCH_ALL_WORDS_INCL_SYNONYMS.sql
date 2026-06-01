SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ICD_10_PHRASE_SEARCH_ALL_WORDS_INCL_SYNONYMS]
--create PROCEDURE [dbo].[ICD_10_PHRASE_SEARCH_ALL_WORDS_INCL_SYNONYMS_UseSearchHistory]		-- temporary name for testing
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

-- begin tuning section A, 2/1/2025 dsexton ----------------------------------------------------------------------------------------------
declare @UsageStatus smallint
declare 
	@EnableHistory bit
	, @CaptureRawHistory bit
	, @UpdateHistory bit
	, @UseHistory bit
select @EnableHistory = EnableHistory, @CaptureRawHistory = CaptureRawHistory, @UpdateHistory = UpdateHistory, @UseHistory = UseHistory 
from ICD10SearchHistoryFeature with(nolock)

if @EnableHistory = 1
BEGIN
	declare @ParmWordCombined varchar(250)
	declare @SearchPhraseID int
	--declare @GUID uniqueidentifier	-- postpone declaring this variable until the end (only if needed)

	-- combine the search words and sort them in the same order provided into a single comma-delimited phrase
		-- sorting them alphabetically would reduce the number of total rows in these history tables. But even though most phrases return identical results no matter the word order, some order combos make a difference. 
	select @ParmWordCombined = 
	 STUFF((
		SELECT ',' + ParmWord
		FROM (
				select ID=1, ParmWord = @parmWord1
				union select ID=2, ParmWord = @parmWord2
				union select ID=3, ParmWord = @parmWord3
				union select ID=4, ParmWord = @parmWord4
				union select ID=5, ParmWord = @parmWord5
			) as x
		WHERE ParmWord <> ''
		order by ID
		FOR XML PATH('')) ,1,1,'') 


	--select @SearchPhraseID = isnull(ICD10SearchPhraseID, 0) from ICD10SearchPhrase where ParmWordCombined = @ParmWordCombined and Status = 1		-- returns null (not 0) when no record found
	select @SearchPhraseID = ICD10SearchPhraseID, @UsageStatus = UsageStatus from ICD10SearchPhrase with(nolock) where ParmWordCombined = @ParmWordCombined	
	select @SearchPhraseID = isnull(@SearchPhraseID, 0)		-- set this variable to 0 if null

	if @SearchPhraseID <> 0			-- a matching search phrase is found in the history tables
	BEGIN	
		if @UpdateHistory = 1		-- update usage history for the found phrase
		BEGIN
			update ICD10SearchPhrase 
			set 
				SearchCount = SearchCount + 1,
				LastSearchDT = getdate(),
				UsageCount = UsageCount + 1,
				LastUsageDT = getdate()
			where ICD10SearchPhraseID = @SearchPhraseID
		END

		if @UseHistory = 1 and @UsageStatus = 1			-- use the history phrase (and its corresponding result set) to bypass all calls to ICD_10_PHRASE_SEARCH_ALL_WORDS
		BEGIN
			/*
			update ICD10SearchPhrase 
			set 
				UsageCount = UsageCount + 1,
				LastUsageDT = getdate()
			where ICD10SearchPhraseID = @SearchPhraseID
			*/

			select r.ResultText, r.ResultCode, Relative_Value = r.RelativeValue, r.SelectionInd 
			from 
				ICD10SearchResult as r with(nolock)
				join ICD10SearchHistory as h with(nolock)
					on r.ICD10SearchResultID = h.ICD10SearchResultID 
					and h.ICD10SearchPhraseID = @SearchPhraseID
			order by Relative_Value desc, ResultText	

			RETURN
		END
	END
END
-- if no match, proceed as usual, then add to the search history table at the end (if the history feature is enabled) ...
-- end tuning section A, 2/1/2025 dsexton -------------------------------------------------------------------------------------------------


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


-- begin tuning section B, 2/1/2025 dsexton ---------------------------------------------------------------------------------------------------------------------------------------------
if @EnableHistory = 1 and @CaptureRawHistory = 1 and @SearchPhraseID = 0
BEGIN
	declare @Timestamp datetime = getdate()
	declare @GUID uniqueidentifier	-- postponed DECLARE until here (only if needed)
	SET @GUID = NEWID()				-- ensures proper grouping within any duplicate result sets in the Raw table (duplicates could exist if the initial entry in Raw has not yet been parsed)

	if exists (select 1 from @resultTable)		-- capture the search phrase and its result set into the Raw table for subsequent parsing
		insert into ICD10SearchHistoryRaw		-- a separate background process will parse this Raw table into tables ICD10SearchPhrase, ICD10SearchResult, and ICD10SearchHistory
			(SearchGUID, SearchPhrase, ResultText, ResultCode, RelativeValue, SelectionInd, RowInsertedDT)
		select DISTINCT @GUID, @ParmWordCombined, rt.ResultText, rt.ResultCode, ru.Relative_Value, rt.SelectionInd, @Timestamp
		from @resultTable rt
			LEFT OUTER JOIN ICD_10_RELATIVE_USAGE ru on ru.ICD10_CODE = REPLACE(rt.ResultCode, '.','') 	

	else	-- capture any search phrases which produce 0 results so the phrase will be added to the history tables and perform better if searched on again
		insert into ICD10SearchHistoryRaw
			(SearchGUID, SearchPhrase, ResultText, ResultCode, RelativeValue, SelectionInd, RowInsertedDT)
		select @GUID, @ParmWordCombined, null, null, null, null, @Timestamp
END
-- decided against querying ICD10SearchHistoryRaw for the final output since that table could become large if the background process gets behind in parsing
-- this sproc gets executed about once per second, so ICD10SearchHistoryRaw could be a very busy table until sufficient history is initially built over a period of days/weeks
-- end tuning section B, 2/1/2025 dsexton ---------------------------------------------------------------------------------------------------------------------------------------------

select DISTINCT rt.ResultText, rt.ResultCode, ru.RELATIVE_VALUE, rt.SelectionInd 
from @resultTable rt
LEFT OUTER JOIN ICD_10_RELATIVE_USAGE ru on ru.ICD10_CODE = REPLACE(rt.ResultCode, '.','') 		
order by ru.RELATIVE_VALUE desc	


END
GO
