CREATE TABLE [dbo].[CMS_LCD_X_PRIMARY_JURISDICTION]
(
[lcd_id] [int] NOT NULL,
[lcd_version] [int] NOT NULL,
[state_id] [int] NOT NULL,
[last_updated] [datetime] NULL
)
GO
ALTER TABLE [dbo].[CMS_LCD_X_PRIMARY_JURISDICTION] ADD CONSTRAINT [PK__CMS_LCD___7E339008FAFEA9AA] PRIMARY KEY NONCLUSTERED ([lcd_id], [lcd_version], [state_id])
GO
