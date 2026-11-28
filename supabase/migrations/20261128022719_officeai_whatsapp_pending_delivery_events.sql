CREATE TABLE public.officeai_whatsapp_delivery_events (
 phone_id text NOT NULL, message_id text NOT NULL, status text NOT NULL CHECK(status IN ('sent','delivered','read','failed')), event_at timestamptz NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(phone_id,message_id,status,event_at));
ALTER TABLE public.officeai_whatsapp_delivery_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.officeai_whatsapp_delivery_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,DELETE ON public.officeai_whatsapp_delivery_events TO service_role;
CREATE FUNCTION public.officeai_whatsapp_record_delivery_event(p_phone_id text,p_message_id text,p_status text,p_at timestamptz) RETURNS boolean LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM public.officeai_whatsapp_channels WHERE meta_phone_number_id=p_phone_id AND enabled) THEN RETURN false; END IF;
INSERT INTO public.officeai_whatsapp_delivery_events(phone_id,message_id,status,event_at) VALUES(p_phone_id,p_message_id,p_status,p_at) ON CONFLICT DO NOTHING;
RETURN public.officeai_whatsapp_apply_delivery_status(p_phone_id,p_message_id,p_status,p_at);
END $$;
REVOKE ALL ON FUNCTION public.officeai_whatsapp_record_delivery_event(text,text,text,timestamptz) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.officeai_whatsapp_record_delivery_event(text,text,text,timestamptz) TO service_role;
