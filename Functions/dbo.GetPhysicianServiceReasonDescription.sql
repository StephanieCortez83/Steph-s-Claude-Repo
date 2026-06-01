SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [dbo].[GetPhysicianServiceReasonDescription]
(@chartID int)
RETURNS varchar(50)
WITH EXEC AS CALLER
AS
BEGIN
declare @desc varchar(50)
declare @dbID int
declare @reasonDesc varchar(50)

DECLARE @ReasonDescriptions TABLE 
(
	reasonDesc varchar(50),
	dataID		int,
	recordUsed BIT DEFAULT 0
)

INSERT INTO @ReasonDescriptions (reasonDesc, dataId, recordUsed) 
	SELECT ph.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_DESC, ch.HISTORY_REASON_ID, 0 
	from	PHYSICIAN_HISTORY_REASON_IF_DIFFERENT ph with (NOLOCK), 
			CHART_PHYSICIAN_HISTORY_REASON_IF_DIFFERENT ch with (NOLOCK)
	WHERE	ph.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID = ch.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID
	AND		ch.CHART_ID = @chartID
	AND		ch.PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID <> -1
	ORDER BY ph.DISPLAY_SEQ


-- First description 	
	set @reasonDesc =	(SELECT TOP 1 reasonDesc
						FROM @ReasonDescriptions where recordUsed = 0 )
	IF (@reasonDesc <> '')
	BEGIN
		SET @desc = RTRIM(@reasonDesc)
		UPDATE @ReasonDescriptions SET recordUsed = 1 where reasonDesc = @reasonDesc
	END
	
-- Second description, if any
	set @reasonDesc =	(SELECT TOP 1 reasonDesc
						FROM @ReasonDescriptions where recordUsed = 0 )
	IF (@reasonDesc <> '')
	BEGIN
		SET @desc = @desc + ',' + RTRIM(@reasonDesc)
		UPDATE @ReasonDescriptions SET recordUsed = 1 where reasonDesc = @reasonDesc
	END
	
	-- Third description, if any
	set @reasonDesc =	(SELECT TOP 1 reasonDesc
						FROM @ReasonDescriptions where recordUsed = 0 )
	IF (@reasonDesc <> '')
	BEGIN
		SET @desc = @desc + ',' + RTRIM(@reasonDesc)
		UPDATE @ReasonDescriptions SET recordUsed = 1 where reasonDesc = @reasonDesc
	END
	
	return @desc
END



GO
