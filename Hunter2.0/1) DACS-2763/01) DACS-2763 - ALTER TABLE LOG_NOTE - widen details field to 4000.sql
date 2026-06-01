-----------------------------------------------------------------------------
-- 01) DACS-2763 - ALTER TABLE LOG_NOTE - widen details field to 4000.sql
-----------------------------------------------------------------------------
USE [RevCycleDB];
GO

/*
  DBA, if needed please uncomment the table lock after this comment.
  Probably not needed but the target table has high record count and high use.
  Metadata change only, so might just be a case of being a bit paranoid on my part.
  Pippin
*/
-- SELECT	TOP (1) 1 FROM	[dbo].[LOG_NOTE] WITH (TABLOCKX)

ALTER TABLE [dbo].[LOG_NOTE] ALTER COLUMN [DETAIL] VARCHAR (4000) NULL;

GO
