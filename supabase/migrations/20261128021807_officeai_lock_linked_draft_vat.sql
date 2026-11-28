CREATE OR REPLACE FUNCTION public.officeai_revise_billing_vat(p_id uuid, p_vat numeric)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare result uuid; begin if auth.uid() is null or (p_vat is not null and (p_vat<0 or p_vat>100 or p_vat<>round(p_vat,2))) then raise exception 'Invalid VAT'; end if; update public.officeai_billing_drafts d set vat_rate=p_vat where d.id=p_id and not exists(select 1 from public.officeai_invoices i where i.source_billing_draft_id=d.id) and exists(select 1 from public.officeai_service_contracts c join public.organization_members m on m.organization_id=c.organization_id where m.user_id=auth.uid() and m.role='owner' and (c.id=d.setup_contract_id or exists(select 1 from public.officeai_monthly_payments p where p.id=d.payment_id and p.contract_id=c.id))) returning d.id into result; if result is null then raise exception 'Borrador no accesible o ya vinculado a una factura'; end if; return result; end; $function$

