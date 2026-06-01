SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-3284 SPROC variant within ChartPhysicianLevelOfService.cs'))
	INSERT INTO 
		[TYPE_CODE]
		(
			[NAME]
		   ,[KEY]
		   ,[VALUE]
		   ,[DISPLAY_NAME]
		   ,[SHORT_NAME]
		   ,[DESCRIPTION]
		)
		VALUES
		(
			'ApplicationFeatureTypeCode'                                      					--NAME
		   ,'CAB_3284'                                                    						--KEY
		   ,19                                                                					--VALUE
		   ,'CAB_3284'                                                    						--DISPLAY_NAME
		   ,'CAB_3284'                                                        					--SHORT_NAME
		   ,'Enable/Disables DACS-3284 SPROC variant within ChartPhysicianLevelOfService.cs' 	--DESCRIPTION
		)
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 19)
	INSERT INTO 
		[dbo].[ApplicationFeature]
		(
			 [DateTimeCreated]
			,[CreatedByUserProfileId]
			,[DateTimeLastUpdated]
			,[LastUpdatedByUserProfileId]
			,[ApplicationFeatureDomainObjectTypeCode]
			,[DomainObjectId]
			,[ApplicationFeatureTypeCode]
		)
	VALUES
		(
			 @dtCreated
			,@Uid
			,@dtCreated
			,@Uid
			,5
			,2147483647															--ALL
			,19
		)
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectHasAPhysicianProcedureWith25ModifierFlagByChartIdAndEtAl]
	 @ChartId INT
	,@UseCMSDefinitionOfSurgicalProcedure BIT = 0
	,@FacilityFinancialClassApplyPhysSvcMod25OnStatusBProcs BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
	
	SELECT TOP 1 1
		-- COUNT(*) Procs,
		-- CASE cpr.[GLOB_DAYS]
		-- 	WHEN '090'
		-- 	THEN '57'
		-- 	ELSE '25'
		-- 	END Modifier
	FROM
		[CHART_PHYSICIAN_LEVEL_OF_SERVICE] c
		JOIN [PHYSICIAN_PROCEDURE_EVALUATION] ppe
		  ON ppe.[CHART_ID] = c.[CHART_ID] AND ppe.[PHYSICIAN_ID] = c.[PROVIDER_ID] AND ppe.[PROCEDURE_DATE] = c.[DATE_OF_SERVICE]
		JOIN [CHARGE_MASTER]
		  ON [CHARGE_MASTER].[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
		JOIN [FACILITY_PROFESSIONAL] fp
		  ON fp.[FACILITY_PROF_ID] = c.[PROVIDER_ID]
		LEFT JOIN [CMS_PHYSICIAN_RVU] cpr
			   ON cpr.[HCPCS] = [CHARGE_MASTER].[CPT_CODE]
				AND DATEADD(DAY, DATEDIFF(DAY, 0, c.[DATE_OF_SERVICE]), 0) BETWEEN cpr.[EFFECTIVE_DT] AND cpr.[EXPIRATION_DT]
				AND cpr.[GLOB_DAYS] = '090'
	WHERE
		c.[CHART_ID] = @ChartId
		AND [CHARGE_MASTER].[CHARGE_MASTER_USAGE_CODE] = 5
		AND
		(
			(
				@UseCMSDefinitionOfSurgicalProcedure = 1
				AND
				(
					EXISTS (
						SELECT 1
						FROM
							[CMS_ADDENDUM_B]
						WHERE
							[HCPCS_CPT_CODE] = [CHARGE_MASTER].[CPT_CODE]
							AND (
									[REQUIRES_MODIFIER_25] = 1
									OR
									(@FacilityFinancialClassApplyPhysSvcMod25OnStatusBProcs = 1 AND [STATUS_INDICATOR] = 'B')
								)
					)
				)
			)
			OR
			(
				@UseCMSDefinitionOfSurgicalProcedure = 0
				AND
					[CHARGE_MASTER].[CPT_CODE] BETWEEN '10000' AND '69999'
					OR ([CHARGE_MASTER].[CPT_CODE] IN ('92950','92953','92960','92961','92977','97597','97598','G0168'))		
			)
		)
	-- GROUP BY
	-- 	CASE cpr.GLOB_DAYS
	-- 		WHEN '090'
	-- 		THEN '57'
	-- 		ELSE '25'
	-- 		END
	-- ORDER BY
	-- 	Modifier

/*
replaces:
file: "\ACS\CCSBusinessObjects\BusinessObjects\Chart\Physician\Service\ChartPhysicianLevelOfService.cs"
procedure: "public bool HasAPhysicianProcedureWith25ModifierFlag(Chart chart)"

			StringBuilder sb = new StringBuilder();
			sb.Append(" SELECT COUNT(*) Procs,");
			sb.Append("   CASE cpr.GLOB_DAYS");
			sb.Append("     WHEN '090'");
			sb.Append("       THEN '57'");
			sb.Append("     ELSE '25'");
			sb.Append("     END Modifier");
			sb.Append(" FROM CHART_PHYSICIAN_LEVEL_OF_SERVICE c WITH (NOLOCK) ");
			sb.Append("   JOIN PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK) ON ppe.CHART_ID = c.CHART_ID AND ppe.PHYSICIAN_ID = c.PROVIDER_ID AND ppe.PROCEDURE_DATE = c.DATE_OF_SERVICE");
			sb.Append("   JOIN CHARGE_MASTER WITH (NOLOCK) ON CHARGE_MASTER.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID");
			sb.Append("   JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = c.PROVIDER_ID");
			sb.Append(" LEFT JOIN CMS_PHYSICIAN_RVU cpr WITH (NOLOCK) ON cpr.HCPCS = CHARGE_MASTER.CPT_CODE");
			sb.Append("   AND DATEADD(DAY, DATEDIFF(DAY, 0, c.DATE_OF_SERVICE), 0) BETWEEN cpr.EFFECTIVE_DT AND cpr.EXPIRATION_DT");
			sb.Append("   AND cpr.GLOB_DAYS = '090'");
			sb.Append(" WHERE c.CHART_ID = " + chart.ChartID);
			sb.Append("   AND CHARGE_MASTER.CHARGE_MASTER_USAGE_CODE = " + ChargeMasterUsageCode.USAGE_CODE_PHYSICIAN_PROCEDURE);
			sb.Append("   AND (");

			if (chart.ServiceAgreement.UseCMSDefinitionOfSurgicalProcedure)
			{
				sb.Append(" EXISTS (");
				sb.Append("   SELECT 1");
				sb.Append("   FROM CMS_ADDENDUM_B WITH (NOLOCK)");
				sb.Append("   WHERE HCPCS_CPT_CODE = CHARGE_MASTER.CPT_CODE");
				sb.Append("     AND (");
				sb.Append("       REQUIRES_MODIFIER_25 = 1");

				if (chart.FacilityFinancialClass.ApplyPhysSvcMod25OnStatusBProcs)
					sb.Append(" OR STATUS_INDICATOR='B'");

				sb.Append("))");
			}
			else
			{
				sb.Append(" CHARGE_MASTER.CPT_CODE BETWEEN '10000' AND '69999'");
				sb.Append(" OR (");
				sb.Append("   CHARGE_MASTER.CPT_CODE IN (");
				sb.Append("     '92950',");
				sb.Append("     '92953',");
				sb.Append("     '92960',");
				sb.Append("     '92961',");
				sb.Append("     '92977',");
				sb.Append("     '97597',");
				sb.Append("     '97598',");
				sb.Append("     'G0168'");
				sb.Append("     )");
				sb.Append("   )");
			}

			sb.Append(")");

			sb.Append(" GROUP BY CASE cpr.GLOB_DAYS");
			sb.Append("   WHEN '090'");
			sb.Append("     THEN '57'");
			sb.Append("   ELSE '25'");
			sb.Append("   END");
			sb.Append(" ORDER BY Modifier");


*/
END
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectHasAPhysicianProcedureWith25ModifierFlagByChartIdAndEtAlVer2]
	 @ChartId INT
	,@UseCMSDefinitionOfSurgicalProcedure BIT = 0
	,@FacilityFinancialClassApplyPhysSvcMod25OnStatusBProcs BIT = 0
	,@ApplyPhysicianService25ModifierBasedOnPerformingProvider BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
	
	DROP TABLE IF EXISTS #TblBaseResults;
	
	CREATE TABLE #TblBaseResults
		(
			 Procs int
			,Modifier VARCHAR(10) NULL
		)
	
	IF @ApplyPhysicianService25ModifierBasedOnPerformingProvider = 1
	BEGIN
		INSERT INTO #TblBaseResults (Procs, Modifier)
		SELECT
			 COUNT(*) Procs
			,CASE cpr.[GLOB_DAYS]
				WHEN '090'
				THEN '57'
				ELSE '25'
				END Modifier
		FROM
			[CHART] c
			JOIN [PHYSICIAN_PROCEDURE_EVALUATION] ppe
			  ON ppe.[CHART_ID] = c.[CHART_ID]
			JOIN [CHARGE_MASTER]
			  ON [CHARGE_MASTER].[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
			LEFT JOIN [FACILITY_PROFESSIONAL] attending
				   ON attending.[FACILITY_PROF_ID] = c.[PHYSICIAN_ID]
			LEFT JOIN [FACILITY_PROFESSIONAL] midlevel
				   ON midlevel.[FACILITY_PROF_ID] = c.[NURSE_PRACTITIONER_ID]
			LEFT JOIN [FACILITY_PROFESSIONAL] performing
				   ON performing.[FACILITY_PROF_ID] = ppe.[PHYSICIAN_ID]
			LEFT JOIN [CMS_PHYSICIAN_RVU] cpr
				   ON cpr.[HCPCS] = [CHARGE_MASTER].[CPT_CODE]
						AND DATEADD(DAY, DATEDIFF(DAY, 0, c.[TIME_OF_SERVICE]), 0) BETWEEN cpr.[EFFECTIVE_DT] AND cpr.[EXPIRATION_DT]
						AND cpr.[GLOB_DAYS] = '090'
			WHERE
				c.[CHART_ID] = @ChartId
				AND [CHARGE_MASTER].[CHARGE_MASTER_USAGE_CODE] = 5 --ChargeMasterUsageCode.USAGE_CODE_PHYSICIAN_PROCEDURE
				AND
				(
					(
						@UseCMSDefinitionOfSurgicalProcedure = 1
						AND
						(
							EXISTS
							(
								SELECT 1
								FROM
									[CMS_ADDENDUM_B]
								WHERE
									[HCPCS_CPT_CODE] = [CHARGE_MASTER].[CPT_CODE]
									AND (
											[REQUIRES_MODIFIER_25] = 1
											OR
											(@FacilityFinancialClassApplyPhysSvcMod25OnStatusBProcs = 1 AND [STATUS_INDICATOR] = 'B')
										)
							)
						)
					)
					OR
					(
						@UseCMSDefinitionOfSurgicalProcedure = 0
						AND
						(
							(
								LEN([CHARGE_MASTER].[CPT_CODE]) >= 5
								AND ([CHARGE_MASTER].[CPT_CODE] BETWEEN '10000' AND '69999')
								AND (SUBSTRING([CHARGE_MASTER].[CPT_CODE], 5, 1) NOT BETWEEN 'A' AND 'Z')
							)
							OR
								[CHARGE_MASTER].[CPT_CODE] IN ('92950','92953','92960','92961','92977','97597','97598','G0168')
						)
					)
				)
				AND
				(
					ppe.[PHYSICIAN_ID] = -1
					OR
					performing.[FACILITY_PROF_ID] IN (attending.[FACILITY_PROF_ID], midlevel.[FACILITY_PROF_ID])
					OR
					performing.[ROLE_ID] = 1
				)
			GROUP BY
				CASE cpr.[GLOB_DAYS]
					WHEN '090'
					THEN '57'
					ELSE '25'
					END
			ORDER BY
				Modifier;
	END
	ELSE
	BEGIN
		INSERT INTO #TblBaseResults (Procs, Modifier)
		SELECT
			 COUNT(*) Procs
			,CASE cpr.[GLOB_DAYS]
				WHEN '090'
				THEN '57'
				ELSE '25'
				END Modifier
		FROM
			[CHART] c
			JOIN [PHYSICIAN_PROCEDURE_EVALUATION] ppe
			  ON ppe.[CHART_ID] = c.[CHART_ID]
			JOIN [CHARGE_MASTER]
			  ON [CHARGE_MASTER].[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
			LEFT JOIN [CMS_PHYSICIAN_RVU] cpr
				   ON cpr.[HCPCS] = [CHARGE_MASTER].[CPT_CODE]
						AND DATEADD(DAY, DATEDIFF(DAY, 0, c.[TIME_OF_SERVICE]), 0) BETWEEN cpr.[EFFECTIVE_DT] AND cpr.[EXPIRATION_DT]
						AND cpr.[GLOB_DAYS] = '090'
		WHERE
			c.[CHART_ID] = @ChartId
			AND [CHARGE_MASTER].[CHARGE_MASTER_USAGE_CODE] =  5 --ChargeMasterUsageCode.USAGE_CODE_PHYSICIAN_PROCEDURE
			AND
			(
				(
					@UseCMSDefinitionOfSurgicalProcedure = 1
					AND
					(
						EXISTS
						(
							SELECT 1
							FROM
								[CMS_ADDENDUM_B]
							WHERE
								[HCPCS_CPT_CODE] = [CHARGE_MASTER].[CPT_CODE]
								AND (
										[REQUIRES_MODIFIER_25] = 1
										OR
										(@FacilityFinancialClassApplyPhysSvcMod25OnStatusBProcs = 1 AND [STATUS_INDICATOR] = 'B')
									)
						)
					)
				)
				OR
				(
					@UseCMSDefinitionOfSurgicalProcedure = 0
					AND
					(
						(
							LEN([CHARGE_MASTER].[CPT_CODE]) >= 5
							AND ([CHARGE_MASTER].[CPT_CODE] BETWEEN '10000' AND '69999')
							AND (SUBSTRING([CHARGE_MASTER].[CPT_CODE], 5, 1) NOT BETWEEN 'A' AND 'Z')
						)
						OR
							[CHARGE_MASTER].[CPT_CODE] IN ('92950','92953','92960','92961','92977','97597','97598','G0168')
					)
				)
			)
			GROUP BY
				CASE cpr.[GLOB_DAYS]
					WHEN '090'
					THEN '57'
					ELSE '25'
					END
			ORDER BY
				Modifier;
	END

	SELECT TOP 1
		Modifier
	FROM
		#TblBaseResults
	WHERE
		Procs > 0;	
	
/*
replaces:
file: "\ACS\CCSBusinessObjects\BusinessObjects\Chart\Demographics\Chart.cs"
procedure: "public bool HasAPhysicianProcedureWith25ModifierFlag(out string modifier)"

				var sb = new StringBuilder();
				sb.Append(" SELECT COUNT(*) Procs,");
				sb.Append("   CASE cpr.GLOB_DAYS");
				sb.Append("     WHEN '090'");
				sb.Append("       THEN '57'");
				sb.Append("     ELSE '25'");
				sb.Append("     END Modifier");
				sb.Append(" FROM CHART c WITH (NOLOCK)");
				sb.Append("   JOIN PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK) ON ppe.CHART_ID = c.CHART_ID");
				sb.Append("   JOIN CHARGE_MASTER WITH (NOLOCK) ON CHARGE_MASTER.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID");

				if (ServiceAgreement.ApplyPhysicianService25ModifierBasedOnPerformingProvider)
				{
					sb.Append(" LEFT JOIN FACILITY_PROFESSIONAL attending WITH (NOLOCK) ON attending.FACILITY_PROF_ID = c.PHYSICIAN_ID");
					sb.Append(" LEFT JOIN FACILITY_PROFESSIONAL midlevel WITH (NOLOCK) ON midlevel.FACILITY_PROF_ID = c.NURSE_PRACTITIONER_ID");
					sb.Append(" LEFT JOIN FACILITY_PROFESSIONAL performing WITH (NOLOCK) ON performing.FACILITY_PROF_ID = ppe.PHYSICIAN_ID");
				}

				sb.Append(" LEFT JOIN CMS_PHYSICIAN_RVU cpr WITH (NOLOCK) ON cpr.HCPCS = CHARGE_MASTER.CPT_CODE");
				sb.Append("   AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cpr.EFFECTIVE_DT AND cpr.EXPIRATION_DT");
				sb.Append("   AND cpr.GLOB_DAYS = '090'");
				sb.Append(" WHERE c.CHART_ID = " + ChartID);
				sb.Append("   AND CHARGE_MASTER.CHARGE_MASTER_USAGE_CODE = " + ChargeMasterUsageCode.USAGE_CODE_PHYSICIAN_PROCEDURE);
				sb.Append("   AND (");

				if (ServiceAgreement.UseCMSDefinitionOfSurgicalProcedure)
				{
					sb.Append(" EXISTS (");
					sb.Append("   SELECT 1");
					sb.Append("   FROM CMS_ADDENDUM_B WITH (NOLOCK)");
					sb.Append("   WHERE HCPCS_CPT_CODE = CHARGE_MASTER.CPT_CODE");
					sb.Append("     AND (");
					sb.Append("       REQUIRES_MODIFIER_25 = 1");

					if (FacilityFinancialClass.ApplyPhysSvcMod25OnStatusBProcs)
						sb.Append(" OR STATUS_INDICATOR='B'");

					sb.Append("))");
				}
				else
				{
					sb.Append(" (( LEN(CHARGE_MASTER.CPT_CODE) >= 5) AND (CHARGE_MASTER.CPT_CODE BETWEEN '10000' AND '69999') AND (SUBSTRING(CHARGE_MASTER.CPT_CODE,5,1) NOT BETWEEN 'A' AND 'Z') )");
					sb.Append(" OR (");
					sb.Append("   CHARGE_MASTER.CPT_CODE IN ('92950','92953','92960','92961','92977','97597','97598','G0168')");
					sb.Append("   )");
				}

				sb.Append(")");

				if (ServiceAgreement.ApplyPhysicianService25ModifierBasedOnPerformingProvider)
				{
					sb.Append(" AND (");
					sb.Append("   ppe.PHYSICIAN_ID = - 1");
					sb.Append("   OR performing.FACILITY_PROF_ID IN (");
					sb.Append("     attending.FACILITY_PROF_ID,");
					sb.Append("     midlevel.FACILITY_PROF_ID");
					sb.Append("     )");
					sb.Append("   OR performing.ROLE_ID = 1");
					sb.Append(" )");
				}

				sb.Append(" GROUP BY CASE cpr.GLOB_DAYS");
				sb.Append("   WHEN '090'");
				sb.Append("     THEN '57'");
				sb.Append("   ELSE '25'");
				sb.Append("   END");
				sb.Append(" ORDER BY Modifier");

*/
END
GO