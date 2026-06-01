SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CHART_DIAGNOSIS_CODE_ICD10_SELECT_BY_CHART_ID_AND_DATE_OF_SERVICE_AND_LEVEL_NUMBER]    
    @CHART_ID INT = NULL    
    ,@DATE_OF_SERVICE DATE = NULL    
    ,@LEVEL_NUMBER INT = NULL    
AS    
    
SET NOCOUNT ON    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
-- If LEVEL_NUMBER == 999, don't include it in the WHERE clause    
IF @LEVEL_NUMBER = 999    
BEGIN    
 SELECT    
   [CDC].[CHART_DIAGNOSIS_CODE_ICD10_ID]    
  ,[CDC].[ICD10_CODE]    
  ,[CDC].[CHART_ID]    
  ,[CDC].[DIAGNOSIS_TYPE_ID]    
  ,[CDC].[LEVEL_NUMBER]    
  ,[CDC].[IS_PRIMARY]    
  ,[CDC].[CREATION_DATE_TIME]    
  ,[CDC].[CREATING_USER_PROFILE_ID]    
  ,[CDC].[CHANGED_DATE_TIME]    
  ,[CDC].[CHANGING_USER_PROFILE_ID]    
  ,[CDC].[POSTING_ORDER]    
  ,[CDC].[MAPPED_ICD9_CODE]    
  ,[CDC].[FULFILLS_REQUIREMENT_OF_ICD10_CODE]    
  ,[CDC].[OVERRIDE_RULE_EDIT]    
  ,[CDC].[OVERRIDE_RULE_EDIT_USER_PROFILE_ID]    
  --[Kalpana Panwar 3/22/2023] Added conditional access to description, if Description is empty/null get short description  
  ,CASE  
  WHEN ([CM].[DESCRIPTION] = '' OR  [CM].[DESCRIPTION] IS NULL) AND [CDC].[CHART_DIAGNOSIS_CODE_ICD10_ID]  > 0 THEN   
  [ICD10CM].[SHORT_DESCRIPTION]  
  ELSE  
  [CM].[DESCRIPTION]  
  END AS [DESCRIPTION]  
  ,CASE  
  WHEN [EX].[CODER_QA_REPORT_EXCLUSION_ID] IS NULL THEN 0  
  ELSE 1  
  END AS [EXCLUDE_FROM_CODER_QA_REPORT]     
 FROM       
  [CHART_DIAGNOSIS_CODE_ICD10] CDC WITH (NOLOCK)    
 LEFT OUTER JOIN     
  [ICD_10_CODE_MASTER] CM WITH (NOLOCK)    
 ON     
  [CM].[ICD_10_CODE] = [CDC].[ICD10_CODE]    
 AND (([CM].[EFFECTIVE_DT] <= @DATE_OF_SERVICE) AND ([CM].[EXPIRATION_DT] >= @DATE_OF_SERVICE))    
 --[Kalpana Panwar 3/22/2023] Added this left outer join to get access to this table to get short description for ICD 10  
 LEFT OUTER JOIN   
 ICD10_CM ICD10CM WITH (NOLOCK)    
 ON  
  [ICD10CM].ICD10_CM = UPPER(REPLACE([CDC].[ICD10_CODE],'.',''))  
 --[Kalpana Panwar 3/22/2023] Added this left outer join to get CODER_QA_REPORT_EXCLUSION_ID count and removed the inline query from select  
 LEFT OUTER JOIN  
 [CODER_QA_REPORT_EXCLUSION] EX WITH (NOLOCK)    
 ON  
   [EX].[SOURCE_RECORD_TABLE_NAME] = 'CHART_DIAGNOSIS_CODE_ICD10'    
   AND [EX].[KEY_VALUE_1] = [CDC].[CHART_ID]    
   AND [EX].[KEY_VALUE_2] = [CDC].[ICD10_CODE]    
 WHERE      
  [CDC].[CHART_ID] = @CHART_ID    
 ORDER  BY     
  [CDC].[POSTING_ORDER] ASC     
END    
ELSE    
-- If LEVEL_NUMBER != 999, include it in the WHERE clause    
BEGIN    
 SELECT    
   [CDC].[CHART_DIAGNOSIS_CODE_ICD10_ID]    
  ,[CDC].[ICD10_CODE]    
  ,[CDC].[CHART_ID]    
  ,[CDC].[DIAGNOSIS_TYPE_ID]    
  ,[CDC].[LEVEL_NUMBER]    
  ,[CDC].[IS_PRIMARY]    
  ,[CDC].[CREATION_DATE_TIME]    
  ,[CDC].[CREATING_USER_PROFILE_ID]    
  ,[CDC].[CHANGED_DATE_TIME]    
  ,[CDC].[CHANGING_USER_PROFILE_ID]    
  ,[CDC].[POSTING_ORDER]    
  ,[CDC].[MAPPED_ICD9_CODE]    
  ,[CDC].[FULFILLS_REQUIREMENT_OF_ICD10_CODE]    
  ,[CDC].[OVERRIDE_RULE_EDIT]    
  ,[CDC].[OVERRIDE_RULE_EDIT_USER_PROFILE_ID]    
  --[Kalpana Panwar 3/22/2023] Added conditional access to description, if Description is empty/null get short description  
  ,CASE  
  WHEN ([CM].[DESCRIPTION] = '' OR  [CM].[DESCRIPTION] IS NULL) AND [CDC].[CHART_DIAGNOSIS_CODE_ICD10_ID]  > 0 THEN   
  [ICD10CM].[SHORT_DESCRIPTION]  
  ELSE  
  [CM].[DESCRIPTION]  
  END AS [DESCRIPTION]  
  --[Kalpana Panwar 3/22/2023] Added conditional access to report Exclusion id and moved the logic to see if we any records to left outer join  
  ,CASE  
  WHEN [EX].[CODER_QA_REPORT_EXCLUSION_ID] IS NULL THEN 0  
  ELSE 1  
  END AS [EXCLUDE_FROM_CODER_QA_REPORT]       
 FROM       
  [CHART_DIAGNOSIS_CODE_ICD10] CDC WITH (NOLOCK)    
 LEFT OUTER JOIN     
  [ICD_10_CODE_MASTER] CM WITH (NOLOCK)    
 ON     
  [CM].[ICD_10_CODE] = [CDC].[ICD10_CODE]    
 AND (([CM].[EFFECTIVE_DT] <= @DATE_OF_SERVICE) AND ([CM].[EXPIRATION_DT] >= @DATE_OF_SERVICE))    
 --[Kalpana Panwar 3/22/2023] Added this left outer join to get access to this table to get short description for ICD 10  
 LEFT OUTER JOIN   
 ICD10_CM ICD10CM WITH (NOLOCK)    
 ON  
  [ICD10CM].ICD10_CM = UPPER(REPLACE([CDC].[ICD10_CODE],'.',''))  
  --[Kalpana Panwar 3/22/2023] Added this left outer join to get CODER_QA_REPORT_EXCLUSION_ID count and removed the inline query from select  
 LEFT OUTER JOIN  
 [CODER_QA_REPORT_EXCLUSION] EX WITH (NOLOCK)    
 ON  
   [EX].[SOURCE_RECORD_TABLE_NAME] = 'CHART_DIAGNOSIS_CODE_ICD10'    
   AND [EX].[KEY_VALUE_1] = [CDC].[CHART_ID]    
   AND [EX].[KEY_VALUE_2] = [CDC].[ICD10_CODE]    
 WHERE      
  [CDC].[CHART_ID] = @CHART_ID    
 AND [CDC].[LEVEL_NUMBER] = @LEVEL_NUMBER    
 ORDER  BY     
  [CDC].[POSTING_ORDER] ASC     
END    
GO
