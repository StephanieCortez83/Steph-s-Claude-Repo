SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Laura Hotalling
-- Create date: 04/10/2013
-- Description:	Returns hourly RVU data for client specified.
-- =============================================
CREATE PROCEDURE [dbo].[REPORT_Average_RVUs_per_Visit_by_Time_of_Day]
	@ClientFacilityID int,
	@ProviderID int,
	@StartDate datetime,
	@EndDate datetime

AS
BEGIN
	declare @_ClientFacilityID int = @ClientFacilityID
	declare @_ProviderID int = @ProviderID
	declare @_StartDate datetime = @StartDate
	declare @_EndDate datetime = @EndDate;

	WITH HourlyRVU
	AS (
		  SELECT COUNT([facility_chart_id]) 'PatientCount'
	  		  ,DATEPART(weekday, [time_of_service]) 'Day'
	  		  ,DATEPART(hour, [time_of_service]) 'Hour'
	  		  ,SUM(TotalWorkRVU) 'TotalWorkRVU'
		  FROM (
	  		  SELECT sp.[facility_chart_id]
	  	  		  ,sp.[time_of_service]
	  	  		  ,SUM(rvu.WORK_RVU * sp.quantity) 'TotalWorkRVU'
	  		  FROM [dbo].[SENT_PROCEDURE] sp WITH (NOLOCK)
	  	  		  ,CMS_PHYSICIAN_RVU rvu WITH (NOLOCK)
	  		  WHERE rvu.HCPCS = sp.cpt_code
	  	  		  AND sp.[service_agreement_id] = (SELECT SERVICE_AGREEMENT_ID FROM SERVICE_AGREEMENT WHERE FACILITY_ID = @_ClientFacilityID)
	  	  		  AND convert(VARCHAR, sp.[time_of_service], 112) BETWEEN convert(VARCHAR, @_StartDate, 112) AND convert(VARCHAR, @_EndDate, 112)
	  	  		  AND convert(VARCHAR, rvu.EFFECTIVE_DT, 112) <= convert(VARCHAR, getdate(), 112)
	  	  		  AND convert(VARCHAR, rvu.EXPIRATION_DT, 112) > convert(VARCHAR, getdate(), 112)
				  AND (@_ProviderID = -1 or sp.[PHYSICIAN_ID] = @_ProviderID)
	  		  GROUP BY sp.[facility_chart_id]
	  	  		  ,sp.[time_of_service]
	  		  ) RawData
		  GROUP BY DATEPART(weekday, [time_of_service])
	  		  ,DATEPART(hour, [time_of_service])
		  )
	SELECT *
	FROM HourlyRVU

END

GO
