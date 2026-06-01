SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[ModifyServiceAgreementServiceLine]  
	 @ServiceAgreementId int = null  
	,@ServiceLineId int = null  
	,@Description varchar(100) = null  

WITH EXEC AS CALLER  
AS  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @ServiceAgreementId IS NULL OR @ServiceAgreementId <= 0
		RETURN;
	
	IF @ServiceLineId > 0 AND EXISTS (
		SELECT TOP 1 1 
		FROM 
			[dbo].[SERVICE_AGREEMENT_SERVICE_LINE] 
		WHERE 
			[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
			AND [SERVICE_LINE_ID] = @ServiceLineId
		)
		UPDATE   
			[dbo].[SERVICE_AGREEMENT_SERVICE_LINE]  
		SET  
			[DESCRIPTION] = @Description  
		WHERE   
			[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
			AND [SERVICE_LINE_ID] = @ServiceLineId
		;
	ELSE
		INSERT INTO [dbo].[SERVICE_AGREEMENT_SERVICE_LINE] (   
			 [SERVICE_AGREEMENT_ID]  
			,[DESCRIPTION]  
		)  
		VALUES   
		(  
			 @ServiceAgreementId  
			,@Description  
		); 

GO
