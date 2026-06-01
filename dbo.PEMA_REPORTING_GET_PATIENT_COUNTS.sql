SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[PEMA_REPORTING_GET_PATIENT_COUNTS] 
		@BILLING_CONTROL_ID int,
		@PHYSICIAN_ID int, 
		@category varchar(50)
AS


SELECT case 
		when @category = '(4) Excluded FX Care'	then 

			(select count(distinct c.chart_id) 
			from	chart c, 
					sent_procedure sp,
					PEMA_REPORTING_BILLING_CONTROL bc,
					PEMA_REPORTING_BILLED_CHARTS pbc
			where	bc.PEMA_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID
			and		pbc.PEMA_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID
			and		pbc.CHART_ID = c.CHART_ID
			and		sp.chart_id = c.CHART_ID
			and		c.PHYSICIAN_ID = @PHYSICIAN_ID
			and		sp.cpt_code in (select cpe.CPT_CODE from CHOA_PEMA_CPT_EXCLUSION cpe where 				
							cpe.CPT_CODE = sp.cpt_code))
				
		
		when @category = '(3) MD w/ Suture Tech'	then
		
			(select COUNT(distinct c.chart_id) 
			from	chart c, 
					sent_procedure sp,
					PEMA_REPORTING_BILLING_CONTROL bc,
					PEMA_REPORTING_BILLED_CHARTS pbc,
					FACILITY_PROFESSIONAL fp,
					PROVIDER_BUSINESS_UNIT pb
			where	bc.PEMA_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID
			and		pbc.PEMA_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID
			and		pbc.CHART_ID = c.CHART_ID
			and		sp.chart_id = c.CHART_ID
			and		c.PHYSICIAN_ID = @PHYSICIAN_ID
			and		sp.PHYSICIAN_ID = fp.FACILITY_PROF_ID
			and		fp.PROVIDER_BUSINESS_UNIT_ID = pb.PROVIDER_BUSINESS_UNIT_ID
			and		pb.BUSINESS_UNIT_NAME like '%5c%'
			)
			
		when @category = '(2) MD w/ MLP' then
			(select COUNT(distinct c.chart_id) 
			from	chart c, 
					PEMA_REPORTING_BILLING_CONTROL bc,
					PEMA_REPORTING_BILLED_CHARTS pbc
			where	bc.PEMA_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID
			and		pbc.PEMA_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID
			and		pbc.CHART_ID = c.CHART_ID
			and		c.NURSE_PRACTITIONER_ID > 0			
			)
			
		when @category = '(1) MD Only'	then	
			(select COUNT(distinct c.chart_id) 
			from	chart c, 
					PEMA_REPORTING_BILLING_CONTROL bc,
					PEMA_REPORTING_BILLED_CHARTS pbc
			where	bc.PEMA_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID
			and		pbc.PEMA_REPORTING_BILLING_CONTROL_ID = @BILLING_CONTROL_ID
			and		pbc.CHART_ID = c.CHART_ID
			and		c.NURSE_PRACTITIONER_ID IS NULL
			)
		end
		

GO
