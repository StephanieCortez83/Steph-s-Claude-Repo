USE [RevCycleDB]
GO

CREATE TRIGGER [dbo].[ChartPostBillAudit_Completed] ON [dbo].[ChartPostBillAudit]
WITH EXEC AS CALLER
AFTER UPDATE
AS

DECLARE @errorCount INT
DECLARE @ChartId INT
DECLARE @newStatusId INT
DECLARE @chartPostBillAuditId INT
DECLARE @CompletedChartVersionId int;

SELECT 
	@chartId = i.ChartId,
	@chartPostBillAuditId = i.ChartPostBillAuditId, 
	@newStatusID = i.[ChartPostBillAuditStatusTypeCode] 
FROM inserted i;

SELECT @CompletedChartVersionId = isnull([ChartAuditVersionId],0)
FROM [dbo].[ChartAuditVersion] WHERE [ChartAuditId] = @chartPostBillAuditId and [VersionNumber] = 2;

IF @newStatusId in (3)
BEGIN

	-- If this is a new PBA structure or not.
	IF @CompletedChartVersionID > 0
	BEGIN
		select @errorCount = count(*) From 
		(
			SELECT ChartAuditAnesthesiaVersionItemId as versionItemId FROM ChartAuditAnesthesiaVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0
	
			UNION

			SELECT ChartAuditDemographicVersionItemId as versionItemId FROM ChartAuditDemographicVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0
	
			UNION

			SELECT ChartAuditDocumentationVersionItemId as versionItemId FROM ChartAuditDocumentationVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0

			UNION

			SELECT ChartAuditFacilityLOSVersionItemId as versionItemId FROM ChartAuditFacilityLOSVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0

			UNION

			SELECT ChartAuditPhysicianLOSVersionItemId as versionItemId FROM ChartAuditPhysicianLOSVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0

			UNION

			-- rules on procedures can vary, so this captures the non OBS procedure count.
			SELECT ChartAuditProcedureVersionItemId as versionItemId FROM ChartAuditProcedureVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0 AND ProcedureType <> 'OB'

			UNION

			-- rules on procedures can vary, so this captures the OBS procedure.
			SELECT ChartAuditProcedureVersionItemId as versionItemId FROM ChartAuditProcedureVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,3,5) and ExcludeFromQA = 0 AND ProcedureType = 'OB'

			UNION

			-- rules on dx codes can vary.  This captures counts for non primary.
			SELECT ChartAuditDiagnosisVersionItemId as versionItemId FROM ChartAuditDiagnosisVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0 and IsPrimary = 0
	
			UNION

			-- rules on dx codes can vary.  This captures counts for primary.
			SELECT ChartAuditDiagnosisVersionItemId as versionItemId FROM ChartAuditDiagnosisVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,3,5) and ExcludeFromQA = 0 and DiagnosisTypeID in (2,3) AND IsPrimary = 1

			UNION

			-- rules on dx codes can vary.  This captures chief complaints.
			SELECT ChartAuditDiagnosisVersionItemId as versionItemId FROM ChartAuditDiagnosisVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,3,5) and ExcludeFromQA = 0 and DiagnosisTypeID not in (2,3) AND IsPrimary = 1

		) as result
	END
	ELSE
	-- else get the error count using the old table.
	BEGIN

		Select @errorCount = count(*) from
		(
				Select [CHART_POST_BILL_AUDIT_REVIEW_ID]
				FROM [dbo].[CHART_POST_BILL_AUDIT_REVIEW] WHERE [CHART_ID] = @chartId
				AND (ISNULL([FACILITY_SVC_ERROR],0) > 0 
				OR ISNULL([INFUSION_ERROR],0) > 0
				OR ISNULL([PHYSICIAN_SVC_ERROR],0) > 0
				OR ISNULL([DIAGNOSIS_ICD10_ERROR],0) > 0
				OR ISNULL([OBSERVATION_HOURS_ERROR],0) > 0
				OR ISNULL([OBSERVATION_PROCEDURES_ERROR],0) > 0
				OR ISNULL([OBSERVATION_INFUSIONS_ERROR],0) > 0
				OR ISNULL([PHYSICIAN_PROCEDURE_ERROR],0) > 0
				OR ISNULL([PHYSICIAN_SVC_ERROR],0) > 0
				OR ISNULL([DEMOGRAPHIC_ERROR],0) > 0
				OR ISNULL([FACILITY_PROCEDURE_ERROR],0) > 0
				)
		) As result2

	END

	-- update the ChartPostBillAudit with the calculated errors in the PBA.
	UPDATE ChartPostBillAudit SET ErrorCount = @errorCount WHERE ChartPostBillAuditId = @chartPostBillAuditID
END

GO