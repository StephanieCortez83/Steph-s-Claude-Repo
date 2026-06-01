SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[udf_Icd9DescriptionSearch]
(@keywords nvarchar(4000), @DOS datetime)
RETURNS table
AS
RETURN (SELECT x.*
        FROM (SELECT DISTINCT (cm.icd9_code), 
                     (SELECT [RANK] 
                      FROM containstable(ICD_9_CM,(medium_desc,long_desc),@keywords) 
                      WHERE [KEY] = cm.icd9_cm_id) AS [RANK], 
                     '' AS Keyword, 
                     cm.medium_desc, 
                     cm.long_desc,  
                     cm.effective_date, 
                     cm.expiration_date, 
                     cm.code_status
              FROM ICD_9_CM cm WITH (NOLOCK)
              WHERE icd9_cm_id in (SELECT [KEY] 
                                   FROM containstable(ICD_9_CM,(medium_desc,long_desc),@keywords))
              AND cm.effective_date <= @DOS 
              AND  (cm.expiration_date > @DOS OR cm.expiration_date IS NULL))x)
GO
