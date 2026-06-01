----------------------------------------
-- 02) DACS-4958 - create or alter SPROC - SelectFacilityProfessionalById.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFacilityProfessionalById]
	 @FacilityProfessionalId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

	SELECT
		 [FACILITY_PROF_ID]
		,[FACILITY_ID]
		,[SERVICE_AGREEMENT_ID]
		,[ROLE_ID]
		,[TITLE]
		,[FIRST_NAME]
		,[MIDDLE_NAME]
		,[LAST_NAME]
		,[NAME_SUFFIX]
		,[ADDR_LINE_1]
		,[ADDR_LINE_2]
		,[CITY]
		,[STATE]
		,[POSTAL_CODE]
		,[PHONE_AREA_CODE]
		,[PHONE_NUMBER]
		,[PHONE_EXT]
		,[FAX_AREA_CODE]
		,[FAX_NUMBER]
		,[EMAIL_ADDRESS]
		,[EMPLOYEE_IDENTIFIER]
		,[UPIR_ID]
		,[CREATION_DATE_TIME]
		,[CREATING_USER_PROFILE_ID]
		,[CHANGED_DATE_TIME]
		,[CHANGING_USER_PROFILE_ID]
		,[PROVIDER_BUSINESS_UNIT_ID]
		,[SPECIALTY]
		,[SECONDARY_EMPLOYEE_ID]
		,[LOCUM_TENENS]
		,[EFFECTIVE_DATE]
		,[EXPIRATION_DATE]
		,[SUPERVISING_EMPLOYEE_ID]
		,[UNSPECIFIED_PROVIDER_IND]
		,[CREDENTIALS]
	FROM
		[FACILITY_PROFESSIONAL]
	WHERE
		[FACILITY_PROF_ID] = @FacilityProfessionalId;
END
GO

DECLARE @exp VARCHAR(50) = (SELECT CAST(modify_date AS VARCHAR(50)) FROM sys.objects WHERE type = 'P' AND name = 'SelectFacilityProfessionalById');

IF OBJECT_ID('dbo.SelectFacilityProfessionalById', 'P') IS NOT NULL
	PRINT ('SPROC SelectFacilityProfessionalById last changed ' + @exp);
ELSE
	PRINT ('failed to create SPROC SelectFacilityProfessionalById');
GO