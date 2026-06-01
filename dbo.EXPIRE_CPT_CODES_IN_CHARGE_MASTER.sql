SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[EXPIRE_CPT_CODES_IN_CHARGE_MASTER]
WITH EXEC AS CALLER
AS


declare @sa_id int;
select distinct sa.SERVICE_AGREEMENT_ID 
	INTO #TempServiceAgreements	
	from Service_Agreement sa, Charge_Master cm 
	where sa.expiration_date > GetDate()
	and   sa.service_agreement_id = cm.service_agreement_id
	and   cm.cpt_code in ('99143','99144','99145','99148','99149','99150')
	and   cm.expiration_date > GetDate()

select @sa_id = service_agreement_id from #TempServiceAgreements
while @@rowcount <> 0
begin
	update charge_master 
	set expiration_date = '2016-12-31',
		CHANGING_USER_PROFILE_ID = 1164,
		CHANGED_DATE_TIME = GetDate()
		where service_agreement_id = @sa_id
		and   expiration_date > GetDate()		
		and   cpt_code in ('99143','99144','99145','99148','99149','99150')
    	
    delete from #TempServiceAgreements where service_agreement_id = @sa_id

    select @sa_id = service_agreement_id from #TempServiceAgreements
end
GO
