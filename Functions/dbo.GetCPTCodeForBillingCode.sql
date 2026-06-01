SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GetCPTCodeForBillingCode]
(@BillingCode varchar(10), @ServiceAgreementID int, @ChargeMasterUsageCode int)
RETURNS varchar(5)
WITH EXEC AS CALLER
AS
BEGIN
declare @cpt varchar(5)


    set @cpt = (SELECT MAX(cm.CPT_CODE) 
                FROM CHARGE_MASTER cm with (NOLOCK)
                WHERE cm.BILLING_CODE = @BillingCode
                AND cm.SERVICE_AGREEMENT_ID = @ServiceAgreementID
                AND cm.CHARGE_MASTER_USAGE_CODE = @ChargeMasterUsageCode)      
		return @cpt
END
GO
