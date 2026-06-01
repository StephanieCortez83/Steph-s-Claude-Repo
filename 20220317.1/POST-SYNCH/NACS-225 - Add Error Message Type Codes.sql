USE [RevCycleDB]
GO

INSERT INTO [dbo].[ERROR_MESSAGE_TYPE_CODE]
           ([ERROR_MESSAGE_TYPE_CODE]
           ,[KEY]
           ,[DISPLAY_NAME]
           ,[EXTERNAL_CODE]
           ,[DESCRIPTION])
SELECT 700, 'DateGreaterThanDischargeDate', '{0} must be on or before the Discharge Date of {1}.',null,null
UNION 
SELECT 701, 'DischargeDateDisabled', 'Discharge must be enabled.',null,null

GO


