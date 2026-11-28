CREATE FUNCTION public.officeai_guard_reservation_closures() RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE d integer; starts timestamp; ends timestamp;
BEGIN
IF NEW.status IS DISTINCT FROM 'resolved' OR NEW.reservation_date IS NULL THEN RETURN NEW; END IF;
IF TG_OP='UPDATE' THEN
IF OLD.status='resolved' AND ROW(OLD.service_instance_id,OLD.organization_id,OLD.reservation_date,OLD.reservation_time) IS NOT DISTINCT FROM ROW(NEW.service_instance_id,NEW.organization_id,NEW.reservation_date,NEW.reservation_time) THEN RETURN NEW; END IF;
END IF;
SELECT reservation_duration_minutes INTO d FROM public.service_instances WHERE id=NEW.service_instance_id AND organization_id=NEW.organization_id;
starts:=NEW.reservation_date+coalesce(NEW.reservation_time,time '00:00');
ends:=starts+make_interval(mins=>coalesce(d,1));
IF EXISTS(SELECT 1 FROM public.officeai_reservation_closures c WHERE c.service_instance_id=NEW.service_instance_id AND starts<(c.closed_until+1)::timestamp AND ends>c.closed_from::timestamp) THEN RAISE EXCEPTION 'Reserva durante un cierre programado'; END IF;
RETURN NEW;
END; $$;
CREATE TRIGGER officeai_guard_reservation_closures BEFORE INSERT OR UPDATE ON public.service_intake_requests FOR EACH ROW EXECUTE FUNCTION public.officeai_guard_reservation_closures();
