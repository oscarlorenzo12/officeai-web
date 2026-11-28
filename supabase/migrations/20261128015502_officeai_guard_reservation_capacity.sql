CREATE FUNCTION public.officeai_guard_reservation_capacity() RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE v record;
BEGIN
 IF NEW.status IS DISTINCT FROM 'resolved' OR NEW.reservation_date IS NULL THEN RETURN NEW; END IF;
 IF TG_OP='UPDATE' THEN
 IF OLD.status='resolved' AND ROW(OLD.service_instance_id,OLD.organization_id,OLD.reservation_date,OLD.reservation_time,OLD.reservation_guests) IS NOT DISTINCT FROM ROW(NEW.service_instance_id,NEW.organization_id,NEW.reservation_date,NEW.reservation_time,NEW.reservation_guests) THEN RETURN NEW; END IF;
 IF OLD.status='resolved' THEN RAISE EXCEPTION 'Reabre la reserva antes de modificar su ocupación'; END IF;
 END IF;
 IF NEW.reservation_time IS NULL OR NEW.reservation_guests IS NULL OR NEW.reservation_guests<1 THEN RAISE EXCEPTION 'Datos de reserva incompletos'; END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(NEW.service_instance_id::text,0));
 SELECT * INTO v FROM public.officeai_reservation_availability(NEW.service_instance_id,NEW.reservation_date,NEW.reservation_time);
 IF FOUND AND v.available_guests<NEW.reservation_guests THEN RAISE EXCEPTION 'Capacidad insuficiente para aceptar la reserva'; END IF;
 RETURN NEW;
END; $$;
CREATE TRIGGER officeai_guard_reservation_capacity BEFORE INSERT OR UPDATE ON public.service_intake_requests FOR EACH ROW EXECUTE FUNCTION public.officeai_guard_reservation_capacity();
