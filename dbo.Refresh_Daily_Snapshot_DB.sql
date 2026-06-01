SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[Refresh_Daily_Snapshot_DB]
WITH EXEC AS CALLER
AS
-- Drop database snapshot if it already exists
IF EXISTS (
	SELECT name 
		from master.sys.databases
		where name = 'RevCycleDB_Snapshot'
)
DROP DATABASE RevCycleDB_Snapshot;

-- Create the database snapshot
-- 2/3/2013 JohnS: Changed FILENAME from D:\RevCycleDB_Snapshot\RevCycleDB_Snapshot.ss
--                 to U:\RevCycleDB_Snapshot.ss after SAN migration.
CREATE DATABASE RevCycleDB_Snapshot ON 
(NAME = RevCycleDB, FILENAME = 'U:\Data\RevCycleDB_Snapshot.ss'),
(NAME = FGData1_File1, FILENAME = 'U:\Data\RevCycleDB_FGD1F1_Snapshot.ss'),
(NAME = FGData2_File1, FILENAME = 'U:\Data\RevCycleDB_FGD2F1_Snapshot.ss'),
(NAME = FGIndex1_File1, FILENAME = 'U:\Data\RevCycleDB_FGI1F1_Snapshot.ss'),
(NAME = FGIndex2_File1, FILENAME = 'U:\Data\RevCycleDB_FGI2F1_Snapshot.ss')
AS SNAPSHOT OF RevCycleDB;

GO
