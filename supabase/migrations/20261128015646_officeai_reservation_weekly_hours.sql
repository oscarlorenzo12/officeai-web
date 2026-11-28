CREATE TABLE public.officeai_reservation_hours (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
service_instance_id uuid NOT NULL REFERENCES public.service_instances(id) ON DELETE CASCADE,
weekday smallint NOT NULL CHECK (weekday BETWEEN 1 AND 7),
opens_at time NOT NULL,
closes_at time NOT NULL,
CHECK (opens_at < closes_at),
UNIQUE(service_instance_id,weekday,opens_at,closes_at)
);
ALTER TABLE public.officeai_reservation_hours ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.officeai_reservation_hours FROM anon, PUBLIC;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.officeai_reservation_hours TO authenticated;
CREATE POLICY reservation_hours_read ON public.officeai_reservation_hours FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.service_instances s WHERE s.id=service_instance_id));
CREATE POLICY reservation_hours_manage ON public.officeai_reservation_hours FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.service_instances s JOIN public.organization_members m ON m.organization_id=s.organization_id WHERE s.id=service_instance_id AND m.user_id=(SELECT auth.uid()) AND m.role IN ('owner','admin'))) WITH CHECK (EXISTS (SELECT 1 FROM public.service_instances s JOIN public.organization_members m ON m.organization_id=s.organization_id WHERE s.id=service_instance_id AND m.user_id=(SELECT auth.uid()) AND m.role IN ('owner','admin')));
