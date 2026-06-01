SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[BulkUpdateFacilityAuthorizationExpirationDateByFacilityAuthorizationIds]
(
	  @FacilityAuthorizationCsv			NVARCHAR(4000)
	, @NewExpirationDate				DATE
	, @ExpirationDateChangeReasonId		INT = NULL
	, @ExpirationDateChangeOtherReason  NVARCHAR(500)
	, @AdministratorUserName			NVARCHAR(100)
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @AuthorizationIds TABLE ( ID INT );
	
	INSERT INTO @AuthorizationIds
	SELECT DISTINCT RTRIM(LTRIM(value))
	  FROM STRING_SPLIT(@FacilityAuthorizationCsv,',') 
	 WHERE LEN(RTRIM(LTRIM(value))) > 0;

	DECLARE @CurrentId INT,
			@Comment NVARCHAR(100),
			@StateString NVARCHAR(100),
			@AdminUserName NVARCHAR(100),
			@FormattedNewExpirationDate NVARCHAR(30);

	SET @FormattedNewExpirationDate = CONVERT(NVARCHAR, @NewExpirationDate, 101);

	DECLARE CursorForIds CURSOR FOR SELECT ID FROM @AuthorizationIds;
	OPEN CursorForIds;

	FETCH NEXT FROM CursorForIds INTO @CurrentId;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE 
			FACILITY_USER_AUTHORIZATION
		SET 
			EXPIRATION_DATE = @NewExpirationDate
			, FACILITY_USER_AUTHORIZATION_EXPIRATION_DATE_CHANGE_REASON_ID    = @ExpirationDateChangeReasonId
			, FACILITY_USER_AUTHORIZATION_EXPIRATION_DATE_CHANGE_OTHER_REASON = @ExpirationDateChangeOtherReason
		WHERE 
				FACILITY_AUTH_ID = @CurrentId
			AND EFFECTIVE_DATE < @NewExpirationDate;

		IF (@@ROWCOUNT > 0)
		BEGIN
			SET @Comment			= CONCAT('Bulk Management: Changed Expiration Date to ', @FormattedNewExpirationDate);
			SET @StateString		= CONCAT('Bulk Management: Changed Expiration Date to ', @FormattedNewExpirationDate);
			SET @AdminUserName		= COALESCE(@AdministratorUserName, 'MFERRELL');

			EXEC [dbo].[Maintenance_LogAdminAction] 
				 @ObjectId = @CurrentId
				,@AdministratorUsername = @AdminUserName
				,@ObjectType = 'Facility Authorization'
				,@EventName = 'Updated'
				,@Comment = @Comment
				,@StateString = @StateString;
		END;

		FETCH NEXT FROM CursorForIds INTO @CurrentId;
	END;

	CLOSE CursorForIds;
	DEALLOCATE CursorForIds;
END
GO
