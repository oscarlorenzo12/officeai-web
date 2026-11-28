ALTER TABLE public.service_instances ADD COLUMN reservation_capacity integer CHECK (reservation_capacity BETWEEN 1 AND 100000);
COMMENT ON COLUMN public.service_instances.reservation_capacity IS 'Optional maximum simultaneous guests; NULL means capacity not configured. Does not itself enforce availability.';
