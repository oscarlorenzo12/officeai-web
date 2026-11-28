CREATE OR REPLACE FUNCTION public.officeai_prepare_linked_invoice(p_draft uuid, p_instance uuid, p_number text)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE d record; result uuid;
BEGIN
SELECT b.id,b.net_eur,b.vat_rate,c.organization_id,c.service_name,c.service_instance_id INTO d FROM public.officeai_billing_drafts b LEFT JOIN public.officeai_monthly_payments p ON p.id=b.payment_id JOIN public.officeai_service_contracts c ON c.id=coalesce(b.setup_contract_id,p.contract_id) WHERE b.id=p_draft AND EXISTS(SELECT 1 FROM public.organization_members m WHERE m.organization_id=c.organization_id AND m.user_id=auth.uid() AND m.role='owner');
IF NOT FOUND THEN RAISE EXCEPTION 'Borrador no accesible'; END IF;
IF d.vat_rate IS NULL OR d.net_eur<0 OR d.net_eur*100>2147483647 THEN RAISE EXCEPTION 'Revisa base e IVA'; END IF;
IF p_number IS NULL OR length(btrim(p_number)) NOT BETWEEN 1 AND 60 THEN RAISE EXCEPTION 'Referencia obligatoria'; END IF;
IF d.service_instance_id IS NOT NULL AND d.service_instance_id IS DISTINCT FROM p_instance THEN RAISE EXCEPTION 'El establecimiento no coincide con el contrato'; END IF;
IF NOT EXISTS(SELECT 1 FROM public.service_instances s WHERE s.id=p_instance AND s.organization_id=d.organization_id) THEN RAISE EXCEPTION 'Establecimiento no accesible'; END IF;
INSERT INTO public.officeai_invoices(organization_id,service_instance_id,invoice_number,description,amount_cents,tax_percent,status,source_billing_draft_id) VALUES(d.organization_id,p_instance,btrim(p_number),left(d.service_name,500),round(d.net_eur*100)::integer,d.vat_rate,'draft',d.id) ON CONFLICT(source_billing_draft_id) DO NOTHING RETURNING id INTO result;
IF result IS NULL THEN SELECT id INTO result FROM public.officeai_invoices WHERE source_billing_draft_id=d.id AND organization_id=d.organization_id; END IF;
RETURN result; END $function$

