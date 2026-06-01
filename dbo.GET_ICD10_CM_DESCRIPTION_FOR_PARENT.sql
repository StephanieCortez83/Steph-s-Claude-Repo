SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[GET_ICD10_CM_DESCRIPTION_FOR_PARENT]
(
	@root varchar(10)
)
AS
BEGIN
;With ret as (
	SELECT cm1.ICD_10_CODE as Code, cm1.DESCRIPTION as CodeDescription, cm1.PARENT_CODE, cm1.PARENT_TYPE 	
	from ICD_10_CODE_MASTER cm1 with (NOLOCK)
	where cm1.PARENT_CODE = @root and cm1.PARENT_TYPE = 'C'
	UNION 
	SELECT cm1.ICD_10_CODE as Code, cm1.DESCRIPTION as CodeDescription, cm1.PARENT_CODE, cm1.PARENT_TYPE 	
	from ICD_10_CODE_MASTER cm1 with (NOLOCK)
	where cm1.PARENT_CODE = @root and cm1.PARENT_TYPE = 'S'
	)	
	
	select distinct r.Code, r.CodeDescription, r.PARENT_CODE, r.PARENT_TYPE 
	from ret r	
	order by r.code
			--,(select 1 from ICD_10_RULE ir where ir.FIRST_CODE <= @root and ir.LAST_CODE >= r.Code and ir.RULE_TYPE_CD = 6 and
			-- (select top 1 1 from ICD_10_CODE_MASTER cm2 where cm2.PARENT_CODE = r.Code) is null) as SEVENTH_CHAR


END

GO
