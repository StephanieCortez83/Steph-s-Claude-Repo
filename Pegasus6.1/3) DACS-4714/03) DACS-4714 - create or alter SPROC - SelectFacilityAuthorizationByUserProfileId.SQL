----------------------------------------
-- 03) DACS-4714 - create or alter SPROC - SelectFacilityAuthorizationByUserProfileId.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'SelectFacilityAuthorizationByUserProfileId', @DestProc = 'SelectFacilityAuthorizationByUserProfileId_DACS-4714';
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFacilityAuthorizationByUserProfileId]
    @UserProfileID INT
  , @IncludeInactive BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @EffectiveDate DATETIME = IIF(@IncludeInactive = 1, '01-01-2200', GETDATE());
    DECLARE @ExpirationDate DATETIME = IIF(@IncludeInactive = 1, '01-01-1900', @EffectiveDate);

    SELECT 
		  fua.FACILITY_AUTH_ID
		, fua.USER_PROFILE_ID
		, fua.FACILITY_ID
		, fua.EFFECTIVE_DATE
		, fua.EXPIRATION_DATE
		, fua.CAN_APPROVE_CHARTS
		, fua.AUDIT_APPROVAL_RATE
		, fua.SECOND_LEVEL_AUDIT_APPROVAL_RATE
		, fua.NUMBER_COMPLETED
		, fua.AUDIT_PROCEDURE_RATE
		, fua.PROCEDURE_NUMBER_COMPLETED
		, fua.AUDIT_INFUSION_RATE
		, fua.INFUSION_NUMBER_COMPLETED
		, fua.AUDIT_OBSERVATION_RATE
		, fua.OBSERVATION_NUMBER_COMPLETED
		, fua.CODER_AUTHORIZED_SERVICE_CODE
		, fua.FACILITY_PROF_ID
		, fua.CREATION_DATE_TIME
		, fua.CREATING_USER_PROFILE_ID
		, fua.CHANGED_DATE_TIME
		, fua.CHANGING_USER_PROFILE_ID
		, fua.FORCE_AUDIT
		, fua.ACTIVE_CHART_ID
		, FACILITY_USER_AUTHORIZATION_EXPIRATION_DATE_CHANGE_REASON_ID
		, FACILITY_USER_AUTHORIZATION_EXPIRATION_DATE_CHANGE_OTHER_REASON
		, ALLOW_EMR_ACCESS
		, EMR_ACCESS_EFFECTIVE_DATE
		, EMR_ACCESS_EXPIRATION_DATE
		, EMR_ACCESS_USER_PROFILE_ID
    FROM 
		FACILITY_USER_AUTHORIZATION fua
		JOIN USER_PROFILE 
          ON USER_PROFILE.USER_PROFILE_ID = fua.USER_PROFILE_ID
        JOIN FACILITY f
          ON f.FACILITY_ID = fua.FACILITY_ID
    WHERE 
		  fua.USER_PROFILE_ID = @UserProfileID
      AND fua.EFFECTIVE_DATE < @EffectiveDate
      AND fua.EXPIRATION_DATE > @ExpirationDate
	ORDER BY f.NAME;
END;
GO


