CREATE OR REPLACE FUNCTION public.officeai_prepare_lead_quote(p_lead_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE l public.officeai_inbound_leads%ROWTYPE; s public.service_catalog%ROWTYPE; rid uuid; qid uuid;
BEGIN
SELECT * INTO l FROM public.officeai_inbound_leads WHERE id=p_lead_id FOR UPDATE;
IF NOT FOUND OR auth.uid() IS NULL OR NOT EXISTS (SELECT 1 FROM public.organization_members m WHERE m.organization_id=l.organization_id AND m.user_id=auth.uid() AND m.role IN ('owner','admin')) THEN RAISE EXCEPTION 'Contacto no disponible'; END IF;
IF l.status = 'closed' THEN RAISE EXCEPTION 'Contacto cerrado'; END IF;
SELECT q.id INTO qid FROM public.officeai_quotes q JOIN public.officeai_requests r ON r.id=q.request_id AND r.organization_id=q.organization_id WHERE r.lead_id=l.id AND r.organization_id=l.organization_id;
IF FOUND THEN RETURN qid; END IF;
SELECT * INTO s FROM public.service_catalog WHERE organization_id=l.organization_id AND code=l.service_code AND status='active';
IF NOT FOUND THEN RAISE EXCEPTION 'Requiere valoración manual'; END IF;
INSERT INTO public.officeai_requests(organization_id,lead_id,created_by,kind,customer_name,customer_contact,details,status) VALUES(l.organization_id,l.id,auth.uid(),'quote',l.company_name,l.contact_email,left(s.name||' · '||l.details,2000),'pending') ON CONFLICT(lead_id) DO NOTHING RETURNING id INTO rid;
IF rid IS NULL THEN SELECT id INTO rid FROM public.officeai_requests WHERE lead_id=l.id AND organization_id=l.organization_id; END IF;
SELECT id INTO qid FROM public.officeai_quotes WHERE request_id=rid AND organization_id=l.organization_id;
IF qid IS NULL THEN RAISE EXCEPTION 'No se pudo preparar el presupuesto'; END IF;
RETURN qid;
END $function$;
