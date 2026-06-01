-----------------------------------------------------------------------------
-- 01) DACS-2737 - ALTER TABLE SERVICE_AGREEMENT - add column RequirePhysicianWhenPendingChart.sql
-----------------------------------------------------------------------------
USE [RevCycleDB];
GO

SELECT	TOP (1) 1 FROM	[dbo].[SERVICE_AGREEMENT] WITH (TABLOCKX)

ALTER TABLE [dbo].[SERVICE_AGREEMENT]
	ADD [REQUIRE_PHYSICIAN_WHEN_PENDING_CHART] [bit] NULL,
	CONSTRAINT [DF_REQUIRE_PHYSICIAN_WHEN_PENDING_CHART]  DEFAULT ((0)) FOR [REQUIRE_PHYSICIAN_WHEN_PENDING_CHART];

GO
