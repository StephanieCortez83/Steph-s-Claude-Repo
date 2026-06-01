SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Don Hutton
-- Create date: 4/23/2018
-- Description:	SQL for the Physician Pending Chart Report - based on view VWInCompleteDocumentation
-- =============================================


CREATE PROCEDURE [dbo].[rpt_InCompleteDocumentation]
	-- Add the parameters for the stored procedure here
@Facility VARCHAR(MAX),
@Physician VARCHAR(MAX),
@ReportUser int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @m_Facility VARCHAR(MAX) = @Facility;
declare @m_Physician VARCHAR(MAX) = @Physician;
declare @m_ReportUser int = @ReportUser;





if object_id('TempDB..#Facility', 'U') is not null
begin
drop table #Facility
end;



select * 
into #Facility
from
(
select distinct sa.facility_id
from SERVICE_AGREEMENT sa  WITH (NOLOCK),								
FACILITY f  WITH (NOLOCK)								
where 								
f.facility_id = sa.facility_ID
and sa.DEMO_TEST_SITE_IND = 0								
and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE	
and EXISTS (								
		SELECT *						
		FROM FACILITY_USER_AUTHORIZATION  FUA WITH (NOLOCK),						
		USER_PROFILE UP	WITH (NOLOCK)					
		WHERE FUA.FACILITY_ID = f.FACILITY_ID						
		AND fua.user_profile_id = up.user_profile_id						
		AND UP.IS_ACTIVE = 'Y'						
		and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE						
		AND FUA.USER_PROFILE_ID = @m_ReportUser	
		)

		AND EXISTS (
				SELECT *
				FROM [dbo].SplitString(@m_Facility, ',')
				WHERE ITEMS = sa.FACILITY_ID				
				)						
)t1;



select x.facility_id, x.fname,
			 x.Facility_Chart_ID  'PatientID',
			 x.Medical_Record_Num  'MedRecID',
			 x.Received,
			 x.DOS,
			 x.Discharged,
			 x.Status,
			 X.Reason,
			 x.Physician,
			 x.Physician_ID PhysicianID,
       x.Coder_Comment
from (
select c.facility_id,  f.NAME fname,
			 c.FACILITY_CHART_ID,
			 c.MEDICAL_RECORD_NUM,
			 convert(varchar, c.DATE_RECEIVED, 110) 'Received',
			 convert(varchar, c.TIME_OF_SERVICE, 110) 'DOS',
			 convert(varchar, c.TIME_OF_DIS, 110) 'Discharged',
			 (select cs.DESCRIPTION from chart_status cs where cs.CHART_STATUS_ID = c.CHART_STATUS_ID) 'Status',
			 (select pr.DESCRIPTION from pending_reason pr where pr.PENDING_REASON_ID = c.PENDING_REASON_ID) 'Reason',
			 c.CODER_COMMENT,
			 (select rtrim(rtrim(rtrim(ltrim(fp.TITLE + ' ' + fp.FIRST_NAME)) + ' ' + fp.MIDDLE_NAME)	+ ' ' + fp.LAST_NAME)
			 from facility_professional fp WITH (NOLOCK)
			 where fp.FACILITY_PROF_ID = c.PHYSICIAN_ID) Physician,
			 c.PHYSICIAN_ID
from chart c WITH (NOLOCK), service_agreement sa WITH (NOLOCK), facility f WITH (NOLOCK)
where c.CHART_STATUS_ID = 2
and   c.pending_reason_id in (2, 3, 8)
and   c.PHYSICIAN_ID in (select fp.FACILITY_PROF_ID from facility_professional fp WITH (NOLOCK)
			where fp.FACILITY_PROF_ID = c.PHYSICIAN_ID)
and   c.FACILITY_ID <> 1
and   sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
and   sa.EXPIRATION_DATE >= getdate()
and   f.facility_id = c.facility_id
and   exists ( select * from #Facility where #Facility.facility_ID = c.facility_id)
and (exists ( select * from SplitString(@m_Physician, ',') where items = c.PHYSICIAN_ID )	
or   exists ( select * from SplitString(@m_Physician, ',') where -1 = items )  )	

) x


END






GO
GRANT EXECUTE ON  [dbo].[rpt_InCompleteDocumentation] TO [dbx_ExecuteReportProcs]
GO
