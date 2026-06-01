SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[Get_ICD10_Hierarchy_Root_Section_And_Chapter_with_DOS]
(
	@code varchar(10),
	@dos  varchar(10)
)
AS
BEGIN 

declare @hasParent varchar(1)
declare @parent varchar(10)
declare @parentCode varchar(10)
set @hasParent = 'N'

set @parent = (SELECT top 1 cm1.PARENT_CODE from ICD_10_CODE_MASTER cm1 with (NOLOCK) 
				where cm1.ICD_10_CODE = @code 
				and   cm1.effective_dt <= @dos and cm1.expiration_dt >= @dos
				order by icd_10_code_master_id desc)

if @parent is not null and @parent <> @code
BEGIN 
	set @hasParent = 'Y'
END

WHILE (@hasParent = 'Y')
BEGIN 

	set @parentCode = (SELECT top 1 cm2.PARENT_CODE from ICD_10_CODE_MASTER cm2 with (NOLOCK) 
	where cm2.ICD_10_CODE = @parent and   cm2.effective_dt <= @dos and cm2.expiration_dt >= @dos
	order by icd_10_code_master_id desc)
	if @parentCode is null or @parentCode = @parent
	BEGIN
		set @hasParent = 'N'
	END
	ELSE 
		set @parent = @parentCode
END 

select @parent as Section_ID, (select top 1 chapter_num from ICD_10_SECTION s  with (NOLOCK) where s.SECTION_ID = @parent) as Chapter_Num 

END




GO
