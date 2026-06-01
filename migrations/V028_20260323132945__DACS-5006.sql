DECLARE @ModifierCD VARCHAR(2) = 'FQ';
DECLARE @ModifierName VARCHAR(200) = 'The Service Was Furnished Using Audio-Only Communication Technology';

IF NOT EXISTS(SELECT 1 FROM [MODIFIER] WHERE [MODIFIER_CD] = @ModifierCD)
BEGIN
	INSERT INTO [MODIFIER]
	(
		 [MODIFIER_CD] 
		,[DESCRIPTION]
	)
	VALUES
	(
		 @ModifierCD
		,@ModifierName   
	);
END;