USE [RevCycleDB]
GO

INSERT INTO [dbo].[ChartAuditSectionTypeCode]
           ([ChartAuditSectionTypeCode]
           ,[Key]
           ,[DisplayName]
           ,[ExternalCode]
           ,[Description])
     VALUES
           (12
           ,'MedicalNecessity'
           ,'Medical Necessity'
           ,'MN'
           ,'Medical Necessity Section')
GO