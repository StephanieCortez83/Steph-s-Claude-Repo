------------------------------------------------------
-- 01) DACS-1866 - create table - ChartAuditDemographicVersionItem.sql
------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ChartAuditDemographicVersionItem](
	-- Base table structure
	[ChartAuditDemographicVersionItemId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditVersionId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[ActionDescription] [varchar](250) NULL,
	[PrevChartAuditDemographicVersionItemId] [int] NULL,
	[IsPreviousVersionCorrect] [bit] NULL,
	-- Exclusion information
	[ExcludeFromQA] [bit] NULL,
	[ExcludeFromQAReasonID] [int] NULL,
	-- Particular to Demographic Audit fields
	[ChartId] [int] NULL,  -- Key field
	[AdmissionDateTime] [datetime] NULL,
	[ArrivalDateTime] [datetime] NULL,
	[MedicalRecordNum] [varchar](20) NULL,
	[PatientDispositionMapId] [int] NULL,
	[PhysicianId] [int] NULL,
	[ServiceAgreementArrivalModeId] [int] NULL,
	[ServiceAgreementTriageAcuityId] [int] NULL,
	[TimeToRoom] [datetime] NULL,
	[Gender] [varchar](1) NULL,
	[ResidentParticipatedInCare] [bit] NULL,
	[FinancialClassCd] [varchar](10) NULL,
	[PatientDob] [datetime] NULL,
	[NursePractitionerId] [int] NULL,
	[ProviderEvalPerformedByInd] [bit] NULL,
	[TimeOfService] [datetime] NULL,
	[PatientDispositionId] [int] NULL,
	[FacilityAdminChartId] [varchar](20) NULL,
	[TimeOfDis] [datetime] NULL,
	[ConditionOfAccidentId] [int] NULL,
	[ClinicId] [varchar](10) NULL,
	[AttestationSignedByAttending] [bit] NULL,
	[ScribeId] [int] NULL,
	[LastEncounterDate] [datetime] NULL,
	[LastMenstrualPeriod] [datetime] NULL,
	[ResidentId] [int] NULL,
	[PatientAge] [int] NULL,
	[TimeOfPhysEval] [datetime] NULL,
	[TimeOfTriage] [datetime] NULL,
	[MedicalExaminerNotified] [bit] NULL,
	[OrganDonation] [bit] NULL,
	[SeenInEdWithin48HoursOfOr] [bit] NULL,
	[PhysicianServiceGuidelineId] [int] NULL,
	[PhysicianServiceSpecialtyTemplateId] [int] NULL,
	[UseTimeBasedChargeCapture] [bit] NULL,
	[TimeBasedPhysicianLos] [int] NULL,
	[UsePreventativeMedicineChargeCapture] [bit] NULL,
	[PreventativeMedicinePhysicianProcId] [int] NULL,
	[NoLcdServices] [bit] NULL,
	[PatientDispositionDestinationId] [int] NULL,	
CONSTRAINT [PK_ChartAuditDemographicVersionItem] PRIMARY KEY CLUSTERED 
(
	[ChartAuditDemographicVersionItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditDemographicVersionItem] ADD  CONSTRAINT [DF_ChartAuditDemographicVersionItem_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditDemographicVersionItem] ADD  CONSTRAINT [DF_ChartAuditDemographicVersionItem_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChartAuditDemographicVersionItem]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditDemographicVersionItem_ChartAuditVersion] FOREIGN KEY([ChartAuditVersionId])
REFERENCES [dbo].[ChartAuditVersion] ([ChartAuditVersionId])
GO

ALTER TABLE [dbo].[ChartAuditDemographicVersionItem] CHECK CONSTRAINT [FK_ChartAuditDemographicVersionItem_ChartAuditVersion]
GO


-- if table needs to be removed: DROP TABLE [dbo].[ChartAuditDemographicVersionItem];