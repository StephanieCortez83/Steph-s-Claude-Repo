SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ICD_10_ADDITIONAL_INCLUSION_TERM_SELECT_BY_CODE]  
--[Kalpana Panwar 3/22/2023] Modified the Vrachar from 20 to 10 in @CODE param, when it is varchar(20)n the stored proc does not return an results
--We matched it to the column width in table 
 @CODE varchar(10)  
AS  
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
 SELECT   
   [ICD_10_INCLUSION_TERM_ID]  
  ,[INCLUSION_TERM_DESC]  
  ,[FIRST_CODE]  
  ,[LAST_CODE]  
  ,[CREATION_DTTM]  
  ,[CREATED_BY_USER_ID]  
  ,[UPDATE_DTTM]  
  ,[UPDATED_BY_USER_ID]  
 FROM   
  [dbo].[ICD_10_ADDITIONAL_INCLUSION_TERM] with (NOLOCK)  
    WHERE  
        (@CODE >= FIRST_CODE)   
  AND (@CODE <= LAST_CODE)  
    ORDER BY   
  [INCLUSION_TERM_DESC]  
GO
