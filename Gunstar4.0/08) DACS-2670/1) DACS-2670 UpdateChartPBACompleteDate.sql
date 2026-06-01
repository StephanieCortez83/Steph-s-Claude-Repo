USE RevCycleDB
GO

UPDATE 
    Chart
SET 
	POST_BILL_AUDIT_COMPLETED = pba.[DateTimeLastUpdated],
	POST_BILL_AUDIT_COMPLETED_BY_USER_ID = pba.[LastUpdatedByUserProfileId]
FROM 
    Chart c
    INNER JOIN [dbo].[ChartPostBillAudit] pba ON c.CHART_ID = pba.ChartId
WHERE 
    c.POST_BILL_AUDIT_COMPLETED IS NULL
	AND pba.[ChartPostBillAuditStatusTypeCode] = 3