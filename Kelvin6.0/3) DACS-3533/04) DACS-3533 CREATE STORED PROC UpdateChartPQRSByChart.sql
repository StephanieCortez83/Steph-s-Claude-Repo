-----------------------------------------------------------------------------
-- 04) DACS-3533 - Create or Alter Stored Procedure - [dbo].[UpdateChartPQRSByChart].SQL
-----------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
    
CREATE OR ALTER PROCEDURE [dbo].[UpdateChartPQRSByChart]    
	 @ChartId INT    
	,@PqrsValue BIT    
AS    
BEGIN    
	IF @ChartId IS NULL OR @ChartId <= 0
		RETURN;    
    
	SET NOCOUNT ON    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    

	UPDATE [CHART]
		SET NO_PQRS = @PqrsValue
	WHERE 
	    [CHART_ID] = @ChartId
	  
END -- end procedure

GO