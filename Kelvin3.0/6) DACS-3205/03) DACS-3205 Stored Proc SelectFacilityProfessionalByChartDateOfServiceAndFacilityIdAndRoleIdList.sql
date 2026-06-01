------------------------------------------------------------------------------------
-- 03) DACS-3205 - Created New stored procedure to get Facility Professionals
------------------------------------------------------------------------------------

Use RevCycleDB
Go

CREATE OR ALTER PROCEDURE dbo.SelectFacilityProfessionalByChartDateOfServiceAndFacilityIdAndRoleIdList
@ChartDateOfService DATETIME,
@FacilityId INT,
@RoleIdList VARCHAR(4000)
AS
BEGIN
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		 fp.FACILITY_PROF_ID
		,fp.FIRST_NAME
		,fp.MIDDLE_NAME
		,fp.LAST_NAME
		,fp.NAME_SUFFIX
		,fp.EMPLOYEE_IDENTIFIER
		,fp.UPIR_ID
		,fp.ROLE_ID
		,fp.PROVIDER_BUSINESS_UNIT_ID 
	FROM 
		FACILITY_PROFESSIONAL fp 
		LEFT OUTER JOIN FACILITY_PROFESSIONAL_LOCUM_ASSIGNMENT fpla
		ON fpla.LOCUM_PHYSICIAN_ID = fp.FACILITY_PROF_ID 
		AND @ChartDateOfService BETWEEN fpla.EFFECTIVE_DATE AND fpla.EXPIRATION_DATE
	WHERE 
		fp.FACILITY_ID = @FacilityId
		AND 
		(
			@ChartDateOfService IS NULL 
			OR 
			@ChartDateOfService BETWEEN fp.EFFECTIVE_DATE AND ISNULL(fp.EXPIRATION_DATE, GETDATE())
		)
		AND
		(
			fp.ROLE_ID <> 9
			OR
			fpla.LOCUM_PHYSICIAN_ID IS NOT NULL
		)
		AND 
		(
			@RoleIdList = '-1'
			OR
			fp.ROLE_ID IN (SELECT * FROM dbo.SplitString(@RoleIdList, ','))
		)
	ORDER BY 
		fp.LAST_NAME, fp.FIRST_NAME
END
GO
