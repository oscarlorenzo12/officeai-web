ALTER TABLE public.officeai_whatsapp_messages ADD COLUMN delivery_status text CHECK (delivery_status IN ('sent','delivered','read','failed')), ADD COLUMN delivery_status_at timestamptz;
ALTER TABLE public.officeai_whatsapp_messages ADD CONSTRAINT whatsapp_delivery_outbound_only CHECK (direction='outbound' OR (delivery_status IS NULL AND delivery_status_at IS NULL));
ALTER TABLE public.officeai_whatsapp_messages ADD CONSTRAINT whatsapp_delivery_timestamp_pair CHECK ((delivery_status IS NULL)=(delivery_status_at IS NULL));
