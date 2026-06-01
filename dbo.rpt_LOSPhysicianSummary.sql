SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 1/24/2014
-- Description:	SQL for the LOS Physician Summary Report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_LOSPhysicianSummary] 
    @ReportDate DATE,
	@Facility INT,
	@Physician INT,
    @PType INT = 0,
    @StartDate DATE = '1/1/1990',
    @PatientClass INT = 0, 
    @DateType INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	DECLARE @m_ReportDate DATE = @ReportDate,
		@m_Facility INT = @Facility,
		@m_Physician INT = @Physician,
		@m_PType INT = @PType,
    @m_StartDate DATE = @StartDate,
	@m_PatientClass INT = @PatientClass,
    @m_DateType INT = @DateType;

    IF @m_StartDate IS NULL
    BEGIN
      SET @m_StartDate = '1/1/1990'
    END

	SELECT f.[NAME] Facility,
		f.FACILITY_ID FacilityID,
		UPPER(ISNULL(fp.LAST_NAME + ', ' + fp.FIRST_NAME, 'Unknown')) Physician,
		ISNULL(fp.FACILITY_PROF_ID, 0) PhysicianID,
		x.DOSMonth,
		x.Disposition,
--		x.PATIENT_CLASS_ID ,
		x.TotLOS,
		x.TotLPT,
		x.TotNC,
		x.TotLOS1,
		x.TotLOS2,
		x.TotLOS3,
		x.TotLOS4,
		x.TotLOS5,
		x.TotLOS6
	FROM FACILITY f WITH (NOLOCK),
		SERVICE_AGREEMENT sa WITH (NOLOCK),
		FACILITY_PROFESSIONAL fp WITH (NOLOCK),
		(
			SELECT sp.SERVICE_AGREEMENT_ID,

			CASE 
            WHEN c.NURSE_PRACTITIONER_ID > 0
                AND (
                    c.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
                    OR c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                    )
                THEN c.NURSE_PRACTITIONER_ID
            ELSE c.PHYSICIAN_ID
            END as PHYSICIAN_ID,				

		DATEADD(MONTH, DATEDIFF(MONTH, 0, CASE @m_DateType
        WHEN 0 THEN sp.TIME_OF_SERVICE
        ELSE sp.SENT_DATE END), 0) DOSMonth,

				CASE 
					WHEN pd.OUTPATIENT_IND = 1
						THEN 'Outpatient'
					WHEN pd.PATIENT_DISPOSITION_ID IN (
							2,
							3,
							4,
							5
							)
						THEN 'Admitted'
					ELSE 'Unknown'
					END Disposition,
--					sp.PATIENT_CLASS_ID ,
				SUM(CASE 
						WHEN pl.REPORTING_COLUMN = 1
							AND sp.QUANTITY > 0
							THEN sp.QUANTITY
						ELSE 0
						END) TotLPT,
				SUM(CASE 
						WHEN pl.REPORTING_COLUMN = 2
							AND sp.QUANTITY > 0
							THEN sp.QUANTITY
						ELSE 0
						END) TotNC,
				SUM(CASE 
						WHEN pl.REPORTING_COLUMN = 3
							AND sp.QUANTITY > 0
							THEN sp.QUANTITY
						ELSE 0
						END) TotLOS1,
				SUM(CASE 
						WHEN pl.REPORTING_COLUMN = 4
							AND sp.QUANTITY > 0
							THEN sp.QUANTITY
						ELSE 0
						END) TotLOS2,
				SUM(CASE 
						WHEN pl.REPORTING_COLUMN = 5
							AND sp.QUANTITY > 0
							THEN sp.QUANTITY
						ELSE 0
						END) TotLOS3,
				SUM(CASE 
						WHEN pl.REPORTING_COLUMN = 6
							AND sp.QUANTITY > 0
							THEN sp.QUANTITY
						ELSE 0
						END) TotLOS4,
				SUM(CASE 
						WHEN pl.REPORTING_COLUMN = 7
							AND sp.QUANTITY > 0
							THEN sp.QUANTITY
						ELSE 0
						END) TotLOS5,
				SUM(CASE 
						WHEN pl.REPORTING_COLUMN = 8
							AND sp.QUANTITY > 0
							THEN sp.QUANTITY
						ELSE 0
						END) TotLOS6,
				SUM(sp.QUANTITY) TotLOS
			FROM SENT_PROCEDURE sp WITH (NOLOCK),
				CHART c WITH (NOLOCK),
				PATIENT_DISPOSITION pd WITH (NOLOCK),
				PHYSICIAN_SERVICE_PROCEDURE pl
			WHERE 
--			@m_PType IN (-1, 1)
--				AND ISNULL(c.PROVIDER_EVAL_PERFORMED_BY_IND, 1) = 1
--				AND 
				sp.CLASS = 'PL'
				AND pl.PHYSICIAN_SERVICE_PROC_ID = sp.LEVEL_ID
				AND pd.PATIENT_DISPOSITION_ID = sp.PATIENT_DISPOSITION_ID
				AND c.CHART_ID = sp.CHART_ID

				AND ( @m_PatientClass = 0
			        OR @m_PatientClass = sp.PATIENT_CLASS_ID
			        )

        AND DATEADD(DAY, DATEDIFF(DAY, 0, CASE @m_DateType
        WHEN 0 THEN sp.TIME_OF_SERVICE
        ELSE sp.SENT_DATE END), 0) BETWEEN @m_StartDate AND @m_ReportDate
			GROUP BY sp.SERVICE_AGREEMENT_ID,

			CASE 
            WHEN c.NURSE_PRACTITIONER_ID > 0
                AND (
                    c.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
                    OR c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                    )
                THEN c.NURSE_PRACTITIONER_ID
            ELSE c.PHYSICIAN_ID
            END,

				DATEADD(MONTH, DATEDIFF(MONTH, 0, CASE @m_DateType
        WHEN 0 THEN sp.TIME_OF_SERVICE
        ELSE sp.SENT_DATE END), 0),
				CASE 
					WHEN pd.OUTPATIENT_IND = 1
						THEN 'Outpatient'
					WHEN pd.PATIENT_DISPOSITION_ID IN (
							2,
							3,
							4,
							5
							)
						THEN 'Admitted'
					ELSE 'Unknown'
					END
--					,
--					sp.patient_class_id			
			
			) x
	WHERE sa.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
		AND f.FACILITY_ID = @m_Facility
		AND sa.FACILITY_ID = f.FACILITY_ID
		AND fp.FACILITY_PROF_ID = x.PHYSICIAN_ID
		AND @m_ReportDate BETWEEN fp.EFFECTIVE_DATE AND ISNULL(fp.EXPIRATION_DATE, @m_ReportDate)
		AND (
			@m_Physician = 0
			OR @m_Physician = fp.FACILITY_PROF_ID
			)
--		AND (
--			@m_PatientClass = 0
--			OR @m_PatientClass = x.PATIENT_CLASS_ID
--			)
		--AND x.DOSMonth BETWEEN @m_StartDate AND @m_ReportDate
	ORDER BY f.[NAME],
		Physician,
		PhysicianID,
		DOSMonth DESC,
		Disposition DESC
END









GO
GRANT EXECUTE ON  [dbo].[rpt_LOSPhysicianSummary] TO [dbx_ExecuteReportProcs]
GO
