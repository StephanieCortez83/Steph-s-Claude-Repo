SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE procedure [dbo].[dba_Purge_Setup]
(
	@FacilityID int,									-- use the Facility_ID value as indicated in the purge request
	@ExpectedChartCnt int,								-- Provide the expected chart count which was indicated in the purge request. The sproc will exit if this count doesn't match what is found in the database.
															-- This is an important validation that helps prevent accidentally purging the wrong facility. 
	@StartDT datetime = '1/1/1900',						-- use '1/1/1900' in most cases.
	@EndDT datetime = '12/31/9999 23:59:59',			-- use '12/31/9999 23:59:59' if all charts for the specified facility are to be purged.
	@ChartStatusID int = NULL,							-- use NULL if not filtering on a specific value for chart_status_ID
	@ChartTablePurgeMode varchar(20) = 'DELETE',		-- use 'DELETE' in most cases.  Should be 'UPDATE' if purging *practice* charts (by special request) and chart_status_ID filter in (4, 5).
	@IsPracticeChartPurge int = 0,						-- Use 0 in most cases.  If a special request has been made to purge practice charts, use 1. Defined as int to support intentional configuration of either 0 or 1.
	@ServiceAgreementID int = 0							-- If more than one service agreement exists for the specified Facility_ID, specify the applicable SAID to be purged. 
															-- So far there has never been more than one SAID per FacilityID in the SERVICE_AGREEMENT table. The purge was designed to be driven from Facility_ID, not Service_Agreement_ID.

)
AS
set nocount on;

declare @FoundChartCnt int
declare @FacilityName varchar(500)
declare @ExpirationDT datetime

select @FacilityName = name from Facility where Facility_ID = @FacilityID
select @ExpirationDT = Expiration_Date from Service_Agreement where Facility_ID = @FacilityID 

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

if isdate(@StartDT) = 0
begin
	Print 'Please enter a valid date value for @StartDT.'
	RETURN;
end

if isdate(@EndDT) = 0
begin
	Print 'Please enter a valid date value for @EndDT.'
	RETURN;
end

if @StartDT >= @EndDT
begin
	Print '@StartDT must be < @EndDT.'
	RETURN;
end

if @StartDT >= @ExpirationDT
begin
	Print '@StartDT must be prior to the facility''s ServiceAgreement expiration date. Use 1/1/1900 if purging all chart data for the facility.'
	RETURN;
end

if not exists (select * from Chart_Status where chart_status_ID = isnull(@ChartStatusID, 1))
begin
	Print 'No rows exist in the Chart_Status table matching the value provided for @ChartStatusID.  Historically, valid values have been 1-8.'
	RETURN;
end


if @ChartTablePurgeMode not in ('Delete', 'Update')
begin
	Print '@ChartTablePurgeMode must be either ''DELETE'' or ''Update''.  Use ''DELETE'' in most cases.'
	RETURN;
end

if @ChartTablePurgeMode = 'UPDATE' and isnull(@ChartStatusID, 0) not in (4, 5)
begin
	Print 'UPDATE purge mode should only be used for practice charts, in which case @ChartStatusID must be either 4 or 5.'
	RETURN	-- exit without further execution
end;


if @IsPracticeChartPurge not in (0, 1)
begin
	Print '@IsPracticeChartPurge should be configured as either 0 (true) or 1 (false).'
	RETURN	-- exit without further execution
end;


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


if exists (Select 1 From RevCycleImages.dbo.IMPORT_IMAGE Where Facility_ID = @FacilityID)
BEGIN
	Print 'Records for Facility_ID ' + cast(@FacilityID as varchar(10)) + ' still exist in the IMPORT_IMAGE table. 
	Those records (and their associated images in the file system) must first be deleted by Colin Nance or someone on his team before running this purge process.'

	Print 'Rerun this stored procedure after the image data has been deleted.'
	RETURN;
END

select @FoundChartCnt = count(*) from Chart where Facility_ID = @FacilityID;
--if not exists (Select 1 From CHART Where Facility_ID = @FacilityID)
if @FoundChartCnt = 0
BEGIN
	Print 'No chart data exists for Facility_ID ' + cast(@FacilityID as varchar(10)) + ' (' + @FacilityName + '). There is nothing to purge.'

	RETURN;
END

if @FoundChartCnt <> @ExpectedChartCnt
BEGIN
	Print '@ExpectedChartCnt = ' + cast(@ExpectedChartCnt as varchar(10)) + '. Actual chart count for Facility_ID ' + cast(@FacilityID as varchar(10)) + ' is ' + cast(@FoundChartCnt as varchar(10)) + '. 
	The facility name for that Facility_ID is ' + @FacilityName + '. 
	Verify you entered the correct value for @FacilityID. Make sure you did not confuse Service_Agreement_ID for Facility_ID.'

	RETURN;
END

if exists (Select 1 From DBA.dbo.PurgeFacilityProgress Where ChartCount <> PurgedCount and LastPurgeDT > '1/1/2022')	-- Counts were sometimes off by one or two prior to 2022. Something was probably changed back then to fix that.
BEGIN
	Print 'At least one facility row in DBA.dbo.PurgeFacilityProgress needs attention due to having this criteria: Where ChartCount <> PurgedCount and LastPurgeDT > ''1/1/2022'''
	Print 'Make sure any such facilities are completely purged before beginning to purge another facility.'
	RETURN;
END



declare @RowsInserted int

declare @FacilityPurgeIteration int					-- Increases by one each time a specific facility is repeatedly purged (e.g. the weekly purge for Facility 492). Uniqueness in PurgeFacilityProgress is the combination of Facility_ID and FacilityPurgeIteration.
select @FacilityPurgeIteration = isnull(max(FacilityPurgeIteration)+1, 1) from DBA..PurgeFacilityProgress where facility_ID = @FacilityID


-- populate PurgeFacilityProgress
if not exists (select 1 from DBA..PurgeFacilityProgress where facility_ID = @FacilityID and FacilityPurgeIteration = @FacilityPurgeIteration)
begin
	insert into DBA..PurgeFacilityProgress (Facility_ID, ChartCount, PurgedCount, Filter_ChartStatusID, Filter_StartDT, Filter_EndDT, FacilityPurgeIteration, RowInsertedDT, ChartTablePurgeMode, IsPracticeChartPurge, Service_Agreement_ID)
		select Facility_ID, count(*), 0, @ChartStatusID, @StartDT, @EndDT, @FacilityPurgeIteration, GetDate(), @ChartTablePurgeMode, @IsPracticeChartPurge, service_agreement_ID
		from CHART with(NOLOCK)
		where Facility_ID = @FacilityID 
			and IsNull(Time_Of_Service, Creation_Date_Time) between @StartDT and @EndDT
			and chart_status_ID = IsNull(@ChartStatusID, chart_status_ID)
			and service_agreement_ID = @ServiceAgreementID
		group by Facility_ID, Service_Agreement_ID;

	if @@ROWCOUNT > 0
		print 'A row for Facility_ID ' + cast(@FacilityID as varchar(10)) + ' was inserted into DBA.dbo.PurgeFacilityProgress.';
	else
		print 'No rows were inserted for Facility_ID ' + cast(@FacilityID as varchar(10)) + '.'
end;
else
begin
	RAISERROR('See message below', 16, 1) with nowait;
	print 'A row for Facility_ID ' + cast(@FacilityID as varchar(10)) + ' already exists in DBA.dbo.PurgeFacilityProgress with the same value for FacilityPurgeIteration. Reconfigure with a different value for FacilityPurgeIteration and try again.';
	RETURN
end;

-- populate PurgeFacilityChart_QUEUE
insert into DBA..PurgeFacilityChart_QUEUE 
	(Facility_ID, Chart_ID, Service_Agreement_ID, Facility_Chart_ID, Creation_Date_Time, Chart_Status_ID, FacilityPurgeIteration, ChartStatusFilter, ChartTablePurgeMode, Time_Of_Service)
select Facility_ID, Chart_ID, Service_Agreement_ID, Facility_Chart_ID, Creation_Date_Time, Chart_Status_ID, @FacilityPurgeIteration, 
		ChartStatusFilter = case @ChartStatusID when null then 0 else @ChartStatusID end,			
		ChartTablePurgeMode = @ChartTablePurgeMode		
		, Time_Of_Service
	from CHART with(NOLOCK)
	where 
		Facility_ID = @FacilityID
		and IsNull(Time_Of_Service, Creation_Date_Time) between @StartDT and @EndDT	
		and chart_status_ID = IsNull(@ChartStatusID, chart_status_ID) 
		and Chart_ID not in (select chart_ID from DBA..PurgeFacilityChart_QUEUE)
		and service_agreement_ID = @ServiceAgreementID		-- when only one row exists in SERVICE_AGREEMENT for the specified FacilityID, @ServiceAgreementID is automatically set to the SAID of that one matching row. Otherwise, SAID must be specified.

select @RowsInserted = @@ROWCOUNT
print cast(@RowsInserted as varchar(10)) + ' rows were inserted into table DBA.dbo.PurgeFacilityChart_QUEUE for Facility_ID ' + cast(@FacilityID as varchar(10)) + '.';


-- review results 
select Description = 'Parameters for this purge iteration.', Facility_ID, FacilityPurgeIteration, RowCnt = count(*), MaxDOS = max(Time_Of_Service), ChartStatusFilter, chart_status_ID, ChartTablePurgeMode from DBA..PurgeFacilityChart_QUEUE where Facility_ID = @FacilityID and PurgedDT is null group by Facility_ID, ChartStatusFilter, chart_status_ID, FacilityPurgeIteration, ChartTablePurgeMode
select FacilityName = f.name, p.* from Facility as f join DBA..PurgeFacilityProgress as p on f.Facility_ID = p.Facility_ID where f.Facility_ID = @FacilityID order by p.FacilityPurgeIteration desc


GO
