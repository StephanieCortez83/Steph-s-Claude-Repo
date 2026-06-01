------------------------------------------------------
-- 03) DACS-1674 - update PhysicianService into ChartAuditSectionTypeCode.sql
------------------------------------------------------
USE [RevCycleDB]
GO

-- if needed:
-- select top 20 * FROM ChartAuditSectionTypeCode;

-- adjust older key
UPDATE [dbo].[ChartAuditSectionTypeCode]
    SET [Key] = 'PhysicianService',
        [DisplayName] = 'Physician Service',
        [Description] = 'Physician Service Audit Section'
	WHERE [Key] = 'ProcedureService'

-- delete this key:
DELETE FROM [dbo].[chartauditsectiontypecode]
	WHERE [Key] = 'PhysicianEvaluation';	

GO
