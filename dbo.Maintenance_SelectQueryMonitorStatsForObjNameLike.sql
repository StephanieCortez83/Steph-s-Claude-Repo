SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_SelectQueryMonitorStatsForObjNameLike] 
	@ObjectName VARCHAR(1000)
WITH EXEC AS CALLER AS
BEGIN
	-------------------------------
	-- setup resources
	-------------------------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SET @ObjectName = '%' + @ObjectName + '%'

	SELECT
		 DurationSecs = DATEDIFF(second, RequestStartTime, AuditDT)
		,RequestStartTime
		,AuditDT
		,login_name
		,LogicalReads
		,Query
		,ExecutingStmt
	FROM
		[queryMonitorArchive]
	WHERE
		query LIKE @ObjectName
		AND monitorProcName NOT LIKE '%full%'
		AND AuditDT IN (
			SELECT 
				MaxAuditDT = MAX(AuditDT)
			FROM
				queryMonitorArchive
			WHERE
				query LIKE @ObjectName
				AND monitorProcName NOT LIKE '%full%'
			GROUP BY RequestStartTime, query
		)
	ORDER BY
		RequestStartTime, AuditDT;

END -- end procedure

GO
