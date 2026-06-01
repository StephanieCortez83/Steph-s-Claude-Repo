SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     PROC [dbo].[SelectICD10RuleExtensionBySelectedCodeAndDateOfService]    
@SelectedCode AS VARCHAR(100)    
, @DateOfService DATE    
WITH EXEC AS CALLER AS          
BEGIN          
    -- setup resources          
    SET NOCOUNT ON          
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED     
    SELECT   
    DISTINCT  
        [RULE_TYPE_CD]      
        ,[FIRST_CODE]  
        ,[LAST_CODE]  INTO #Temp_ICD10_RULE    
    FROM       
        [ICD_10_RULE]    
    WHERE       
        [RULE_TYPE_CD] IN (2,3,5,8) AND
        (      
            @DateOfService IS NULL      
        OR     
        (     
            [EFFECTIVE_DT] <= @DateOfService AND       
            [EXPIRATION_DT] >= @DateOfService    
        )    
        ) AND    
        (    
            (@SelectedCode BETWEEN FIRST_CODE and LAST_CODE)     
            OR     
            FIRST_CODE = @SelectedCode     
            OR    
            (@SelectedCode >= FIRST_CODE AND @SelectedCode LIKE (LAST_CODE + '%')  )
        )      
    ORDER BY        
        [FIRST_CODE]    
        ,[LAST_CODE]    
        ,[RULE_TYPE_CD];     
    SELECT    
    DISTINCT
        [ICD_10_RULE_EXTENSION].[ICD_10_RULE_EXTENSION_ID],     
        [ICD_10_RULE_EXTENSION].[RULE_TYPE_CD],     
        [ICD_10_RULE_EXTENSION].[FIRST_CODE],     
        [ICD_10_RULE_EXTENSION].[LAST_CODE],     
        [ICD_10_RULE_EXTENSION].[RULE_DESCRIPTION],     
        [ICD_10_RULE_EXTENSION].[FLAG_FOR_QA],     
        [ICD_10_RULE_EXTENSION].[SEQUENCING_RULE],     
        [ICD_10_RULE_EXTENSION].[ADDTL_CODE_RULE],     
        [ICD_10_RULE_EXTENSION].[CODE_LIST_RULE],     
        [ICD_10_RULE_EXTENSION].[SPECIAL_RULE_TYPE_CD],     
        [ICD_10_RULE_EXTENSION].[EFFECTIVE_DT],     
        [ICD_10_RULE_EXTENSION].[EXPIRATION_DT]    
    FROM     
        [ICD_10_RULE_EXTENSION]     
        JOIN     
        [#Temp_ICD10_RULE]     
    ON 
        ([ICD_10_RULE_EXTENSION].[FIRST_CODE] = [#Temp_ICD10_RULE].[FIRST_CODE] AND     
        [ICD_10_RULE_EXTENSION].[LAST_CODE] = [#Temp_ICD10_RULE].[LAST_CODE])     
    WHERE     
        (    
            (    
                [ICD_10_RULE_EXTENSION].[FIRST_CODE] = [#Temp_ICD10_RULE].[FIRST_CODE] AND    
                [ICD_10_RULE_EXTENSION].[LAST_CODE] = [#Temp_ICD10_RULE].[LAST_CODE]    
            )     
            OR     
            (    
                [ICD_10_RULE_EXTENSION].[FIRST_CODE] = @SelectedCode AND     
                [ICD_10_RULE_EXTENSION].[LAST_CODE] = @SelectedCode AND     
                @SelectedCode >= [#Temp_ICD10_RULE].[FIRST_CODE] AND    
                @SelectedCode <= (SELECT MAX(cm.ICD_10_CODE) FROM [ICD_10_CODE_MASTER] cm with (NOLOCK) WHERE cm.ICD_10_CODE LIKE [#Temp_ICD10_RULE].[LAST_CODE] + '%')    
            )    
        ) AND    
        (    
            @DateOfService IS NULL    
            OR 
            (    
                [ICD_10_RULE_EXTENSION].[EFFECTIVE_DT] <= @DateOfService     
                AND [ICD_10_RULE_EXTENSION].[EXPIRATION_DT] >= @DateOfService    
            )    
        )    
    ORDER BY       
        [ICD_10_RULE_EXTENSION].[ADDTL_CODE_RULE],     
        [ICD_10_RULE_EXTENSION].[FIRST_CODE],     
        [ICD_10_RULE_EXTENSION].[LAST_CODE];     
END
GO
