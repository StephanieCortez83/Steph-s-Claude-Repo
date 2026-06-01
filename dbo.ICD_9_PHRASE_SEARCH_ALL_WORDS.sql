SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ICD_9_PHRASE_SEARCH_ALL_WORDS]
(
	@parmDate  datetime, 
	@chartID   int,
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
declare @gender varchar(1) = null
declare @age int = 0 
declare @ageDays int = 0 
declare @dob datetime
declare @dos datetime
declare @peds bit = 0
declare @newborn bit = 0
declare @adult bit = 0 

set @dob = (select c.patient_DOB from CHART c where c.CHART_ID = @chartID)
set @dos = (select c.time_of_service from CHART c where c.CHART_ID = @chartID)
set @gender = (select c.GENDER from CHART c where c.CHART_ID = @chartID and c.GENDER in ('M', 'F'))

if @dob is not null and @dos is not null
BEGIN
	set @age = DATEDIFF(MONTH, @dob, @dos)
	set @ageDays = DATEDIFF(DAY, @dob, @dos)
END

if @ageDays <= 28
BEGIN
	set @newborn = 1
END

if @age < 216
BEGIN
	set @peds = 1
END
	
if @age > 179
BEGIN
	set @adult = 1
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
	AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
		
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
		AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status	, ru.relative_value	
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value 
		from ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE cm.ICD9_CODE IN (SELECT DISTINCT(icdxref.CODE) FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK) WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord2) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord3)
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord4)
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord5)) 
		AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
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
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value		
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  IN (SELECT DISTINCT(icdxref.CODE) FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord2) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord3) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord4)) 
		AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
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
		AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
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
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value		
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id)as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  IN (SELECT DISTINCT(icdxref.CODE) FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord2) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord3)) 
		AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value			
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCOde, cm.code_status, MAX(cm.icd9_cm_id)as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE cm.ICD9_CODE IN (SELECT DISTINCT(icdxref.CODE) 
		FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref1 WITH (NOLOCK) WHERE icdxref.CODE = icdxref1.CODE AND icdxref1.KEYWORD = @parmWord2) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord3)) 
		AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
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
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value	
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  IN (SELECT DISTINCT(icdxref.CODE) FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK)  WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord2))
		AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value				
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCOde, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value 
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE cm.ICD9_CODE IN (SELECT DISTINCT(icdxref.CODE) 
		FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1) 
		AND EXISTS (SELECT 'x' FROM ICD_9_XREF icdxref2 WITH (NOLOCK) WHERE icdxref.CODE = icdxref2.CODE AND icdxref2.KEYWORD = @parmWord2)) 
		AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate
		AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
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
	AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate and cm.code_status <> 'I'
	AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.pediatric = 1 and icdag.adult = 0) and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.pediatric = 1 and icdag.adult = 0) and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.pediatric = 1 and icdag.adult = 0) and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.pediatric = 1 or icdag.adult = 1) and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.pediatric = 1 or icdag.adult = 1) and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.pediatric = 1 or icdag.adult = 1) and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.pediatric = 0 and icdag.adult = 1) and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.pediatric = 0 and icdag.adult = 1) and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.pediatric = 0 and icdag.adult = 1) and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END
	) 

	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status, ru.relative_value		
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  IN (SELECT DISTINCT(icdxref.CODE) FROM ICD_9_XREF icdxref WITH (NOLOCK) WHERE icdxref.KEYWORD IN (@parmWord1)) 
	AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate and cm.code_status <> 'I'
	AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
	
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status	, ru.relative_value		
	
	UNION 
	select cm.LONG_DESC as ResultText, cm.ICD9_CODE as ResultCode, cm.code_status, MAX(cm.icd9_cm_id) as cmID , ru.relative_value
	FROM ICD_9_CM cm with (NOLOCK)
		left outer join ICD_9_RELATIVE_USAGE ru on cm.icd9_code = ru.icd9_code
	WHERE  cm.ICD9_CODE  LIKE @parmWord1 + '%' 
	AND	  cm.effective_date <= @parmDate AND cm.expiration_date >= @parmDate and cm.code_status <> 'I'
	AND   (cm.icd9_code =
		CASE 
			-- Newborn or pediatric
			WHEN (@newborn = 1 and @gender IS NULL)				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))	
					)							  
			WHEN (@newborn = 1 and @gender = 'M')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0)
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			WHEN (@newborn = 1 and @gender = 'F')				
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 (icdag.newborn = '1' OR icdag.pediatric = 1) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0) 
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric only
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @newborn = 0 and @adult = 0 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 and icdag.adult = 0) OR (icdag.pediatric = 0 AND icdag.adult = 0 and icdag.newborn = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)
			-- Pediatric or adult
			WHEN (@peds = 1 and @adult = 1 and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 --and (icdag.female = 0 and icdag.male = 0)
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			WHEN (@peds = 1 and @adult = 1 and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.pediatric = 0 AND icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)			
			-- Adult 		
			WHEN (@adult = 1 and @peds = 0  and @gender IS NULL) 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
						--and (icdag.female = 0 and icdag.male = 0)
						or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'M') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.male = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)				
			WHEN (@adult = 1 and @peds = 0  and @gender = 'F') 
				THEN (SELECT distinct icdag.CODE FROM ICD_9_AGE_GENDER icdag WITH (NOLOCK) WHERE cm.icd9_code = icdag.code AND (
					 ((icdag.pediatric = 1 OR icdag.adult = 1) or (icdag.adult = 0))
					 and (icdag.female = 1 OR (icdag.female = 0 and icdag.male = 0))
					  or (icdag.adult = 0 AND icdag.female = 0 AND icdag.male = 0 AND icdag.newborn = 0 and icdag.pediatric = 0 ))
					)	
		END)	
	GROUP by cm.LONG_DESC, cm.ICD9_CODE, cm.code_status	, ru.relative_value		
	
	) x
	where x.ResultCode <> ''
	order by  x.ResultCode	
END

END








GO
