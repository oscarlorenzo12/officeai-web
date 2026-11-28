CREATE FUNCTION public.officeai_reservation_availability(p_instance uuid,p_date date,p_time time without time zone) RETURNS TABLE(capacity integer,peak_guests bigint,available_guests bigint) LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
WITH cfg AS (SELECT id,organization_id,reservation_capacity AS cap,reservation_duration_minutes AS dur,p_date+p_time AS start_at FROM public.service_instances WHERE id=p_instance AND reservation_capacity IS NOT NULL AND reservation_duration_minutes IS NOT NULL),
intervals AS (SELECT greatest(r.reservation_date+r.reservation_time,c.start_at) AS a,least(r.reservation_date+r.reservation_time+make_interval(mins=>c.dur),c.start_at+make_interval(mins=>c.dur)) AS b,r.reservation_guests AS guests FROM cfg c JOIN public.service_intake_requests r ON r.service_instance_id=c.id AND r.organization_id=c.organization_id WHERE r.status='resolved' AND r.reservation_date BETWEEN p_date-1 AND p_date+1 AND r.reservation_guests>0 AND r.reservation_date+r.reservation_time<c.start_at+make_interval(mins=>c.dur) AND r.reservation_date+r.reservation_time+make_interval(mins=>c.dur)>c.start_at),
events AS (SELECT a AS t,guests::bigint AS delta FROM intervals UNION ALL SELECT b,-guests::bigint FROM intervals),
grouped AS (SELECT t,sum(delta) AS delta FROM events GROUP BY t),
running AS (SELECT sum(delta) OVER (ORDER BY t) AS occupancy FROM grouped),
peak AS (SELECT coalesce(max(occupancy),0)::bigint AS n FROM running)
SELECT c.cap,p.n,greatest(0,c.cap-p.n) FROM cfg c CROSS JOIN peak p;
$$;
REVOKE ALL ON FUNCTION public.officeai_reservation_availability(uuid,date,time without time zone) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.officeai_reservation_availability(uuid,date,time without time zone) TO authenticated;
