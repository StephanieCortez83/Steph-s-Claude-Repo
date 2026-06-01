SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[Get_ICD10_Top_Level_Code]
(
	@code varchar(10)
)
AS
BEGIN 

declare @hasParent varchar(1)
declare @parent varchar(10)
declare @parentCode varchar(10)
set @hasParent = 'N'

set @parent = (SELECT cm1.PARENT_CODE from ICD_10_CODE_MASTER cm1 with (NOLOCK) where cm1.ICD_10_CODE = @code and cm1.PARENT_TYPE = 'C')

if @parent is not null
BEGIN 
	set @hasParent = 'Y'
END
ELSE
	set @parent = @code

WHILE (@hasParent = 'Y')
BEGIN 

	set @parentCode = (SELECT cm2.PARENT_CODE from ICD_10_CODE_MASTER cm2 with (NOLOCK) 
						where cm2.ICD_10_CODE = @parent and cm2.PARENT_TYPE = 'C')
	if @parentCode is null
	BEGIN
		set @hasParent = 'N'
	END
	ELSE 
		set @parent = @parentCode
END 

select @parent as ParentCode
END

GO
