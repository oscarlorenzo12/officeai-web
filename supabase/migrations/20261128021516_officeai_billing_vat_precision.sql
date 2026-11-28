CREATE OR REPLACE FUNCTION public.officeai_prepare_billing_draft(p_payment uuid, p_vat numeric DEFAULT NULL::numeric)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare result uuid; begin if auth.uid() is null or (p_vat is not null and (p_vat<0 or p_vat>100 or p_vat<>round(p_vat,2))) then raise exception 'Invalid request'; end if; insert into public.officeai_billing_drafts(payment_id,net_eur,vat_rate,created_by) select p.id,p.amount_eur,p_vat,auth.uid() from public.officeai_monthly_payments p join public.officeai_service_contracts c on c.id=p.contract_id where p.id=p_payment and exists(select 1 from public.organization_members m where m.organization_id=c.organization_id and m.user_id=auth.uid() and m.role='owner') on conflict(payment_id) do nothing returning id into result; if result is null then select d.id into result from public.officeai_billing_drafts d join public.officeai_monthly_payments p on p.id=d.payment_id join public.officeai_service_contracts c on c.id=p.contract_id where p.id=p_payment and exists(select 1 from public.organization_members m where m.organization_id=c.organization_id and m.user_id=auth.uid() and m.role='owner'); end if; if result is null then raise exception 'Payment not accessible'; end if; return result; end; $function$

