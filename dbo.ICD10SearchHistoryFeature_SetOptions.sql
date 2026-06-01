SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[ICD10SearchHistoryFeature_SetOptions]
(
	@EnableHistory bit										
	, @CaptureRawHistory bit
	, @UpdateHistory bit
	, @UseHistory bit
)
as 

	set nocount on

	update ICD10SearchHistoryFeature 
	set 
		EnableHistory = @EnableHistory											
		, CaptureRawHistory = @CaptureRawHistory
		, UpdateHistory = @UpdateHistory
		, UseHistory = @UseHistory	
GO
