ALTER TABLE public.officeai_reservation_hours DROP CONSTRAINT officeai_reservation_hours_check, ADD CONSTRAINT officeai_reservation_hours_distinct_times CHECK (opens_at <> closes_at);
COMMENT ON COLUMN public.officeai_reservation_hours.closes_at IS 'If earlier than opens_at, closes on the following calendar day.';
