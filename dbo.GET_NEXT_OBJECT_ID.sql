SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GET_NEXT_OBJECT_ID] 
	-- Add the parameters for the stored procedure here
  @classID int,
  @nextObjectID int Output
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
  BEGIN TRANSACTION;
  Select @nextObjectID = NEXT_OBJECT_ID
  From CLASS (updlock)
  Where CLASS_ID=@classID
  Update CLASS
  Set NEXT_OBJECT_ID = @nextObjectID + 1
  Where CLASS_ID=@classID
  COMMIT TRANSACTION;
END
GO
