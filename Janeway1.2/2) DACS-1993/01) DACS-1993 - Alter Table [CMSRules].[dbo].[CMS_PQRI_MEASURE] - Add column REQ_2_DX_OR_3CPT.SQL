------------------------------------------------------------------------------------
-- 01) DACS-1993 - Alter Table [CMSRules].[dbo].[CMS_PQRI_MEASURE] - Add column REQ_2_DX_OR_3CPT.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing

	-- table lock because this table is used a fair amount in ACS
	SELECT TOP (1) 1 FROM [dbo].[CMS_PQRI_MEASURE] WITH (TABLOCKX)

	ALTER TABLE [dbo].[CMS_PQRI_MEASURE]
	ADD [REQ_2_DX_OR_3CPT] BIT NULL;

-- rollback tran; -- testing
-- commit tran; -- testing

GO



