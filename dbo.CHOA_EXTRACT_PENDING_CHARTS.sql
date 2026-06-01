SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Eric Fawks
-- Create date: 3/1/2017
-- Description:	CHOA - Extract Pending charts for Intermedix
-- =============================================
CREATE PROCEDURE [dbo].[CHOA_EXTRACT_PENDING_CHARTS]
WITH EXEC AS CALLER
AS
BEGIN
select	c.facility_chart_id as AccountNumber, 
		f.name as Location, 
		c.medical_record_num as MRN, 
		c.patient_last_name + ', ' + c.patient_first_name as PatientName, 
		c.time_of_service as DOS, 
		pr.description + ';  Coder Notes: ' + c.coder_comment as PendingReason, 
		c.changed_date_time as LastChanged, 
		fp1.last_name + ', ' + fp1.first_name as ED_Physician, 
		fp2.last_name + ', ' + fp2.first_name as ED_MLP
from	CHART c WITH (NOLOCK)
		INNER JOIN	facility f on c.facility_id = f.facility_id
		INNER JOIN	pending_reason pr on c.pending_reason_id = pr.pending_reason_id
		LEFT JOIN	facility_professional fp1 on fp1.facility_prof_id = c.physician_id
		LEFT JOIN	facility_professional fp2 on fp2.facility_prof_id = c.NURSE_PRACTITIONER_ID and fp2.ROLE_ID = 1
where	c.chart_status_id = 2
and		c.pending_reason_id in (2,3,8,12,16,18)
--and     c.facility_id in (276,277)
and		((c.facility_id = 277) or (c.facility_id = 276 and fp1.provider_business_unit_id = 76) or (c.facility_id = 276 and fp2.provider_business_unit_id = 76)) 
order by c.facility_id, c.chart_id	
END



GO
