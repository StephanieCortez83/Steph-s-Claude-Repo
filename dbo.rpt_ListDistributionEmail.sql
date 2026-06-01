SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 6/20/2013
-- Description:	Returns a list of email addresses for the distribution list.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListDistributionEmail]
	@DistributionListId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  DECLARE @m_DistributionListId INT = @DistributionListId;

  SELECT DISTINCT EMAIL_ADDRESS
  FROM DISTRIBUTION_LIST
    INNER JOIN DISTRIBUTION_LIST_ITEM ON DISTRIBUTION_LIST_ITEM.DISTRIBUTION_LIST_ID = DISTRIBUTION_LIST.DISTRIBUTION_LIST_ID
  WHERE DISTRIBUTION_LIST.DISTRIBUTION_LIST_ID = @m_DistributionListId
END
GO
GRANT EXECUTE ON  [dbo].[rpt_ListDistributionEmail] TO [dbx_ExecuteReportProcs]
GO
