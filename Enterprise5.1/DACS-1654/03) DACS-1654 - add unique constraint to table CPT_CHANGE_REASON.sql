--------------------------------------------------------------
-- 03) DACS-1654 - add unique constraint to table CPT_CHANGE_REASON.sql
--------------------------------------------------------------
USE [RevCycleDB]
GO

BEGIN TRAN

ALTER TABLE [RevCycleDB].[dbo].[CPT_CHANGE_REASON] 
	ADD CONSTRAINT UNQ_CptChangeReason  
       UNIQUE  
       ( 
		   [SERVICE_AGREEMENT_ID]
		  ,[DISPLAY_NAME]
		  ,[DESCRIPTION]
		  ,[EFFECTIVE_DATE]
		  ,[EXPIRATION_DATE] 
       );

COMMIT TRAN
-- ROLLBACK TRANSACTION
	   
GO

/*
-- test of unique constraint:
-- should fail:
insert into [RevCycleDB].[dbo].[CPT_CHANGE_REASON]
([DISPLAY_NAME],[DESCRIPTION],[EFFECTIVE_DATE])
values
('CPT Bundle Rule','CPT Bundle Rule','2022-06-01')


*/