CREATE TABLE [dbo].[CMS_CONTRACTOR]
(
[CONTRACTOR_ID] [int] NOT NULL,
[CONTRACTOR_TYPE_ID] [int] NOT NULL,
[CONTRACTOR_VERSION] [int] NOT NULL,
[CONTRACTOR_NAME] [varchar] (100) NULL,
[CONTRACTOR_BUS_NAME] [varchar] (100) NULL,
[CONTRACTOR_NUMBER] [varchar] (20) NULL,
[DMERC_RGN] [int] NULL,
[ADDRESS1] [varchar] (50) NULL,
[ADDRESS2] [varchar] (50) NULL,
[ADDRESS3] [varchar] (50) NULL,
[CITY] [varchar] (30) NULL,
[STATE_ID] [int] NULL,
[ZIPCODE] [varchar] (10) NULL,
[PHONE] [varchar] (10) NULL,
[FAX] [varchar] (10) NULL,
[STATUS] [varchar] (1) NULL,
[LAST_UPDATED] [datetime] NULL,
[URL] [varchar] (max) NULL,
[email] [varchar] (max) NULL,
[ignore] [varchar] (10) NULL,
[status_flag] [varchar] (1) NULL,
[cmd_name] [varchar] (100) NULL,
[cmd_title] [varchar] (100) NULL
)
GO
ALTER TABLE [dbo].[CMS_CONTRACTOR] ADD CONSTRAINT [PK__CMS_CONT__BA136EB85AC043A8] PRIMARY KEY NONCLUSTERED ([CONTRACTOR_ID], [CONTRACTOR_TYPE_ID], [CONTRACTOR_VERSION])
GO
