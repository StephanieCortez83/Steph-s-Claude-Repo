SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[ICD10SearchPhrase_RemoveSpecifiedPhrase]
(@SearchPhraseID int)
as

set nocount on

if not exists (select 1 from ICD10SearchPhrase where ICD10SearchPhraseID = @SearchPhraseID)
BEGIN
	print 'No record is found where ICD10SearchPhraseID = ' + cast(@SearchPhraseID as varchar) + '.'
	RETURN
END
else
BEGIN
	delete from ICD10SearchHistory where ICD10SearchPhraseID = @SearchPhraseID
	delete from ICD10SearchPhrase where ICD10SearchPhraseID = @SearchPhraseID
	--delete from ICD10SearchResult where ICD10SearchResultID not in (Select ICD10SearchResultID from ICD10SearchHistory)		-- moved this to final step in SQL Agent job
END

GO
