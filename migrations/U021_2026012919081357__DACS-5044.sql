----------------------------------------
-- 01) DACS-5044 - ROLLBACK All.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP TABLE [dbo].[UrgentCareHistoryWithProvider]
GO

IF OBJECT_ID('dbo.InsertUrgentCareHistoryWithProvider', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertUrgentCareHistoryWithProvider.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertUrgentCareHistoryWithProvider
END
GO

IF OBJECT_ID('dbo.UpdateByUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId
END
GO
IF OBJECT_ID('dbo.DeleteUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId
END
GO

IF OBJECT_ID('[dbo].[SelectUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId]
END
GO

IF OBJECT_ID('[dbo].[SelectUrgentCareHistoryWithProvider]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectUrgentCareHistoryWithProvider].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectUrgentCareHistoryWithProvider]
END
GO

IF OBJECT_ID('[dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementIdAndMedicalRecordNumber]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementIdAndMedicalRecordNumber].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementIdAndMedicalRecordNumber]
END
GO
IF OBJECT_ID('[dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementId]
END
GO