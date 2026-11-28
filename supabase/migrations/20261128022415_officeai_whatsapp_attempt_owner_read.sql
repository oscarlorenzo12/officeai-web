ALTER TABLE public.officeai_whatsapp_send_attempts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.officeai_whatsapp_send_attempts FROM anon,authenticated;
GRANT SELECT ON public.officeai_whatsapp_send_attempts TO authenticated;
CREATE POLICY whatsapp_attempt_owner_read ON public.officeai_whatsapp_send_attempts FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.service_instances s JOIN public.organization_members m ON m.organization_id=s.organization_id WHERE s.id=officeai_whatsapp_send_attempts.service_instance_id AND m.user_id=(SELECT auth.uid()) AND m.role='owner'));
