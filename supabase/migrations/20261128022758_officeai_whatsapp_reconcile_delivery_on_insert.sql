CREATE FUNCTION public.officeai_whatsapp_reconcile_delivery_on_insert() RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE e record;
BEGIN
IF NEW.direction<>'outbound' THEN RETURN NEW; END IF;
FOR e IN SELECT d.* FROM public.officeai_whatsapp_delivery_events d JOIN public.officeai_whatsapp_channels c ON c.meta_phone_number_id=d.phone_id WHERE c.service_instance_id=NEW.service_instance_id AND c.organization_id=NEW.organization_id AND d.message_id=NEW.meta_message_id ORDER BY d.event_at LOOP
PERFORM public.officeai_whatsapp_apply_delivery_status(e.phone_id,e.message_id,e.status,e.event_at);
END LOOP;
RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.officeai_whatsapp_reconcile_delivery_on_insert() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.officeai_whatsapp_reconcile_delivery_on_insert() TO service_role;
CREATE TRIGGER officeai_whatsapp_reconcile_delivery AFTER INSERT ON public.officeai_whatsapp_messages FOR EACH ROW EXECUTE FUNCTION public.officeai_whatsapp_reconcile_delivery_on_insert();
