CREATE TABLE public.officeai_reservation_closures (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
service_instance_id uuid NOT NULL REFERENCES public.service_instances(id) ON DELETE CASCADE,
closed_from date NOT NULL,
closed_until date NOT NULL,
reason text CHECK (char_length(reason)<=250),
CHECK (closed_until>=closed_from),
UNIQUE(service_instance_id,closed_from,closed_until)
);
ALTER TABLE public.officeai_reservation_closures ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.officeai_reservation_closures FROM PUBLIC,anon;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.officeai_reservation_closures TO authenticated;
CREATE POLICY reservation_closures_read ON public.officeai_reservation_closures FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.service_instances s WHERE s.id=service_instance_id));
CREATE POLICY reservation_closures_manage ON public.officeai_reservation_closures FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.service_instances s JOIN public.organization_members m ON m.organization_id=s.organization_id WHERE s.id=service_instance_id AND m.user_id=(SELECT auth.uid()) AND m.role IN ('owner','admin'))) WITH CHECK (EXISTS (SELECT 1 FROM public.service_instances s JOIN public.organization_members m ON m.organization_id=s.organization_id WHERE s.id=service_instance_id AND m.user_id=(SELECT auth.uid()) AND m.role IN ('owner','admin')));
