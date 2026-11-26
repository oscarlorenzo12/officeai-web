# Lista de lanzamiento OfficeAI

No activar servicios públicos, enviar mensajes ni crear clientes ficticios para completar esta lista.

| Comprobación | Estado |
|---|---|
| Recepcionista público: acceso y aviso de privacidad | Pendiente de prueba HTTP |
| Bandeja privada: selección de empresa y cambio de estado | Pendiente de prueba en navegador |
| WhatsApp: recepción | Existe un mensaje entrante registrado |
| WhatsApp: envío y deduplicación | Pendiente de prueba autorizada |
| Contacto → solicitud → presupuesto → contrato | Pendiente de prueba integral |
| Mensualidades y borradores fiscales | Pendiente de prueba integral; no son facturas oficiales |
| Separación entre empresas con datos reales | Pendiente de validación |
| Interfaz móvil y escritorio | Pendiente de validación |

## Criterio de salida
Validar los flujos esenciales con autorización del propietario, sin gastos ni comunicaciones externas no autorizadas. Mantener aprobación humana de presupuestos, contratos y envíos. No presentar borradores fiscales como facturas oficiales.

## Avances consolidados — 26/11/2026
- Catálogo: cinco servicios activos, precios básico y profesional coinciden con ventas.html.
- Asistente gratuito: ocho pruebas de lógica superadas; HTTP autenticado pendiente.
- Privacidad: borrador interno PRIVACIDAD-LANZAMIENTO.md; datos del responsable pendientes.
- Captación: formulario oculto (83a4264056378564787a63592b93e28a917ad19d); Edge officeai-lead-intake v4 exige OFFICEAI_PUBLIC_LEADS_ENABLED=true. Confirmar configuración efectiva y HTTP antes de apertura.
- Presupuestos: desglose alta/mensualidad en base de datos y pantalla (381f0bbc9b3914d2543dc48c2c0dac4756348c77); conversión exige importes aprobados.
- Mensualidades: registro individual y masivo excluyen meses anteriores a activación. Prorrateo pendiente de decisión comercial.

## Pendientes de aceptación (no repetir auditorías anteriores)
1. Sesión real del propietario: probar navegación móvil y escritorio y asistente autenticado.
2. Validación integral autorizada de contacto, presupuesto, contrato y mensualidad; no crear clientes ficticios en producción.
3. Verificar aislamiento entre organizaciones con datos y autorización adecuados.
4. Completar privacidad y confirmar condiciones comerciales; mantener captación cerrada hasta autorización.
5. Prueba de WhatsApp saliente únicamente con autorización y destinatario de prueba controlado.

No considerar el lanzamiento aprobado por el mero hecho de tener código implementado. No emitir facturas fiscales desde los borradores.
