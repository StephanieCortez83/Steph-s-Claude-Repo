-------------------------------------------------------------------------------
-- DACS-1385  
-- Add new values to Service Model dropdown for SADetailsView.aspx
-------------------------------------------------------------------------------
USE [RevCycleDB]
GO


	INSERT INTO [dbo].[SERVICE_MODEL]
	(
		[SERVICE_MODEL_CD], [DESCRIPTION]
	)
	VALUES
		('ATM', 'Automation' )
	   ,( 'AUG', 'Staff Aug'  );

GO
