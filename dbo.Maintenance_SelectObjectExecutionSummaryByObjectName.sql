SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_SelectObjectExecutionSummaryByObjectName] 
	 @ObjectName VARCHAR(1000)
	,@AsJsonOutput BIT = 1
WITH EXEC AS CALLER AS
BEGIN
	-------------------------------
	-- setup resources
	-------------------------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @AsJsonOutput <> 1
		SELECT
			 OName = object_name(x.object_id)
			,Oid = x.object_id 
			,OType = x.type_desc
			,LastModDT = o.modify_date
			,CacheDT = cached_time 
			,LastExecDT = last_execution_time 
			,ExecCnt = execution_count
			,MinCpuMs = min_worker_time/1000
			,MaxCpuMs = max_worker_time/1000
			,AvgCpuMs = (total_worker_time/1000)/execution_count
			,MinRunMs = min_elapsed_time/1000
			,MaxRunMs = max_elapsed_time/1000
			,AvgRunMs = (total_elapsed_time/1000)/execution_count
			,MinLReads = min_logical_reads
			,MaxLReads = max_logical_reads
			,AvgLReads = total_logical_reads/execution_count
			,AuditDT = GETDATE()
		FROM
			sys.dm_exec_procedure_stats AS x
			LEFT JOIN sys.objects AS o ON x.object_id = o.object_id
		WHERE
			object_name(x.object_id) = @ObjectName;
	ELSE
		SELECT
			  '{"OName":"' + object_name(x.object_id)
			+ '","Oid":' + CAST(x.object_id AS VARCHAR(64))
			+ ',"OType":"' + CAST(x.type_desc AS VARCHAR(64))
			+ '","LastModDT":"' + CAST(o.modify_date AS VARCHAR(64))
			+ '","CacheDT":"' + CAST(cached_time AS VARCHAR(64))
			+ '","LastExecDT":"' + CAST(last_execution_time AS VARCHAR(64))
			+ '","ExecCnt":' + CAST(execution_count AS VARCHAR(64))
			+ ',"MinCpuMs":' + CAST(min_worker_time/1000 AS VARCHAR(64))
			+ ',"MaxCpuMs":' + CAST(max_worker_time/1000 AS VARCHAR(64))
			+ ',"AvgCpuMs":' + CAST((total_worker_time/1000)/execution_count AS VARCHAR(64))
			+ ',"MinRunMs":' + CAST(min_elapsed_time/1000 AS VARCHAR(64))
			+ ',"MaxRunMs":' + CAST(max_elapsed_time/1000 AS VARCHAR(64))
			+ ',"AvgRunMs":' + CAST((total_elapsed_time/1000)/execution_count AS VARCHAR(64))
			+ ',"MinLReads":' + CAST(min_logical_reads AS VARCHAR(64))
			+ ',"MaxLReads":' + CAST(max_logical_reads AS VARCHAR(64))
			+ ',"AvgLReads":' + CAST(total_logical_reads/execution_count AS VARCHAR(64))
			+ ',"AuditDT":"' + CAST(GETDATE() AS VARCHAR(64))
			+ '"}'
			AS 'RESULT'
		FROM
			sys.dm_exec_procedure_stats AS x
			LEFT JOIN sys.objects AS o ON x.object_id = o.object_id
		WHERE
			object_name(x.object_id) = @ObjectName;

/*
-- usage example
exec [dbo].[Maintenance_SelectObjectExecutionSummaryByObjectName] @ObjectName = 'SelectPhysicianProcedureEvaluationListByChartIdAndTimeOfService'
-- {"OName":"SelectPhysicianProcedureEvaluationListByChartIdAndTimeOfService","Oid":1392840870,"OType":"SQL_STORED_PROCEDURE","LastModDT":"Dec  2 2024 10:47PM","CacheDT":"Jan 24 2025  9:22AM","LastExecDT":"Jan 29 2025  6:57AM","ExecCnt":16857,"MinCpuMs":0,"MaxCpuMs":31,"AvgCpuMs":0,"MinRunMs":0,"MaxRunMs":117,"AvgRunMs":0,"MinLReads":119,"MaxLReads":367,"AvgLReads":125,"AuditDT":"Jan 29 2025 11:34AM"}
exec [dbo].[Maintenance_SelectObjectExecutionSummaryByObjectName] @ObjectName = 'SelectPhysicianProcedureEvaluationListByChartIdAndTimeOfService',@AsJsonOutput=0
*/

END -- end procedure

GO
