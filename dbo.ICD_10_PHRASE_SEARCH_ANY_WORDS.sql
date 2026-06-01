SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ICD_10_PHRASE_SEARCH_ANY_WORDS]
(
	@parmWord1 varchar(50),
	@parmWord2 varchar(50),	
	@parmWord3 varchar(50),
	@parmWord4 varchar(50),
	@parmWord5 varchar(50)				
)
AS
BEGIN

declare @word1 varchar(50) 
declare @word2 varchar(50) 
declare @word3 varchar(50) 
declare @word4 varchar(50) 
declare @word5 varchar(50) 

declare @containsParmWordAll varchar(1000)
declare @containsParmWordAny varchar(1000)
declare @formsof1 varchar(200) 
declare @formsof2 varchar(200) 
declare @thesaurus1 varchar(200) 
declare @thesaurus2 varchar(200) 

set @word1 =  (Select top 1 sy.CM_WORD from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord1)
if @word1 is not null 
BEGIN
set @containsParmWordAny =  @parmWord1 + ' ' + @word1 + ' '
END
ELSE
set @containsParmWordAny =  @parmWord1 + ' '


if @parmWord2 <> ''
BEGIN	
	set @word2 =  (Select top 1 sy.CM_WORD from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord2)
	if @word2 is not null
	BEGIN	
		set @containsParmWordAny = @containsParmWordAny +  @parmWord2 + ' ' + @word2 + ' ' 	
	END
	ELSE
		set @containsParmWordAny = @containsParmWordAny + ' ' + @parmWord2 + '"'
END	

if @parmWord3 <> ''
BEGIN	
	set @word3 =  (Select top 1 sy.CM_WORD from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord3)
	if @word3 is not null
	BEGIN	
		set @containsParmWordAny = @containsParmWordAny +  @parmWord3 + ' ' + @word3 + ' ' 	
	END
	ELSE
		set @containsParmWordAny = @containsParmWordAny + ' ' + @parmWord3 + '"'
END	

if @parmWord4 <> ''
BEGIN	
	set @word4 =  (Select top 1 sy.CM_WORD from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord4)
	if @word4 is not null
	BEGIN	
		set @containsParmWordAny = @containsParmWordAny +  @parmWord4 + ' ' + @word4 + ' ' 	
	END
	ELSE
		set @containsParmWordAny = @containsParmWordAny + ' ' + @parmWord4 + '"'
END	

if @parmWord5 <> ''
BEGIN	
	set @word5 =  (Select top 1 sy.CM_WORD from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord5)
	if @word5 is not null
	BEGIN	
		set @containsParmWordAny = @containsParmWordAny +  @parmWord5 + ' ' + @word5 + ' ' 	
	END
	ELSE
		set @containsParmWordAny = @containsParmWordAny + ' ' + @parmWord5 + '"'
END	
	
SELECT DISTINCT x.ResultText
			   ,x.ResultCode
			   ,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
FROM 
(
select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm
WHERE FREETEXT(cm.[DESCRIPTION], @containsParmWordAny)
GROUP by cm.DESCRIPTION, cm.ICD_10_CODE

UNION ALL
select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm
WHERE cm.[DESCRIPTION] like '%' + @parmWord1 + '%'
GROUP by cm.DESCRIPTION, cm.ICD_10_CODE

UNION ALL 
select cm.TITLE as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm
WHERE FREETEXT(cm.TITLE, @containsParmWordAny)
GROUP by cm.TITLE, cm.CODE

UNION ALL
select cm.TITLE as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm
WHERE cm.TITLE like '%' + @parmWord1 + '%'
GROUP by cm.TITLE, cm.CODE

UNION ALL 
select cm.TITLE as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm
WHERE FREETEXT(cm.TITLE, @containsParmWordAny)
GROUP by cm.TITLE, cm.CODE

) x
LEFT JOIN [ICD_10_CM]
	   ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
where x.ResultCode <> ''
order by  x.ResultCode	
END
GO
