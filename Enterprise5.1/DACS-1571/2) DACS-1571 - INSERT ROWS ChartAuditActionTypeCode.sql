USE [RevCycleDB]
GO

INSERT INTO 
    [dbo].[ChartAuditActionTypeCode]
(
    [ChartAuditActionTypeCode]
   ,[Key]
   ,[DisplayName]
   ,[ExternalCode]
   ,[Description]
)
VALUES
(
    1                   -- ChartAuditActionTypeCode
   ,'Revised'           -- Key
   ,'Revised'           -- DisplayName
   ,'R'                 -- ExternalCode
   ,'Revised'           -- Description
)
,(
    2                   -- ChartAuditActionTypeCode
   ,'Added'             -- Key
   ,'Added'             -- DisplayName
   ,'A'                 -- ExternalCode
   ,'Added'             -- Description
)
,(
    3                   -- ChartAuditActionTypeCode
   ,'AbstractChange'    -- Key
   ,'Abstract Change'   -- DisplayName
   ,'C'                 -- ExternalCode
   ,'Abstract Change'   -- Description
)
,(
    4                   -- ChartAuditActionTypeCode
   ,'NoChange'          -- Key
   ,'No Change'         -- DisplayName
   ,''                  -- ExternalCode
   ,'No Change'         -- Description
)
,(
    5                   -- ChartAuditActionTypeCode
   ,'Deleted'           -- Key
   ,'Deleted'           -- DisplayName
   ,'D'                 -- ExternalCode
   ,'Deleted'           -- Description
)