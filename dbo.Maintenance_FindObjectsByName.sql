SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_FindObjectsByName]
    @SearchString VARCHAR(255)
AS
BEGIN
	-- Adapted from SQL Script provided from Marcus Ferrell

	IF @SearchString IS NULL OR LEN(@SearchString) <= 1
	BEGIN
		SELECT 'Result' = 'Search String is too short';
		RETURN;
	END;

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT DISTINCT 
		  sysobjects.name AS [ObjectName] 
		, sysobjects.xtype AS [ObjectBaseType]
		, CASE WHEN sysobjects.xtype = 'P' THEN 'Stored Proc'
			WHEN sysobjects.xtype = 'TF' THEN 'Function'
			WHEN sysobjects.xtype = 'TR' THEN 'Trigger'
			WHEN sysobjects.xtype = 'V' THEN 'View'
			WHEN sysobjects.xtype = 'T' THEN 'TABLE'
		END AS [ObjectType]
	FROM 
		sysobjects,syscomments
	WHERE 
		sysobjects.id = syscomments.id
		AND sysobjects.type IN ('P','TF','TR','V','T')
		AND CHARINDEX(@SearchString, syscomments.text) > 0;
END
GO
