SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 1/24/2014
-- Description:	SQL for the Physician LOS Summary Chart
-- =============================================
CREATE PROCEDURE [dbo].[rpt_PhysicianLOSDistributionSummary] 
    @ReportDate DATETIME,
    @Facility INT,
    @Physician INT,
    @StartDate DATE = '1/1/1990',
	@PatientClass INT, 
    @DateType INT = 0
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @m_ReportDate DATETIME = @ReportDate,
        @m_Facility INT = @Facility,
        @m_Physician INT = @Physician,
        @m_Role INT = (
            SELECT ROLE_ID
            FROM FACILITY_PROFESSIONAL
            WHERE FACILITY_PROF_ID = @Physician
            ),
        @m_StartDate DATE = @StartDate,
		@m_PatientClass INT = @PatientClass,
        @m_DateType INT = @DateType

        IF @m_StartDate IS NULL
        BEGIN
          SET @m_StartDate = '1/1/1990';
        END

    -- Physician LOS Distribution Summary
    SELECT FACILITY_ID,
        PHYSICIAN_ID,
        REPORTING_COLUMN,
		PATIENT_CLASS_ID,
        lrc.SHORT_DESCRIPTION,
        SUM(CURLOS) CURLOS,
        SUM(CURLOSOP) CURLOSOP,
        SUM(YTDLOS) YTDLOS,
        SUM(YTDLOSOP) YTDLOSOP,
        SUM(D90LOS) D90LOS,
        SUM(D90LOSOP) D90LOSOP,
        SUM(ITDLOS) ITDLOS,
        SUM(ITDLOSOP) ITDLOSOP
    FROM LOS_REPORT_COLUMN lrc,
        (
            SELECT FACILITY_ID,
                PHYSICIAN_ID,
                REPORTING_COLUMN,
				PATIENT_CLASS_ID,
                CURLOS,
                CURLOSOP,
                YTDLOS,
                YTDLOSOP,
                D90LOS,
                D90LOSOP,
                ITDLOS,
                ITDLOSOP
            FROM (
                SELECT x.FACILITY_ID,
                    x.PHYSICIAN_ID,
                    x.REPORTING_COLUMN,
					x.PATIENT_CLASS_ID,
                    SUM(x.CURLOS) CURLOS,
                    SUM(x.CURLOSOP) CURLOSOP,
                    SUM(x.YTDLOS) YTDLOS,
                    SUM(x.YTDLOSOP) YTDLOSOP,
                    SUM(x.D90LOS) D90LOS,
                    SUM(x.D90LOSOP) D90LOSOP,
                    SUM(x.ITDLOS) ITDLOS,
                    SUM(x.ITDLOSOP) ITDLOSOP
                FROM (
                    SELECT sp.FACILITY_ID,

					CASE 
            WHEN c.NURSE_PRACTITIONER_ID > 0
                AND (
                    c.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
                    OR c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                    )
                THEN c.NURSE_PRACTITIONER_ID
            ELSE c.PHYSICIAN_ID
            END as PHYSICIAN_ID,


                        --CASE @m_Role
                        --    WHEN 2
                        --        THEN CASE 
                        --                WHEN sp.PHYSICIAN_ID IS NULL
                        --                    THEN 0
                        --                ELSE sp.PHYSICIAN_ID
                        --                END
                        --    ELSE c.NURSE_PRACTITIONER_ID                            
                        --    END PHYSICIAN_ID,

						sp.PATIENT_CLASS_ID ,
                        psp.REPORTING_COLUMN,
                        CASE 
                            WHEN DATEADD(MONTH, DATEDIFF(MONTH, 0, CASE @m_DateType
                                            WHEN 0
                                                THEN cast(sp.TIME_OF_SERVICE as date)
                                            ELSE sp.SENT_DATE
                                            END), 0) = DATEADD(MONTH, DATEDIFF(MONTH, 0, @m_ReportDate), 0)
                                THEN sp.QUANTITY
                            ELSE 0
                            END CURLOS,
                        CASE 
                            WHEN DATEADD(MONTH, DATEDIFF(MONTH, 0, CASE @m_DateType
                                            WHEN 0
                                                THEN sp.TIME_OF_SERVICE
                                            ELSE sp.SENT_DATE
                                            END), 0) = DATEADD(MONTH, DATEDIFF(MONTH, 0, @m_ReportDate), 0)
                                AND sp.PATIENT_DISPOSITION_ID IN (
                                    1,
                                    5,
                                    6,
                                    7,
                                    8
                                    )
                                THEN sp.QUANTITY
                            ELSE 0
                            END CURLOSOP,
                        CASE 
                            WHEN DATEADD(YEAR, DATEDIFF(YEAR, 0, CASE @m_DateType
                                            WHEN 0
                                                THEN sp.TIME_OF_SERVICE
                                            ELSE sp.SENT_DATE
                                            END), 0) = DATEADD(YEAR, DATEDIFF(YEAR, 0, @m_ReportDate), 0)
                                THEN sp.QUANTITY
                            ELSE 0
                            END YTDLOS,
                        CASE 
                            WHEN DATEADD(YEAR, DATEDIFF(YEAR, 0, CASE @m_DateType
                                            WHEN 0
                                                THEN sp.TIME_OF_SERVICE
                                            ELSE sp.SENT_DATE
                                            END), 0) = DATEADD(YEAR, DATEDIFF(YEAR, 0, @m_ReportDate), 0)
                                AND sp.PATIENT_DISPOSITION_ID IN (
                                    1,
                                    5,
                                    6,
                                    7,
                                    8
                                    )
                                THEN sp.QUANTITY
                            ELSE 0
                            END YTDLOSOP,
                        CASE 
                            WHEN DATEDIFF(DAY, CASE @m_DateType
                                        WHEN 0
                                            THEN sp.TIME_OF_SERVICE
                                        ELSE sp.SENT_DATE
                                        END, @m_ReportDate) <= 90
                                THEN sp.QUANTITY
                            ELSE 0
                            END D90LOS,
                        CASE 
                            WHEN DATEDIFF(DAY, CASE @m_DateType
                                        WHEN 0
                                            THEN sp.TIME_OF_SERVICE
                                        ELSE sp.SENT_DATE
                                        END, @m_ReportDate) <= 90
                                AND sp.PATIENT_DISPOSITION_ID IN (
                                    1,
                                    5,
                                    6,
                                    7,
                                    8
                                    )
                                THEN sp.QUANTITY
                            ELSE 0
                            END D90LOSOP,
                        sp.QUANTITY ITDLOS,
                        CASE 
                            WHEN sp.PATIENT_DISPOSITION_ID IN (
                                    1,
                                    5,
                                    6,
                                    7,
                                    8
                                    )
                                THEN sp.QUANTITY
                            ELSE 0
                            END ITDLOSOP
                    FROM SENT_PROCEDURE sp
                    INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = sp.CHART_ID
                    INNER JOIN PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK) ON psp.PHYSICIAN_SERVICE_PROC_ID = sp.LEVEL_ID --ISNULL(NULLIF(c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID, - 1), c.PHYSICIAN_SERVICE_PROC_ID)
                    WHERE sp.CLASS = 'PL'
                        AND CASE @m_DateType
                            WHEN 0
                                THEN cast(sp.TIME_OF_SERVICE as date) 
                            ELSE sp.SENT_DATE
                            END BETWEEN @m_StartDate AND @m_ReportDate
                        --AND CASE 
                        --    WHEN @m_Role = 1
                        --        AND ISNULL(c.PROVIDER_EVAL_PERFORMED_BY_IND, 1) = 1
                        --        THEN 1
                        --    WHEN @m_Role = 2
                        --        THEN 1
                        --    ELSE 0
                        --    END = 1
                    ) x
                GROUP BY x.FACILITY_ID,
                    x.PHYSICIAN_ID,
                    x.REPORTING_COLUMN,
					x.PATIENT_CLASS_ID
                
                UNION
                
                SELECT @m_Facility FACILITY_ID,
                    @m_Physician PHYSICIAN_ID,
                    COLUMN_ID REPORTING_COLUMN,
					@m_PatientClass ,
                    0 CURLOS,
                    0 CURLOSOP,
                    0 YTDLOS,
                    0 YTDLOSOP,
                    0 D90LOS,
                    0 D90LOSOP,
                    0 ITDLOS,
                    0 ITDLOSOP
                FROM LOS_REPORT_COLUMN
                WHERE SERVICE_TYPE = 'PL'
				and COLUMN_ID between 1 and 8
                ) y
            ) z
    WHERE FACILITY_ID = @m_Facility
        AND PHYSICIAN_ID = @m_Physician 
		AND ( @m_PatientClass = 0
			  OR @m_PatientClass = PATIENT_CLASS_ID
			)
        AND REPORTING_COLUMN = lrc.COLUMN_ID
        AND lrc.SERVICE_TYPE = 'PL'
    GROUP BY FACILITY_ID,
        PHYSICIAN_ID,
        REPORTING_COLUMN,
		PATIENT_CLASS_ID,
        lrc.SHORT_DESCRIPTION
    ORDER BY FACILITY_ID,
        PHYSICIAN_ID,
        REPORTING_COLUMN
END







GO
GRANT EXECUTE ON  [dbo].[rpt_PhysicianLOSDistributionSummary] TO [dbx_ExecuteReportProcs]
GO
