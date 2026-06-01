SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

	----------------
	-- making a reusable block out of oft used MIPS SQL Script
	----------------

CREATE   FUNCTION [dbo].[udfReturnMips411Questions]
	(
		 @tempDenominatorList tDenominatorInfo READONLY
		,@MeasureId INT
	)
RETURNS @returnResults TABLE
(
	 [RESULT] VARCHAR(32)
	,[QUESTION] VARCHAR(2000)
	,[CODE] VARCHAR(32)
)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList tdl WHERE tdl.[CodingSystem] = 'DQ411' AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0)
		INSERT INTO @returnResults ([RESULT], [QUESTION], [CODE])
			VALUES ('411', ' ', '00001')
	ELSE
		INSERT INTO @returnResults ([RESULT], [QUESTION], [CODE])
			SELECT TOP 5
				'411' AS 'RESULT'
				, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
				, tdl.[Code] AS 'CODE'
			FROM 
				@tempDenominatorList tdl
			WHERE 
				tdl.[CodingSystem] = 'DQ411'
				AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0
			ORDER BY
				tdl.[Code];
	RETURN;
END; -- end function

GO
