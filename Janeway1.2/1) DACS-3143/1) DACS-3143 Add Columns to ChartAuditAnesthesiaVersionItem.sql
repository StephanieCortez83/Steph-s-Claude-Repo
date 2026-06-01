USE [RevCycleDB]
GO

ALTER TABLE ChartAuditAnesthesiaVersionItem 
ADD [StartTime] [datetime] NULL,
 	[StopTime] [datetime] NULL,
 	[ExcludeMinutes] [int] NULL,
 	[Units] [int] NULL,
 	[Minutes] [int] NULL,
 	[ProviderModifiers] [varchar](100) NULL,
 	[MacModifiers] [varchar](2) NULL,
 	[PhysicalStatusModifier] [varchar](2) NULL,
 	[BaseUnitExceptionFieldAvoidance] [bit] NULL,
 	[BaseUnitExceptionNonSupine] [bit] NULL,
 	[BaseUnitExceptionModifier] [varchar](2) NULL,
 	[QualifyingCircumstanceCode] [varchar](100) NULL,
 	[ChargeMasterId] [int] NULL,
 	[BaseUnitExceptionLimitedAccessToAirway] [bit] NULL,
 	[DocumentationSupportsIncreasedComplexity] [bit] NULL,
 	[DocumentationSupportsIncreasedComplexityReasonId] [int] NULL,
 	[CptModifiers] [varchar](100) NULL