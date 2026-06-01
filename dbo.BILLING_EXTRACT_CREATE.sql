SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[BILLING_EXTRACT_CREATE]
WITH EXEC AS CALLER
AS
	BEGIN
		SET DEADLOCK_PRIORITY HIGH;

		SET NOCOUNT ON;

		DECLARE @BookmarkDT		  datetime
			  , @DateBilled		  datetime
			  , @BillingControlID int
			  , @BillEndDate	  datetime;

		SELECT	@BookmarkDT		  = DATEADD(dd, -7, START_DATE)
				-- go back 7 days from start of current period to make sure any stragglers are captured	
			  , @DateBilled		  = BILLING_DATE
			  , @BillingControlID = BILLING_CONTROL_ID
			  , @BillEndDate	  = END_DATE
		FROM	BILLING_CONTROL
		WHERE	STATUS_CD = 'A';

		DECLARE @BillEndDTFrom datetime = CAST(CAST(@BillEndDate AS date) AS datetime);
		DECLARE @BillEndDTThru datetime = DATEADD(ms, -3, DATEADD(DAY, 1, @BillEndDTFrom));
		DECLARE @cmd nvarchar(2000);
		 
		DROP TABLE IF EXISTS #BilledChart1;
		DROP TABLE IF EXISTS #BilledChart2;
		DROP TABLE IF EXISTS #BilledChart3;
		DROP TABLE IF EXISTS #BilledChart4;
		DROP TABLE IF EXISTS #BilledChart5; 
		DROP TABLE IF EXISTS #A; 
		DROP TABLE IF EXISTS #C;

		--get charts not yet invoiced (type A)
		WITH a AS (
				  SELECT	c.CHART_ID
				  FROM		CHART AS c WITH (NOLOCK)
				  WHERE		c.APPROVED_DATE BETWEEN @BookmarkDT AND @BillEndDTFrom
							AND c.CHART_STATUS_ID IN (4, 5)
							AND NOT EXISTS (SELECT	1
											FROM	BILLED_CHART b
											WHERE	c.CHART_ID = b.CHART_ID
													AND b.TYPE_CD = 'A')
				  )
		SELECT	CHART_ID
			  , COMPLETED_BY_USER_PROFILE_ID
			  , APPROVED_BY_USER_PROFILE_ID
			  , c.SERVICE_AGREEMENT_ID
			  , sa.BILL_CODER_METHOD_CD
		INTO	#A
		FROM	CHART							 c WITH (NOLOCK)
				INNER JOIN dbo.SERVICE_AGREEMENT sa WITH (NOLOCK)
					ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE	EXISTS (SELECT 1  FROM a  x WHERE x	 .CHART_ID = c.CHART_ID)
				AND DEMO_TEST_SITE_IND <> 1;

		--get charts not yet invoiced (type C)
		WITH c AS (
				  SELECT	c.CHART_ID
				  FROM		CHART AS c WITH (NOLOCK)
				  WHERE		c.APPROVED_DATE BETWEEN @BookmarkDT AND @BillEndDTFrom
							AND c.CHART_STATUS_ID IN (4, 5)
							AND NOT EXISTS (SELECT	1
											FROM	BILLED_CHART b
											WHERE	c.CHART_ID = b.CHART_ID
													AND b.TYPE_CD = 'C')
				  )
		SELECT	CHART_ID
			  , COMPLETED_BY_USER_PROFILE_ID
			  , APPROVED_BY_USER_PROFILE_ID
			  , c.SERVICE_AGREEMENT_ID
			  , sa.BILL_CODER_METHOD_CD
		INTO	#C
		FROM	CHART							 c WITH (NOLOCK)
				INNER JOIN dbo.SERVICE_AGREEMENT sa WITH (NOLOCK)
					ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE	EXISTS (SELECT 1  FROM c  x WHERE x	 .CHART_ID = c.CHART_ID)
				AND DEMO_TEST_SITE_IND <> 1;

		-- Break up the UNIONs so they insert into separate temp tables, thereby reducing the chance (and duration) of any potential blocking.
		-- Results are unioned together at the end (from the temp tables) to ensure no duplicates.
		SELECT	*
		INTO	#BilledChart1
		FROM	(
				-- Pay First Coder
				SELECT	c.CHART_ID	-- Coder
					  , 'C'							AS TYPE_CD
					  , ln.CREATING_USER_PROFILE_ID AS CODER_USER_ID
				FROM	LOG_NOTE ln WITH (NOLOCK)
					  , #C c
					  , USER_PROFILE up WITH (NOLOCK)

						-- For some reason, not joining to either service_agreement or billing_control on this first query explodes LReads on Log_Note to 600K vs. 80K (at least on RCMSQL02\ACSDW01).
						-- Joining to BOTH of these tables reduces LReads even more on Log_Note (50K vs 80K).  This is the only query exhibiting that behavior.
					  , SERVICE_AGREEMENT sa WITH (NOLOCK)
					  , BILLING_CONTROL bctl WITH (NOLOCK)
				WHERE	ln.LOG_NOTE_ID = (SELECT	MIN(ln2.LOG_NOTE_ID)	-- Pick up user ID from first complete event in log_note
										  FROM		LOG_NOTE ln2 WITH (NOLOCK)
												  , USER_PROFILE upr WITH (NOLOCK)
										  WHERE		ln2.CHART_ID = c.CHART_ID
													AND ln2.CATEGORY_ID = 2
													AND ln2.COMPLETED_BY_USER_ID = upr.USER_PROFILE_ID
													AND upr.USER_CLASS_CD = 2)
						AND c.CHART_ID = ln.CHART_ID
						AND sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						AND sa.DEMO_TEST_SITE_IND <> 1 -- Ignore Demo sites
						AND sa.BILL_CODER_METHOD_CD = 1 -- Pay first coder
						AND bctl.STATUS_CD = 'A'
						AND bctl.END_DATE <= DATEADD(d, 30, sa.EXPIRATION_DATE)
						AND up.USER_PROFILE_ID = ln.CREATING_USER_PROFILE_ID
						AND up.USER_CLASS_CD = 2	-- Contractor
		) AS t;

		SELECT	*
		INTO	#BilledChart2
		FROM	(
				-- Pay First Auditor
				SELECT	c.CHART_ID	-- Auditor
					  , 'A'							AS TYPE_CD
					  , ln.CREATING_USER_PROFILE_ID AS CODER_USER_ID
				FROM	LOG_NOTE ln WITH (NOLOCK)
					  , #A c
					  , USER_PROFILE up WITH (NOLOCK)
				WHERE	ln.LOG_NOTE_ID = (SELECT	MIN(ln2.LOG_NOTE_ID)	-- Pick up user ID from first approved event in log_note
										  FROM		LOG_NOTE ln2 WITH (NOLOCK)
												  , USER_PROFILE upr WITH (NOLOCK)
										  WHERE		ln2.CHART_ID = ln.CHART_ID
													AND ln2.CATEGORY_ID = 3
													AND ln2.COMPLETED_BY_USER_ID = upr.USER_PROFILE_ID
													AND upr.USER_CLASS_CD = 2)
						AND ln.COMPLETED_BY_USER_ID NOT IN (SELECT	ln2.COMPLETED_BY_USER_ID	-- Dismiss any approval where approving user is same as completing user
															FROM	LOG_NOTE ln2 WITH (NOLOCK)
															WHERE	ln2.LOG_NOTE_ID = (SELECT	MIN(ln3.LOG_NOTE_ID)
																					   FROM		LOG_NOTE ln3 WITH (NOLOCK)
																							  , USER_PROFILE upr WITH (NOLOCK)
																					   WHERE	ln3.CHART_ID = ln.CHART_ID
																								AND ln3.CATEGORY_ID = 2
																								AND ln3.COMPLETED_BY_USER_ID = upr.USER_PROFILE_ID
																								AND upr.USER_CLASS_CD = 2))
						AND c.CHART_ID = ln.CHART_ID
						AND c.Bill_Coder_Method_CD = 1 -- Pay first coder
						AND ln.CHART_ID NOT IN (SELECT	bc.CHART_ID
												FROM	BILLED_CHART bc WITH (NOLOCK)	-- Not previously paid as coder
												WHERE	bc.TYPE_CD IN ('C')
														AND bc.CODER_USER_ID = ln.CREATING_USER_PROFILE_ID)
						AND up.USER_PROFILE_ID = ln.CREATING_USER_PROFILE_ID
						AND up.USER_CLASS_CD = 2	-- Contractor
		) AS t;

		SELECT	*
		INTO	#BilledChart3
		FROM	(
				-- Pay Last Coder
				SELECT	c.CHART_ID
					  , 'C'							   AS TYPE_CD		-- Coder
					  , c.COMPLETED_BY_USER_PROFILE_ID AS CODER_USER_ID -- Most recent completion user 
				FROM	#C c
					  , USER_PROFILE up WITH (NOLOCK)
				WHERE	c.Bill_Coder_Method_CD = 2 -- Pay last coder
						AND c.COMPLETED_BY_USER_PROFILE_ID <> -1
						AND up.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
						AND up.USER_CLASS_CD = 2	-- Contractor
		) AS t;

		SELECT	*
		INTO	#BilledChart4
		FROM	(
				-- Pay Last Auditor
				SELECT	c.CHART_ID
					  , 'A'							  AS TYPE_CD	-- Auditor
					  , c.APPROVED_BY_USER_PROFILE_ID AS CODER_USER_ID
				FROM	#A c
					  , USER_PROFILE up WITH (NOLOCK)
				WHERE	c.Bill_Coder_Method_CD = 2
						AND c.COMPLETED_BY_USER_PROFILE_ID <> c.APPROVED_BY_USER_PROFILE_ID
						AND c.CHART_ID NOT IN (SELECT	bc.CHART_ID
											   FROM		BILLED_CHART bc WITH (NOLOCK)	-- Not previously paid as coder
											   WHERE	bc.CHART_ID = c.CHART_ID
														AND bc.TYPE_CD IN ('C')
														AND bc.CODER_USER_ID = c.APPROVED_BY_USER_PROFILE_ID)
						AND c.APPROVED_BY_USER_PROFILE_ID <> -1
						AND up.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
						AND up.USER_CLASS_CD = 2	-- Contractor
		) AS t;
		 
				 
		SELECT	c.CHART_ID
			  , 'B' AS TYPE_CD	-- Invoice Item
			  , 80	AS CODER_USER_ID
		INTO	#BilledChart5
		FROM	CHART						 c WITH (NOLOCK)
				INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK)
					ON c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		WHERE	c.SENT_DATE >= @BookmarkDT -- use Max(Creation_Date) from Billed_Chart as a bookmark
				AND DEMO_TEST_SITE_IND <> 1
				AND c.CHART_STATUS_ID IN (3, 4, 5)
				AND NOT EXISTS (SELECT	1
								FROM	BILLED_CHART b WITH (NOLOCK)
								WHERE	b.CHART_ID = c.CHART_ID
										AND b.TYPE_CD = 'B')
				AND (sa.BILL_ONLY_ACTIVE_PROCEDURES_IND <> 1 -- Bill all processed charts
					 OR c.CHART_ID IN (SELECT	sp.chart_id
									   FROM		SENT_PROCEDURE sp WITH (NOLOCK))) --~~~~~~~NEED TO DO!!!!!!
				AND ((sa.BILL_SELECTION_METHOD_CD = 1 -- Sent prior to period end
					  AND	c.CHART_STATUS_ID = 5 -- Sent
					  AND	ISNULL(c.SENT_DATE, c.CREATION_DATE_TIME) <= @BillEndDTFrom)
					 OR (sa.BILL_SELECTION_METHOD_CD = 2 -- Date of Service prior to period end and coded, approved or sent
						 AND c.CHART_STATUS_ID IN (3, 4, 5) -- Approved or Sent
						 AND c.TIME_OF_SERVICE <= @BillEndDTFrom)
					 OR (sa.BILL_SELECTION_METHOD_CD = 3 -- Discharged and Sent prior to period end
						 AND c.CHART_STATUS_ID IN (5) -- Sent
						 AND c.TIME_OF_DIS <= @BillEndDTFrom));
									 
    INSERT INTO Billed_Chart (CHART_ID
                            , TYPE_CD
                            , CODER_USER_ID
                            , DATE_BILLED
                            , BILLING_CONTROL_ID
                            , CREATION_DATE)
                SELECT	CHART_ID
			  , TYPE_CD
			  , CODER_USER_ID
			  , @DateBilled					Date_Billed
			  , @BillingControlID			Billing_Control_ID
			  , CAST(GETDATE() AS datetime) Creation_Date
		FROM	(SELECT *
				 FROM	#BilledChart1
				 UNION
				 SELECT *
				 FROM	#BilledChart2
				 UNION
				 SELECT *
				 FROM	#BilledChart3
				 UNION
				 SELECT *
				 FROM	#BilledChart4
				 UNION
				 SELECT *
				 FROM	#BilledChart5) AS t
		WHERE	NOT EXISTS (SELECT	1
							FROM	BILLED_CHART bc WITH (NOLOCK)	-- Ignore if previously invoiced
							WHERE	bc.CHART_ID = t.CHART_ID
									AND bc.TYPE_CD = t.TYPE_CD);
	END;
GO
