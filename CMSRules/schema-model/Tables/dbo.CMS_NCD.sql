CREATE TABLE [dbo].[CMS_NCD]
(
[ncd_id] [int] NOT NULL,
[ncd_vrsn_num] [int] NOT NULL,
[natl_cvrg_type] [varchar] (10) NULL,
[cvrg_lvl_cd] [int] NULL,
[ncd_mnl_sect] [varchar] (10) NULL,
[ncd_mnl_sect_title] [varchar] (1000) NULL,
[ncd_efctv_dt] [datetime] NULL,
[ncd_trmntn_dt] [datetime] NULL,
[last_updt_tmstmp] [datetime] NULL
)
GO
ALTER TABLE [dbo].[CMS_NCD] ADD CONSTRAINT [PK__CMS_NCD___1E86CE6DD313B02A] PRIMARY KEY NONCLUSTERED ([ncd_id], [ncd_vrsn_num])
GO
