---------------------------------------------------------------
/*
DACS-2571:      Deprecate NextGen Funcitonality
Description:    This script drops the synonymsbelow that is
                used by NextGen code:

                report_NG_UnmappedPayers 
                usp_R_NextGen_DFT_Errors
                usp_R_NEXTGEN_Insurances
                usp_R_NextGen_RCM_Clients
                usp_R_NextGen_RCM_Hospitals
                usp_R_RCM_Hospital_Insurances
                usp_U_Client_Facility_Insurance_NextGen_Key
                usp_U_Reprocess_Void_NextGen_DFT_Error

*/
---------------------------------------------------------------

USE [RevCycleDB];


IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'report_NG_UnmappedPayers')
BEGIN
    DROP SYNONYM report_NG_UnmappedPayers;
    PRINT 'Synonym [report_NG_UnmappedPayers] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_R_NextGen_DFT_Errors')
BEGIN
    DROP SYNONYM usp_R_NextGen_DFT_Errors;
    PRINT 'Synonym [usp_R_NextGen_DFT_Errors] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_R_NEXTGEN_Insurances')
BEGIN
    DROP SYNONYM usp_R_NEXTGEN_Insurances;
    PRINT 'Synonym [usp_R_NEXTGEN_Insurances] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_R_NextGen_RCM_Clients')
BEGIN
    DROP SYNONYM usp_R_NextGen_RCM_Clients;
    PRINT 'Synonym [usp_R_NextGen_RCM_Clients] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_R_NextGen_RCM_Hospitals')
BEGIN
    DROP SYNONYM usp_R_NextGen_RCM_Hospitals;
    PRINT 'Synonym [usp_R_NextGen_RCM_Hospitals] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_R_RCM_Hospital_Insurances')
BEGIN
    DROP SYNONYM usp_R_RCM_Hospital_Insurances;
    PRINT 'Synonym [usp_R_RCM_Hospital_Insurances] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_U_Client_Facility_Insurance_NextGen_Key')
BEGIN
    DROP SYNONYM usp_U_Client_Facility_Insurance_NextGen_Key;
    PRINT 'Synonym [usp_U_Client_Facility_Insurance_NextGen_Key] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_U_Reprocess_Void_NextGen_DFT_Error')
BEGIN
    DROP SYNONYM usp_U_Reprocess_Void_NextGen_DFT_Error;
    PRINT 'Synonym [usp_U_Reprocess_Void_NextGen_DFT_Error] has been dropped.';
END


