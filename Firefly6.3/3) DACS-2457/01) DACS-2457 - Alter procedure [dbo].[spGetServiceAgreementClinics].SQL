--------------------------------------------------------------------------
-- 01) DACS-2457 - Alter procedure [dbo].[spGetServiceAgreementClinics].SQL
--------------------------------------------------------------------------

USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spGetServiceAgreementClinics]
@ServiceAgreementId int = null, @ClinicId varchar(10) = null
WITH EXEC AS CALLER
AS
declare @service_agreement_id int=@ServiceAgreementId;
declare @clinic_id datetime=@ClinicId;

select SERVICE_AGREEMENT_ID, 
       CLINIC_ID, 
       [DESCRIPTION], 
       SERVICE_LINE_ID,
       NEW_PATIENT_CLASS_ID,
       ESTABLISHED_PATIENT_CLASS_ID
from SERVICE_AGREEMENT_CLINIC
where (@service_agreement_id is null or SERVICE_AGREEMENT_ID=@service_agreement_id)
  and (@clinic_id is null or CLINIC_ID=@clinic_id)
order by [DESCRIPTION]; -- add ordering 20230607 - DACS-2457

GO


