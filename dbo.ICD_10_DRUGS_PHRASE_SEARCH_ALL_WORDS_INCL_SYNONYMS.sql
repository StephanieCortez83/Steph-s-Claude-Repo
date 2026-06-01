SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ICD_10_DRUGS_PHRASE_SEARCH_ALL_WORDS_INCL_SYNONYMS]
(
	@parmWord1 varchar(50),
	@parmWord2 varchar(50),	
	@parmWord3 varchar(50)
	--@parmWord4 varchar(50),
	--@parmWord5 varchar(50)				
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
	SELECT DISTINCT y.ResultCode, cm.DESCRIPTION  from ICD_10_CODE_MASTER cm, (
	SELECT DISTINCT  x.ResultText, x.ResultCode
	FROM 
	(
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK)
	WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2)
	AND   CONTAINS(cm.[DESCRIPTION], @containsParmWord3) 
	AND   cm.ICD_10_CODE LIKE 'T%'	
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE

	UNION ALL
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK), ICD_10_ADDITIONAL_INCLUSION_TERM it with (NOLOCK)
	WHERE CONTAINS(it.INCLUSION_TERM_DESC,  @containsParmWord1) AND CONTAINS(it.INCLUSION_TERM_DESC, @containsParmWord2)
	AND   CONTAINS(it.INCLUSION_TERM_DESC, @containsParmWord3) 
	AND   ((cm.ICD_10_CODE >= it.FIRST_CODE AND cm.ICD_10_CODE <= it.LAST_CODE) or (cm.ICD_10_CODE = it.FIRST_CODE))
	AND   cm.ICD_10_CODE LIKE 'T%'		
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
	GROUP by cm.TITLE, cd.CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2)
	AND   CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord3) 
	AND cm.ICD_10_PCS_CODE is not null
	AND   cm.ICD_10_PCS_CODE LIKE 'T%'	
	AND   cm.ICD_10_PCS_CODE = cm2.ICD_10_CODE	
	GROUP by cm2.DESCRIPTION, cm.ICD_10_PCS_CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
	AND   CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3) 
	AND cm.ICD_10_PCS_CODE is not null
	AND   cm.ICD_10_PCS_CODE LIKE 'T%'	
	AND   cm.ICD_10_PCS_CODE = cm2.ICD_10_CODE
	GROUP by cm2.DESCRIPTION, cm.ICD_10_PCS_CODE
	) x
	where x.ResultCode <> ''
	) y 
	where y.ResultCode = cm.ICD_10_CODE
	order by  y.ResultCode	
END 

ELSE

if @containsParmWord2 is not null 
BEGIN
	SELECT DISTINCT y.ResultCode, cm.DESCRIPTION  from ICD_10_CODE_MASTER cm, (
	SELECT DISTINCT  x.ResultText, x.ResultCode
	FROM 
	(
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK)
	WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2)
	AND   cm.ICD_10_CODE LIKE 'T%'	
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE

	UNION ALL
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK), ICD_10_ADDITIONAL_INCLUSION_TERM it with (NOLOCK)
	WHERE CONTAINS(it.INCLUSION_TERM_DESC,  @containsParmWord1) AND CONTAINS(it.INCLUSION_TERM_DESC, @containsParmWord2)
	AND   ((cm.ICD_10_CODE >= it.FIRST_CODE AND cm.ICD_10_CODE <= it.LAST_CODE) or (cm.ICD_10_CODE = it.FIRST_CODE))
	AND   cm.ICD_10_CODE LIKE 'T%'		
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
	GROUP by cm.TITLE, cd.CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2)
	AND cm.ICD_10_PCS_CODE is not null
	AND   cm.ICD_10_PCS_CODE LIKE 'T%'	
	AND   cm.ICD_10_PCS_CODE = cm2.ICD_10_CODE		
	GROUP by cm2.DESCRIPTION, cm.ICD_10_PCS_CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2)
	AND cm.ICD_10_PCS_CODE is not null
	AND   cm.ICD_10_PCS_CODE LIKE 'T%'	
	AND   cm.ICD_10_PCS_CODE = cm2.ICD_10_CODE	
	GROUP by cm2.DESCRIPTION, cm.ICD_10_PCS_CODE
	) x
	where x.ResultCode <> ''
	) y 
	where y.ResultCode = cm.ICD_10_CODE
	order by  y.ResultCode		
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
	SELECT DISTINCT y.ResultCode, cm.DESCRIPTION  from ICD_10_CODE_MASTER cm, (	
	SELECT DISTINCT  x.ResultText, x.ResultCode
	FROM 
	(
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK)
	WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) 
	AND   cm.ICD_10_CODE LIKE 'T%'	
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE

	UNION ALL 
	
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK)
	WHERE cm.ICD_10_CODE LIKE @codeWord + '%' 
	AND   cm.ICD_10_CODE LIKE 'T%'
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE
	
	UNION ALL
	select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode  from ICD_10_CODE_MASTER cm with (NOLOCK), ICD_10_ADDITIONAL_INCLUSION_TERM it with (NOLOCK)
	WHERE CONTAINS(it.INCLUSION_TERM_DESC,  @containsParmWord1) 
	AND   ((cm.ICD_10_CODE >= it.FIRST_CODE AND cm.ICD_10_CODE <= it.LAST_CODE) or (cm.ICD_10_CODE = it.FIRST_CODE))	
	AND   cm.ICD_10_CODE LIKE 'T%'
	GROUP by cm.DESCRIPTION, cm.ICD_10_CODE
	
	UNION ALL
	select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode 
	from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK),
			ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK), 
			ICD_10_CODE_MASTER cm2	with (NOLOCK)
	WHERE CONTAINS(cm.TITLE, @containsParmWord1) 
	and   cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID
	and   cd.COLUMN_NUMBER = 1 and cd.CODE <> '--'
	GROUP by cm.TITLE, cd.CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) 
	AND cm.ICD_10_PCS_CODE is not null
	AND   cm.ICD_10_PCS_CODE LIKE 'T%'	
	AND   cm.ICD_10_PCS_CODE = cm2.ICD_10_CODE			
	GROUP by cm2.DESCRIPTION, cm.ICD_10_PCS_CODE

	UNION ALL
	select cm2.DESCRIPTION as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK), ICD_10_CODE_MASTER cm2 with (NOLOCK)
	WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) 
	AND   cm.ICD_10_PCS_CODE LIKE 'T%'	
	AND   cm.ICD_10_PCS_CODE = cm2.ICD_10_CODE			
	GROUP by cm2.DESCRIPTION, cm.ICD_10_PCS_CODE
	) x
	where x.ResultCode <> ''
	) y 
	where y.ResultCode = cm.ICD_10_CODE
	order by  y.ResultCode	
END

END


GO
