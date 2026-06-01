CREATE TABLE [dbo].[CMS_LCD]
(
[LCD_ID] [int] NOT NULL,
[LCD_VERSION] [int] NOT NULL,
[TITLE] [varchar] (255) NULL,
[DETERMINATION_NUMBER] [varchar] (40) NULL,
[ORIG_DET_EFF_DATE] [datetime] NULL,
[ENT_DET_END_DATE] [datetime] NULL,
[REV_EFF_DATE] [datetime] NULL,
[REV_END_DATE] [datetime] NULL,
[INDICATION] [varchar] (max) NULL,
[DIAGNOSIS_SUPPORT] [varchar] (max) NULL,
[ICD9_DONT_SUPPORT_PARA] [varchar] (max) NULL,
[ICD9_DONT_SUPPORT_AST] [varchar] (max) NULL,
[DIAGNOSIS_DONT_SUPPORT] [varchar] (max) NULL,
[CODING_GUIDELINES] [varchar] (max) NULL,
[DOC_REQS] [varchar] (max) NULL,
[APPENDICES] [varchar] (max) NULL,
[UTIL_GUIDE] [varchar] (max) NULL,
[SOURCE_INFO] [varchar] (max) NULL,
[ADV_MEETING] [varchar] (max) NULL,
[COMMENT_START_DT] [datetime] NULL,
[COMMENT_END_DT] [datetime] NULL,
[NOTICE_START_DT] [datetime] NULL,
[REV_HIST_NUM] [varchar] (max) NULL,
[HISTORY_EXP] [varchar] (max) NULL,
[LAST_REVIEWED_ON] [datetime] NULL,
[STATUS] [varchar] (1) NULL,
[LAST_UPDATED] [datetime] NULL,
[CMS_COV_POLICY] [varchar] (max) NULL,
[DISPLAY_ID] [int] NULL,
[DRAFT_CONTACT] [int] NULL,
[STICKY_NOTE] [varchar] (max) NULL,
[REVENUE_PARA] [varchar] (max) NULL,
[THIRTY_PERCENT] [varchar] (max) NULL
)
GO
ALTER TABLE [dbo].[CMS_LCD] ADD CONSTRAINT [PK__CMS_LCD___D04F62F7073ACA37] PRIMARY KEY CLUSTERED ([LCD_ID], [LCD_VERSION])
GO
