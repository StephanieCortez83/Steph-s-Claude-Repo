SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_Get_DashboardPendingReportSimple] @ReturnCount			bit			 = 0
																			 , @ChartSearchMaxCount int			 = 3000
																			 , @OrderBy				int			 = 0
																			 , @SortDirection		varchar(4)	 = 'ASC'

																				-- Core Filtering
																			 , @Facilities			varchar(MAX) = NULL
																			 , @ChartStatuses		varchar(50)	 = ''
																			 , @PendingReasons		varchar(MAX) = NULL
																			 , @DosFrom				date		 = NULL
																			 , @DosTo				date		 = NULL
																			 , @ReceivedFrom		date		 = NULL
																			 , @ReceivedTo			date		 = NULL

																				-- Additional Filtering
																			 , @ImageFilter			int			 = 0
																			 , @ShowDebug			bit			 = 0
AS
	BEGIN
		SET NOCOUNT ON;

		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

		IF @Facilities IS NULL
		   OR	LEN(@Facilities) <= 0
			BEGIN
				IF @ShowDebug = 1
					PRINT ('No Facility List provided. Exiting.'); -- testing
				RETURN -1;
			END;
            

		DECLARE @TodayDate date = GETDATE();
		DECLARE @MinimumDate date = DATEADD(MONTH, -12, @TodayDate); -- techanical Max -42 for Archival system.  12 months for actual use.  ACS set at 6 months
		DECLARE @TodayDateTime datetime = GETDATE();
		DECLARE @MinimumDateTime datetime = DATEADD(MONTH, -12, @TodayDateTime); -- techanical Max -42 for Archival system  12 months for actual use.  ACS set at 6 months
		DECLARE @DosFromDate date = IIF(@DosFrom IS NULL OR @DosFrom < '01-01-1900' OR @DosFrom	 > @TodayDate, @MinimumDate, @DosFrom);
		DECLARE @DosFromDateTime datetime = @DosFromDate;
		DECLARE @DosToDate date = IIF(@DosTo IS NULL OR @DosTo < '01-01-1900' OR @DosTo > @TodayDate, @TodayDate, @DosTo);
		DECLARE @DosToDateTime datetime = DATEADD(ms, -3, DATEADD(DAY, 1, CAST(@DosToDate AS datetime)));
		DECLARE @ReceivedFromDate date = IIF(@ReceivedFrom IS NULL OR @ReceivedFrom	  < '01-01-1900' OR @ReceivedFrom > @TodayDate, @MinimumDate, @ReceivedFrom);
		DECLARE @ReceivedFromDateTime datetime = @ReceivedFromDate;
		DECLARE @ReceivedToDate date = IIF(@ReceivedTo IS NULL OR @ReceivedTo <	  '01-01-1900' OR @ReceivedTo >	  @TodayDate, @TodayDate, @ReceivedTo);
		DECLARE @ReceivedToDateTime datetime = DATEADD(ms, -3, DATEADD(DAY, 1, CAST(@ReceivedToDate AS datetime)));
		
		SELECT	  CAST(items AS int) AS Items
		INTO	#FacilityIDList
		FROM	dbo.SplitString(@Facilities, ',');

		SELECT	CAST(items AS int) AS Items
		INTO	#PendingIDList
		FROM	dbo.SplitString(@PendingReasons, ',');


		IF ISNULL(LEN(@ChartStatuses),0)=0
			SET @ChartStatuses = '1,2,3,4,6,7,8'; -- excluding SENT status charts for default behavior.

		SELECT	 CAST(items AS int)AS Items
		INTO	#StatusIDList
		FROM	dbo.SplitString(@ChartStatuses, ',');

        
		IF @ShowDebug = 1
		BEGIN
			SELECT '#FacilityIDList',  Items FROM #FacilityIDList	-- testing
			UNION
			SELECT '#StatusIDList',	 Items FROM #StatusIDList	-- testing
			UNION
			SELECT '#PendingIDList',  Items FROM #PendingIDList;	-- testing
		END;

		DECLARE @MaxChartId int = (SELECT	MAX([CHART_ID])
								   FROM		[CHART]
								   WHERE	[TIME_OF_SERVICE] <= @DosToDateTime
											AND [DATE_RECEIVED] <= @ReceivedToDateTime);
		DECLARE @MinChartId int = (@MaxChartId - 2000000); -- ACS creates roughly 2 million charts/year.  this value helps limit searches to speed efficiency

		IF @MaxChartId >= 2100100100 -- for QA servers
			BEGIN
				SET @MinChartId = ((SELECT	MAX([CHART_ID])
									FROM	[CHART]
									WHERE	[CHART_ID] < 2100100100) - 2000000);
			END;

		IF @ShowDebug = 1
			BEGIN
				SELECT	'Inputs'			  = 'Inputs:'
					  , 'ReturnCount'		  = @ReturnCount
					  , 'ChartSearchMaxCount' = @ChartSearchMaxCount
					  , 'OrderBy'			  = @OrderBy
					  , 'SortDirection'		  = @SortDirection
					  , 'Facilities'		  = @Facilities
					  , 'ChartStatuses'		  = @ChartStatuses
					  , 'PendingReasons'	  = @PendingReasons
					  , 'DosFrom'			  = @DosFrom
					  , 'DosTo'				  = @DosTo
					  , 'ReceivedFrom'		  = @ReceivedFrom
					  , 'ReceivedTo'		  = @ReceivedTo
					  , 'ImageFilter'		  = @ImageFilter;
			END;

		IF @OrderBy >= 25
		   OR	@OrderBy <= 0
			SET @OrderBy = 100;

		IF @ChartSearchMaxCount > 3001
			SET @ChartSearchMaxCount = 3001;

		IF @ShowDebug = 1
			BEGIN
				-- testing
				SELECT	'Derivatives'		   = 'Input derivatives:'
					  , 'TodayDate'			   = @TodayDate
					  , 'MinimumDate'		   = @MinimumDate
					  , 'TodayDateTime'		   = @TodayDateTime
					  , 'MinimumDateTime'	   = @MinimumDateTime
					  , 'DosFromDate'		   = @DosFromDate
					  , 'DosFromDateTime'	   = @DosFromDateTime
					  , 'DosToDate'			   = @DosToDate
					  , 'DosToDateTime'		   = @DosToDateTime
					  , 'ReceivedFromDate'	   = @ReceivedFromDate
					  , 'ReceivedFromDateTime' = @ReceivedFromDateTime
					  , 'ReceivedToDate'	   = @ReceivedToDate
					  , 'ReceivedToDateTime'   = @ReceivedToDateTime
					  , 'MinChartId'		   = @MinChartId
					  , 'MaxChartId'		   = @MaxChartId
					  , 'ChartSearchMaxCount'  = @ChartSearchMaxCount
					  , 'OrderBy'			   = @OrderBy;
			END;

		DROP TABLE IF EXISTS #ChartIDs;

		CREATE TABLE #ChartIDs ([CHART_ID]			   int
							  , [IMAGES_AVAILABLE]	   bit NULL
							  , [CHART_STATUS_ID]	   int
							  , [SERVICE_AGREEMENT_ID] int) 
            
         --no pending reason filter
		IF NOT EXISTS (SELECT 1	  FROM #PendingIDList)
			BEGIN
            WITH cteCharts AS (
						   SELECT	TOP (10000)
									c.[CHART_ID]
						   FROM		[CHART] c
						   WHERE	c.[CHART_ID] BETWEEN @MinChartId AND @MaxChartId
									AND c.[TIME_OF_SERVICE] BETWEEN @DosFromDateTime AND @DosToDateTime
									AND c.[DATE_RECEIVED] BETWEEN @ReceivedFromDateTime AND @ReceivedToDateTime
									AND EXISTS (SELECT	1
												FROM	#FacilityIDList t1
												WHERE	c.[FACILITY_ID] = t1.Items)
									AND EXISTS (SELECT	1
												FROM	#StatusIDList t2
												WHERE	c.[CHART_STATUS_ID] = t2.Items)
						   ORDER BY c.[TIME_OF_SERVICE] DESC)
				INSERT INTO #ChartIDs ([CHART_ID]
									  , IMAGES_AVAILABLE
									  , CHART_STATUS_ID
									  , SERVICE_AGREEMENT_ID)
							SELECT	TOP (10000)
									c.[CHART_ID]
								  , c.[IMAGES_AVAILABLE]
								  , c.[CHART_STATUS_ID]
								  , c.[SERVICE_AGREEMENT_ID]
							FROM	[CHART] c
							WHERE	EXISTS (SELECT	1
											FROM	cteCharts t2
											WHERE	c.CHART_ID = t2.CHART_ID);
			END;
		ELSE
        --pending reason filter
			BEGIN
            WITH cteCharts AS (
						   SELECT	TOP (10000)
									c.[CHART_ID]
						   FROM		[CHART] c
						   WHERE	c.[CHART_ID] BETWEEN @MinChartId AND @MaxChartId
									AND c.[TIME_OF_SERVICE] BETWEEN @DosFromDateTime AND @DosToDateTime
									AND c.[DATE_RECEIVED] BETWEEN @ReceivedFromDateTime AND @ReceivedToDateTime
									AND EXISTS (SELECT	1
												FROM	#FacilityIDList t1
												WHERE	c.[FACILITY_ID] = t1.Items)
									AND EXISTS (SELECT	1
												FROM	#StatusIDList t2
												WHERE	c.[CHART_STATUS_ID] = t2.Items))
				INSERT INTO #ChartIDs ([CHART_ID]
									  , IMAGES_AVAILABLE
									  , CHART_STATUS_ID
									  , SERVICE_AGREEMENT_ID)
							SELECT		TOP (10000)
										c.[CHART_ID]
									  , c.[IMAGES_AVAILABLE]
									  , c.[CHART_STATUS_ID]
									  , c.[SERVICE_AGREEMENT_ID]
							FROM		[CHART] c
							WHERE		EXISTS (SELECT	1
												FROM	cteCharts t2
												WHERE	c.CHART_ID = t2.CHART_ID)
										AND (c.[CHART_STATUS_ID] NOT IN (2, 6)-- statuses not requiring the pending reason check
											 OR EXISTS (SELECT	1
														FROM	[CHART_PENDING_REASON]					cpr2
																JOIN [SERVICE_AGREEMENT_PENDING_REASON] spr2
																	ON cpr2.[SERVICE_AGREEMENT_PENDING_REASON_ID] = spr2.[SERVICE_AGREEMENT_PENDING_REASON_ID]
														WHERE	cpr2.[CHART_ID] = c.[CHART_ID]
																AND spr2.[PENDING_REASON_ID] IN (SELECT Items FROM #PendingIDList  )))
							ORDER BY	c.[TIME_OF_SERVICE] DESC;
			END;


            

            
		 IF @ShowDebug = 1
		 BEGIN
		 	SELECT '233) #ChartIDs (Base) = ' = '#ChartIDs (Base) ----->>>'; -- testing
		 	SELECT * FROM #ChartIDs; -- testing
		 END
		IF @ImageFilter = 1 -- per JB comments will eventually turn this into a BIT null check to give a tertiary behavior based on BIT instead of INT data type
			BEGIN
				PRINT ('Image filtering [1]...');

				DELETE FROM	 #ChartIDs WHERE [IMAGES_AVAILABLE]	   <> 1;
			END;
		ELSE IF @ImageFilter = 2
			BEGIN
				PRINT ('Image filtering [2]...');

				DELETE FROM	 #ChartIDs WHERE [IMAGES_AVAILABLE]	   <> 0;
			END;

		DECLARE @CountChartIds int = (SELECT COUNT	 (*)FROM   #ChartIDs);
        
		IF @ShowDebug = 1
			BEGIN
				SELECT	'250) #ChartIDs (Filter images) = ' = '#ChartIDs (Filter images) ----->>>'; -- testing
				PRINT ('@CountChartIds = ' + CAST(@CountChartIds AS varchar(50))); -- testing
				SELECT *  FROM #ChartIDs;	-- testing
            
			END;



		IF @ReturnCount = 1
			BEGIN
				SELECT '[TOTAL]'  = @CountChartIds;

				RETURN @CountChartIds;
			END;

		IF @CountChartIds <= 0 RETURN;

		SELECT	TOP (@ChartSearchMaxCount)
				c.[CHART_ID]
			  , c.[FACILITY_CHART_ID]
			  , c.[MEDICAL_RECORD_NUM]
			  , c.[PATIENT_DOB]
			  , c.[SERVICE_AGREEMENT_ID]
			  , c.[CLIENT_COMMENT]
			  , c.[CHANGED_DATE_TIME]
			  , c.[CREATION_DATE_TIME]
			  , c.[TIME_OF_SERVICE]
			  , c.[TIME_OF_DIS]
			  , c.[CODER_COMMENT]
			  , c.[PATIENT_LAST_NAME]
			  , c.[PATIENT_FIRST_NAME]
			  , c.[CHART_STATUS_ID]
			  , c.[PATIENT_DISPOSITION_ID]
			  , c.[PENDING_REASON_ID]
			  , c.[FACILITY_ID]
			  , c.[SENT_DATE]
			  , c.[LOCATION_CODE]
			  , c.[FACILITY_ADMIN_CHART_ID]
			  , c.[PHYSICIAN_ID]
			  , c.[NURSE_PRACTITIONER_ID]
			  , c.[PATIENT_CLASS_ID]
			  , c.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]
			  , c.[INITIAL_CHARGE_MASTER_DEPT_ID]
			  , f.[NAME]														 FACILITY
			  , sa.[SERVICE_MODEL_CD] + CONVERT(varchar(10), up.[USER_CLASS_CD]) AS ServiceModelCode
			  , up.[FIRST_NAME]
			  , up.[LAST_NAME]
			  , c.[ASSIGNED_TO_ID]
			  , c.[LONG_PATIENT_ID1]
			  , c.[DATE_RECEIVED]
		INTO	#ChartSubset
		FROM	#ChartIDs					 t
				INNER JOIN CHART			 c
					ON c.CHART_ID = t.CHART_ID
				INNER JOIN FACILITY			 f
					ON f.FACILITY_ID = c.FACILITY_ID
				INNER JOIN USER_PROFILE		 up
					ON up.USER_PROFILE_ID = c.ASSIGNED_TO_ID
				INNER JOIN SERVICE_AGREEMENT sa
					ON sa.SERVICE_AGREEMENT_ID = t.SERVICE_AGREEMENT_ID;
                 

		DECLARE @CountSubset int = (SELECT COUNT(*)FROM	 #ChartSubset);
		IF @ShowDebug = 1
			PRINT ('@CountSubset = ' + CAST(@CountSubset AS varchar(50))); -- testing

            --need to split this into two queries due to indexing
		 SELECT	i.IMPORT_IMAGE_ID
			  , s.[FACILITY_CHART_ID]
			  , i.[SERVICE_AGREEMENT_ID]
		INTO	#ImagesFilter
		FROM	[IMPORT_IMAGE]			i
				INNER JOIN #ChartSubset s
					ON i.[FACILITY_CHART_ID] = s.[FACILITY_CHART_ID];

		SELECT	x.FACILITY_CHART_ID
			  , x.SERVICE_AGREEMENT_ID
			  , i.[CREATION_DATE_TIME]
		INTO	#Images
		FROM	#ImagesFilter			  x
				INNER JOIN [IMPORT_IMAGE] i
					ON i.IMPORT_IMAGE_ID = x.IMPORT_IMAGE_ID;

			IF @ShowDebug = 1
			BEGIN
				SELECT '322) #Images = '  = '#Images ----->>>'; -- testing

				SELECT *  FROM #Images;		-- testing
			END;

		WITH cteSubqueryA AS (
							 SELECT		[FACILITY_CHART_ID]
									  , [SERVICE_AGREEMENT_ID]
									  , MAX(img1.[CREATION_DATE_TIME]) [CREATION_DATE_TIME]
							 FROM		#Images img1
							 GROUP BY	[FACILITY_CHART_ID]
									  , [SERVICE_AGREEMENT_ID]
							 )
		   , cteSubqueryC AS (
							 SELECT c.[CHART_ID]
								  , STRING_AGG(pr.[DESCRIPTION], '|') WITHIN GROUP(ORDER BY sap.[RANK_VALUE]) [PendingReason]
							 FROM	#ChartSubset								  c
									INNER JOIN [CHART_PENDING_REASON]			  cpr
										ON cpr.[CHART_ID] = c.[CHART_ID]
									INNER JOIN [SERVICE_AGREEMENT_PENDING_REASON] sap
										ON sap.[SERVICE_AGREEMENT_PENDING_REASON_ID] = cpr.[SERVICE_AGREEMENT_PENDING_REASON_ID]
									INNER JOIN [PENDING_REASON]					  pr
										ON sap.[PENDING_REASON_ID] = pr.[PENDING_REASON_ID]
							 WHERE	c.[CHART_STATUS_ID] IN (2, 6)
							 GROUP BY -- pip group by added so SPROC would execute without select error
									sap.[RANK_VALUE]
								  , c.[CHART_ID]
							 )
		SELECT	c.[FACILITY]																								 [FACILITY]
			  , c.[CHART_ID]																								 [CHART_ID]
			  , c.[FACILITY_CHART_ID]																						 [FACILITY_CHART_ID]
			  , c.[MEDICAL_RECORD_NUM]																						 [MEDICAL_RECORD_NUM]
			  , c.[PATIENT_DOB]																								 [PATIENT_DOB]
			  , subA.CREATION_DATE_TIME																						 [LAST_IMAGE_RECEIPT_DATE]
			  , c.[CLIENT_COMMENT]																							 [LIENT_COMMENT]
			  , c.[CHANGED_DATE_TIME]																						 [CHANGED_DATE_TIME]
			  , IIF(subB.FACILITY_CHART_ID IS NOT NULL, 'Yes', 'No')														 [EMR?]
			  , 'Yes'																										 [Census?]
			  , c.[CREATION_DATE_TIME]																						 Received
			  , c.[TIME_OF_SERVICE]																							 DOS
			  , c.[TIME_OF_DIS]																								 DISCHARGE
			  , cs.[DESCRIPTION]																							 [STATUS]
			  , ISNULL(subC.[PendingReason], '')																			 [Pending Reason]
			  , pd.[DESCRIPTION]																							 [Patient Disposition]
			  , c.[CODER_COMMENT]																							 [Coder Notes]
			  , c.[PATIENT_LAST_NAME] + ', ' + c.[PATIENT_FIRST_NAME]														 [Patient]
			  , fp.[LAST_NAME] + ', ' + fp.[FIRST_NAME] + ' ' + fp.[NAME_SUFFIX] + ' (' + fp.[EMPLOYEE_IDENTIFIER] + ')'	 Physician
			  , c.[CHART_STATUS_ID]																							 [CHART_STATUS_ID]
			  , ISNULL([PATIENT_CLASS].[DESCRIPTION], 'All')																 PatientClass
			  , c.[PATIENT_DISPOSITION_ID]																					 [PATIENT_DISPOSITION_ID]
			  , c.[PENDING_REASON_ID]																						 [PENDING_REASON_ID]
			  , c.[FACILITY_ID]																								 [FACILITY_ID]
			  , c.[SENT_DATE]																								 [SENT]
			  , c.[LOCATION_CODE]																							 [LOCATION_CODE]
			  , mlp.[LAST_NAME] + ', ' + mlp.[FIRST_NAME] + ' ' + mlp.[NAME_SUFFIX] + ' (' + mlp.[EMPLOYEE_IDENTIFIER] + ')' [Mid-Level]
			  , sao.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC]																 [OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC]
			  , cmd.[NAME]																									 [InitialObservationDept]
			  , c.[FACILITY_ADMIN_CHART_ID]																					 [FACILITY_ADMIN_CHART_ID]
			  , c.[ServiceModelCode]																						 [Service Model Code]
			  , c.[FIRST_NAME]																								 [First Name]
			  , c.[LAST_NAME]																								 [Last Name]
			  , pba.[ChartPostBillAuditStatusTypeCode]																		 [ChartPostBillAuditStatusTypeCode]
			  , c.[LONG_PATIENT_ID1]
		FROM	#ChartSubset													 c
				LEFT JOIN [FACILITY_PROFESSIONAL]								 fp
					ON fp.[FACILITY_PROF_ID] = c.[PHYSICIAN_ID]
					   AND c.[PHYSICIAN_ID] > -1
				LEFT JOIN [FACILITY_PROFESSIONAL]								 mlp
					ON mlp.[FACILITY_PROF_ID] = c.[NURSE_PRACTITIONER_ID]
					   AND c.[NURSE_PRACTITIONER_ID] > -1
				INNER JOIN [CHART_STATUS]										 cs
					ON cs.[CHART_STATUS_ID] = c.[CHART_STATUS_ID]
				LEFT JOIN [PATIENT_CLASS]
					ON [PATIENT_CLASS].[PATIENT_CLASS_ID] = c.[PATIENT_CLASS_ID]
				LEFT JOIN [PATIENT_DISPOSITION]									 pd
					ON pd.[PATIENT_DISPOSITION_ID] = c.[PATIENT_DISPOSITION_ID]
				LEFT JOIN [SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE] sao
					ON sao.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID] = c.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]
				LEFT JOIN [CHARGE_MASTER_DEPARTMENT]							 cmd
					ON cmd.[CHARGE_MASTER_DEPT_ID] = c.[INITIAL_CHARGE_MASTER_DEPT_ID]
					   AND c.[INITIAL_CHARGE_MASTER_DEPT_ID] > -1
				LEFT JOIN [ChartPostBillAudit]									 pba
					ON pba.[ChartId] = c.[CHART_ID]
				LEFT JOIN cteSubqueryA											 subA
					ON subA.[FACILITY_CHART_ID] = c.[FACILITY_CHART_ID]
					   AND subA.[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
				LEFT JOIN (SELECT	DISTINCT
									img2.[FACILITY_CHART_ID]
								  , img2.[SERVICE_AGREEMENT_ID]
						   FROM		#Images img2	--jb subquery B					
				)																 subB
					ON c.[FACILITY_CHART_ID] = subB.[FACILITY_CHART_ID]
					   AND c.[SERVICE_AGREEMENT_ID] = subB.[SERVICE_AGREEMENT_ID]
				LEFT JOIN cteSubqueryC											 subC
					ON c.[CHART_ID] = subC.[CHART_ID]
	ORDER BY 
		CASE @OrderBy WHEN  100 THEN c.[TIME_OF_SERVICE] END ASC, --dos
		CASE @OrderBy WHEN -100 THEN c.[TIME_OF_SERVICE] END DESC, --dos

		CASE @OrderBy WHEN  1 THEN c.[FACILITY_CHART_ID] END ASC, 
		CASE @OrderBy WHEN -1 THEN c.[FACILITY_CHART_ID] END DESC, 
	
		CASE @OrderBy WHEN  2 THEN c.[MEDICAL_RECORD_NUM] END ASC, 
		CASE @OrderBy WHEN -2 THEN c.[MEDICAL_RECORD_NUM] END DESC, 
	
		CASE @OrderBy WHEN  3 THEN c.[CREATION_DATE_TIME] END ASC,	-- Received
		CASE @OrderBy WHEN -3 THEN c.[CREATION_DATE_TIME] END DESC,	-- Received
	
		CASE @OrderBy WHEN  4 THEN c.[CHANGED_DATE_TIME] END ASC, 
		CASE @OrderBy WHEN -4 THEN c.[CHANGED_DATE_TIME] END DESC, 
	
		CASE @OrderBy WHEN  5 THEN IIF(subB.FACILITY_CHART_ID IS NOT NULL, 'Yes', 'No') END ASC, --EMR?
		CASE @OrderBy WHEN -5 THEN IIF(subB.FACILITY_CHART_ID IS NOT NULL, 'Yes', 'No') END DESC, --EMR?
	
		CASE @OrderBy WHEN  6 THEN 'Yes' END ASC, --Census?
		CASE @OrderBy WHEN -6 THEN 'Yes' END DESC, --Census?
	
		CASE @OrderBy WHEN  7 THEN c.[CREATION_DATE_TIME] END ASC,-- Received
		CASE @OrderBy WHEN -7 THEN c.[CREATION_DATE_TIME] END DESC,-- Received
	
		CASE @OrderBy WHEN  8 THEN cs.[DESCRIPTION] END ASC, --Status
		CASE @OrderBy WHEN -8 THEN cs.[DESCRIPTION] END DESC, --Status
	
		CASE @OrderBy WHEN  9 THEN ISNULL(subC.[PendingReason], '')	 END ASC, --PendingReason
		CASE @OrderBy WHEN -9 THEN ISNULL(subC.[PendingReason], '')	 END DESC,--PendingReason
	
		CASE @OrderBy WHEN  10 THEN c.[PATIENT_LAST_NAME] + ', ' + c.[PATIENT_FIRST_NAME] END ASC, --Patient
		CASE @OrderBy WHEN -10 THEN c.[PATIENT_LAST_NAME] + ', ' + c.[PATIENT_FIRST_NAME] END DESC,--Patient
	
		CASE @OrderBy WHEN  11 THEN fp.[LAST_NAME] + ', ' + fp.[FIRST_NAME] + ' ' + fp.[NAME_SUFFIX] + ' (' + fp.[EMPLOYEE_IDENTIFIER] + ')' END ASC, --Physician
		CASE @OrderBy WHEN -11 THEN fp.[LAST_NAME] + ', ' + fp.[FIRST_NAME] + ' ' + fp.[NAME_SUFFIX] + ' (' + fp.[EMPLOYEE_IDENTIFIER] + ')' END DESC,--Physician
	
		CASE @OrderBy WHEN  12 THEN c.[TIME_OF_DIS] END ASC,--DISCHARGE
		CASE @OrderBy WHEN -12 THEN c.[TIME_OF_DIS] END DESC,--DISCHARGE
	
		CASE @OrderBy WHEN  13 THEN subA.CREATION_DATE_TIME END ASC,--LAST_IMAGE_RECEIPT_DATE
		CASE @OrderBy WHEN -13 THEN subA.CREATION_DATE_TIME END DESC,--LAST_IMAGE_RECEIPT_DATE
	
		CASE @OrderBy WHEN  14 THEN ISNULL([PATIENT_CLASS].[DESCRIPTION], 'All') END ASC,--PatientClass
		CASE @OrderBy WHEN -14 THEN ISNULL([PATIENT_CLASS].[DESCRIPTION], 'All') END DESC,--PatientClass
	
		CASE @OrderBy WHEN  15 THEN c.[FACILITY] END ASC, 
		CASE @OrderBy WHEN -15 THEN c.[FACILITY] END DESC, 
																				 
		CASE @OrderBy WHEN  16 THEN c.[SENT_DATE]	 END ASC,--SENT
		CASE @OrderBy WHEN -16 THEN c.[SENT_DATE]	 END DESC,--SENT 
	
		CASE @OrderBy WHEN  17 THEN c.[LOCATION_CODE] END ASC, 
		CASE @OrderBy WHEN -17 THEN c.[LOCATION_CODE] END DESC, 
	
		CASE @OrderBy WHEN  18 THEN mlp.[LAST_NAME] + ', ' + mlp.[FIRST_NAME] + ' ' + mlp.[NAME_SUFFIX] + ' (' + mlp.[EMPLOYEE_IDENTIFIER] + ')' END ASC,--Mid-Level
		CASE @OrderBy WHEN -18 THEN mlp.[LAST_NAME] + ', ' + mlp.[FIRST_NAME] + ' ' + mlp.[NAME_SUFFIX] + ' (' + mlp.[EMPLOYEE_IDENTIFIER] + ')' END DESC,--Mid-Level
	
		CASE @OrderBy WHEN  19 THEN cmd.[NAME] END ASC,--InitialObservationDept 
		CASE @OrderBy WHEN -19 THEN cmd.[NAME] END DESC,--InitialObservationDept 
	
		CASE @OrderBy WHEN  20 THEN sao.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC] END ASC, 
		CASE @OrderBy WHEN -20 THEN sao.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC] END DESC, 
	
		CASE @OrderBy WHEN  21 THEN c.[FACILITY_ADMIN_CHART_ID] END ASC, 
		CASE @OrderBy WHEN -21 THEN c.[FACILITY_ADMIN_CHART_ID] END DESC, 
	
		CASE @OrderBy WHEN  22 THEN pd.[DESCRIPTION] END ASC,--Patient Disposition 
		CASE @OrderBy WHEN -22 THEN pd.[DESCRIPTION] END DESC,--Patient Disposition 
	
		CASE @OrderBy WHEN  23 THEN c.[PATIENT_DOB] END ASC, 
		CASE @OrderBy WHEN -23 THEN c.[PATIENT_DOB] END DESC, 
	
		CASE @OrderBy WHEN  24 THEN c.[LONG_PATIENT_ID1] END ASC,--ChartPostBillAuditStatusTypeCode 
		CASE @OrderBy WHEN -24 THEN c.[LONG_PATIENT_ID1] END DESC--ChartPostBillAuditStatusTypeCode
		, [CHART_ID];


        SET @CountSubset = @@rowcount        

		IF @ShowDebug = 1
			PRINT ('@CountResults = ' + CAST(@CountSubset AS varchar(50))); -- testing

	END;
GO
