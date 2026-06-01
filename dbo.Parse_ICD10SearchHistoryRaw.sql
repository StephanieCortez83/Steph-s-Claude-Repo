SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[Parse_ICD10SearchHistoryRaw]
(
	@UseWAITFOR bit,
	@WaitMinutes int,		-- (0-59) how many minutes to wait for rows to appear in Raw table if empty. Suggest initially setting to half the frequency of the SQL Agent job schedule.
	@PauseSeconds int		-- (0-59) how many seconds to pause between parsing iterations.  Suggest a low value between 0 and 2.
)
as
set nocount on
set transaction isolation level read uncommitted

declare @ParmWordCombined varchar(250)
declare @ResultRowCnt int
declare @Timestamp datetime 
declare @MinRowInsertDT datetime
declare @GUID uniqueidentifier	-- SearchGUID ensures only one result set is dealt with in case multiple result sets have the same value for RowInsertedDT
declare @PhraseID int

declare @strWaitSecs varchar(8) = '00:00:'
declare @strWaitMins varchar(5) = '00:'

-- format WAIT seconds
if @PauseSeconds not between 0 and 59 
	set @PauseSeconds = 1

	if @PauseSeconds < 10
		set @strWaitSecs = @strWaitSecs + '0' + cast(@PauseSeconds as varchar(1))
	else
		set @strWaitSecs = @strWaitSecs + cast(@PauseSeconds as varchar(2))

-- format WAIT minutes
if @WaitMinutes not between 0 and 59 
	set @WaitMinutes = 1

	if @WaitMinutes < 10
	set @strWaitMins = @strWaitMins + '0' + cast(@WaitMinutes as varchar(1))
	else
	set @strWaitMins = @strWaitMins + cast(@WaitMinutes as varchar(2))

if @UseWAITFOR = 1
	BEGIN
		if not exists (select 1 from ICD10SearchHistoryRaw)		
			waitfor delay @strWaitMins		-- allows minimizing frequency of SQL Agent job schedule to avoid bloating the job history log
											-- for example: job runs every 10 minutes, but wait 5 minutes here to see if any records appear for parsing
	END

while exists (select 1 from ICD10SearchHistoryRaw)
BEGIN
	set @Timestamp = getdate()

	select @MinRowInsertDT = min(RowInsertedDT) from ICD10SearchHistoryRaw	 -- FIFO

	select top 1 
		@GUID = SearchGUID,					-- SearchGUID will be the same in all rows of a raw result set.
		@ParmWordCombined = SearchPhrase	-- SearchPhrase will be the same in all rows of a raw result set. 
	from ICD10SearchHistoryRaw 
	where RowInsertedDT = @MinRowInsertDT	-- RowInsertedDT will be the same in all rows of a raw result set. 

	select @ResultRowCnt = count(*) from ICD10SearchHistoryRaw where RowInsertedDT = @MinRowInsertDT and ResultText is not null

	-- populate table ICD10SearchPhrase
	if not exists (select 1 from ICD10SearchPhrase where ParmWordCombined = @ParmWordCombined)		-- could already exist if the phrase was searched multiple times before it was parsed from the first Raw entry
	BEGIN
		insert into ICD10SearchPhrase (ParmWordCombined, ResultRows, UsageStatus, SearchCount, LastSearchDT, UsageCount, LastUsageDT, RowInsertedDT)	-- UsageStatus 1 = searchable, 0 = not searchable (e.g., parsing not yet completed)
		select @ParmWordCombined, @ResultRowCnt, 0, 1, @Timestamp, 0, null, @Timestamp		-- all search phrases should be inserted, even those with empty result sets

		select @PhraseID = ICD10SearchPhraseID from ICD10SearchPhrase where ParmWordCombined = @ParmWordCombined		-- @PhraseID will be used for updating UsageStatus in final UPDATE statement
																														-- ParmWordCombined is the PK
	END
	else	
	BEGIN
		DELETE from ICD10SearchHistoryRaw where RowInsertedDT = @MinRowInsertDT and SearchGUID = @GUID		-- no need to process this "duplicate" Raw entry of ParmWordCombined
		CONTINUE	-- go back to the beginning of the WHILE loop and process the next Raw entry
	END

	-- populate table ICD10SearchResult
	insert into ICD10SearchResult (ResultText, ResultCode, RelativeValue, SelectionInd, RowInsertedDT)
	select ResultText, ResultCode, RelativeValue, SelectionInd, @Timestamp
	from ICD10SearchHistoryRaw as t1
	where 
		t1.RowInsertedDT = @MinRowInsertDT
		and t1.SearchGUID = @GUID
		and t1.ResultText is not null	-- skip empty result sets for this table
		and not exists 
	(
		select 1 
		from ICD10SearchResult as t2 
		where t1.ResultText = t2.ResultText 
			and t1.ResultCode = t2.ResultCode 
			and isnull(t1.RelativeValue, '') = isnull(t2.RelativeValue, '')
			and isnull(t1.SelectionInd, 0) = isnull(t2.SelectionInd, 0)
	)

	-- populate bridge table ICD10SearchHistory (one-to-many relationship between ICD10SearchPhrase and ICD10SearchResult)
	insert into ICD10SearchHistory (ICD10SearchPhraseID, ICD10SearchResultID, RowInsertedDT)
	select p.ICD10SearchPhraseID, r.ICD10SearchResultID, @Timestamp
	from
		ICD10SearchPhrase as p
		join ICD10SearchHistoryRaw as raw on p.ParmWordCombined = raw.SearchPhrase
		join ICD10SearchResult as r 
			on raw.ResultText = r.ResultText
			and raw.ResultCode = r.ResultCode
			and isnull(raw.RelativeValue, '') = isnull(r.RelativeValue, '')
			and isnull(raw.SelectionInd, 0) = isnull(r.SelectionInd, 0)
	where
		raw.RowInsertedDT = @MinRowInsertDT
		and raw.SearchGUID = @GUID
		and raw.ResultText is not null		-- skip empty result sets for this table
		and not exists 
	(
		select 1 
		from ICD10SearchHistory as h
		where p.ICD10SearchPhraseID = h.ICD10SearchPhraseID 
			and r.ICD10SearchResultID = h.ICD10SearchResultID
	)

	update ICD10SearchPhrase set UsageStatus = 1 where ICD10SearchPhraseID = @PhraseID		-- this allows ParmWordCombined to be used for searches (now that all parsing is complete)

	DELETE from ICD10SearchHistoryRaw where RowInsertedDT = @MinRowInsertDT and SearchGUID = @GUID

	if @UseWAITFOR = 1
	BEGIN
		if not exists (select 1 from ICD10SearchHistoryRaw)		
			waitfor delay @strWaitMins		-- allows minimizing frequency of SQL Agent job schedule to avoid bloating the job history log
											-- for example: job runs every 10 minutes, but wait 5 minutes here to see if any records appear for parsing
		else
			waitfor delay @strWaitSecs		-- allows throttling the parsing iterations if desired
	END
END

print 'Executed with parameter settings: ' + char(13) + 
	'@UseWAITFOR = ' + cast(@UseWAITFOR as varchar) + char(13) +
	'@strWaitMins = ' + @strWaitMins + ' (hh:mm)' + char(13) + 
	'@strWaitSecs = ' + @strWaitSecs + ' (hh:mm:ss)' + char(13)

GO
