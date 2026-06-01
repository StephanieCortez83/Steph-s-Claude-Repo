------------------------------------------------------------------------------------
-- 01) DACS-3485 - Script - Create table TenetChargeValidation
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TenetChargeValidation]
(
	[TenetChargeValidationId] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_TenetChargeValidation_TenetChargeValidationId] PRIMARY KEY CLUSTERED,
	[PatientId] [varchar](20) NOT NULL,
	[BillingCode] [varchar](20) NOT NULL,
	[CPTCode] [varchar](5) NOT NULL,
	[TenetChargeId] [int] NOT NULL,
	[CreationDateTime] [datetime] NOT NULL	
)