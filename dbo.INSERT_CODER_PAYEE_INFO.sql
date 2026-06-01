SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[INSERT_CODER_PAYEE_INFO] 
            @CODER_USER_PROFILE_ID int,
            @PAYEE_NAME varchar(255),
            @TAXPAYER_ID_TYPE varchar(1),
            @DIRECT_DEPOSIT bit,
            @BANK_ROUTING_NUMBER int,
            @BANK_ACCT_NUMBER varchar(50),
            @CREATION_DATE_TIME datetime,
            @CREATING_USER_PROFILE_ID int,
            @CHANGED_DATE_TIME datetime,
            @CHANGING_USER_PROFILE_ID int
AS
BEGIN

INSERT INTO CODER_PAYEE_INFO (
            CODER_USER_PROFILE_ID,
            PAYEE_NAME,
            TAXPAYER_ID_TYPE,
            DIRECT_DEPOSIT,
            BANK_ROUTING_NBR,
            BANK_ACCT_NBR,
            CREATION_DATE_TIME,
            CREATING_USER_PROFILE_ID,
            CHANGED_DATE_TIME,
            CHANGING_USER_PROFILE_ID)
            VALUES(
            @CODER_USER_PROFILE_ID,
            @PAYEE_NAME,
            @TAXPAYER_ID_TYPE,
            @DIRECT_DEPOSIT,
            @BANK_ROUTING_NUMBER,
            @BANK_ACCT_NUMBER,
            @CREATION_DATE_TIME,
            @CREATING_USER_PROFILE_ID,
            @CHANGED_DATE_TIME,
            @CHANGING_USER_PROFILE_ID
            )


            
END
GO
