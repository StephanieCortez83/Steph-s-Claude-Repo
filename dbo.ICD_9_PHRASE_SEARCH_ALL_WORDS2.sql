SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ICD_9_PHRASE_SEARCH_ALL_WORDS2]
(
	@parmDate datetime, 
	@parmWord1 varchar(50),
	@parmWord2 varchar(50),	
	@parmWord3 varchar(50),
	@parmWord4 varchar(50),
	@parmWord5 varchar(50)				
)
AS
BEGIN

declare @containsParmWord1 nvarchar(1000)
declare @containsParmWord2 nvarchar(1000)
declare @containsParmWord3 nvarchar(1000)
declare @containsParmWord4 nvarchar(1000)
declare @containsParmWord5 nvarchar(1000)

set @containsParmWord1 = null
set @containsParmWord2 = null
set @containsParmWord3 = null
set @containsParmWord4 = null
set @containsParmWord5 = null

declare @synTable table (syn_id int identity (1,1), syn_word varchar(1000), processed bit)
declare @id int
declare @synWord varchar(250)

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

if @parmWord4 <> ''
BEGIN	
	DELETE from @synTable
	insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord4
	set @containsParmWord4 = ' FormsOf(INFLECTIONAL, "' + @parmWord4 + '") ' 
	if (select COUNT(*) from @synTable) > 0
	BEGIN
		WHILE exists (select * from @synTable where processed = 0)
		BEGIN 
			set @id = (select MIN(syn_id) from @synTable where processed = 0)	
			set @synWord = (Select syn_word from @synTable where syn_id = @id)
			set @containsParmWord4 = @containsParmWord4 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") '
			update @synTable SET Processed = 1 where syn_id = @id
		END
	END
END	

if @parmWord5 <> ''
BEGIN	
	DELETE from @synTable
	insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord5
	set @containsParmWord5 = ' FormsOf(INFLECTIONAL, "' + @parmWord5 + '") ' 
	if (select COUNT(*) from @synTable) > 0
	BEGIN
		WHILE exists (select * from @synTable where processed = 0)
		BEGIN 
			set @id = (select MIN(syn_id) from @synTable where processed = 0)	
			set @synWord = (Select syn_word from @synTable where syn_id = @id)
			set @containsParmWord5 = @containsParmWord5 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") '
			update @synTable SET Processed = 1 where syn_id = @id
		END
	END
END	

if @containsParmWord5 is not null
BEGIN
	SELECT DISTINCT  x.ResultText, x.ResultCode, x.code_status, x.Relative_Value
	FROM 
	(
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value  
	from ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE CONTAINS(cm.LONG_DESC, @containsParmWord1) AND CONTAINS(cm.LONG_DESC, @containsParmWord2)
	AND   CONTAINS(cm.LONG_DESC, @containsParmWord3) AND CONTAINS(cm.LONG_DESC, @containsParmWord4) AND CONTAINS(cm.LONG_DESC, @containsParmWord5)
	AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value		
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value
	from ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  IN (SELECT DISTINCT(icdxref.CODE) FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord2) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord3) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord4) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord5)) 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status	, ru.relative_value	
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value 
		from ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE cm.ICD9_CODE IN (SELECT DISTINCT(icdxref.CODE) 
		FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK) WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord2) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord3)
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord4)
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord5)) 
		AND (cm.ICD9_CODE IN (SELECT icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE icdag.CODE = cm.ICD9_CODE AND icdag.FEMALE = '1') 
		OR cm.CODE_STATUS = 'I') 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value			
	) x
	where x.ResultCode <> ''
	order by  x.ResultCode	
END

ELSE
if @containsParmWord4 is not null 
BEGIN 
	SELECT DISTINCT  x.ResultText, x.ResultCode, x.code_status, x.Relative_Value
	FROM 
	(
	SELECT cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value  
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE CONTAINS(cm.LONG_DESC, @containsParmWord1) AND CONTAINS(cm.LONG_DESC, @containsParmWord2)
	AND   CONTAINS(cm.LONG_DESC, @containsParmWord3) AND CONTAINS(cm.LONG_DESC, @containsParmWord4) 
	AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value		
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  IN (SELECT DISTINCT(icdxref.CODE) FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord2) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord3) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord4)) 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value			
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCOde, cm.code_status, MAX(cm.icd9_cm_id)as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE cm.ICD9_CODE IN (SELECT DISTINCT(icdxref.CODE) 
		FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK) WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord2) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord3)
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord4)) 
		AND (cm.ICD9_CODE IN (SELECT icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE icdag.CODE = cm.ICD9_CODE AND icdag.FEMALE = '1') 
		OR cm.CODE_STATUS = 'I') 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value			
	) x
	where x.ResultCode <> ''
	order by  x.ResultCode	
END
ELSE

if @containsParmWord3 is not null 
BEGIN 
	SELECT DISTINCT  x.ResultText, x.ResultCode, x.code_status, x.Relative_Value
	FROM 
	(
	SELECT cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id)as cmID  , ru.relative_value 
		FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE CONTAINS(cm.LONG_DESC, @containsParmWord1) AND CONTAINS(cm.LONG_DESC, @containsParmWord2)
	AND   CONTAINS(cm.LONG_DESC, @containsParmWord3) 
	AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value		
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id)as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  IN (SELECT DISTINCT(icdxref.CODE) FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord2) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord3)) 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value			
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCOde, cm.code_status, MAX(cm.icd9_cm_id)as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE cm.ICD9_CODE IN (SELECT DISTINCT(icdxref.CODE) 
		FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK) WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord2) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord3)) 
		AND (cm.ICD9_CODE IN (SELECT icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE icdag.CODE = cm.ICD9_CODE AND icdag.FEMALE = '1') 
		OR cm.CODE_STATUS = 'I') 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status	, ru.relative_value		
	) x
	where x.ResultCode <> ''
	order by  x.ResultCode	
END 

ELSE

if @containsParmWord2 is not null 
BEGIN
	SELECT DISTINCT  x.ResultText, x.ResultCode, x.code_status, x.Relative_Value
	FROM 
	(
	SELECT cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, max(cm.icd9_cm_id) as cmID  , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE CONTAINS(cm.LONG_DESC, @containsParmWord1) AND CONTAINS(cm.LONG_DESC, @containsParmWord2)
	AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value	
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  IN (SELECT DISTINCT(icdxref.CODE) FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord2)) 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value				
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCOde, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE cm.ICD9_CODE IN (SELECT DISTINCT(icdxref.CODE) 
		FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord2)) 
		AND (cm.ICD9_CODE IN (SELECT icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE icdag.CODE = cm.ICD9_CODE AND icdag.FEMALE = '1') 
		OR cm.CODE_STATUS = 'I') 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status	, ru.relative_value		
	) x
	where x.ResultCode <> ''
	order by  x.ResultCode	
END

ELSE
if @containsParmWord1 is not null 
BEGIN
	SELECT DISTINCT  x.ResultText, x.ResultCode, x.code_status, x.Relative_Value
	FROM 
	(
	SELECT cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value  
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE CONTAINS(cm.LONG_DESC, @containsParmWord1)
	AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value		
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  IN (SELECT DISTINCT(icdxref.CODE) FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1)) 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status	, ru.relative_value		
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCOde, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE cm.ICD9_CODE IN (SELECT DISTINCT(icdxref.CODE) 
		FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1)) 
		AND (cm.ICD9_CODE IN (SELECT icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE icdag.CODE = cm.ICD9_CODE AND icdag.FEMALE = '1') 
		OR cm.CODE_STATUS = 'I') 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status	, ru.relative_value		
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  LIKE @parmWord1 + '%' 
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status	, ru.relative_value		
	
	) x
	where x.ResultCode <> ''
	order by  x.ResultCode	
END

END



--UNION ALL
--select nd.PROPRIETARY_NAME + ' (' + cm.Title + ')' as ResultText, substring(cd.CODE,1,6) as ResultCode 
--from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm, ICD_10_TABLE_OF_DRUGS_CODES cd, ICD_10_NDC_TABLE nd
--where CONTAINS (nd.PROPRIETARY_NAME, @containsParmWordAll) or CONTAINS(nd.NON_PROPRIETARY_NAME, @containsParmWordAll)
--and   nd.NON_PROPRIETARY_NAME like '%' + cm.TITLE + '%'
--and   cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID
--and   cm.LEVEL = 0
--and   cd.COLUMN_NUMBER = 1 and cd.CODE <> '--'







GO
