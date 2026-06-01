SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 9/9/2013
-- Description:	Lists the services performed by each active service agreement
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ActiveClientServices]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  SELECT [DESCRIPTION] Facility,
	  LAST_NAME + ', ' + FIRST_NAME AccountManager,
	  CASE 
		  WHEN EVALUATE_FACILITY_SVC > 0
			  THEN 'Yes'
		  ELSE NULL
		  END FacilityServices,
	  CASE 
		  WHEN EVALUATE_PHYSICIAN_SVC > 0
			  THEN 'Yes'
		  ELSE NULL
		  END PhysicianServices,
	  CASE 
		  WHEN EVALUATE_FACILITY_PROCEDURES > 0
			  THEN 'Yes'
		  ELSE NULL
		  END FacilityProcedures,
	  CASE 
		  WHEN EVALUATE_PHYSICIAN_PROCEDURES > 0
			  THEN 'Yes'
		  ELSE NULL
		  END PhysicianProcedures,
	  CASE 
		  WHEN PERFORM_DIAGNOSIS_CODING > 0
			  THEN 'Yes'
		  ELSE NULL
		  END DiagnosisCoding,
	  CASE 
		  WHEN EVALUATE_OBSERVATION_DEPARTMENTS > 0
			  THEN 'Yes'
		  ELSE NULL
		  END Observation,
	  CASE 
		  WHEN EVALUATE_PHYSICIAN_OBSERVATION > 0
			  THEN 'Yes'
		  ELSE NULL
		  END PHYSICIAN_Observation,
	  CASE 
		  WHEN INFUSION_INJECTION_METHOD_ID > 0
			  THEN 'Yes'
		  ELSE NULL
		  END [Infusion/Injection]
  FROM SERVICE_AGREEMENT
  LEFT JOIN SERVICE_AGREEMENT_MANAGEMENT_TEAM ON SERVICE_AGREEMENT_MANAGEMENT_TEAM.SERVICE_AGREEMENT_ID = SERVICE_AGREEMENT.SERVICE_AGREEMENT_ID
	  AND MANAGEMENT_TEAM_ROLE_ID = 1
  LEFT JOIN USER_PROFILE ON USER_PROFILE.USER_PROFILE_ID = SERVICE_AGREEMENT_MANAGEMENT_TEAM.USER_PROFILE_ID
  WHERE DEMO_TEST_SITE_IND = 0
	  AND GETDATE() BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
  ORDER BY Facility
END

GO
GRANT EXECUTE ON  [dbo].[rpt_ActiveClientServices] TO [dbx_ExecuteReportProcs]
GO
