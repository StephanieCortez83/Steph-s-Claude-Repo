SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[GET_CHART_ICD10_LCD_WITH_LOS]
@ChartID int,
@LevelNumber int,
@ServiceID int, 
@LCDTYpeCD varchar(1)
AS
	select x.count1 + x.count2 from 
		(select count(*) as count1, 
		(
			select count(*) 
			from chart_cms_lcd with (NOLOCK), CMS_LCD_ICD10_SUPPORT_RANGE cms2 with (NOLOCK), chart_diagnosis_code_icd10 cdc with (NOLOCK)
			 where chart_cms_lcd.chart_id = @ChartID
			 and chart_cms_lcd.level_number = @LevelNumber
			 and chart_cms_lcd.lcd_id = @ServiceID
			 and chart_cms_lcd.lcd_type_cd = @LCDTypeCD
			 and chart_cms_lcd.lcd_id = cms2.lcd_id
			 and cdc.chart_id = chart_cms_lcd.chart_id
			 and cdc.level_number = chart_cms_lcd.level_number
			 and (cdc.icd10_code >= cms2.begin_icd10_code_id
					and cdc.icd10_code <= cms2.end_icd10_code_id)
		) as count2
	from chart_cms_lcd with (NOLOCK), cms_lcd_icd10_support with (NOLOCK), chart_diagnosis_code_icd10 with (NOLOCK)
			where chart_cms_lcd.chart_id = @ChartID
			and chart_cms_lcd.level_number = @LevelNumber
			and chart_cms_lcd.lcd_id = @ServiceID
			and chart_cms_lcd.lcd_type_cd = @LCDTypeCD
			and chart_cms_lcd.lcd_id = cms_lcd_icd10_support.lcd_id
			and chart_diagnosis_code_ICD10.chart_id = chart_cms_lcd.chart_id
			and chart_diagnosis_code_ICD10.level_number = chart_cms_lcd.level_number
			and chart_diagnosis_code_ICD10.icd10_code = cms_lcd_icd10_support.icd10_code_id
			and cms_lcd_icd10_support.[range] not in ('B','E')
	) x



GO
