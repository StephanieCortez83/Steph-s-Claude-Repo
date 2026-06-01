--ONLY Run in Production for this user

EXEC [dbo].[Maintenance_GrantUserAccessToAllFacilities] @UserProfileId = 10245, @AdministratorUsername = 'MFERRELL', @EffectiveDate = '7/24/2023 12:00:00 AM', @ExpirationDate = '12/30/2099 12:00:00 AM'  