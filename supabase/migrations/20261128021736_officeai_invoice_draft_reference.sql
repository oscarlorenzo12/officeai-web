ALTER TABLE public.officeai_invoices ADD COLUMN source_billing_draft_id uuid UNIQUE REFERENCES public.officeai_billing_drafts(id) ON DELETE RESTRICT;
CREATE FUNCTION public.officeai_guard_invoice_draft_reference() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$ BEGIN
IF TG_OP='UPDATE' THEN IF OLD.source_billing_draft_id IS NOT NULL AND NEW.source_billing_draft_id IS DISTINCT FROM OLD.source_billing_draft_id THEN RAISE EXCEPTION 'No se puede cambiar el borrador asociado'; END IF; END IF;
IF NEW.source_billing_draft_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.officeai_billing_drafts d LEFT JOIN public.officeai_monthly_payments p ON p.id=d.payment_id JOIN public.officeai_service_contracts c ON c.id=coalesce(d.setup_contract_id,p.contract_id) WHERE d.id=NEW.source_billing_draft_id AND c.organization_id=NEW.organization_id) THEN RAISE EXCEPTION 'Borrador no accesible para esta organización'; END IF;
RETURN NEW; END $$;
CREATE TRIGGER officeai_guard_invoice_draft_reference BEFORE INSERT OR UPDATE ON public.officeai_invoices FOR EACH ROW EXECUTE FUNCTION public.officeai_guard_invoice_draft_reference();
