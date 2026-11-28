CREATE FUNCTION public.officeai_whatsapp_apply_delivery_status(p_phone_id text,p_message_id text,p_status text,p_at timestamptz) RETURNS boolean LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE n integer;
BEGIN
IF p_status IS NULL OR p_status NOT IN ('sent','delivered','read','failed') OR p_at IS NULL THEN RETURN false; END IF;
UPDATE public.officeai_whatsapp_messages m SET delivery_status=p_status,delivery_status_at=p_at
FROM public.officeai_whatsapp_channels c WHERE c.meta_phone_number_id=p_phone_id AND c.service_instance_id=m.service_instance_id AND c.organization_id=m.organization_id AND m.meta_message_id=p_message_id AND m.direction='outbound'
AND (m.delivery_status IS NULL OR (CASE p_status WHEN 'read' THEN 4 WHEN 'delivered' THEN 3 WHEN 'failed' THEN 2 ELSE 1 END > CASE m.delivery_status WHEN 'read' THEN 4 WHEN 'delivered' THEN 3 WHEN 'failed' THEN 2 ELSE 1 END) OR (m.delivery_status=p_status AND p_at>m.delivery_status_at));
GET DIAGNOSTICS n=ROW_COUNT; RETURN n>0;
END $$;
REVOKE ALL ON FUNCTION public.officeai_whatsapp_apply_delivery_status(text,text,text,timestamptz) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.officeai_whatsapp_apply_delivery_status(text,text,text,timestamptz) TO service_role;
