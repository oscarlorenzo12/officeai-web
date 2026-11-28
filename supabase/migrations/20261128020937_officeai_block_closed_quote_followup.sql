CREATE OR REPLACE FUNCTION public.officeai_record_quote_followup(p_quote uuid, p_channel text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare q public.officeai_quotes%rowtype; rid uuid; begin select * into q from public.officeai_quotes where id=p_quote for update; if not found or auth.uid() is null or not exists(select 1 from public.organization_members where organization_id=q.organization_id and user_id=auth.uid() and role in ('owner','admin')) then raise exception 'Presupuesto no accesible'; end if; if q.status<>'approved' or q.customer_accepted_at is not null or q.followup_closed_at is not null then raise exception 'Seguimiento no aplicable'; end if; if exists(select 1 from public.officeai_quote_followups where quote_id=q.id and recorded_at>now()-interval '24 hours') then raise exception 'Ya existe un seguimiento registrado en las últimas 24 horas'; end if; insert into public.officeai_quote_followups(quote_id,recorded_by,channel) values(q.id,auth.uid(),p_channel) returning id into rid; return rid; end $function$

