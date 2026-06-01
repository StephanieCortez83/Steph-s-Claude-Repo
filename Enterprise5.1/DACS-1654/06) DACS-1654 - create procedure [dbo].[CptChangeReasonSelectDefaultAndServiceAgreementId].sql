--------------------------------------------------------------------------------
-- 01) DACS-1654 - create procedure [dbo].[CptChangeReasonSelectDefaultAndServiceAgreementId].sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- CREATE PROCEDURE [dbo].[CptChangeReasonSelectDefaultAndServiceAgreementId] -- use this line of CREATE OR ALTER is not supported by database
CREATE OR ALTER PROCEDURE [dbo].[CptChangeReasonSelectDefaultAndServiceAgreementId]
@ServiceAgreementId INT = 0
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [CPT_CHANGE_REASON].[CPT_CHANGE_REASON_ID]
	,[CPT_CHANGE_REASON].[DISPLAY_NAME]
	,[CPT_CHANGE_REASON].[DESCRIPTION]
	,[CPT_CHANGE_REASON].[CREATION_DATE_TIME]
	,[CPT_CHANGE_REASON].[CREATING_USER_PROFILE_ID]
	,[CPT_CHANGE_REASON].[CHANGED_DATE_TIME]
	,[CPT_CHANGE_REASON].[CHANGING_USER_PROFILE_ID]
	,[CPT_CHANGE_REASON].[SERVICE_AGREEMENT_ID]
	,[CPT_CHANGE_REASON].[EFFECTIVE_DATE]
    ,[CPT_CHANGE_REASON].[EXPIRATION_DATE]

FROM
	[dbo].[CPT_CHANGE_REASON]
WHERE
	([EFFECTIVE_DATE] IS NOT NULL AND [EFFECTIVE_DATE] < getdate())
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= getdate())
	AND ([SERVICE_AGREEMENT_ID] IS NULL OR [SERVICE_AGREEMENT_ID] = @ServiceAgreementId)
ORDER BY
	[SERVICE_AGREEMENT_ID],[DISPLAY_NAME],[CPT_CHANGE_REASON_ID];

GO

/*testing

exec [dbo].[CptChangeReasonSelectDefaultAndServiceAgreementId] @ServiceAgreementId = 9999;

*/
