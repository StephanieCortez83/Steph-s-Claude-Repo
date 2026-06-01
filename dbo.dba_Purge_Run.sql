SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[dba_Purge_Run]
-- The parameter values below should match corresponding parameter values in the script Purge_Step1_Setup.

(
	@PurgeTargetServer sysname,							-- Data will be purged from the designated server (usually prcmsqlaz04). For testing, change the value to TRCMSQLAZ04 (Staging) and run this script on that server.
	@FacilityID int,									-- If restarting the purge, make sure the correct facility_ID is designated here.
	@ExpectedChartCnt int,								-- Provide the expected chart count which was indicated in the purge request. The sproc will exit if this count doesn't match what was configured by dba_Purge_Setup.
															-- This is an important validation which helps prevent accidentally purging the wrong facility. 
	@FacilityPurgeIteration int,						-- Corresponds to a column in PurgeFacilityProgress to identify the applicable row in that table (along with @FacilityID).
	--@PurgeCutoffDate datetime,							-- Only charts where IsNull(Time_Of_Service, Creation_Date_Time) <= the cutoff date will be deleted, but that is determined by @EndDT in the script Purge_Step1_Setup. In this script, @PurgeCutoffDate is only used for logging info.

	--@ChartStatusID int,									-- Corresponds to Chart_Status_ID. See notes below: 
	/*
	Effect of @ChartStatusID:
		0 = no filtering (applicable records in CHART table will be deleted regardless of Chart_Status_ID)
		1-n = only charts with the indicated value for chart_Status_ID will have their related data purged
		(For Practice Charts) If chart_status_ID in (4,5) and @ChartTablePurgeMode = 'UPDATE', delete records only in child tables of CHART, and update applicable rows in CHART.
	*/

	--@ChartTablePurgeMode varchar(10),					-- use 'DELETE' in most cases.  Should be 'UPDATE' if purging *practice* charts (by special request) and chart_status_ID filter in (4, 5).
	--@IsPracticeChartPurge bit,							-- use 0 in most cases.  If a special request has been made to purge practice charts, use 1.	
	@ChartBatchSize int = 10,							-- Determines how many Chart_IDs will be deleted at a time from each table. To minimize potential locking/blocking, a low number such as 10 is recommended.	

	@LoggingLevel int = 2,								-- use 2 in most cases.
	@SendEmailForBadConfig int = 0,						-- Determines if questionable config will generate an email notification in addition to the error message that is returned.
	@SendEmailForPurgeCompletion int = 1,				-- Suggested setting = 0 when purging many small facilities.
	@ServiceAgreementID int = 0							-- If more than one service agreement exists for the specified Facility_ID, specify the applicable SAID to be purged. 
															-- So far there has never been more than one SAID per FacilityID in the SERVICE_AGREEMENT table. The purge was designed to be driven from Facility_ID, not Service_Agreement_ID.

	/*
	Logging level descriptions
	1 = least logging (only logs summary purge info at the batch level)
	2 = medium logging (logs at the table level for each table where at least 1 row was purged)
	3 = most logging (logs at the table level for every table looked at, even if no rows were purged) 
	*/

)
as
set nocount on;

SET DEADLOCK_PRIORITY -10	-- range (-10 ... 10)

declare @ChartStatusID int
declare @PurgeCutoffDate datetime
declare @ChartTablePurgeMode varchar(20)
declare @IsPracticeChartPurge bit
declare @ConfiguredChartCnt int
declare @FacilityName varchar(500)
declare @ExpirationDT datetime
declare @PurgedCnt int

select @FacilityName = name from Facility where Facility_ID = @FacilityID
select @ExpirationDT = Expiration_Date from Service_Agreement where Facility_ID = @FacilityID 
select 
	@ChartStatusID = isnull(Filter_ChartStatusID, 0), 
	@PurgeCutoffDate = Filter_EndDT, 
	@ChartTablePurgeMode = ChartTablePurgeMode,
	@IsPracticeChartPurge = IsPracticeChartPurge
from DBA.dbo.PurgeFacilityProgress 
where Facility_ID = @FacilityID and FacilityPurgeIteration = @FacilityPurgeIteration;



if @FacilityID is null
begin
	Print '@FacilityID can not be NULL.'
	RETURN;
end

if @FacilityID < 1
begin
	Print '@FacilityID must be > 0.'
	RETURN;
end

if @ExpectedChartCnt is null
begin
	Print '@ExpectedChartCnt can not be NULL.'
	RETURN;
end

if @ExpectedChartCnt < 1
begin
	Print '@ExpectedChartCnt must be > 0.'
	RETURN;
end

if @ChartBatchSize > 100
begin
	Print '@ChartBatchSize must be <= 100.  Use 10 in most cases (to minimize performance impact on ACS).'
	RETURN;
end


if @LoggingLevel not in (1, 2, 3)
begin
	Print '@LoggingLevel must be 1, 2, or 3.  Use 2 in most cases.'
	RETURN;
end


if @ServiceAgreementID > 0 
	and @ServiceAgreementID not in (Select service_Agreement_ID from service_agreement where facility_ID = @FacilityID)
begin
	Print 'The value specified for @ServiceAgreementID is not found in SERVICE_AGREEMENT for the specified Facility_ID.  Enter a valid value, or disable the line for @ServiceAgreementID if not needed (most common scenario).'
	RETURN	-- exit without further execution
end

if 1 < (select count(*) from service_agreement where facility_ID = @FacilityID)
	--and @ServiceAgreementID = 0
begin
	if @ServiceAgreementID = 0
	BEGIN
		Print 'More than one service agreement exists for the specified Facility_ID. Get approval for which SAID to purge. Then rerun this script and specify the applicable SAID using @ServiceAgreementID.'
		RETURN	-- exit without further execution
	END
end
else
	select @ServiceAgreementID = service_agreement_ID from Service_Agreement where facility_ID = @FacilityID	-- Assign the SAID of the one matching row


if exists (Select 1 From IMPORT_IMAGE Where Facility_ID = @FacilityID)
BEGIN
	Print 'Records for Facility_ID ' + cast(@FacilityID as varchar(10)) + ' still exist in the IMPORT_IMAGE table. 
	Those records (and their associated images in the file system) must first be deleted by Colin Nance or someone on his team before running this purge process.'

	Print 'Rerun this stored procedure after the image data has been deleted.'
	RETURN;
END

select @ConfiguredChartCnt = ChartCount from DBA.dbo.PurgeFacilityProgress where Facility_ID = @FacilityID and FacilityPurgeIteration = @FacilityPurgeIteration;
--select @FoundChartCnt = count(*) from Chart where Facility_ID = @FacilityID;
if @ConfiguredChartCnt <> @ExpectedChartCnt
BEGIN
	Print '@ExpectedChartCnt = ' + cast(@ExpectedChartCnt as varchar(10)) + '. Actual chart count for Facility_ID ' + cast(@FacilityID as varchar(10)) + ' before purging is ' + cast(@ConfiguredChartCnt as varchar(10)) + '. 
	The facility name for that Facility_ID is ' + @FacilityName + '. 
	Verify you entered the correct value for @FacilityID. Make sure you did not confuse Service_Agreement_ID for Facility_ID.'

	RETURN;
END

if @ChartTablePurgeMode = 'UPDATE' and (@ChartStatusID not in (4, 5) OR @IsPracticeChartPurge = 0)
begin
	RAISERROR('UPDATE purge mode should only be used for practice charts, in which case @ChartStatusID must be either 4 or 5.  This batch will exit without purging any tables.', 1, 1)

	if @SendEmailForBadConfig = 1
	begin
		EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'TSystem_Client_Services'
			,@recipients = 'SQLAdmin@CorroHealth.com'
			,@body = ''
		,@subject = 'Questionable Purge Configuration. Purge mode of "UPDATE" does not correlate with @ChartStatusID and/or @IsPracticeChart.'
	end

	RETURN	-- exit without further execution
end;

if @ChartTablePurgeMode = 'DELETE' and @IsPracticeChartPurge = 1 and @ChartStatusID in (4, 5)
begin
	RAISERROR('DELETE purge mode should NOT be used for practice charts having chart_status_ID in (4, 5).  This batch will exit without purging any tables.', 1, 1)

	if @SendEmailForBadConfig = 1
	begin
		EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'TSystem_Client_Services'
			,@recipients = 'SQLAdmin@CorroHealth.com'
			,@body = ''
			,@subject = 'Questionable Purge Configuration. Purge mode of "DELETE" does not correlate with @ChartStatusID and/or @IsPracticeChart.'
	end

	RETURN	-- exit without further execution
end;


if not exists 
(
	select 1 
	from DBA..PurgeFacilityProgress 
	where
		Facility_ID = @FacilityID
		and FacilityPurgeIteration = @FacilityPurgeIteration 
		and PurgedCount < ChartCount
)
begin
	RAISERROR('There are no entries in PurgeFacilityProgress that match the setting for @FacilityPurgeIteration and have charts to be purged.  This batch will exit without purging any tables.', 1, 1)

	if @SendEmailForBadConfig = 1
	begin
		EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'TSystem_Client_Services'
			,@recipients = 'SQLAdmin@CorroHealth.com'
			,@body = ''
			,@subject = 'Questionable Purge Configuration. No records found in PurgeFacilityProgress that correlate with @FacilityPurgeIteration.'
	end

	RETURN	-- exit without further execution
end;


if @ChartStatusID is null		-- not in (0, 1, 2)
begin
	RAISERROR('Invalid value for @ChartStatusID.  This batch will exit without purging any tables.', 1, 1)

	if @SendEmailForBadConfig = 1
	begin
		EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'TSystem_Client_Services'
			,@recipients = 'SQLAdmin@CorroHealth.com'
			,@body = ''
			,@subject = 'Questionable Purge Configuration. @ChartStatusID is null.'
	end

	RETURN	-- exit without further execution
end;


--if @ChartStatusID = 1 and exists (select 1 from PurgeFacilityChart_Queue where chart_status_ID not in (4, 5))
if @ChartStatusID <> 0 and exists (select 1 from DBA..PurgeFacilityChart_Queue where chart_status_ID <> @ChartStatusID)
begin
	RAISERROR('There are charts in PurgeFacilityChart_Queue with Chart_Status_ID values that do not correspond with the setting for @ChartStatusID.  This batch will exit without purging any tables.', 1, 1)

	if @SendEmailForBadConfig = 1
	begin
		EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'TSystem_Client_Services'
			,@recipients = 'SQLAdmin@CorroHealth.com'
			,@body = ''
			,@subject = 'Questionable Purge Configuration. Records in PurgeFacilityChart_Queue do not correlate with @ChartStatusID.'
	end

	RETURN	-- exit without further execution
end;

/*
if @ChartStatusID = 2 and exists (select 1 from PurgeFacilityChart_Queue where chart_status_ID <> 6)
begin
begin
	RAISERROR('There are charts in PurgeFacilityChart_Queue with Chart_Status_ID values that do not correspond with the setting for @ChartStatusID.  This batch will exit without purging any tables.', 1, 1)

	EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'TSystem_Client_Services'
		,@recipients = 'david.sexton@CorroHealth.com'
		,@body = ''
		,@subject = 'Questionable Purge Configuration.'

	RETURN	-- exit without further execution
end;
*/

--select Facility_ID, MinCreateDT = min(Creation_Date_Time) from DBA..PurgeFacilityChart group by Facility_ID order by MinCreateDT
--select count(*) from DBA..PurgeFacilityChart where Facility_ID = @FacilityID and Creation_Date_Time < @PurgeCutoffDate and PurgedDT is null

IF object_ID('TempDB..##PurgeFacilities', 'U') is not null DROP TABLE ##PurgeFacilities;
SELECT Facility_ID INTO ##PurgeFacilities 
FROM DBA..PurgeFacilityProgress 
WHERE	--(Facility_ID = @FacilityID or @FacilityID = -1) 
	Facility_ID = @FacilityID
	and FacilityPurgeIteration = @FacilityPurgeIteration 
	and PurgedCount < ChartCount
ORDER BY Facility_ID;

IF @@ServerName = @PurgeTargetServer	
BEGIN
	declare @ChartID int;
	declare @ExecutionDT datetime = getdate();
	declare @BatchTimestamp datetime;
	declare @msg varchar(2000);
	declare @MinChartID int;
	declare @MaxChartID int;
	declare @MinDOS datetime;
	declare @MaxDOS datetime;
	declare @RowCount int;
	declare @RowsAffected int;
	declare @TimeStart datetime;
	declare @DBName sysname;
	declare @TableName sysname;
	declare @ColumnName sysname;
	declare @cmd varchar(500);

	IF object_ID('TempDB..##PurgeCharts', 'U') is not null DROP TABLE ##PurgeCharts;
	--CREATE TABLE ##PurgeCharts (Chart_ID int, Creation_Date_Time datetime, Chart_Status_ID int);
	CREATE TABLE ##PurgeCharts (Chart_ID int, Creation_Date_Time datetime, Time_Of_Service datetime, Chart_Status_ID int);		-- added Time_Of_Service  1/22/2020, dsexton

	IF object_ID('TempDB..#TransmissionBatchIDs', 'U') is not null DROP TABLE #TransmissionBatchIDs;
	CREATE TABLE #TransmissionBatchIDs (Transmission_Batch_ID int);

	IF object_ID('TempDB..#ChargeReconIDs', 'U') is not null DROP TABLE #ChargeReconIDs;
	CREATE TABLE #ChargeReconIDs (Charge_Reconciliation_ID int);

	IF object_ID('TempDB..#ChartAuditVersionIDs', 'U') is not null DROP TABLE #ChartAuditVersionIDs;
	CREATE TABLE #ChartAuditVersionIDs (ChartAuditVersionId int);
	
	IF object_ID('TempDB..#TableList', 'U') is not null DROP TABLE #TableList;
	SELECT PurgeOrderPhase, DBName, TableName, JoinColumnName1, Processed = 0
	  INTO #TableList 
	FROM DBA..PurgeTable
	WHERE 
		TableName <> 'TRANSMISSION_BATCH_ITEM'					-- delete separately, but before deleting CHART due to FK constraint in Transmission_Batch_Item on Chart_ID
			and JoinColumnName1 <> 'Transmission_Batch_ID'		-- other Transmission_Batch* tables are grouped together with Transmission_Batch_Item in a separate section
		and TableName not in ('CHARGE_RECONCILIATION', 'CHARGE_RECONCILIATION_MODIFIER')	-- in a separate section - they need special handling since deletes on Charge_Reconciliation are driven by combo of Facility_Chart_ID and Service_Agreement_ID instead of just Chart_ID.
		and TableName <> 'ChartPostBillAudit'  -- Deleted separately. Referenced by FK in ChartAuditVersion which itself is reference by other ChartAuditVersion* tables.
			and JoinColumnName1 not in ('ChartAuditID', 'ChartAuditVersionID', 'ChartAuditFacilityLosVersionItemID', 'ChartAuditPhysicianLosVersionItemID')	-- ChartAudit* tables are grouped together with ChartPostBillAudit in a separate section
		and TableName <> 'CHART'	-- Delete CHART last in a separate section



	WHILE EXISTS (Select 1 From ##PurgeFacilities)
	BEGIN -- Loop 1
		SELECT TOP 1 @FacilityID = Facility_ID FROM ##PurgeFacilities order by Facility_ID;

		insert into DBA..PurgeFacilityChart		-- to help performance, periodically archive PurgeFacilityChart records where PurgeDT is not null
			select * from DBA..PurgeFacilityChart_Queue where Facility_ID = @FacilityID and FacilityPurgeIteration = @FacilityPurgeIteration
				and (@ChartStatusID = 0 OR @ChartStatusID = Chart_Status_ID)
				and Service_agreement_ID = @ServiceAgreementID				-- added 10/8/2023 (dsexton)

		delete from DBA..PurgeFacilityChart_Queue where facility_ID = @FacilityID and FacilityPurgeIteration = @FacilityPurgeIteration 
			and (@ChartStatusID = 0 OR @ChartStatusID = Chart_Status_ID)
			and Service_agreement_ID = @ServiceAgreementID					-- added 10/8/2023 (dsexton)
			and chart_ID in (select chart_ID from DBA..PurgeFacilityChart)

		WHILE EXISTS (Select 1 From DBA..PurgeFacilityChart Where Facility_ID = @FacilityID and FacilityPurgeIteration = @FacilityPurgeIteration and Service_Agreement_ID = @ServiceAgreementID and PurgedDT is null)	-- added SAID criteria 10/8/2023 (dsexton)
			/*and Creation_Date_Time < @PurgeCutoffDate*/ 
		BEGIN -- Loop 2
			set @BatchTimestamp = getdate();
			set @RowsAffected = 0;

			INSERT INTO ##PurgeCharts (Chart_ID, Creation_Date_Time, Time_Of_Service, Chart_Status_ID)			-- added Time_Of_Service 1/22/2020, dsexton
				Select top (@ChartBatchSize) Chart_ID, Creation_Date_Time, Time_Of_Service, Chart_Status_ID
				From DBA..PurgeFacilityChart 
				Where Facility_ID = @FacilityID 
					--and Creation_Date_Time < @PurgeCutoffDate 
					and FacilityPurgeIteration = @FacilityPurgeIteration					-- added 1/22/2020, dsexton
					and (@ChartStatusID = 0 OR @ChartStatusID = Chart_Status_ID)			-- added 1/22/2020, dsexton
					and Service_Agreement_ID = @ServiceAgreementID							-- added 10/8/2023 (dsexton)
					and PurgedDT is null
				Order By chart_ID; 

			select @MinChartID = min(Chart_ID) from ##PurgeCharts;
			select @MaxChartID = max(Chart_ID) from ##PurgeCharts;
			select @MinDOS = min(IsNull(Time_Of_Service, Creation_Date_Time)) from ##PurgeCharts;
			select @MaxDOS = max(IsNull(Time_Of_Service, Creation_Date_Time)) from ##PurgeCharts;
			
			BEGIN TRY
				UPDATE #TableList SET Processed = 0
				WHILE EXISTS (Select 1 From #TableList Where Processed = 0)
				BEGIN
					set @RowCount = 0;
					
					SELECT top 1 @DBName = DBName, @TableName = TableName, @ColumnName = JoinColumnName1 FROM #TableList WHERE Processed = 0 ORDER BY PurgeOrderPhase DESC, DBName, TableName;

					SET @cmd = 'DELETE FROM [' + @DBName + '].dbo.[' + @TableName + '] where [' + @ColumnName + '] IN (Select chart_ID from ##PurgeCharts)'
					set @Timestart = getdate();
					--print @cmd
					EXEC (@cmd)
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;

					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, @DBName, @TableName, @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					--DELETE FROM #TableList WHERE DBName = @DBName and TableName = @TableName;
					UPDATE #TableList SET Processed = 1 WHERE DBName = @DBName and TableName = @TableName;
				END;				

				------------------------------------------------------------------------------------------------------------------
				-- must include TRANSMISSION_BATCH_ITEM due to FK constraint referencing CHART
					
				INSERT INTO #TransmissionBatchIDs (Transmission_Batch_ID)
					SELECT DISTINCT Transmission_Batch_ID FROM TRANSMISSION_BATCH_ITEM WHERE Chart_ID IN (Select Chart_ID From ##PurgeCharts);
						
					set @RowCount = 0;
					set @Timestart = getdate();

				--DELETE FROM [RevCycleDB].dbo.[TRANSMISSION_BATCH_ITEM] where Chart_ID IN (Select chart_ID from ##PurgeCharts);		-- must delete all based on Transmission_Batch_ID due to FK referencing TRANSMISSION_BATCH
				DELETE FROM TRANSMISSION_BATCH_ITEM where Transmission_Batch_ID IN (Select Transmission_Batch_ID from #TransmissionBatchIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'TRANSMISSION_BATCH_ITEM', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM TRANSMISSION_BATCH_FILE WHERE Transmission_Batch_ID IN (Select Transmission_Batch_ID From #TransmissionBatchIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'TRANSMISSION_BATCH_FILE', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM TRANSMISSION_BATCH_ADJUSTMENT WHERE Transmission_Batch_ID IN (Select Transmission_Batch_ID From #TransmissionBatchIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'TRANSMISSION_BATCH_ADJUSTMENT', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM TRANSMISSION_BATCH WHERE Transmission_Batch_ID IN (Select Transmission_Batch_ID From #TransmissionBatchIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'TRANSMISSION_BATCH', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

				TRUNCATE TABLE #TransmissionBatchIDs;

				------------------------------------------------------------------------------------------------------------------

				INSERT INTO #ChargeReconIDs (Charge_Reconciliation_ID)
					SELECT DISTINCT cr.CHARGE_RECONCILIATION_ID 
					FROM CHARGE_RECONCILIATION as cr
						join DBA..PurgeFacilityChart as pfc
							on pfc.service_agreement_ID = cr.SERVICE_AGREEMENT_ID
							and pfc.facility_Chart_ID = cr.facility_Chart_ID
					WHERE pfc.chart_ID in (Select chart_ID from ##PurgeCharts);


					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM CHARGE_RECONCILIATION_MODIFIER where CHARGE_RECONCILIATION_ID IN (Select CHARGE_RECONCILIATION_ID from #ChargeReconIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'CHARGE_RECONCILIATION_MODIFIER', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;


					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM CHARGE_RECONCILIATION where CHARGE_RECONCILIATION_ID IN (Select CHARGE_RECONCILIATION_ID from #ChargeReconIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'CHARGE_RECONCILIATION', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

				TRUNCATE TABLE #ChargeReconIDs;

				-------------------------------------------------------------------------------------------------------------------


				INSERT INTO #ChartAuditVersionIDs (ChartAuditVersionID)
					SELECT DISTINCT ChartAuditVersionID FROM ChartAuditVersion WHERE ChartAuditID IN 
						(select ChartPostBillAuditID from ChartPostBillAudit where chartID in 
							(Select Chart_ID From ##PurgeCharts));
						
					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditAnesthesiaVersionItem where ChartAuditVersionID IN (Select ChartAuditVersionID from #ChartAuditVersionIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditAnesthesiaVersionItem', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditDemographicVersionItem where ChartAuditVersionID IN (Select ChartAuditVersionID from #ChartAuditVersionIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditDemographicVersionItem', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditDiagnosisVersionItem where ChartAuditVersionID IN (Select ChartAuditVersionID from #ChartAuditVersionIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditDiagnosisVersionItem', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditDocumentationVersionItem where ChartAuditVersionID IN (Select ChartAuditVersionID from #ChartAuditVersionIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditDocumentationVersionItem', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;


-- BEGIN new section for ChartAuditFacilityLosEvalVersionItem -- added 4/26/2024 by dsexton
					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditFacilityLosEvalVersionItem where ChartAuditFacilityLosVersionItemId IN
					(Select ChartAuditFacilityLosVersionItemId FROM ChartAuditFacilityLosVersionItem where ChartAuditVersionID IN 
						(Select ChartAuditVersionID from #ChartAuditVersionIDs)
					);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditFacilityLosEvalVersionItem', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;
-- END new section for ChartAuditFacilityLosEvalVersionItem -- added 4/26/2024 by dsexton

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditFacilityLosVersionItem where ChartAuditVersionID IN (Select ChartAuditVersionID from #ChartAuditVersionIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditFacilityLosVersionItem', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;


-- BEGIN new section for ChartAuditPhysicianLosEvalVersionItem -- added 4/26/2024 by dsexton
					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditPhysicianLosEvalVersionItem where ChartAuditPhysicianLosVersionItemId IN
					(Select ChartAuditPhysicianLosVersionItemId FROM ChartAuditPhysicianLosVersionItem where ChartAuditVersionID IN 
						(Select ChartAuditVersionID from #ChartAuditVersionIDs)
					);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditPhysicianLosEvalVersionItem', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;
-- END new section for ChartAuditPhysicianLosEvalVersionItem -- added 4/26/2024 by dsexton



					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditPhysicianLosVersionItem where ChartAuditVersionID IN (Select ChartAuditVersionID from #ChartAuditVersionIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditPhysicianLosVersionItem', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditProcedureVersionItem where ChartAuditVersionID IN (Select ChartAuditVersionID from #ChartAuditVersionIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditProcedureVersionItem', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditVersionComment where ChartAuditVersionID IN (Select ChartAuditVersionID from #ChartAuditVersionIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditVersionComment', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartAuditVersion where ChartAuditVersionID IN (Select ChartAuditVersionID from #ChartAuditVersionIDs);
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartAuditVersion', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;

					set @RowCount = 0;
					set @Timestart = getdate();
				DELETE FROM ChartPostBillAudit where chartID in (Select Chart_ID From ##PurgeCharts)	-- delete ChartPostBillAudit here because it is referenced by FK in ChartAuditVersion
					SET @RowCount = @@ROWCOUNT
					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'ChartPostBillAudit', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;


				TRUNCATE TABLE #ChartAuditVersionIDs;

				-------------------------------------------------------------------------------------------------------------------
				--PRINT 'All child tables were successfully purged during this batch.  Facility_ID = ' + cast(@FacilityID as varchar(10)) + '. ChartBatchSize = ' + cast(@ChartBatchSize as varchar(10)) + '.  Duration (ms) = ' + cast(DateDiff(millisecond, @BatchTimestamp, GetDate()) as varchar(10)) + '. Chart_ID range = ' + cast(@MinChartID as varchar(10)) + ' to ' + cast(@MaxChartID as varchar(10)) + '.'
			END TRY
			BEGIN CATCH
				RAISERROR('An error was raised while purging child tables, passing execution to the CATCH statement.  This batch will exit without purging the CHART table.', 1, 1)
				set @msg = 'Facility_ID = ' + cast(@FacilityID as varchar(10)) + '. ChartBatchSize = ' + cast(@ChartBatchSize as varchar(10)) + '.  Duration (ms) = ' + cast(DateDiff(millisecond, @BatchTimestamp, GetDate()) as varchar(10)) + '. Chart_ID batch range = ' + cast(@MinChartID as varchar(10)) + ' to ' + cast(@MaxChartID as varchar(10)) + '.'
				RAISERROR(@msg, 1, 1)

				EXEC msdb.dbo.sp_send_dbmail 
					 @profile_name = 'TSystem_Client_Services'
					,@recipients = 'SQLAdmin@CorroHealth.com'
					,@body = ''
					,@subject = 'Error during ACS Chart Purge. Place 1'

				RETURN	-- exit without further execution
			END CATCH;

			BEGIN TRY		-- delete from CHART only if no errors were encountered while deleting from child tables.
					set @RowCount = 0;
					set @Timestart = getdate();

				--IF @ChartStatusID = 0
				IF @ChartTablePurgeMode = 'DELETE' and @ChartStatusID = 0
				BEGIN
					DELETE FROM CHART where Chart_ID IN (Select chart_ID from ##PurgeCharts);
					SET @RowCount = @@ROWCOUNT;
				END
				ELSE
				--IF @ChartStatusID = 2	-- delete practice charts (where chart_status_ID = 6)
				IF @ChartTablePurgeMode = 'DELETE' and @ChartStatusID <> 0
				BEGIN
					DELETE FROM CHART where Chart_ID IN (Select chart_ID from ##PurgeCharts where Chart_Status_ID = @ChartStatusID);
					SET @RowCount = @@ROWCOUNT;
				END
				ELSE
				--IF @ChartStatusID = 1	-- update practice charts (where chart_status_ID in (4, 5)
				IF @ChartTablePurgeMode = 'UPDATE' and @IsPracticeChartPurge = 1 and @ChartStatusID in (4, 5)
				BEGIN
					UPDATE CHART
					SET CHART_STATUS_ID = 1, PENDING_REASON_ID = -1, ASSIGNED_TO_ID = 80, COMPLETION_DATE = NULL, COMPLETED_BY_USER_PROFILE_ID = -1, START_QA_DATE = NULL, START_QA_USER_PROFILE_ID = NULL, APPROVED_DATE = NULL, APPROVED_BY_USER_PROFILE_ID = -1, SENT_DATE = NULL, 
						SENT_BY_USER_PROFILE_ID = -1, FACILITY_LEVEL_ID = -1, OVERRIDE_FACILITY_LEVEL_ID = -1, PHYSICIAN_SERVICE_PROC_ID = -1, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1, ACCIDENT_DATE = NULL, 
						ADD_24_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL = 0, ADD_59_XU_MODIFIER = 0, ADD_GC_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL = 0, ADD_GE_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL = 0, ADD_MODIFIER_32_TO_PHYSICIAN_LOS = 0,
						ADD_MODIFIER_57_TO_PHYSICIAN_LOS = 0, ADD_MODIFIER_GW_TO_PHYSICIAN_LOS = 0, ADD_PHYSICIAN_SVC_25_MODIFIER = 0, ADDITIONAL_COMPLAINT = NULL, ADDITIONAL_COMPLAINT2 = NULL, ADDITIONAL_CRITICAL_CARE_UNITS = 0,
						ANESTHESIA_CODING_AUDIT_COMMENT = NULL, ANESTHESIA_CODING_COMPLETE = 0, ATTESTATION_SIGNED_BY_ATTENDING = 0, AUDIT_REQUIRED = 0, AUDITOR_REVIEW_FEEDBACK = '', CHANGED_DATE_TIME = GetDate(), CHANGING_USER_PROFILE_ID = 2,
						CHIEF_COMPLAINT = NULL, CLIENT_COMMENT = NULL, CODER_COMMENT = NULL, DEMOGRAPHIC_AUDIT_COMMENT = NULL, DEMOGRAPHICS_COMPLETED = 0, DIAGNOSIS_CODING_AUDIT_COMMENT = NULL, DIAGNOSIS_CODING_COMPLETE = 0,
						DO_NOT_APPLY_PHYSICIAN_MODIFER_25 = 0, DOCUMENTATION_COMPLETED = 0, DOCUMENTATION_EVALUATION_OK = 0, EDITED_BY_EXPERT = 0, EVER_COMPLETED = 0, EXCLUDE_OBSERVATION_DIRECT_CHARGE	= 0, FAC_PROC_COMPLETED = 0,
						FAC_SVCS_COMPLETED = 0, FACILITY_CRITICAL_CARE = 0, FACILITY_CRITICAL_CARE_CALC_METHOD_CD = -1, FACILITY_CRITICAL_CARE_MINUTES = 0, FACILITY_CRITICAL_CARE_START_DATE = NULL, FACILITY_CRITICAL_CARE_STOP_DATE = NULL,
						FACILITY_LEVEL_CODER_COMMENT = NULL, FACILITY_LOS_27_MODIFIER = 0, FACILITY_PROCEDURES_AUDIT_COMMENT = NULL, FACILITY_SERVICE_LEVEL_AUDIT_COMMENT = NULL, FLAGGED_FOR_AUDIT = 0, FLAGGED_FOR_POST_BILL_AUDIT = 0,
						FLAGGED_FOR_POST_BILL_AUDIT_DT = NULL, FORCED_AUDIT = 0, FRACTURE_CARE_CPT_CHARGED = 0, INFUSION_INJECTION_AUDIT_COMMENT = NULL, INFUSION_INJECTION_REQUIRES_DOS_PLUS_2 = 0, INFUSION_INJECTION_RESULTS_LOCKED = 0,
						INFUSIONS_COMPLETED = 0, INSUFFICIENT_PHYSICIAN_PROCEDURE_DOC = 0, INSUFFICIENT_PHYSICIAN_PROCEDURE_REASON_ID = 1, IS_PRIORITY = 0, MODIFIER_25_REQUIRED_REASON_ID = -1, NO_ACTIVITY_CODES = 0, 
						NO_ANESTHESIA_CODING = 0, NO_ATTENDING_PROVIDER_SELECTED_IND = 0, NO_DIAGNOSIS_CODING = 0, NO_FACILITY_PROCEDURES = 0, NO_FACILITY_SERVICES = 0, NO_INJECTIONS_OR_INFUSIONS = 0, NO_IVS_OR_FACILITY_PROCEDURES = 0,
						NO_LCD_SERVICES = 0, NO_OBSERVATION_HOURS = 0, NO_PHYSICIAN_LOS_REASON_ID = -1, NO_PHYSICIAN_PROCEDURES = 0, NO_PHYSICIAN_SERVICES = 0, NO_PREBILL_AUDIT = 0, NO_SUPPLIES = 0, NON_ER_PROCEDURES_OVERRIDE = 0,
						OBS_DEPT_EVAL_COMPLETED = 0, OBSERVATION_AUDITOR_REVIEW_FEEDBACK = NULL, OBSERVATION_BILLING_METHOD_CD = -1, OBSERVATION_COMPLETED_BY_USER_PROFILE_ID = -1, OBSERVATION_COMPLETION_DTTM = NULL,
						OBSERVATION_DISCHARGE_PROVIDER_ID = -1, OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT = NULL, OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = -1, OBSERVATION_PROCEDURES_AUDIT_COMMENT = NULL,
						OBSERVATION_TELEMETRY = 0, ORGAN_DONATION = 0, OVERRIDE_LCD_ERRORS = 0, OVERRIDE_PHYS_EXAM_ID = -1, OVERRIDE_PHYS_HIST_ID = -1, OVERRIDE_PHYS_MDM_ID = -1, OVERRIDE_PHYSICIAN_SERVICE_GUIDELINE_ID = -1,
						PATIENT_DISPOSITION_DESTINATION_ID = -1, PATIENT_DISPOSITION_ID = -1, PATIENT_DISPOSITION_MAP_ID = -1, /*PENDING_REASON_ID = -1,*/ PHYS_COMPLETED = -1, PHYS_PROC_COMPLETED = -1, PHYSICIAN_CRITICAL_CARE = -1,
						PHYSICIAN_CRITICAL_CARE_CALC_METHOD_CD = -1, PHYSICIAN_CRITICAL_CARE_MINUTES = 0, PHYSICIAN_CRITICAL_CARE_START_DATE = NULL, PHYSICIAN_CRITICAL_CARE_STOP_DATE = NULL, PHYSICIAN_EXAM_ID = -1,
						PHYSICIAN_HISTORY_ID = -1, PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID = -1, PHYSICIAN_LEVEL_CODER_COMMENT = NULL, PHYSICIAN_MDM_ID = -1, PHYSICIAN_PROCEDURES_AUDIT_COMMENT = NULL, PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT = NULL,
						PHYSICIAN_SERVICE_MOD = NULL, PHYSICIAN_SERVICE_OBSERVATION_ADMIT_DATETIME = NULL, PHYSICIAN_SERVICE_OBSERVATION_DISCHARGE_DATETIME = NULL, PHYSICIAN_SERVICE_OBSERVATION_FINAL_EXAM = NULL,
						PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID = NULL, PHYSICIAN_SIGNATURE_PRESENT = 0, POST_BILL_AUDIT_COMPLETED = NULL, POST_BILL_AUDIT_COMPLETED_BY_USER_ID = NULL, POST_BILL_AUDIT_STARTED = NULL,
						POST_BILL_AUDIT_STARTED_BY_USER_ID = NULL, POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE = NULL, PREBILL_AUDIT_COMPLETED = 0, PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID = NULL, PRIMARY_CARE_PHYSICIAN_ID = NULL,
						PRIMARY_COMPLAINT = NULL, PROVIDER_EVAL_PERFORMED_BY_IND = NULL, QUALIFIED_FOR_SECOND_AUDIT_AT_COMPLETION = 0, REASON_FOR_VISIT_CATEGORY_DETAIL_ID = NULL, REPORT_ADDITIONAL_COMPLAINT_AS_SECONDARY = 0,
						REPORT_ADDITIONAL_COMPLAINT2_AS_SECONDARY = 0, REPORT_CHIEF_COMPLAINT_AS_SECONDARY = 0, RESIDENT_CPT_ENTIRELY_PRESENT = NULL, RESIDENT_CPT_PRESENT_DURING_KEY_PORTION = NULL, RESIDENT_ID = -1,
						RESIDENT_PARTICIPATED_IN_CARE = 0, RESIDENT_PHYS_INDEPENDENT_DISCUSSED = 0, RESIDENT_PHYS_INDEPENDENT_PERSONALLY_SAW = 0, RESIDENT_PHYS_INDEPENDENT_REF_RES_NOTES = 0, RESIDENT_PHYS_PRESENT = 0, 
						RESIDENT_PHYS_PRESENT_DISCUSSED_PLAN = 0, RESIDENT_PHYS_PRESENT_REF_RES_NOTES = 0, RESULTS_COMPLETED = 0, SAFETY_DEVICE_CD = NULL, SCRIBE_ID = -1, SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID = NULL,
						SECOND_LEVEL_QA_APPROVED_DATETIME = NULL, SEEN_IN_ED_WITHIN_48_HOURS_OF_OR = 0, SERIAL_CODE = NULL, SERVICE_AGREEMENT_ADMIT_TYPE_ID = NULL, SERVICE_AGREEMENT_ARRIVAL_MODE_ID = NULL,	
						SERVICE_AGREEMENT_MODE_OF_DEPARTURE_ID = NULL, SERVICE_AGREEMENT_TRANSFER_FACILITY_ID = NULL, SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = NULL, SERVICE_LINE_ID = NULL, SERVICES_PERFORMED_BY_RESIDENT = 0,
						SPORT_TYPE_CD = NULL, START_SECOND_LEVEL_QA_DATETIME = NULL, START_SECOND_LEVEL_QA_USER_PROFILE_ID = NULL, SUBSEQUENT_VISIT_CODE = NULL, SUPPLIES_COMPLETED = 0, TIME_BASED_CHARGE_CAPTURE_COMMENT = NULL,
						TIME_BASED_PHYSICIAN_LOS = NULL, TIME_OF_DIS = NULL, TIME_OF_PHYS_DIS = NULL, TIME_OF_PHYS_EVAL = NULL, TIME_OF_PHYSICIAN_EVAL_NOT_AVAILABLE = NULL, TIME_OF_TRIAGE = NULL, TIME_OF_TRIAGE_NOT_AVAILABLE = NULL,
						TIME_TO_ROOM = NULL, TIME_TO_ROOM_NOT_AVAILABLE = NULL, TRIAGE_ACUITY_NOT_AVAILABLE = NULL, TRIAGE_NURSE_ID = -1, USE_INPATIENT_DOWNCODE_OPTION = NULL, USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE = NULL,
						USE_TIME_BASED_CHARGE_CAPTURE = NULL
					--WHERE Chart_ID IN (Select chart_ID from ##PurgeCharts where Chart_Status_ID in (4,5));
					WHERE Chart_ID IN (Select chart_ID from ##PurgeCharts where Chart_Status_ID = @ChartStatusID);
					SET @RowCount = @@ROWCOUNT;
				END
				ELSE 
				BEGIN
					--RAISERROR('Invalid value for @ChartStatusID.  No action will be taken on the CHART table for this batch.', 1, 1)
					RAISERROR('Invalid purge configuration.  No action will be taken on the CHART table for this batch.', 1, 1)
					set @msg = 'Facility_ID = ' + cast(@FacilityID as varchar(10)) + '. ChartBatchSize = ' + cast(@ChartBatchSize as varchar(10)) + '.  Duration (ms) = ' + cast(DateDiff(millisecond, @BatchTimestamp, GetDate()) as varchar(10)) + '. Chart_ID batch range = ' + cast(@MinChartID as varchar(10)) + ' to ' + cast(@MaxChartID as varchar(10)) + '.'
					RAISERROR(@msg, 1, 1)

					EXEC msdb.dbo.sp_send_dbmail 
							@profile_name = 'TSystem_Client_Services'
						,@recipients = 'SQLAdmin@CorroHealth.com'
						,@body = ''
						,@subject = 'Questionable Purge Configuration. Chart table will not be purged this batch.'

					RETURN	-- exit without further execution
				END;


					SET @RowsAffected = @RowsAffected + @RowCount;
					IF @LoggingLevel = 3 OR (@LoggingLevel = 2 AND @RowCount > 0)
					BEGIN 
						INSERT INTO DBA..PurgeLog_ACS (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, DBName, TableName, RowsPurged, DurationMS, FIrstChartID, LastChartID, PurgeBatchDT, RowInsertedDT, ExecutionDT)
						SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, 'RevCycleDB', 'CHART', @RowCount, DateDiff(millisecond, @TimeStart, GetDate()), @MinChartID, @MaxChartID, @BatchTimestamp, GetDate(), @ExecutionDT;
					END;
								
				--PRINT 'The parent table (CHART) was successfully purged.'
			END TRY
			BEGIN CATCH
				RAISERROR('An error was raised while attempting to purge the CHART table.', 1, 1)
				set @msg = 'Facility_ID = ' + cast(@FacilityID as varchar(10)) + '. ChartBatchSize = ' + cast(@ChartBatchSize as varchar(10)) + '.  Duration (ms) = ' + cast(DateDiff(millisecond, @BatchTimestamp, GetDate()) as varchar(10)) + '. Chart_ID batch range = ' + cast(@MinChartID as varchar(10)) + ' to ' + cast(@MaxChartID as varchar(10)) + '.'
				RAISERROR(@msg, 1, 1)

				EXEC msdb.dbo.sp_send_dbmail 
					 @profile_name = 'TSystem_Client_Services'
					,@recipients = 'SQLAdmin@CorroHealth.com'
					,@body = ''
					,@subject = 'Error during ACS Chart Purge. Place 2'

				RETURN	-- exit without further execution
			END CATCH;

			while exists (select 1 from ##PurgeCharts)		-- select * from ##PurgeCharts
			BEGIN -- Loop 3
				select top 1 @chartID = chart_ID from ##PurgeCharts order by Chart_ID;

				IF (@ChartTablePurgeMode = 'DELETE' AND not EXISTS (select 1 from CHART where Chart_ID = @ChartID))
				OR (@ChartTablePurgeMode = 'UPDATE' AND EXISTS (select 1 from CHART where Chart_ID = @ChartID and 
					CHART_STATUS_ID = 1 and PENDING_REASON_ID = -1 and ASSIGNED_TO_ID = 80 and COMPLETION_DATE is NULL and COMPLETED_BY_USER_PROFILE_ID = -1))
				BEGIN
					-- Flag Chart_IDs in the work queue table which were purged.
						UPDATE DBA..PurgeFacilityChart SET PurgedDT = @BatchTimestamp WHERE facility_ID = @FacilityID and chart_ID = @ChartID and FacilityPurgeIteration = @FacilityPurgeIteration;

					-- Update the Progress summary table.
						UPDATE DBA..PurgeFacilityProgress SET PurgedCount = PurgedCount + 1, LastPurgeDT = GetDate() 
						where Facility_ID = @FacilityID and FacilityPurgeIteration = @FacilityPurgeIteration;
				END;
				ELSE
				BEGIN
					set @msg = '    *** Chart_ID ' + cast(isnull(@ChartID, 0) as varchar(10)) + ' was not entirely purged.' 
					PRINT @msg 
					EXEC msdb.dbo.sp_send_dbmail 
							@profile_name = 'TSystem_Client_Services'
						,@recipients = 'SQLAdmin@CorroHealth.com;2147979756@vtext.com'
						,@body = @msg
						,@subject = 'Incomplete purge results.'
				END;

				DELETE from ##PurgeCharts where chart_ID = @ChartID;
			END -- Loop 3
			truncate table ##PurgeCharts;

			IF @LoggingLevel > 0
			BEGIN
				INSERT INTO DBA..PurgeBatchLog (PurgeCutoffDate, Facility_ID, FacilityPurgeIteration, ChartBatchSize, FirstChartID, LastChartID, MinDOS, MaxDOS, RowsPurged, BatchDurationMS, AvgMSPerChart, AvgMSPerRow, PurgeBatchDT, RowInsertedDT, ExecutionDT)
				SELECT @PurgeCutoffDate, @FacilityID, @FacilityPurgeIteration, @ChartBatchSize, @MinChartID, @MaxChartID, @MinDOS, @MaxDOS, @RowsAffected, DateDiff(millisecond, @BatchTimestamp, getdate()), DateDiff(millisecond, @BatchTimestamp, getdate()) / @ChartBatchSize, 
					DateDiff(millisecond, @BatchTimestamp, getdate()) / CASE When @RowsAffected = 0 THEN 1 ELSE @RowsAffected END,		-- Added CASE because encountered a divide-by-zero error one time. Not sure if it was at this point.
					@BatchTimestamp, GetDate(), @ExecutionDT
			END;

		END -- Loop 2
		DELETE FROM ##PurgeFacilities WHERE Facility_ID = @FacilityID;
	END -- Loop 1
	--/*

--/*
	-- View the results:
			select Description = 'Count remaining in CHART table for FacilityID ' + cast(@FacilityID as varchar(10)) + ' with supplied parameters:', ChartCnt = count(*)  
			from Chart with(nolock) 
			where facility_ID = @FacilityID 
				and (@ChartStatusID = 0 or @ChartStatusID = chart_status_ID) 
				and IsNull(Time_Of_Service, Creation_Date_Time) <= @PurgeCutoffDate

			select TableName = 'PurgeFacilityProgress', * from DBA..PurgeFacilityProgress where lastPurgeDT > cast(getdate() as date) order by LastPurgeDT desc		--PurgedCount desc, Facility_ID
--*/
		

		--if @LoggingLevel > 1
		--	select * from PurgeLog_ACS order by ExecutionDT desc, TableName;

		--select TableName = 'PurgeFacilityChart'
		--	select * from PurgeFacilityChart where Facility_ID = 475 order by PurgedDT desc
		-- select * from RevCycleDB..Chart where chart_ID = 12485988
	--*/

	select @PurgedCnt = PurgedCount from DBA.dbo.PurgeFacilityProgress where Facility_ID = @FacilityID and FacilityPurgeIteration = @FacilityPurgeIteration
	set @msg = 'Purge of chart data for facility "' + @FacilityName + '" (Facility_ID ' + cast(@FacilityID as varchar(10)) + ') has completed.  ' + cast(@PurgedCnt as varchar(10)) + ' of ' + cast(@ConfiguredChartCnt as varchar(10)) + ' charts were purged.'

	if @SendEmailForPurgeCompletion = 1
	begin
		EXEC msdb.dbo.sp_send_dbmail 
					 @profile_name = 'TSystem_Client_Services'
					,@recipients = 'SQLAdmin@CorroHealth.com'
					,@body = @msg
					,@subject = 'ACS Chart Purge completed.'
	end

end;
else 
begin
	print 'Wrong server!'

	if @SendEmailForBadConfig = 1
	begin
		EXEC msdb.dbo.sp_send_dbmail 
					 @profile_name = 'TSystem_Client_Services'
					,@recipients = 'SQLAdmin@CorroHealth.com'
					,@body = ''
					,@subject = 'Invalid purge configuration.  Wrong server.'
	end
end
GO
