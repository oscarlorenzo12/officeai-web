CREATE FUNCTION public.officeai_public_reservation_check(p_instance uuid,p_date date,p_time time without time zone,p_guests integer) RETURNS text LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path='' AS $$
DECLARE s record; a timestamp; b timestamp; v record;
BEGIN
IF p_instance IS NULL OR p_date IS NULL OR p_time IS NULL OR p_guests IS NULL OR p_guests<1 OR p_guests>100000 OR p_date+p_time <= (now() AT TIME ZONE 'Europe/Madrid') THEN RETURN 'invalid'; END IF;
SELECT * INTO s FROM public.service_instances WHERE id=p_instance AND public_enabled AND privacy_notice_url IS NOT NULL;
IF NOT FOUND THEN RETURN 'unavailable'; END IF;
a:=p_date+p_time; b:=a+make_interval(mins=>coalesce(s.reservation_duration_minutes,1));
IF EXISTS(SELECT 1 FROM public.officeai_reservation_closures c WHERE c.service_instance_id=p_instance AND a<(c.closed_until+1)::timestamp AND b>c.closed_from::timestamp) THEN RETURN 'closed'; END IF;
IF s.reservation_duration_minutes IS NULL THEN RETURN 'manual'; END IF;
IF EXISTS(SELECT 1 FROM public.officeai_reservation_hours WHERE service_instance_id=p_instance) THEN
IF NOT EXISTS(SELECT 1 FROM public.officeai_reservation_hours h CROSS JOIN (VALUES(p_date),(p_date-1)) AS days(day) WHERE h.service_instance_id=p_instance AND h.weekday=extract(isodow FROM days.day) AND a>=days.day+h.opens_at AND b<=days.day+h.closes_at+CASE WHEN h.closes_at<h.opens_at THEN interval '1 day' ELSE interval '0 day' END) THEN RETURN 'outside_hours'; END IF;
ELSE RETURN 'manual'; END IF;
SELECT * INTO v FROM public.officeai_reservation_availability(p_instance,p_date,p_time);
IF NOT FOUND THEN RETURN 'manual'; END IF;
IF v.available_guests<p_guests THEN RETURN 'full'; END IF;
RETURN 'available';
END; $$;
REVOKE ALL ON FUNCTION public.officeai_public_reservation_check(uuid,date,time without time zone,integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.officeai_public_reservation_check(uuid,date,time without time zone,integer) TO service_role;
