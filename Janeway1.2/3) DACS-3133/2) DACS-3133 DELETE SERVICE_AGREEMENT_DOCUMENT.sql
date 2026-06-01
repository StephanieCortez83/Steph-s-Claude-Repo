----------------------------------------
-- 03) DACS-3131 - SQL Script will delete all documents for Service agreement for Document type id = 7 (Denials). Also, remove type id =7 from SERVICE_AGREEMENT_DOCUMENT_TYPE TABLE
----------------------------------------
USE [RevCycleDB]
GO

SELECT * FROM SERVICE_AGREEMENT_DOCUMENT 
WHERE service_agreement_document_type_id = 7

DELETE FROM SERVICE_AGREEMENT_DOCUMENT 
WHERE service_agreement_document_type_id = 7

DELETE FROM SERVICE_AGREEMENT_DOCUMENT_TYPE
WHERE service_agreement_document_type_id = 7