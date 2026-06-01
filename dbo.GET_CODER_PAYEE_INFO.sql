SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_CODER_PAYEE_INFO] 
  @CODER_USER_PROFILE_ID int
AS
BEGIN

SELECT 
            u.user_profile_id,
                  pi.PAYEE_NAME,
                  pi.TAXPAYER_ID_TYPE,
                  pi.DIRECT_DEPOSIT,
                  pi.BANK_ROUTING_NBR,
                  pi.BANK_ACCT_NBR,
                  pi.CREATION_DATE_TIME,
                  pi.CREATING_USER_PROFILE_ID,
                  pi.CHANGED_DATE_TIME,
                  pi.CHANGING_USER_PROFILE_ID,
                  '' as AccountNumber,
                  '' as Phone,
                  '' as FirstName,
                  '' as LastName,
                  '' as CompanyName,
                  1 as IsActive,
                  0 as ListID,
                  '' as Name,
                  '' as VendorAddress_Addr1,
                  '' as VendorAddress_Addr2,
                  '' as VendorAddress_City,
                  '' as VendorAddress_State,
                  '' as VendorAddress_PostalCode,
                  '' as NameOnCheck,
                  '' as VendorTaxIdent,
                  u.EMAIL_ADDRESS,
                  1 as Status,
                  u.PHONE_AREA_CODE,
                  u.PHONE_NUMBER,
                  u.PHONE_EXT,
                  u.ADDR_LINE_1,
                  u.ADDR_LINE_2,
                  u.CITY,
                  u.STATE,
                  u.POSTAL_CODE
                  
                  
FROM                    user_profile u          
LEFT OUTER JOIN         coder_payee_info pi  on u.user_profile_id = pi.coder_user_profile_id                  
WHERE                   u.user_profile_id = @CODER_USER_PROFILE_ID
                  
END               
GO
