SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CopyTableCmsLcdxContractor]
WITH EXEC AS CALLER
AS
CREATE TABLE [dbo].[CMS_LCD_X_CONTRACTOR_COPY] (
[lcd_id] int NOT NULL,
[lcd_verion] int NOT NULL,
[contractor_id] int NOT NULL,
[contractor_type_id] int NOT NULL,
[contractor_version] int NOT NULL,
[last_update] datetime NULL,
PRIMARY KEY NONCLUSTERED ([lcd_id] ASC, [lcd_verion] ASC, [contractor_id] ASC, [contractor_type_id] ASC, [contractor_version] ASC)
WITH ( PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE )
 ON [PRIMARY]
)
ON [PRIMARY]
WITH (DATA_COMPRESSION = NONE);
GO
