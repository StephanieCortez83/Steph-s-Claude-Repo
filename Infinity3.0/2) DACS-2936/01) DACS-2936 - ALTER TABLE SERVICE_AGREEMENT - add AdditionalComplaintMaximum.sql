-----------------------------------------------------------------------------
-- 01) DACS-2936 - ALTER TABLE SERVICE_AGREEMENT - add AdditionalComplaintMaximum.sql
-----------------------------------------------------------------------------
USE [RevCycleDB];
GO

SELECT	TOP (1) 1 FROM	[dbo].[SERVICE_AGREEMENT] WITH (TABLOCKX)

ALTER TABLE [dbo].[SERVICE_AGREEMENT]
	ADD [ADDITIONAL_COMPLAINT_MAXIMUM] INT NULL,
	CONSTRAINT [DF_ADDITIONAL_COMPLAINT_MAXIMUM] DEFAULT ((0)) FOR [ADDITIONAL_COMPLAINT_MAXIMUM];

GO
