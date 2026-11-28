CREATE FUNCTION public.officeai_guard_reservation_hours() RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE d integer; starts timestamp; ends timestamp;
BEGIN
IF NEW.status IS DISTINCT FROM 'resolved' OR NEW.reservation_date IS NULL THEN RETURN NEW; END IF;
IF TG_OP='UPDATE' THEN
IF OLD.status='resolved' AND ROW(OLD.service_instance_id,OLD.reservation_date,OLD.reservation_time) IS NOT DISTINCT FROM ROW(NEW.service_instance_id,NEW.reservation_date,NEW.reservation_time) THEN RETURN NEW; END IF;
END IF;
IF NOT EXISTS(SELECT 1 FROM public.officeai_reservation_hours WHERE service_instance_id=NEW.service_instance_id) THEN RETURN NEW; END IF;
SELECT reservation_duration_minutes INTO d FROM public.service_instances WHERE id=NEW.service_instance_id AND organization_id=NEW.organization_id;
IF d IS NULL OR NEW.reservation_time IS NULL THEN RAISE EXCEPTION 'Configura la duración y la hora de reserva'; END IF;
starts:=NEW.reservation_date+NEW.reservation_time; ends:=starts+make_interval(mins=>d);
IF NOT EXISTS(SELECT 1 FROM public.officeai_reservation_hours h CROSS JOIN (VALUES (NEW.reservation_date),(NEW.reservation_date-1)) AS days(day) WHERE h.service_instance_id=NEW.service_instance_id AND h.weekday=extract(isodow FROM days.day) AND starts>=days.day+h.opens_at AND ends<=days.day+h.closes_at+CASE WHEN h.closes_at<h.opens_at THEN interval '1 day' ELSE interval '0 day' END) THEN RAISE EXCEPTION 'Reserva fuera del horario configurado'; END IF;
RETURN NEW;
END; $$;
CREATE TRIGGER officeai_guard_reservation_hours BEFORE INSERT OR UPDATE ON public.service_intake_requests FOR EACH ROW EXECUTE FUNCTION public.officeai_guard_reservation_hours();
