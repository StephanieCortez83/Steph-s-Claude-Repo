SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[GET_CHART_ICD10_NCD_WITH_LOS]
@ChartID int,
@LevelNumber int,
@ServiceID int, 
@LCDTYpeCD nvarchar(1)
AS
select Sum(RowCnt) FROM
(
select RowCnt = count(*)
from CHART_CMS_LCD with (NOLOCK)
  join CMS_NCD with (NOLOCK) on CMS_NCD.NCD_ID = CHART_CMS_LCD.LCD_ID
  join CHART_DIAGNOSIS_CODE_ICD10 with (NOLOCK) on CHART_DIAGNOSIS_CODE_ICD10.CHART_ID = CHART_CMS_LCD.CHART_ID AND CHART_DIAGNOSIS_CODE_ICD10.LEVEL_NUMBER = chart_cms_lcd.level_number
  join CMS_NCD_ICD10 with (NOLOCK) on LEFT(cms_ncd_icd10.NCD_NUMBER, 6) = CMS_NCD.NCD_MNL_SECT
where CHART_CMS_LCD.CHART_ID = @ChartID
	   and chart_cms_lcd.level_number = @LevelNumber
       and CHART_CMS_LCD.LCD_ID = @ServiceID
       and CHART_CMS_LCD.LCD_TYPE_CD = @LCDTypeCD
       and CMS_NCD_ICD10.RESOLUTION_CODE = '1'
       and 
              replace(CHART_DIAGNOSIS_CODE_ICD10.icd10_code, '.', '') between case 
                           when charindex('-', CMS_NCD_ICD10.[ICD-10_CODE]) = 0
                                  then CMS_NCD_ICD10.[ICD-10_CODE]
                           else substring(CMS_NCD_ICD10.[ICD-10_CODE], 1, (charindex('-', CMS_NCD_ICD10.[ICD-10_CODE]) - 1))
                           end
              and case 
                           when charindex('-', CMS_NCD_ICD10.[ICD-10_CODE]) = 0
                                  then CMS_NCD_ICD10.[ICD-10_CODE]
                           else substring(CMS_NCD_ICD10.[ICD-10_CODE], (charindex('-', CMS_NCD_ICD10.[ICD-10_CODE]) + 1), (len(CMS_NCD_ICD10.[ICD-10_CODE]) - charindex('-', CMS_NCD_ICD10.[ICD-10_CODE])))
                           end

UNION

select RowCnt = count(*)
from CHART_CMS_LCD with (NOLOCK)
  join CMS_NCD with (NOLOCK) on CMS_NCD.NCD_ID = CHART_CMS_LCD.LCD_ID
  join CHART_DIAGNOSIS_CODE_ICD10 with (NOLOCK) on CHART_DIAGNOSIS_CODE_ICD10.CHART_ID = CHART_CMS_LCD.CHART_ID AND CHART_DIAGNOSIS_CODE_ICD10.LEVEL_NUMBER = CHART_CMS_LCD.level_number
  join CMS_NCD_ICD10 with (NOLOCK) on LEFT(cms_ncd_icd10.NCD_NUMBER, 6) = CMS_NCD.NCD_MNL_SECT
where CHART_CMS_LCD.CHART_ID = @ChartID
	   and chart_cms_lcd.level_number = @LevelNumber
       and CHART_CMS_LCD.LCD_ID = @ServiceID
       and CHART_CMS_LCD.LCD_TYPE_CD = @LCDTypeCD
       and CMS_NCD_ICD10.RESOLUTION_CODE = '1'
       and (
                     CMS_NCD_ICD10.[ICD-10_CODE] = '@@@@@@@'
                     and (
                           select count(*)
                           from CHART_CMS_LCD with (NOLOCK)
                           join CMS_NCD with (NOLOCK) on CMS_NCD.NCD_ID = CHART_CMS_LCD.LCD_ID
                           join CHART_DIAGNOSIS_CODE_ICD10 with (NOLOCK) on CHART_DIAGNOSIS_CODE_ICD10.CHART_ID = CHART_CMS_LCD.CHART_ID AND CHART_DIAGNOSIS_CODE_ICD10.LEVEL_NUMBER = CHART_CMS_LCD.level_number
                           join CMS_NCD_ICD10 with (NOLOCK) on LEFT(cms_ncd_icd10.NCD_NUMBER, 6) = CMS_NCD.NCD_MNL_SECT
                           where CHART_CMS_LCD.CHART_ID = @ChartID
						   		  and chart_cms_lcd.level_number = @LevelNumber
                                  and CHART_CMS_LCD.LCD_ID = @ServiceID
                                  and CHART_CMS_LCD.LCD_TYPE_CD = @LCDTypeCD
                                  and CMS_NCD_ICD10.RESOLUTION_CODE = '2'
                                  and replace(CHART_DIAGNOSIS_CODE_ICD10.icd10_code, '.', '') between case 
                                                       when charindex('-', CMS_NCD_ICD10.[ICD-10_CODE]) = 0
                                                              then CMS_NCD_ICD10.[ICD-10_CODE]
                                                       else substring(CMS_NCD_ICD10.[ICD-10_CODE], 1, (charindex('-', CMS_NCD_ICD10.[ICD-10_CODE]) - 1))
                                                       end
                                         and case 
                                                       when charindex('-', CMS_NCD_ICD10.[ICD-10_CODE]) = 0
                                                              then CMS_NCD_ICD10.[ICD-10_CODE]
                                                       else substring(CMS_NCD_ICD10.[ICD-10_CODE], (charindex('-', CMS_NCD_ICD10.[ICD-10_CODE]) + 1), (len(CMS_NCD_ICD10.[ICD-10_CODE]) - charindex('-', CMS_NCD_ICD10.[ICD-10_CODE])))
                                                       end
                           ) < (
                           select count(*)
                           from chart_diagnosis_code_ICD10 with (NOLOCK)
                           where chart_id = @ChartID
						   and   level_number = @LevelNumber
                           )
                     )
              
) as t


GO
