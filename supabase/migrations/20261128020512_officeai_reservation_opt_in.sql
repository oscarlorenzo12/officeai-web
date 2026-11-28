ALTER TABLE public.service_instances ADD COLUMN reservation_enabled boolean NOT NULL DEFAULT false;
UPDATE public.service_instances SET reservation_enabled=true WHERE id='4c4dad72-5589-428c-beee-5863e7b3edff'::uuid;
COMMENT ON COLUMN public.service_instances.reservation_enabled IS 'Explicit per-business opt-in for public reservation requests; does not activate public reception.';
