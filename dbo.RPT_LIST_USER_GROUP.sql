SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RPT_LIST_USER_GROUP]
	@ReportUser int = 80
AS

--  Base script provided by SQL Team
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- active admin users permission to all User groups                                                                                                                                                           
SELECT 
	 [USER_GROUP_ID]
	,[NAME]                                                                                                                                                            
FROM 
	[dbo].[USER_GROUP] WITH (NOLOCK)
WHERE 
	[USER_GROUP_ID] not in ( 51,54,55,56,57,59,60,61,63,64,65,66,67,68,69,70,71,73,75,
								80,81,82,84,85,86,87,88,90,91,92,93,96,98,99,101,102,103,104,105,106,107,111,113,114,115,
								116,117,118,120,121,122,123,124,127,128,135,138,139,140,141,142,143,150,151,152,153,154,156,
								157,160,161,162,163,167,168,170,171,172,175,176,177)
	AND -1 = ( SELECT -1                                                                                                                                                         
			FROM 
				[dbo].[USER_PROFILE] WITH (NOLOCK)
			WHERE                                                                                                 
				[USER_PROFILE_ID] = @ReportUser                                                                                                           
				AND [USER_GROUP_ID] in (1, 116)                                                                                                             
				AND [is_active] = 'Y'                                                                                                             

			UNION                                                                                                 

				SELECT -1                                                                                                             
				FROM 
					 [dbo].[USER_GROUP_TO_USER_PROFILE] ugup WITH (NOLOCK)
					,[dbo].[user_profile] up WITH (NOLOCK)
				WHERE 
					up.[user_profile_id] = ugup.[user_profile_id]                                                                                                              
					AND up.[is_active] = 'Y'                                                                                                       
					AND ugup.[USER_PROFILE_ID] = @ReportUser                                                                                                       
					AND ugup.[USER_GROUP_ID] in (1, 116)                 
		)                                                                                              

union                                    

SELECT 
	 [USER_GROUP_ID]
	,[NAME]
FROM
	[dbo].[USER_GROUP] WITH (NOLOCK)
WHERE                                                                                                                                                                                   
	[USER_GROUP_ID] in                                                                                                                                                                                         
		(                                                                                                                                                                                              
			--Primary User Group to user_group_id_1 in USER_GROUP_TO_USER_GROUP table                                                                                                                                                                                          
			SELECT 
				[USER_GROUP_TO_USER_GROUP].[USER_GROUP_ID_1]                                                                                                                                      
			FROM 
				[dbo].[USER_PROFILE] WITH (NOLOCK)                                                                                                                                                                                   
				JOIN [dbo].[USER_GROUP_TO_USER_GROUP] WITH (NOLOCK) ON [USER_GROUP_TO_USER_GROUP].[USER_GROUP_ID_1] = [USER_PROFILE].[USER_GROUP_ID]                                                                                                                                                                                              
			WHERE 
				[USER_PROFILE_ID] = @ReportUser                                                                                                                                                                                           

			UNION                                                                                                                                                                                 

			-- Secondary User Group to user_group_id_1 in USER_GROUP_TO_USER_GROUP table                                                                                                                                                                                   
			SELECT 
				[USER_GROUP_TO_USER_GROUP].[USER_GROUP_ID_1]
			FROM 
				[dbo].[USER_GROUP_TO_USER_GROUP] WITH (NOLOCK)
				JOIN [dbo].[USER_GROUP_TO_USER_PROFILE] WITH (NOLOCK) ON [USER_GROUP_ID] = [USER_GROUP_TO_USER_GROUP].[USER_GROUP_ID_1]                                                                                                                                                                                                
				JOIN [dbo].[USER_PROFILE] WITH (NOLOCK) ON [USER_PROFILE].[USER_PROFILE_ID] = [USER_GROUP_TO_USER_PROFILE].[USER_PROFILE_ID]                                                                                                                                                                                
			WHERE 
				[USER_PROFILE].[USER_PROFILE_ID] = @ReportUser                                                                                                                                                                                             

			UNION                                                                                                                                                                                 

			--Primary User Group to user_group_id_2 in USER_GROUP_TO_USER_GROUP table                                                                                                                                                                                          
			SELECT 
				[USER_GROUP_TO_USER_GROUP].[USER_GROUP_ID_2]                                                                                                                                                                                      
			FROM 
				[dbo].[USER_PROFILE] WITH (NOLOCK)                                                                                                                                                                                   
				JOIN [dbo].[USER_GROUP_TO_USER_GROUP] WITH (NOLOCK) ON [USER_GROUP_TO_USER_GROUP].[USER_GROUP_ID_1] = [USER_PROFILE].[USER_GROUP_ID]                                                                                                                                                                                              
			WHERE 
				[USER_PROFILE_ID] = @ReportUser                                                                                                                                                                                           

			UNION                                                                                                                                                                                 
			-- Secondary User Group to user_group_id_2 in USER_GROUP_TO_USER_GROUP table                                                                                                                                                                                   
			SELECT 
				[USER_GROUP_TO_USER_GROUP].[USER_GROUP_ID_2]                                                                                                                                                                                      
			FROM 
				[dbo].[USER_GROUP_TO_USER_GROUP] WITH (NOLOCK)                                                                                                                                                                                
				JOIN [dbo].[USER_GROUP_TO_USER_PROFILE] WITH (NOLOCK) ON [USER_GROUP_ID] = [USER_GROUP_TO_USER_GROUP].[USER_GROUP_ID_1]                                                                                                                                                                                                
				JOIN [dbo].[USER_PROFILE] WITH (NOLOCK) ON [USER_PROFILE].[USER_PROFILE_ID] = [USER_GROUP_TO_USER_PROFILE].[USER_PROFILE_ID]                                                                                                                                                                                
			WHERE 
				[USER_PROFILE].[USER_PROFILE_ID] = @ReportUser                                                                                                                                                                                             
		)                                                                                                                                                                              
ORDER BY 
	[NAME]          

GO
