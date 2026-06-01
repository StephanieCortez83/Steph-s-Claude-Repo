SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[GetLastICD10CodeForParent] 
(
	@root varchar(10)
)
RETURNS varchar(10)
AS
BEGIN
declare @Result varchar(10)
SELECT @Result = (SELECT top 1 y.code 
	from (
	
			SELECT top 1 x.code from 
			(
				SELECT cm1.ICD_10_CODE as Code	
					-- These other columns are not needed. The DESCRIPTION column in particular was adding expensive overhead to this function. 2/22/2023 (dsexton)
					--, cm1.ICD_10_CODE + ' - ' + cm1.DESCRIPTION as CodeDescription, cm1.PARENT_CODE, cm1.PARENT_TYPE 	
				from ICD_10_CODE_MASTER cm1 with (NOLOCK)
				where cm1.PARENT_CODE = @root and cm1.PARENT_TYPE = 'C'
				UNION 
				SELECT cm1.ICD_10_CODE as Code	
					-- These other columns are not needed. The DESCRIPTION column in particular was adding expensive overhead to this function. 2/22/2023 (dsexton)
					--, cm1.ICD_10_CODE + ' - ' + cm1.DESCRIPTION as CodeDescription, cm1.PARENT_CODE, cm1.PARENT_TYPE 	
				from ICD_10_CODE_MASTER cm1 with (NOLOCK)
				where cm1.PARENT_CODE = @root and cm1.PARENT_TYPE = 'S'
			) x	
			order by x.code desc
			) y
		)
	-- Return the result of the function
	RETURN @Result

END

GO
