SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[Get_ICD10_Hierarchy]
(
	@root varchar(10)
)
AS
BEGIN
;With ret as (
	SELECT cm1.ICD_10_CODE as Code, cm1.ICD_10_CODE + ' - ' + cm1.DESCRIPTION as CodeDescription, cm1.PARENT_CODE, cm1.PARENT_TYPE 	
	from ICD_10_CODE_MASTER cm1 with (NOLOCK)
	where cm1.PARENT_CODE = @root and cm1.PARENT_TYPE = 'C'
	UNION ALL
	SELECT cm1.ICD_10_CODE as Code, cm1.ICD_10_CODE + ' - ' + cm1.DESCRIPTION as CodeDescription, null as PARENT_CODE, cm1.PARENT_TYPE  	
	from ICD_10_CODE_MASTER cm1 with (NOLOCK)
	where cm1.PARENT_CODE = @root and cm1.PARENT_TYPE = 'S'
	UNION ALL
	select cm1.ICD_10_CODE as Code, cm1.ICD_10_CODE + ' - ' + cm1.DESCRIPTION as CodeDescription, cm1.PARENT_CODE, cm1.PARENT_TYPE 	 	 
	FROM   ICD_10_CODE_MASTER cm1 with (NOLOCK)
		INNER JOIN ret r on cm1.PARENT_CODE = r.Code and cm1.PARENT_TYPE = 'C'
	)	
	
	select distinct r.Code, r.CodeDescription, r.PARENT_CODE, r.PARENT_TYPE,  cm2.icd9_code 	 
	from ret r	
	LEFT OUTER JOIN ICD10CM_TO_ICD9CM_GEM icd9	
		ON replace(r.Code, '.', '') = icd9.ICD_10_CODE
	LEFT OUTER JOIN ICD_9_CM cm2
		ON icd9.ICD_9_CODE = REPLACE(cm2.ICD9_CODE, '.','') 
		AND cm2.expiration_date = '2099-09-30 00:00:00.000'
	order by r.code
			--,(select 1 from ICD_10_RULE ir where ir.FIRST_CODE <= @root and ir.LAST_CODE >= r.Code and ir.RULE_TYPE_CD = 6 and
			-- (select top 1 1 from ICD_10_CODE_MASTER cm2 where cm2.PARENT_CODE = r.Code) is null) as SEVENTH_CHAR


END

GO
