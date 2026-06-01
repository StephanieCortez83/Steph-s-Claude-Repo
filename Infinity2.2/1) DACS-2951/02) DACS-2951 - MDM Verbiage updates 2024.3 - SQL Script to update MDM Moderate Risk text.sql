----------------------------------------
-- 02) DACS-2951 - MDM Verbiage updates 2024.3 - SQL Script to update MDM Moderate Risk text.sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

exec [dbo].[Maintenance_UpdatePhysicianServiceRiskMessages]
     @RiskSearchString = '<b>Moderate%'
	,@BackupPhysicianServiceTable = 1
    ,@NewRiskMessage = '<b>Moderate</b> risk of morbidity from additional diagnostic testing or treatment.<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Examples only:<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Prescription Drug Management (Prescriptions written at discharge; prescription strength meds administered<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;during encounter - <font color="Red">including those required for a procedure i.e., lidocaine or tetanus</font>, dosage changes, instructions<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;to stop taking prescriptions medication, and prescriptions considered but ultimately not given.<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Decision regarding minor surgery with identified patient or procedure risk factors<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Decision regarding elective major surgery without identified risk factors<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Diagnosis or treatment significantly limited by SDOH. (Food and/or housing insecurities, unemployment,<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;lack of transportation etc.)<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Radiation exposure from CT scan (No Contrast) or Head, Neck, or Torso X-Ray</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Administration of IV Fluids, with or without additives</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Infant OTC Meds</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Acetaminophen (Tylenol) age < 24 months</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Ibuprofen (Motrin) age < 6 months</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Diphenhydramine (Benadryl) age < 6 years</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Rigid Musculoskeletal Immobilization (Custom Splint or Cast)</font><br> '

GO