SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[BILLING_SUMMARY_BY_CODER_AND_FACILITY_TEMP] 
	-- Add the parameters for the stored procedure here
  @coder_user_profile_id int,
  @byear int,
  @bmonth int
AS
BEGIN

declare @billing_year int
declare @billing_month int

set @billing_year = @byear
set @billing_month = @bmonth

--if (select status_cd from BILLING_CONTROL	where BILLING_PERIOD_YEAR = @billing_year 
--											and   BILLING_PERIOD_MONTH = @billing_month) <> 'A'
											
--BEGIN
--select	up.LAST_NAME + ', ' + up.FIRST_NAME Name,
-- 		b1.BILLING_PERIOD_YEAR,
-- 		b1.BILLING_PERIOD_MONTH,
--		h.Coding_Charts "Coding Charts",
--		h.Approval_Charts "Approval Charts",
--		h.Coding_Charts + h.APPROVAL_CHARTS "Base Charts",
--		(round((h.CODING_CHARTS + h.APPROVAL_CHARTS) * h.rate,2))  "Base Fee",
--		0 "Bonus Charts",
--		0 "Bonus Fee",
--		(round((h.CODING_CHARTS + h.APPROVAL_CHARTS) * h.rate,2))  "Total Fee",
--		h.USER_PROFILE_ID,
--		h.PROCESS_DATE "Process Date",		 
--		f.FACILITY_NUMBER Facility,
--		f.NAME FacilityName,
--		h.Rate,
--		h.BILLING_CONTROL_ID,
--		h.SERVICE_AGREEMENT_ID
--FROM	CODER_BILLING_HISTORY h,
--		USER_PROFILE up,
--		FACILITY f,
--		SERVICE_AGREEMENT sa,
--		BILLING_CONTROL b1
--WHERE	B1.BILLING_PERIOD_MONTH = @billing_month and b1.BILLING_PERIOD_YEAR = @billing_year
--AND		b1.BILLING_CONTROL_ID = h.BILLING_CONTROL_ID
--AND		h.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
--AND		f.FACILITY_ID = sa.FACILITY_ID
--AND		up.USER_PROFILE_ID = @coder_user_profile_id
--AND		h.USER_PROFILE_ID = up.USER_PROFILE_ID						 

--END

--ELSE											

select up.LAST_NAME + ', ' + up.FIRST_NAME Name,
 			 w.BILLING_PERIOD_YEAR,
 			 w.BILLING_PERIOD_MONTH,
			 w.CCount "Coding Charts",
			 w.ACount "Approval Charts",
			 w.Charts "Base Charts",
			 w.Total  "Base Fee",
			 w.BonusCharts "Bonus Charts",
			 w.BonusTotal "Bonus Fee",
			 w.Total + w.BonusTotal "Total Fee",
			 w.USER_PROFILE_ID,
			 w.PDate "Process Date",		 
			 f.FACILITY_NUMBER Facility,
			 f.NAME FacilityName,
			 w.Rate,
			 w.BILLING_CONTROL_ID,
			 w.SERVICE_AGREEMENT_ID
from user_profile up, service_agreement sa, facility f,
(select v.USER_PROFILE_ID,
		v.BILLING_PERIOD_YEAR, v.BILLING_PERIOD_MONTH, v.BILLING_CONTROL_ID,
        v.service_agreement_id,
				v.pdate,
				v.rate,
			 sum(v.CCount) CCount,
			 sum(v.ACount) ACount,
 			 sum(v.Charts) Charts,
			 sum(v.Total) Total,
			 sum(v.BonusCharts) BonusCharts,
			 sum(v.BonusTotal) BonusTotal
from   
(select z.USER_PROFILE_ID,
			z.BILLING_PERIOD_YEAR,z.BILLING_PERIOD_MONTH, z.BILLING_CONTROL_ID,
 			 z.service_agreement_id,
			 z.pdate,
			 z.rate,
			 sum(z.CCount) CCount,
			 sum(z.ACount) ACount,
			 sum(z.total) Charts,
			 sum(round(z.total * z.rate,2)) Total,
			 0 BonusCharts,
			 0 BonusTotal
from (select y.service_agreement_id,
			 y.type_cd,
			 y.USER_PROFILE_ID,
			 y.BILLING_PERIOD_YEAR,y.BILLING_PERIOD_MONTH, y.BILLING_CONTROL_ID,
			 y.pdate,
			 y.Total,
			 y.CCount,
			 y.ACount,
			 y.CRate + y.ORate - y.DRate Rate
from (select x.service_agreement_id,
		   x.type_cd,
			 x.USER_PROFILE_ID,
			 x.BILLING_PERIOD_YEAR,x.BILLING_PERIOD_MONTH, x.BILLING_CONTROL_ID,
			 x.user_class_cd,
			 x.PDate,
			 (case when x.CRate is null then 0 else x.CRate end) CRate,
			 (case when x.DRate is null then 0 else x.DRate end) DRate,
			 (case when x.ORate is null then 0 else x.ORate end) ORate,
			 count(*) as 'Total',
			 sum(x.CCount) as CCount,
			 sum(x.ACount) as ACount
		 from (select c.SERVICE_AGREEMENT_ID,
		   convert(date, (case when bc.TYPE_CD = 'A' then c.APPROVED_DATE else c.COMPLETION_DATE end), 112) PDate,
			 bc.CHART_ID,
			 bc.TYPE_CD,
			 case when bc.TYPE_CD = 'C' then 1 else 0 end CCount,
			 case when bc.TYPE_CD = 'A' then 1 else 0 end ACount,
			 up.USER_PROFILE_ID,
			 bctl.BILLING_PERIOD_YEAR,bctl.BILLING_PERIOD_MONTH, bctl.BILLING_CONTROL_ID,
			 up.user_class_cd,
			 case when up.USER_CLASS_CD = 2 					
					then 
						case when c.PATIENT_DISPOSITION_ID = 5 
							AND c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID IN
								(SELECT sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID  from SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sap
									where sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD <> 1
									and sap.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
							AND sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1
						then 0
					else
						(select top 1 sar.RATE 
			 			from SERVICE_AGREEMENT_RATE sar
			 			where sar.RATE_CLASS_CD = 'C'
						and   sar.RATE_TYPE_CD = bc.TYPE_CD
						and	  case when sa.CONTRACTOR_RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
								when sa.CONTRACTOR_RATE_METHOD_CD = 2 then c.SENT_DATE
								else bctl.END_DATE end BETWEEN sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
						and   sar.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID) 
					end
			 else 0 end CRate,
			 case when up.USER_CLASS_CD = 2 and sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 and c.PATIENT_DISPOSITION_ID = 5 then 
				case when c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID IN
								(SELECT sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID  from SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sap
									where sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 2
									and sap.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
				then (select top 1 sar.RATE 
						from SERVICE_AGREEMENT_RATE sar
						where	sar.RATE_CLASS_CD = 'C' 
						and		sar.RATE_TYPE_CD = 'CO'
						and	  case	when sa.CONTRACTOR_RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
									when sa.CONTRACTOR_RATE_METHOD_CD = 2 then c.SENT_DATE
									else bctl.END_DATE end BETWEEN sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
						and   sar.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
				else
				(select top 1 sar.RATE 
			 		from SERVICE_AGREEMENT_RATE sar
			 		where sar.RATE_CLASS_CD = 'C'
			 		and    sar.RATE_TYPE_CD = case when sa.SERVICE_MODEL_CD = 'ASP' then '7'
			 			  else '7' end			 			  
					and	  case when sa.CONTRACTOR_RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
							when sa.CONTRACTOR_RATE_METHOD_CD = 2 then c.SENT_DATE
							else bctl.END_DATE end BETWEEN sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
					and   sar.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID) 
				end
			 else 0 end ORate,
			 case when up.USER_CLASS_CD = 2 and sa.PERFORM_DIAGNOSIS_CODING = 1 and c.NO_DIAGNOSIS_CODING = 1 then 
			 	(select top 1 sar.RATE
					from SERVICE_AGREEMENT_RATE sar
			 		where sar.RATE_CLASS_CD = 'C'
					and   sar.RATE_TYPE_CD = 'D'
					and	  case when sa.CONTRACTOR_RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
							when sa.CONTRACTOR_RATE_METHOD_CD = 2 then c.SENT_DATE
							else bctl.END_DATE end BETWEEN sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
					and   sar.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID) else 0 end DRate
		 from   billed_chart bc, chart c WITH (NOLOCK), billing_control bctl, service_agreement sa WITH (NOLOCK), user_profile up WITH (NOLOCK)
		 where  bctl.BILLING_PERIOD_MONTH = @billing_month  and bctl.BILLING_PERIOD_YEAR = @billing_year 
		 and	bctl.BILLING_CONTROL_ID = bc.BILLING_CONTROL_ID 
		 and    c.CHART_ID = bc.CHART_ID
		 and    sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		 and    up.USER_PROFILE_ID = bc.CODER_USER_ID
		 and    ((bc.TYPE_CD = 'C')
   		 or   (bc.TYPE_CD = 'A' 
	   			and sa.BILL_QA_IND <> 1
		 		and up.USER_CLASS_CD = 2)
	 		 or   (bc.TYPE_CD = 'A'
	   		and sa.BILL_QA_IND = 1
		 		and c.PATIENT_DISPOSITION_ID not in (4, 5)))
	UNION		 		
		select c.SERVICE_AGREEMENT_ID, 
		   convert(date,  c.OBSERVATION_COMPLETION_DTTM, 112) PDate,
			 bc.CHART_ID,
			 bc.TYPE_CD,
			 case when bc.TYPE_CD = 'C' then 1 else 0 end CCount,
			 0 ACount,
			 up.USER_PROFILE_ID,
			 bctl.BILLING_PERIOD_YEAR,bctl.BILLING_PERIOD_MONTH, bctl.BILLING_CONTROL_ID,
			 up.user_class_cd,
			 0 CRate,
			 case when up.USER_CLASS_CD = 2 and sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 and c.PATIENT_DISPOSITION_ID = 5 then 
				case when c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID IN
								(SELECT sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID  from SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sap
									where sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 2
									and sap.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
				then (select top 1 sar.RATE 
						from SERVICE_AGREEMENT_RATE sar
						where	sar.RATE_CLASS_CD = 'C' 
						and		sar.RATE_TYPE_CD = 'CO'
						and	  case	when sa.CONTRACTOR_RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
									when sa.CONTRACTOR_RATE_METHOD_CD = 2 then c.SENT_DATE
									else bctl.END_DATE end BETWEEN sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
						and   sar.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
				else
				(select top 1 sar.RATE 
			 		from SERVICE_AGREEMENT_RATE sar
			 		where sar.RATE_CLASS_CD = 'C'
			 		and    sar.RATE_TYPE_CD = case when sa.SERVICE_MODEL_CD = 'ASP' then '7'
			 			  else '7' end			 			  
					and	  case when sa.CONTRACTOR_RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
							when sa.CONTRACTOR_RATE_METHOD_CD = 2 then c.SENT_DATE
							else bctl.END_DATE end BETWEEN sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
					and   sar.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID) 
				end
			 else 0 end ORate,
			 0 DRate
		 from   billed_chart bc, chart c WITH (NOLOCK), billing_control bctl, service_agreement sa WITH (NOLOCK), user_profile up WITH (NOLOCK)
		 where  bctl.BILLING_PERIOD_MONTH = @bmonth  and bctl.BILLING_PERIOD_YEAR = @byear 
		 and	bctl.BILLING_CONTROL_ID = bc.BILLING_CONTROL_ID
		 and    bc.TYPE_CD = 'C'
		 and    c.CHART_ID = bc.CHART_ID
		 and    sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		 and    up.USER_PROFILE_ID = c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID
		 and	up.USER_PROFILE_ID <> bc.CODER_USER_ID
		 and	up.USER_CLASS_CD = 2
		 and	up.USER_PROFILE_ID = @coder_user_profile_id
		 and	c.PATIENT_DISPOSITION_ID = 5		 		
		) x
group by x.service_agreement_id,
			 x.TYPE_CD,
			 x.USER_PROFILE_ID,
			 x.BILLING_PERIOD_YEAR,x.BILLING_PERIOD_MONTH, x.BILLING_CONTROL_ID,
			 x.user_class_cd,
			 x.pdate,
			 x.CRate,
			 x.ORate,
			 x.DRate) y) z
group by z.USER_PROFILE_ID,z.BILLING_PERIOD_YEAR,z.BILLING_PERIOD_MONTH, z.BILLING_CONTROL_ID, z.service_agreement_id, z.PDate, z.Rate
union
select z.USER_PROFILE_ID,
z.BILLING_PERIOD_YEAR,z.BILLING_PERIOD_MONTH, z.BILLING_CONTROL_ID,
			 z.service_agreement_id,
			 z.pdate,
			 z.rate,
			 0 CCount,
			 0 ACount,
       0 Charts,
			 0 Total,
			 sum(z.Charts) BonusCharts,
			 sum(z.Total) BonusTotal
from 
(select y.USER_PROFILE_ID, 
y.BILLING_PERIOD_YEAR,y.BILLING_PERIOD_MONTH, y.BILLING_CONTROL_ID,
			 y.service_agreement_id, 
			 y.pdate, y.rate, y.total Charts, 
			 round(y.total * y.rate,2) Total 
from
(select x.USER_PROFILE_ID,
		x.BILLING_PERIOD_YEAR,x.BILLING_PERIOD_MONTH, x.BILLING_CONTROL_ID,
       x.service_agreement_id,
       x.pdate,
			 x.bonus_rate rate,
			 count(*) Total
from (
select up.USER_PROFILE_ID,
bcnt.BILLING_PERIOD_YEAR, bcnt.BILLING_PERIOD_MONTH, bcnt.BILLING_CONTROL_ID,
			 c.service_agreement_id,
			 convert(date, (case when bc.TYPE_CD = 'A' then c.APPROVED_DATE else c.COMPLETION_DATE end), 112) as PDate,
			 cb.BONUS_RATE
from   chart c WITH (NOLOCK), billed_chart bc, service_agreement sa WITH (NOLOCK), billing_control bcnt, user_profile up WITH (NOLOCK), contractor_bonus cb
where  bcnt.BILLING_PERIOD_MONTH = @billing_month  and bcnt.BILLING_PERIOD_YEAR = @billing_year  
and    bcnt.BILLING_CONTROL_ID = bc.BILLING_CONTROL_ID  
and	   c.CHART_ID = bc.CHART_ID
and    sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
and    sa.COMPANY_ID = 3
and    up.USER_PROFILE_ID = bc.CODER_USER_ID
and    up.USER_CLASS_CD = 2
and    cb.USER_PROFILE_ID = bc.CODER_USER_ID
and    bc.CODER_USER_ID in (select distinct zz.USER_PROFILE_ID
from (
select yy.USER_PROFILE_ID, yy.pdate, yy.total Charts, round(yy.total * yy.bonus_rate,2) Total 
from
(select xx.USER_PROFILE_ID,
       xx.pdate,
			 xx.bonus_rate,
			 count(*) Total
from (select up2.USER_PROFILE_ID,
			 bcnt.BILLING_PERIOD_YEAR, bcnt.BILLING_PERIOD_MONTH, bcnt.BILLING_CONTROL_ID,
			 convert(date, (case when bc2.TYPE_CD = 'A' then c2.APPROVED_DATE else c2.COMPLETION_DATE end), 112) as PDate,
			 cb2.BONUS_RATE
from   chart c2 WITH (NOLOCK), billed_chart bc2, service_agreement sa2 WITH (NOLOCK), billing_control bcnt2, user_profile up2 WITH (NOLOCK), contractor_bonus cb2 WITH (NOLOCK)
where  bcnt2.BILLING_PERIOD_MONTH = @billing_month  and bcnt2.BILLING_PERIOD_YEAR = @billing_year  
and    bcnt2.BILLING_CONTROL_ID = bc2.BILLING_CONTROL_ID
and	   c2.CHART_ID = bc2.CHART_ID 
and    sa2.SERVICE_AGREEMENT_ID = c2.SERVICE_AGREEMENT_ID
and    sa2.COMPANY_ID = 3
and    up2.USER_PROFILE_ID = bc2.CODER_USER_ID
and    up2.USER_CLASS_CD = 2
and    cb2.USER_PROFILE_ID = bc2.CODER_USER_ID) xx
group by xx.USER_PROFILE_ID, xx.BILLING_PERIOD_YEAR,xx.BILLING_PERIOD_MONTH, xx.BILLING_CONTROL_ID, xx.pdate, xx.bonus_rate) yy
where  yy.total >= 100
and    yy.pdate = (convert(date, (case when bc.TYPE_CD = 'A' then c.APPROVED_DATE else c.COMPLETION_DATE end), 112))) zz)) x
group by x.USER_PROFILE_ID,x.BILLING_PERIOD_YEAR,x.BILLING_PERIOD_MONTH, BILLING_CONTROL_ID,  x.service_agreement_id, x.pdate, x.bonus_rate) y) z
group by z.USER_PROFILE_ID, z.BILLING_PERIOD_YEAR,z.BILLING_PERIOD_MONTH, z.BILLING_CONTROL_ID,
				 z.service_agreement_id,
				 z.pdate, z.rate) v
group by v.USER_PROFILE_ID, v.BILLING_PERIOD_YEAR,v.BILLING_PERIOD_MONTH, v.BILLING_CONTROL_ID,
				 v.service_agreement_id,
				 v.pdate, v.rate) w				 
where  up.USER_PROFILE_ID = w.USER_PROFILE_ID
and		up.USER_PROFILE_ID = @coder_user_profile_id
and    sa.SERVICE_AGREEMENT_ID = w.service_agreement_id
and    f.FACILITY_ID = sa.FACILITY_ID

order by up.LAST_NAME, up.FIRST_NAME, f.FACILITY_NUMBER, w.pdate, w.rate


END





GO
