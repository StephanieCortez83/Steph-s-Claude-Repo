USE [RevCycleDB]
GO

INSERT INTO [dbo].[TYPE_CODE]
           ([NAME]
           ,[KEY]
           ,[VALUE]
           ,[DISPLAY_NAME])
SELECT 'ErrorMessageSeverityTypeCode', 'None', 0, 'None'
UNION
SELECT 'ErrorMessageSeverityTypeCode', 'Info', 1, 'Information'
UNION
SELECT 'ErrorMessageSeverityTypeCode', 'Warning', 2, 'Warning'
UNION
SELECT 'ErrorMessageSeverityTypeCode', 'Severe', 3, 'Severe'
UNION
SELECT 'ErrorMessageSeverityTypeCode', 'Exception', 4, 'Exception'
GO


