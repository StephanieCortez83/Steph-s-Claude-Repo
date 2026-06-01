----------------------------------------
-- 03) DACS-2991 - SQL Script to insert data into table - UserGroupReportAccess.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

INSERT INTO [dbo].[UserGroupReportAccess]
(
	 [DateTimeCreated]
	,[CreatedByUserProfileId]
	,[DateTimeLastUpdated]
	,[LastUpdatedByUserProfileId]
	,[EffectiveDate]
	,[UserGroupId]
	,[ReportName]
)
VALUES
-- 203 : Visionary MGMT
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Accounts by Diagnosis'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'ACS User Login Report'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Audit Rate Change History Report'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Auditor Productivity by Time to Approve'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Chart Import Count by DOS - Client'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder Performance Metrics'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder Productivity by Facility Report'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder Productivity by Time to Enter without Exclusions'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder Productivity Summary'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder Productivity Summary by Time to Enter'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder QA Detail Snapshot'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder QA Detail with Observation'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder QA Summary'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder QA Trending'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder Scorecard'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coder Trending Error Report'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Coverage Summary Report'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Daily Aged Accounts Report'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Daily Productivity Summary'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Dashboard Pending Status'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Level of Service Summary'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Level of Service Summary by Date Range'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Level of Service Trending by Quarter'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Level of Service Trending Monthly Comparison'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Patient Encounters by Physician'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Peace Health Daily Aged Accounts Report'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Post Bill Audit Report'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Production Snapshot Report'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'QA Diagnosis Changes by Facility'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'SLA Detail'),
	('02-15-2024',10149,'02-15-2024',10149,'02-15-2024',203,'Vendor SLA Summary');

