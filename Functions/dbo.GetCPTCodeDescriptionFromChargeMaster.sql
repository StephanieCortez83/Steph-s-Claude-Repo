SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[GetCPTCodeDescriptionFromChargeMaster]
(	@cptCode varchar(5), @procType varchar(10), @serviceAgreementID int
)

RETURNS varchar(100)
AS 

BEGIN
	declare @description varchar(100)
	declare @usageCode int	
	
	if (@procType = 'FP')
	begin
		SELECT @description = 
		(SELECT top 1 cm.DESCRIPTION from CHARGE_MASTER cm, CHARGE_MASTER_CATEGORY cmc
		 where cm.CPT_CODE = @cptCode 
		 and cm.CHARGE_MASTER_CATEGORY_ID = cmc.CHARGE_MASTER_CATEGORY_ID
		 and cm.CHARGE_MASTER_USAGE_CODE = 3 
		 and cm.SERVICE_AGREEMENT_ID = @serviceAgreementID
		 and cmc.INFUSION_CATEGORY = 0 
		 ORDER BY cm.EFFECTIVE_DATE desc)
	end
	if (@procType = 'PP')
	begin
		SELECT @description = 
		(SELECT top 1 cm.DESCRIPTION from CHARGE_MASTER cm, CHARGE_MASTER_CATEGORY cmc
		 where cm.CPT_CODE = @cptCode 
		 and cm.CHARGE_MASTER_CATEGORY_ID = cmc.CHARGE_MASTER_CATEGORY_ID
		 and cm.CHARGE_MASTER_USAGE_CODE = 5
		 and cm.SERVICE_AGREEMENT_ID = @serviceAgreementID
		 and cmc.INFUSION_CATEGORY = 0
		 ORDER BY cm.EFFECTIVE_DATE desc)
	end	
	if (@procType = 'CI')
	begin
		SELECT @description = 
		(SELECT top 1 cm.DESCRIPTION from CHARGE_MASTER cm, CHARGE_MASTER_CATEGORY cmc
		 where cm.CPT_CODE = @cptCode 
		 and cm.CHARGE_MASTER_CATEGORY_ID = cmc.CHARGE_MASTER_CATEGORY_ID
		 and cm.CHARGE_MASTER_USAGE_CODE = 3
		 and cm.SERVICE_AGREEMENT_ID = @serviceAgreementID
		 and cmc.INFUSION_CATEGORY = 1
		 ORDER BY cm.EFFECTIVE_DATE desc)
	end		
	if (@procType = 'FS')
	begin
		SELECT @description = 
		(SELECT top 1 cm.DESCRIPTION from CHARGE_MASTER cm, CHARGE_MASTER_CATEGORY cmc
		 where cm.CPT_CODE = @cptCode 
		 and cm.CHARGE_MASTER_CATEGORY_ID = cmc.CHARGE_MASTER_CATEGORY_ID
		 and cm.CHARGE_MASTER_USAGE_CODE = 2
		 and cm.SERVICE_AGREEMENT_ID = @serviceAgreementID
		 and cmc.INFUSION_CATEGORY = 0
		 ORDER BY cm.EFFECTIVE_DATE desc)
	end		
	if (@procType = 'PS')
	begin
		SELECT @description = 
		(SELECT top 1 cm.DESCRIPTION from CHARGE_MASTER cm, CHARGE_MASTER_CATEGORY cmc
		 where cm.CPT_CODE = @cptCode 
		 and cm.CHARGE_MASTER_CATEGORY_ID = cmc.CHARGE_MASTER_CATEGORY_ID
		 and cm.CHARGE_MASTER_USAGE_CODE = 4
		 and cm.SERVICE_AGREEMENT_ID = @serviceAgreementID
		 ORDER BY cm.EFFECTIVE_DATE desc)
	end		
	if (@procType = 'AC')
	begin
		SELECT @description = 
		(SELECT top 1 cm.DESCRIPTION from CHARGE_MASTER cm, CHARGE_MASTER_CATEGORY cmc
		 where cm.CPT_CODE = @cptCode 
		 and cm.CHARGE_MASTER_CATEGORY_ID = cmc.CHARGE_MASTER_CATEGORY_ID
		 and cm.CHARGE_MASTER_USAGE_CODE = 10
		 and cm.SERVICE_AGREEMENT_ID = @serviceAgreementID
		 ORDER BY cm.EFFECTIVE_DATE desc)
	end		
	if (@procType = 'SUP')
	begin
		SELECT @description = 
		(SELECT top 1 cm.DESCRIPTION from CHARGE_MASTER cm, CHARGE_MASTER_CATEGORY cmc
		 where cm.CPT_CODE = @cptCode 
		 and cm.CHARGE_MASTER_CATEGORY_ID = cmc.CHARGE_MASTER_CATEGORY_ID
		 and cm.CHARGE_MASTER_USAGE_CODE = 1
		 and cm.SERVICE_AGREEMENT_ID = @serviceAgreementID
		 ORDER BY cm.EFFECTIVE_DATE desc)
	end			
RETURN @description
END
GO
