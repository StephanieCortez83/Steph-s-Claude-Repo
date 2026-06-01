CREATE TABLE [dbo].[CMS_LCD_X_CONTRACTOR]
(
[lcd_id] [int] NOT NULL,
[lcd_verion] [int] NOT NULL,
[contractor_id] [int] NOT NULL,
[contractor_type_id] [int] NOT NULL,
[contractor_version] [int] NOT NULL,
[last_update] [datetime] NULL
)
GO
ALTER TABLE [dbo].[CMS_LCD_X_CONTRACTOR] ADD CONSTRAINT [PK__CMS_LCD___241B43B580D05D1D] PRIMARY KEY NONCLUSTERED ([lcd_id], [lcd_verion], [contractor_id], [contractor_type_id], [contractor_version])
GO
