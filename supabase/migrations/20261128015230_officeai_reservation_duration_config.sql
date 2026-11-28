ALTER TABLE public.service_instances ADD COLUMN reservation_duration_minutes integer CHECK (reservation_duration_minutes BETWEEN 15 AND 720);
COMMENT ON COLUMN public.service_instances.reservation_duration_minutes IS 'Optional planned reservation duration in minutes; NULL means not configured.';
