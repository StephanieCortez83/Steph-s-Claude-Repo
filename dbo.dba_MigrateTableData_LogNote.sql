SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- NOTE: need to create a two-key NC index (at least temporarily) on Log_Note_ID and Changed_Date_Time (in that key column order) in LOG_NOTE or else LReads will grow significantly higher and higher as the copy table grows in size.

create   procedure [dbo].[dba_MigrateTableData_LogNote]
	@BatchSize int = 10					-- If 10 rows at a time doesn't cause issues, try bumping up to 20, 50, 100, etc. Probably should not go higher than 1000.
	, @AnalyzePerformance bit = 0
as
BEGIN
	if @AnalyzePerformance = 1
	BEGIN
		set nocount off;
		set statistics io on;
	END

	declare @MaxID bigint
	declare @MaxCreateDT datetime
	declare @MaxChangedDT datetime

	select @MaxID = isnull(max(Log_Note_ID), 0) from Log_Note_BigInt
	select @MaxCreateDT = isnull(max(Creation_Date_Time), '1/1/1900') from Log_Note_BigInt
	select @MaxChangedDT = isnull(max(Changed_Date_Time), '1/1/1900') from Log_Note_BigInt

	declare @MinChangedID bigint
	select @MinChangedID = min(Log_Note_ID) from Log_Note where Changed_Date_Time > @MaxChangedDT

	truncate table Staging_Log_Note

	-- process updated records
	if @AnalyzePerformance = 1
		print 'looking for updated records ...'

	while exists 
		(
			select top 1 1
			from Log_Note 
			where Changed_Date_Time > @MaxChangedDT		-- creating a single-column NC index on Changed_Date_Time should keep LReads of this subquery under control as the copy table grows in size.
				  AND Log_Note_ID between @MinChangedID and @MaxID
				  AND Log_Note_ID not in (Select Log_Note_ID from Staging_Log_Note)
		)
	begin
		if @AnalyzePerformance = 1
			print 'inserting updated records to Staging ...'

		INSERT into Staging_Log_Note
			--select TOP 10 *
			--select TOP 100 *
			--select TOP 1000 *
			select TOP (@BatchSize) *
			FROM Log_Note 
			WHERE Changed_Date_Time > @MaxChangedDT 
				  AND Log_Note_ID between @MinChangedID and @MaxID
				  AND Log_Note_ID not in (Select Log_Note_ID from Staging_Log_Note)
			--Order By Log_Note_ID		-- not necessary?  not as performant?
	end

	if exists (select 1 from Staging_Log_Note)
	BEGIN
		-- remove existing records of updated rows
		if @AnalyzePerformance = 1
			print 'deleting for updated rows ...'

		DELETE 
		FROM Log_Note_BigInt 
		FROM Log_Note_BigInt as t1
			 JOIN Staging_Log_Note as t2 
		 ON t1.Log_Note_ID= t2.Log_Note_ID 

		-- insert updated records to target
		if @AnalyzePerformance = 1
			print 'inserting updated rows to target ...'

		set identity_insert Log_Note_BigInt ON
		INSERT into Log_Note_BigInt (Log_Note_ID, Chart_ID, Summary, Detail, System_Defined, Completion_Date, Completed_By_User_ID, Category_ID, Chart_Adjustment_ID, Creation_Date_Time, Creating_User_Profile_ID, Changed_Date_Time, Changing_User_Profile_ID)
			select *
			from Staging_Log_Note
			order by Log_Note_ID
		set identity_insert Log_Note_BigInt OFF

		if @AnalyzePerformance = 1
			print 'truncating staging table ...'
		truncate table Staging_Log_Note
	END

	-- process new records
	if @AnalyzePerformance = 1
		print 'inserting new records to staging ...'

	INSERT into Staging_Log_Note
		--select TOP 10 *
		--select TOP 100 *
		--select TOP 1000 *
		select TOP (@BatchSize) *
		FROM Log_Note  
		WHERE Log_Note_ID  > @MaxID 
		Order By Log_Note_ID

	-- remove existing records of new rows if they somehow exist
	if @AnalyzePerformance = 1
		print 'deleting for new rows ...'

	DELETE 
	FROM Log_Note_BigInt 
	FROM Log_Note_BigInt as t1
		 JOIN Staging_Log_Note as t2 
	 ON t1.Log_Note_ID= t2.Log_Note_ID 

	-- insert new records to target
	if @AnalyzePerformance = 1
		print 'inserting new records to target ...'

	set identity_insert Log_Note_BigInt ON
	INSERT into Log_Note_BigInt (Log_Note_ID, Chart_ID, Summary, Detail, System_Defined, Completion_Date, Completed_By_User_ID, Category_ID, Chart_Adjustment_ID, Creation_Date_Time, Creating_User_Profile_ID, Changed_Date_Time, Changing_User_Profile_ID)
		select *
		from Staging_Log_Note
		order by Log_Note_ID
	set identity_insert Log_Note_BigInt OFF

	if @AnalyzePerformance = 1
		print 'truncating staging table ...'
	truncate table Staging_Log_Note

	set nocount on;
	set statistics io off;
END
GO
