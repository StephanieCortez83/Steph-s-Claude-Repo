SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ICD_10_SPECIFIC_SUBSET_SEARCH_WITH_T_CODES]
(
	@parmWord1 varchar(50),
	@parmWord2 varchar(50),	
	@parmWord3 varchar(50),
	@selectedExtensionID int,
	@selectedExtensionID2 int
			
)
AS
BEGIN


declare @containsParmWord1 nvarchar(1000)
declare @containsParmWord2 nvarchar(1000)
declare @containsParmWord3 nvarchar(1000)

set @containsParmWord1 = null
set @containsParmWord2 = null
set @containsParmWord3 = null

declare @synTable table (syn_id int identity (1,1), syn_word varchar(1000), processed bit)
declare @id int
declare @synWord varchar(250)

-- Try searching for multi-word synonyms first 
if @parmWord2 <> ''
BEGIN	
	insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord1 + ' ' + @parmWord2
	set @containsParmWord1 = ' FormsOf(INFLECTIONAL, "' + @parmWord1 + '") ' 
	if (select COUNT(*) from @synTable) > 0
	BEGIN
		WHILE exists (select * from @synTable where processed = 0)
		BEGIN 
			set @id = (select MIN(syn_id) from @synTable where processed = 0)	
			set @synWord = (Select syn_word from @synTable where syn_id = @id)
			set @containsParmWord1 = @containsParmWord1 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") '
			update @synTable SET Processed = 1 where syn_id = @id
		END
	END
END

insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord1
set @containsParmWord1 = ' FormsOf(INFLECTIONAL, "' + @parmWord1 + '") ' 
if (select COUNT(*) from @synTable) > 0
BEGIN
	WHILE exists (select * from @synTable where processed = 0)
	BEGIN 
		set @id = (select MIN(syn_id) from @synTable where processed = 0)	
		set @synWord = (Select syn_word from @synTable where syn_id = @id)
		set @containsParmWord1 = @containsParmWord1 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") '
		update @synTable SET Processed = 1 where syn_id = @id
	END
END

if @parmWord2 <> ''
BEGIN	
	DELETE from @synTable
	insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord2
	set @containsParmWord2 = ' FormsOf(INFLECTIONAL, "' + @parmWord2 + '") ' 
	if (select COUNT(*) from @synTable) > 0
	BEGIN
		WHILE exists (select * from @synTable where processed = 0)
		BEGIN 
			set @id = (select MIN(syn_id) from @synTable where processed = 0)	
			set @synWord = (Select syn_word from @synTable where syn_id = @id)
			set @containsParmWord2 = @containsParmWord2 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") '
			update @synTable SET Processed = 1 where syn_id = @id
		END
	END
	
END	

if @parmWord3 <> ''
BEGIN	
	DELETE from @synTable
	insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord3
	set @containsParmWord3 = ' FormsOf(INFLECTIONAL, "' + @parmWord3 + '") ' 
	if (select COUNT(*) from @synTable) > 0
	BEGIN
		WHILE exists (select * from @synTable where processed = 0)
		BEGIN 
			set @id = (select MIN(syn_id) from @synTable where processed = 0)	
			set @synWord = (Select syn_word from @synTable where syn_id = @id)
			set @containsParmWord3 = @containsParmWord3 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") '
			update @synTable SET Processed = 1 where syn_id = @id
		END
	END
END	


if @containsParmWord3 is not null 
BEGIN 
	SELECT DISTINCT z.ResultCode, z.ResultText from (
	SELECT DISTINCT y.ResultCode, cm.DESCRIPTION as ResultText from ICD_10_CODE_MASTER cm, (
	SELECT DISTINCT  x.ResultText, x.ResultCode
	FROM 
	(
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK)
	WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2)
	AND   CONTAINS(cm.[DESCRIPTION], @containsParmWord3) 
	AND	  cm.ICD_10_CODE in (SELECT rl.ADDITIONAL_CODE 
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )	
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE

	UNION ALL
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK), ICD_10_ADDITIONAL_INCLUSION_TERM it with (NOLOCK)
	WHERE CONTAINS(it.INCLUSION_TERM_DESC,  @containsParmWord1) AND CONTAINS(it.INCLUSION_TERM_DESC, @containsParmWord2)
	AND   CONTAINS(it.INCLUSION_TERM_DESC, @containsParmWord3) 
	AND   ((cm.ICD_10_CODE >= it.FIRST_CODE AND cm.ICD_10_CODE <= it.LAST_CODE) or (cm.ICD_10_CODE = it.FIRST_CODE))
	AND	  cm.ICD_10_CODE in (SELECT rl.ADDITIONAL_CODE 
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )			
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE
	
	UNION ALL
	select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode 
	from	ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), 
			ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK), 
			ICD_10_CODE_MASTER cm2 with (NOLOCK)			
	WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2)
	AND   CONTAINS(cm.TITLE, @containsParmWord3) 
	and   cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID
	and   cd.COLUMN_NUMBER = 1 and cd.CODE <> '--'
	and   substring(cd.CODE,1,6) = cm2.ICD_10_CODE
	and	  cm2.ICD_10_CODE in (SELECT rl.ADDITIONAL_CODE 
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )		
	GROUP by cm.TITLE, cd.CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2)
	AND   CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord3) 
	AND cm.ICD_10_CODE is not null
	AND	  cm.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(cm.ICD_10_CODE))
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )	
	AND   cm.ICD_10_CODE = cm2.ICD_10_CODE	
	GROUP by cm2.DESCRIPTION, cm.ICD_10_CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
	AND   CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3) 
	AND cm.ICD_10_CODE is not null
	AND	  cm.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(cm.ICD_10_CODE))
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )	
	AND   cm.ICD_10_CODE = cm2.ICD_10_CODE
	GROUP by cm2.DESCRIPTION, cm.ICD_10_CODE
	) x
	where x.ResultCode <> ''
	) y 
	where y.ResultCode = cm.ICD_10_CODE
	UNION ALL
	select distinct y2.ResultCode, y2.ResultText from 
		(
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '1'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '1'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3)		
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'
		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '2'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '2'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3)		
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '3'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '3'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3)		
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '4'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '4'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3)		
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '5'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '5'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '6'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '6'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		


		) y2
	where y2.ResultCode is not null
	GROUP by y2.ResultText, y2.ResultCode
	) z
	order by  z.ResultCode
END 

ELSE

if @containsParmWord2 is not null 
BEGIN
	SELECT DISTINCT z.ResultCode, z.ResultText from (
	SELECT DISTINCT y.ResultCode, cm.DESCRIPTION as ResultText  from ICD_10_CODE_MASTER cm, (
	SELECT DISTINCT  x.ResultText, x.ResultCode
	FROM 
	(
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK)
	WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2)
	AND	  cm.ICD_10_CODE in (SELECT rl.ADDITIONAL_CODE 
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )	
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE

	UNION ALL
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK), ICD_10_ADDITIONAL_INCLUSION_TERM it with (NOLOCK)
	WHERE CONTAINS(it.INCLUSION_TERM_DESC,  @containsParmWord1) AND CONTAINS(it.INCLUSION_TERM_DESC, @containsParmWord2)
	AND   ((cm.ICD_10_CODE >= it.FIRST_CODE AND cm.ICD_10_CODE <= it.LAST_CODE) or (cm.ICD_10_CODE = it.FIRST_CODE))
	AND	  cm.ICD_10_CODE in (SELECT rl.ADDITIONAL_CODE 
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )		
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE

	UNION ALL
	select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode 
	from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK),
			ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK), 
			ICD_10_CODE_MASTER cm2	 with (NOLOCK)	
	WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2)
	and   cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID
	and   cd.COLUMN_NUMBER = 1 and cd.CODE <> '--'
	and   substring(cd.CODE,1,6) = cm2.ICD_10_CODE	
	and	  cm2.ICD_10_CODE in (SELECT rl.ADDITIONAL_CODE 
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )		
	GROUP by cm.TITLE, cd.CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2)
	AND cm.ICD_10_CODE is not null
	AND	  cm.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(cm.ICD_10_CODE))
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )	
	AND   cm.ICD_10_CODE = cm2.ICD_10_CODE	
	GROUP by cm2.DESCRIPTION, cm.ICD_10_CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
	AND cm.ICD_10_CODE is not null
	AND	  cm.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(cm.ICD_10_CODE))
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )	
	AND   cm.ICD_10_CODE = cm2.ICD_10_CODE	
	GROUP by cm2.DESCRIPTION, cm.ICD_10_CODE
	) x
	where x.ResultCode <> ''
	) y 
	where y.ResultCode = cm.ICD_10_CODE

	UNION ALL
	select distinct y2.ResultCode, y2.ResultText from 
		(
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '1'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '1'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'
		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '2'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '2'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '3'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '3'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '4'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '4'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '5'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '5'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '6'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '6'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) OR CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		

		) y2
	where y2.ResultCode is not null
	GROUP by y2.ResultText, y2.ResultCode
	) z
	order by  z.ResultCode

END

ELSE

if @containsParmWord1 is not null 
BEGIN
	declare @codeWord varchar(15)
	if (LEN(@parmWord1) < 7 AND LEN(@parmWord1) > 2)
	BEGIN
		if (LEN(@parmWord1) = 3)
		BEGIN
			set @codeWord = @parmWord1
		END
		ELSE
		set @codeWord = SUBSTRING(@parmWord1, 1, 3) + '.' + SUBSTRING(@parmWord1, 4, LEN(@parmWord1) - 3)
	END
	
	SELECT DISTINCT z.ResultCode, z.ResultText from (
	SELECT DISTINCT y.ResultCode, cm.DESCRIPTION as ResultText  from ICD_10_CODE_MASTER cm, (	
	SELECT DISTINCT  x.ResultText, x.ResultCode
	FROM 
	(
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK)
	WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) 
	AND	  cm.ICD_10_CODE in (SELECT rl.ADDITIONAL_CODE 
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )							 
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE

	UNION ALL 
	
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK)
	WHERE cm.ICD_10_CODE LIKE @codeWord + '%' 
	AND	  cm.ICD_10_CODE in (SELECT rl.ADDITIONAL_CODE 
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )	
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE
	
	UNION ALL
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK), ICD_10_ADDITIONAL_INCLUSION_TERM it with (NOLOCK)
	WHERE CONTAINS(it.INCLUSION_TERM_DESC,  @containsParmWord1) 
	AND   ((cm.ICD_10_CODE >= it.FIRST_CODE AND cm.ICD_10_CODE <= it.LAST_CODE) or (cm.ICD_10_CODE = it.FIRST_CODE))	
	AND	  cm.ICD_10_CODE in (SELECT rl.ADDITIONAL_CODE 
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )	
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE
	
	UNION ALL
	select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode 
	from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK),
			ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK), 
			ICD_10_CODE_MASTER cm2	with (NOLOCK)
	WHERE CONTAINS(cm.TITLE, @containsParmWord1) 
	and   cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID
	and   cd.COLUMN_NUMBER = 1 and cd.CODE <> '--'
	and   substring(cd.CODE,1,6) = cm2.ICD_10_CODE		
	and	  cm2.ICD_10_CODE in (SELECT rl.ADDITIONAL_CODE 
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )		
	GROUP by cm.TITLE, cd.CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) 
	AND cm.ICD_10_CODE is not null
	AND	  cm.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(cm.ICD_10_CODE))
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )		
	AND   cm.ICD_10_CODE = cm2.ICD_10_CODE	
	GROUP by cm2.DESCRIPTION, cm.ICD_10_CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) 
	AND	  cm.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(cm.ICD_10_CODE))
							 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
							 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
							 )	
	AND   cm.ICD_10_CODE = cm2.ICD_10_CODE		
	GROUP by cm2.DESCRIPTION, cm.ICD_10_CODE

	) x
	where x.ResultCode <> ''
	) y 
	where y.ResultCode = cm.ICD_10_CODE
	--order by  y.ResultCode	
	
	UNION ALL
	select distinct y2.ResultCode, y2.ResultText from 
		(
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '1'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '1'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'
		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '2'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '2'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '3'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))					 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '3'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '4'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '4'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '5'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '5'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		
		UNION ALL 
		 SELECT  cm.DRUG_TRADE_NAME + ' -' + 
		  (STUFF((SELECT '; ' + icm.DESCRIPTION AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac, ICD_10_CODE_MASTER icm			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   rac.ADDITIONAL_CODE = icm.ICD_10_CODE
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 		
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '6'			
				For XML Path ('')),1,1,'')) as ResultText, 		
		'Compound(' +  
		  (STUFF((SELECT ',' + UPPER(rac.ADDITIONAL_CODE)  AS [text()]
				FROM DRUG_COMPOUND_INGREDIENT dci, DRUG d2, ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rac			
				WHERE dci.COMPOUND_DRUG_ID = cm.DRUG_ID
				AND   rac.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2)
				AND   dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
				AND	  d2.ICD_10_CODE in (SELECT SUBSTRING(rl.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE))
										 FROM ICD_10_RULE_ADDITIONAL_CODE_DEFINITION rl
										 WHERE rl.ICD_10_RULE_EXTENSION_ID IN (@selectedExtensionID, @selectedExtensionID2))								 
				AND   d2.ICD_10_CODE = SUBSTRING(rac.ADDITIONAL_CODE,1, LEN(d2.ICD_10_CODE)) 	
				--AND SUBSTRING(rac.ADDITIONAL_CODE, PATINDEX('%X%',rac.ADDITIONAL_CODE) + 1,1) = '6'			
				For XML Path ('')),1,1,'')) + ')' as ResultCode 
		from DRUG cm with (NOLOCK)
		WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1)
		AND   cm.DRUG_CLASSIFCATION = 'Multiingredient'		
		) y2		
	where y2.ResultCode is not null
	GROUP by y2.ResultText, y2.ResultCode
	) z
	order by  z.ResultCode
END

END



GO
