SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GetTopAdjustmentReasons]
(@FacilityID varchar(10), @YR int, @MO int, @TopN int)
RETURNS table
AS
Return
select top(@TopN) Facility, YR, MO, Description, Total
from HMA_ADJUSTMENT_REASON_SUMMARY
where facility = @FacilityID
and   YR = @YR
and   MO = @MO
order by Total desc, description
GO
EXEC sp_addextendedproperty N'MS_Description', N'Service Month', 'SCHEMA', N'dbo', 'FUNCTION', N'GetTopAdjustmentReasons', 'PARAMETER', N'@MO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Number of items to return', 'SCHEMA', N'dbo', 'FUNCTION', N'GetTopAdjustmentReasons', 'PARAMETER', N'@TopN'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Service Year', 'SCHEMA', N'dbo', 'FUNCTION', N'GetTopAdjustmentReasons', 'PARAMETER', N'@YR'
GO
