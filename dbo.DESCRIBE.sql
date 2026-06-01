SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DESCRIBE]
(
@tablename varchar(256)
)
as
begin
SELECT distinct sCols.colid as 'order', sCols.name, sTyps.name, sCols.length
FROM [syscolumns] sCols
INNER JOIN [systypes] sTyps ON sCols.xtype = sTyps.xtype
INNER JOIN [sysobjects] sObjs ON sObjs.id = sCols.[id]
and UPPER(sObjs.name) = UPPER(@tablename)
order by sCols.colid
end
GO
