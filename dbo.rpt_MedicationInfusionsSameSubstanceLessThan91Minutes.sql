SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 10/30/2014
-- Description:	SQL for the Medication Infusion with Same Substance less than 91 Minutes report.
-- Includes only results where 96366 units >= 1.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_MedicationInfusionsSameSubstanceLessThan91Minutes]
	-- Add the parameters for the stored procedure here
	@ReportUser INT,
	@UserProfileID VARCHAR(MAX) = NULL,
	@SentFrom DATETIME,
	@SentThru DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	DECLARE @m_ReportUser INT = @ReportUser,
		@m_UserProfileID VARCHAR(MAX) = @UserProfileID,
		@m_SentFrom DATETIME = @SentFrom,
		@m_SentThru DATETIME = DATEADD(MINUTE, - 1, DATEADD(DAY, 1, @SentThru));

	-- Default to all account managers is not valued
	IF (
			@m_UserProfileID IS NULL
			OR @m_UserProfileID = ''
			)
	BEGIN
		SET @m_UserProfileID = (
				SELECT STUFF((
							SELECT DISTINCT ',' + CONVERT(VARCHAR, USER_PROFILE_ID)
							FROM SERVICE_AGREEMENT_MANAGEMENT_TEAM
							WHERE MANAGEMENT_TEAM_ROLE_ID = 1
							FOR XML PATH('')
							), 1, 1, '')
				);
	END

	SELECT *
	FROM (
		SELECT f.NAME FACILITY,
			c.FACILITY_CHART_ID,
			(
				SELECT SUM(cir.UNITS)
				FROM CHART_INFUSION_RESULT cir WITH (NOLOCK)
				INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID
				WHERE cir.CHART_ID = c.CHART_ID
					AND cm.CPT_CODE = '96366'
				) UNITS_96366,
			SUM(DATEDIFF(MINUTE, ci.[START_DATE], ci.[STOP_DATE])) TOTAL_MINUTES,
			COUNT(*) TOTAL_MED_INFUSIONS,
			up.LAST_NAME + ', ' + up.FIRST_NAME ACCOUNT_MANAGER,
			up.EMAIL_ADDRESS
		FROM CHART c WITH (NOLOCK)
		INNER JOIN SERVICE_AGREEMENT_MANAGEMENT_TEAM samt WITH (NOLOCK) ON samt.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND MANAGEMENT_TEAM_ROLE_ID = 1
		INNER JOIN USER_PROFILE up WITH (NOLOCK) ON up.USER_PROFILE_ID = samt.USER_PROFILE_ID
		INNER JOIN CHART_INFUSION ci WITH (NOLOCK) ON ci.CHART_ID = c.CHART_ID
		INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
		WHERE c.CHART_STATUS_ID = 5 -- Sent
			AND ci.INFUSION_TYPE = 1 -- Medication Infusion
			AND ci.[START_DATE] IS NOT NULL
			AND ci.[STOP_DATE] IS NOT NULL
			AND ISNULL([NO_STOP_TIME], 0) = 0
			AND c.SENT_DATE >= @m_SentFrom
			AND c.SENT_DATE <= @m_SentThru
			AND EXISTS (
				SELECT *
				FROM SERVICE_AGREEMENT_MANAGEMENT_TEAM WITH (NOLOCK)
				WHERE USER_PROFILE_ID IN (
						SELECT *
						FROM dbo.SplitString(@m_UserProfileID, ',')
						)
					AND SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				)
			AND EXISTS (
				SELECT *
				FROM FACILITY_USER_AUTHORIZATION WITH (NOLOCK)
				WHERE USER_PROFILE_ID = @m_ReportUser
					AND FACILITY_ID = c.FACILITY_ID
				)
		GROUP BY f.NAME,
			c.SERVICE_AGREEMENT_ID,
			c.CHART_ID,
			c.FACILITY_CHART_ID,
			ci.SUBSTANCE_NUMBER,
			ci.INFUSION_TYPE,
			up.USER_PROFILE_ID,
			up.LAST_NAME,
			up.FIRST_NAME,
			up.EMAIL_ADDRESS
		HAVING COUNT(*) > 1
			AND SUM(DATEDIFF(MINUTE, ci.[START_DATE], ci.[STOP_DATE])) < 91
		) x
	WHERE UNITS_96366 >= 1
	ORDER BY FACILITY,
		FACILITY_CHART_ID
END
GO
GRANT EXECUTE ON  [dbo].[rpt_MedicationInfusionsSameSubstanceLessThan91Minutes] TO [dbx_ExecuteReportProcs]
GO
