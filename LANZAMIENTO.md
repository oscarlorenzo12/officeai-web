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

## Recuperación de contraseña — 26/11/2026
- Implementada en commit 4e3ba90738f29b95dcb0860181dcb7803a060d3d.
- El propietario confirma haber configurado la URL de redirección, recibido el correo, cambiado la contraseña y vuelto a iniciar sesión correctamente.
- Validación comunicada por el propietario, no ejecutada independientemente por el asistente.

## Piloto de reservas y aceptación — 26/11/2026
- Outra: horario cafetería 08:00 hasta cierre; cocina 13:00–15:45 y 20:00–23:45; reservas admitidas con confirmación humana.
- Campos estructurados y RPC de reservas instalados; API recepción v5 activa, piloto público desactivado.
- Formulario (3cd2d453c3a3da41ee82edec75f3108d63dc6696), bandeja (09eabc42041fcc172b63a88a114b38af6180b524), filtros (a37e96eb9f13a8b8f7bfc13012079b71dcb9dbe7), agenda (7658b4f97e5025b4738e12900ce81623a6502217).
- Verificado: RPC rechaza datos inválidos y servicio desactivado; ejecución anónima denegada. Cero reservas registradas en el piloto en la comprobación. No se ha probado el flujo positivo HTTP/navegador.
- Pendientes: dirección real, aviso de privacidad revisado, prueba autorizada de extremo a extremo, autorización de apertura. Agenda limitada a 100 filas; aceptación interna sin notificación automática ni control de aforo.
- El propietario comunicó funcionamiento del asistente autenticado; falta verificación independiente.
- Condiciones comerciales acordadas en CONDICIONES-COMERCIALES.md; revisión jurídica y fiscal pendiente. No publicar datos fiscales sin revisión.

## Aceptación de navegación por el propietario — 26/11/2026
El propietario confirma que cargan Presupuestos, Contratos, Finanzas, Facturación, Recepción y Usuarios. No repetir comprobaciones de carga. Esta aceptación no valida escrituras, operaciones integrales, aislamiento con datos ni todos los dispositivos. Pendientes: circuito comercial autorizado, WhatsApp saliente, revisión legal y autorización de apertura.
