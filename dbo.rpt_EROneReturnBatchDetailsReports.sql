SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 10/7/2013
-- Description:	SQL for the EROne return batch details report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_EROneReturnBatchDetailsReports]
	-- Add the parameters for the stored procedure here
	@VisitType INT = NULL,
	@AccountNumber VARCHAR(20) = NULL,
	@StartDate DATE = NULL,
	@ThruDate DATE = NULL,
	@ReportUser INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	DECLARE @m_VisitType VARCHAR(3) = @VisitType;
	DECLARE @m_AccountNumber VARCHAR(20) = @AccountNumber;
	DECLARE @m_StartDate DATE = ISNULL(@StartDate, GETDATE());
	DECLARE @m_ThruDate DATE = ISNULL(@ThruDate, GETDATE());
	DECLARE @m_ReportUser INT = @ReportUser;
	DECLARE @Today DATE = GETDATE();

	SELECT CodingChargeID,
		AccountNumber,
		DateOfService,
		CPT,
		Modifier,
		Diag1,
		Diag2,
		Diag3,
		Diag4,
		AccidentCode,
		ProviderID,
		LocumID,
		MLPID,
		OrderingPhysicianID,
		SupervisingProviderID,
		AccidentDate,
		AdmitDate,
		DischargeDate,
		DeceasedDate,
		TransferDate,
		IncidentDate,
		WorkerCompDate,
		MotorVehicleAccidentDate,
		CoderID,
		Facility,
		EncID,
		WorkingID,
		VisitID,
		Rejected,
		RejectedStatus,
		Reindexed,
		BatchDate
	FROM RCM_FLATFILE_OUTBOUND_ERONE WITH (NOLOCK)
	WHERE (
			@m_AccountNumber IS NULL
			OR AccountNumber = @m_AccountNumber
			)
		AND VisitID = CASE @m_VisitType
			WHEN 1
				THEN 'ED'
			WHEN 2
				THEN 'FAC'
			ELSE VisitID
			END
		AND BatchDate BETWEEN @m_StartDate AND @m_ThruDate
		AND EXISTS (
			SELECT *
			FROM FACILITY_USER_AUTHORIZATION fua WITH (NOLOCK)
			INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = fua.FACILITY_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.FACILITY_ID = f.FACILITY_ID
				AND @Today BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE
			WHERE USER_PROFILE_ID = @m_ReportUser
				AND sa.COMPANY_ID IN (54,55)
				AND @Today BETWEEN fua.EFFECTIVE_DATE AND fua.EXPIRATION_DATE
			)
	ORDER BY VisitID,
		Facility,
		AccountNumber,
    CPT DESC
END

GO
GRANT EXECUTE ON  [dbo].[rpt_EROneReturnBatchDetailsReports] TO [dbx_ExecuteReportProcs]
GO
