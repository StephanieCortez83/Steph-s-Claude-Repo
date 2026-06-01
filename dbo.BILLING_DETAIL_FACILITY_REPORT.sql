SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[BILLING_DETAIL_FACILITY_REPORT]
@BillPD int,
@ClientFacility int
WITH RECOMPILE
AS
BEGIN

declare @P_BillPD int 
declare @P_ClientFacility int
set @P_BillPD = @BillPD
set @P_ClientFacility = @ClientFacility

SELECT c.facility_id
	  ,(SELECT [NAME] from [dbo].[FACILITY] WHERE [FACILITY_ID] = c.[FACILITY_ID]) 'Client Facility'
	  ,UPPER(RTRIM([PATIENT_FIRST_NAME] + ' ' + [PATIENT_MIDDLE_NAME]) + ' ' + RTRIM([PATIENT_LAST_NAME] + ' ' + [PATIENT_NAME_SUFFIX])) 'Patient Name'
	  ,c.FACILITY_CHART_ID		'Account'
	  ,c.MEDICAL_RECORD_NUM		'Medical Record No'
	  ,c.[TIME_OF_SERVICE]		'DOS'
	  ,c.[SENT_DATE]			'Date Sent'
	  ,isnull(sp_PP.CPTQty,0)	'PP CPTQty'
	  ,isnull(sp_FP.CPTQty,0)	'FP CPTQty'
	  ,isnull(sp_IP.CPTQty,0)	'IP CPTQty'
	  ,isnull(sp_FL.CPTQty,0)	'FL CPTQty'
	  ,isnull(sp_PL.CPTQty,0)	'PL CPTQty'
	  ,isnull(d.DCodeCount,0)	'Diagnoses'
FROM [dbo].[CHART] c WITH (NOLOCK) LEFT OUTER JOIN (SELECT [CHART_ID] ,COUNT([ICD9_CODE]) 'DCodeCount'
																 FROM [dbo].[CHART_DIAGNOSIS_CODE] WITH (NOLOCK)
																 GROUP BY CHART_ID) d
	ON c.chart_id = d.chart_id LEFT OUTER JOIN (SELECT sp.chart_id, [class] ,COUNT([cpt_code]) 'CPTCount', SUM([quantity]) 'CPTQty'
												FROM [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE] sp WITH (NOLOCK)
													 ,dbo.CHART c2 WITH (NOLOCK), dbo.BILLED_CHART bc2  WITH (NOLOCK)
												WHERE sp.facility_id IN (@P_ClientFacility) and [class]='PP'
												and   sp.chart_id = c2.CHART_ID
												and   c2.CHART_ID = bc2.CHART_ID
												and   bc2.BILLING_CONTROL_ID = @P_BillPD and bc2.TYPE_CD = 'B'
												GROUP BY sp.chart_id ,sp.facility_chart_id ,[class]) sp_PP

	ON c.chart_id = sp_PP.chart_id LEFT OUTER JOIN (SELECT sp.chart_id, [class] ,COUNT([cpt_code]) 'CPTCount', SUM([quantity]) 'CPTQty'
												FROM [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE sp WITH (NOLOCK)
													 ,dbo.CHART c2  WITH (NOLOCK), dbo.BILLED_CHART bc2 WITH (NOLOCK)
												WHERE sp.facility_id IN (@P_ClientFacility) and [class]='FP'
												and   sp.chart_id = c2.CHART_ID
												and   c2.CHART_ID = bc2.CHART_ID
												and   bc2.BILLING_CONTROL_ID = @P_BillPD and bc2.TYPE_CD = 'B'
												GROUP BY sp.chart_id ,sp.facility_chart_id ,[class]) sp_FP

	ON c.chart_id = sp_FP.chart_id LEFT OUTER JOIN (SELECT sp.[chart_id], [class] ,COUNT([cpt_code]) 'CPTCount', SUM([quantity]) 'CPTQty'
												FROM [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE] sp WITH (NOLOCK)
													 ,dbo.CHART c2  WITH (NOLOCK), dbo.BILLED_CHART bc2  WITH (NOLOCK)
												WHERE sp.facility_id IN (@P_ClientFacility) and [class]='IP'
												and   sp.chart_id = c2.CHART_ID
												and   c2.CHART_ID = bc2.CHART_ID
												and   bc2.BILLING_CONTROL_ID = @P_BillPD and bc2.TYPE_CD = 'B'
												GROUP BY sp.chart_id ,sp.facility_chart_id ,[class]) sp_IP

	ON c.chart_id = sp_IP.chart_id LEFT OUTER JOIN (SELECT sp.chart_id, [class] ,COUNT([cpt_code]) 'CPTCount', SUM([quantity]) 'CPTQty'
												FROM [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE] sp WITH (NOLOCK)
													 ,dbo.CHART c2  WITH (NOLOCK), dbo.BILLED_CHART bc2 WITH (NOLOCK)
												WHERE sp.facility_id IN (@P_ClientFacility) and [class]='FL'
												and   sp.chart_id = c2.CHART_ID
												and   c2.CHART_ID = bc2.CHART_ID
												and   bc2.BILLING_CONTROL_ID = @P_BillPD and bc2.TYPE_CD = 'B'
												GROUP BY sp.chart_id ,sp.facility_chart_id ,[class]) sp_FL

	ON c.chart_id = sp_FL.chart_id LEFT OUTER JOIN (SELECT sp.chart_id, [class] ,COUNT([cpt_code]) 'CPTCount', SUM([quantity]) 'CPTQty'
												FROM [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE] sp WITH (NOLOCK)
													 ,dbo.CHART c2 WITH (NOLOCK), dbo.BILLED_CHART bc2 WITH (NOLOCK)
												WHERE sp.facility_id IN (@P_ClientFacility) and [class]='PL'
												and   sp.chart_id = c2.CHART_ID
												and   c2.CHART_ID = bc2.CHART_ID
												and   bc2.BILLING_CONTROL_ID = @P_BillPD and bc2.TYPE_CD = 'B'
												GROUP BY sp.chart_id ,sp.facility_chart_id ,[class]) sp_PL
	ON c.chart_id = sp_PL.chart_id 

WHERE c.[facility_id] = @P_ClientFacility
	and c.CHART_ID IN (SELECT CHART_ID 
					   FROM [dbo].[BILLED_CHART] WITH (NOLOCK)
					   WHERE [BILLING_CONTROL_ID] = @P_BillPD
						and [TYPE_CD]='B')
ORDER BY c.[TIME_OF_SERVICE], PATIENT_LAST_NAME, PATIENT_FIRST_NAME
END
GO
GRANT EXECUTE ON  [dbo].[BILLING_DETAIL_FACILITY_REPORT] TO [dbx_ExecuteReportProcs]
GO
