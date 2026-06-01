----------------------------------------
-- 06) DACS-645 - Alter Table - Add unique constraint and Index to [dbo].[PhysicianServiceEvalDiagnosis].sql
----------------------------------------
USE [RevCycleDB]
GO

-- index group fields = [ChartId], [PhysicianServiceProcId], [PhysicianServiceLevelNumber], [DateOfService], [CptCode]
ALTER TABLE [RevCycleDB].[dbo].[PhysicianServiceEvalDiagnosis] 
	ADD CONSTRAINT UNQ_PhysicianServiceEvalDiagnosis  
       UNIQUE  
       ( 
		     [ChartId]
		   , [PhysicianServiceProcId]
		   , [PhysicianServiceLevelNumber]
		   , [DateOfService]
		   , [CptCode]
	   );
	   
GO

CREATE INDEX ix_PhysicianServiceEvalDiagnosis_CidPspIdPslnDosCpt  
	ON [RevCycleDB].[dbo].[PhysicianServiceEvalDiagnosis] 
		(	
			 [ChartId]
		   , [PhysicianServiceProcId]
		   , [PhysicianServiceLevelNumber]
		   , [DateOfService]
		   , [CptCode]
		)		 
		ON FGIndex1;

GO