SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[ModifyPhySvcDiagnosisCode]
	@ChartId INT,
	@PhysicianServiceProcId INT,
	@LevelNumber INT,
	@UserProfileId INT,
	@CptCode VARCHAR(10),
	@Icd10Code VARCHAR(128),
	@Modifiers VARCHAR(128),
	@DOS DATETIME
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- check the input variables
	IF 	@ChartId <= 0
	BEGIN
		SELECT 'Result' = -1
		RETURN;
	END;
	
	IF 	@PhysicianServiceProcId <= 0
	BEGIN
		SELECT 'Result' = -2
		RETURN;
	END;
	
	IF 	@LevelNumber <= 0
	BEGIN
		SELECT 'Result' = -3
		RETURN;
	END;
	
	IF 	@UserProfileId <= 0
	BEGIN
		SELECT 'Result' = -4
		RETURN;
	END;

	IF 	@CptCode IS NULL OR @CptCode = ''
	BEGIN
		SELECT 'Result' = -5
		RETURN;
	END;

	IF 	@DOS < DATEADD(yyyy, -100 , GETDATE())
	BEGIN
		SELECT 'Result' = -6
		RETURN;
	END;

	IF @Icd10Code IS NULL
		SET @Icd10Code = '';

	IF @Modifiers IS NULL
		SET @Modifiers = '';
	
	-- search index group fields = [ChartId], [PhysicianServiceProcId], [PhysicianServiceLevelNumber], [DateOfService], [CptCode]
	
	-- see if we already have an entry
	DECLARE @FoundProcId INT = (SELECT 
									[PhysicianServiceEvalDiagnosisId] 
								FROM 
									[dbo].[PhysicianServiceEvalDiagnosis]
								WHERE	
									[ChartId] = @ChartId
									AND [PhysicianServiceProcId] = @PhysicianServiceProcId
									AND [PhysicianServiceLevelNumber] = @LevelNumber
									AND [DateOfService] = @DOS
									AND [CptCode] = @CptCode);
	
	IF @FoundProcId IS NOT NULL -- if already have an entry, do an UPDATE
	BEGIN
		UPDATE [dbo].[PhysicianServiceEvalDiagnosis]
			SET 
				  [DateTimeLastUpdated] = GETDATE()
				, [Icd10Codes] = @Icd10Code
				, [Modifiers] = @Modifiers
		WHERE
			[ChartId] = @ChartId
			AND [PhysicianServiceProcId] = @PhysicianServiceProcId
			AND [PhysicianServiceLevelNumber] = @LevelNumber
			AND [DateOfService] = @DOS
			AND [CptCode] = @CptCode;
	END
	ELSE -- if not already existing entry do an insert.
	BEGIN
		INSERT INTO [dbo].[PhysicianServiceEvalDiagnosis]
			([CreatedByUserProfileId],[LastUpdatedByUserProfileId],[ChartId],[PhysicianServiceLevelNumber],[PhysicianServiceProcId],[CptCode],[Icd10Codes],[Modifiers],[DateOfService])
		VALUES
			(@UserProfileId,@UserProfileId,@ChartId,@LevelNumber,@PhysicianServiceProcId,@CptCode,@Icd10Code,@Modifiers,@DOS);
	END;

	--Send result:
	SELECT 
		COUNT(PhysicianServiceEvalDiagnosisId) 
	FROM 
		[dbo].[PhysicianServiceEvalDiagnosis]
	WHERE	
		[ChartId] = @ChartId
		AND [PhysicianServiceLevelNumber] = @LevelNumber
		AND [PhysicianServiceProcId] = @PhysicianServiceProcId
		AND [DateOfService] = @DOS
		AND [CptCode] = @CptCode;
	
END
GO
