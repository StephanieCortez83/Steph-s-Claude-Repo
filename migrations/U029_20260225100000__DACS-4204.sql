SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS SelectExistsLogNoteListDAOByChartIdAndLogNoteCategoryIdAndCompletedByUserProfileIDAndCompletionDate; 
GO

DELETE FROM [TYPE_CODE]
	WHERE
		[DESCRIPTION] IN ('Enable/Disables DACS-4204 SPROC variant within LogNotesListDAO.cs')
		AND [NAME] = 'ApplicationFeatureTypeCode';
GO

DELETE FROM [ApplicationFeature]
	WHERE
		[ApplicationFeatureDomainObjectTypeCode] = 5
		AND [ApplicationFeatureTypeCode] = 26
		AND [DomainObjectId] = 2147483647;
GO
