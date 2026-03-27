# Contexto Supabase de Avalon

Este archivo existe para que futuros chats o modelos tengan el contexto minimo necesario del backend de Avalon sin depender de la memoria de una conversacion anterior.

## Instruccion para futuros chats

Antes de proponer cambios relacionados con datos, autenticacion, RPCs, roles, RLS o integracion del backend, leer este archivo primero.

## Proyecto

- App: `Avalon`
- Stack app: `Flutter`
- Backend: `Supabase`
- Fecha de referencia de este contexto: `2026-03-22`

## Conexion Supabase

- `SUPABASE_URL`: `https://xovztnvrchdgpxnyebpr.supabase.co`
- `SUPABASE_ANON_KEY`: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhvdnp0bnZyY2hkZ3B4bnllYnByIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5Mjc1OTYsImV4cCI6MjA4ODUwMzU5Nn0.vepP0wFgTt6fiOdhzaZtL4DnN9Te1PDN9nVjD0SJ4tM`

## Nota de seguridad

- La app usa `anon key`, no `service_role`.
- No crear ni pedir `service_role` salvo que el usuario lo solicite explicitamente.
- Si este repositorio va a compartirse o subirse a git remoto, considerar mover la `anon key` fuera de este archivo y dejar solo la URL y las instrucciones de configuracion.

## Como se conecta la app

La aplicacion usa variables de entorno por `--dart-define`.

Ejemplo:

```bash
flutter run ^
  --dart-define=SUPABASE_URL=https://xovztnvrchdgpxnyebpr.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhvdnp0bnZyY2hkZ3B4bnllYnByIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5Mjc1OTYsImV4cCI6MjA4ODUwMzU5Nn0.vepP0wFgTt6fiOdhzaZtL4DnN9Te1PDN9nVjD0SJ4tM
```

## Archivos clave del proyecto

- `README.md`: documenta `SUPABASE_URL` y `SUPABASE_ANON_KEY`
- `lib/main.dart`: inicializa `Supabase.initialize(url, anonKey)`
- `lib/core/constants/app_constants.dart`: lee `SUPABASE_URL` y `SUPABASE_ANON_KEY` por `String.fromEnvironment`
- `lib/features/auth/data/auth_service.dart`: login por RPC propio y manejo de token de sesion
- `lib/core/supabase/supabase_client.dart`: acceso central al cliente de Supabase

## Autenticacion actual

La app no depende solo del flujo estandar de Supabase Auth. El login principal usa RPCs propias:

- `login`
- `validate_session`
- `logout`
- `get_user_id_from_token`

Detalles importantes:

- `signIn(email, password)` llama `rpc('login', params: { p_email, p_password })`
- El backend devuelve un `token` o `session_token`
- Ese token se guarda en almacenamiento seguro local (`flutter_secure_storage`)
- `getSessionUser()` llama `validate_session` con `p_token`
- `signOut()` llama `logout` con `p_token`

## Estado actual de credenciales de prueba

- El usuario no recuerda credenciales activas de prueba
- No crear usuarios por cuenta propia
- No asumir passwords
- Sin `email/password` validos no se pueden probar flujos autenticados completos desde la app

## Roles esperados

- `superadmin`
- `admin`
- `psicologo`
- `secretaria`

## Backend esperado por la app

RPCs minimos esperados segun el proyecto:

- Auth: `login`, `validate_session`, `logout`, `get_user_id_from_token`
- Dashboard: `get_dashboard_stats`
- Pacientes: `get_pacientes`, `buscar_pacientes`, `crear_paciente`, `actualizar_paciente`, `eliminar_paciente`, `get_historia_clinica`, `actualizar_ficha_clinica`
- Citas: `get_citas`, `get_citas_hoy`, `get_citas_semana`, `crear_cita`, `actualizar_cita`, `verificar_conflicto_cita`, `get_auditoria_cita`
- Notas: `get_notas_paciente`, `crear_nota`, `actualizar_nota`, `firmar_nota`, `eliminar_nota`
- Evaluaciones: `get_evaluaciones`, `crear_evaluacion`, `eliminar_evaluacion`
- Recordatorios: `get_recordatorios`, `crear_recordatorio`, `resolver_recordatorio`, `eliminar_recordatorio`
- Usuarios/SuperAdmin: `get_psicologos_org` o `get_usuarios_org`, `sa_get_metricas`, `sa_get_organizaciones`, `sa_get_usuarios`, `sa_get_pagos`, `cambiar_plan`
- Pagos: `get_info_plan`, `get_historial_pagos`
- Edge Function: `crear-preferencia-mp`

## Esquema de base de datos entregado por el usuario

Tablas principales reportadas:

- `usuarios`
- `organizaciones`
- `planes`
- `pagos`
- `payment_links`
- `historial_planes`
- `pacientes`
- `citas`
- `citas_auditoria`
- `evaluaciones`
- `notas_terapia`
- `notas_adjuntos`
- `recordatorios`
- `cola_notificaciones`
- `plantillas_notificacion`

## Relaciones funcionales relevantes

- `usuarios.organizacion_id -> organizaciones.id`
- `pacientes.creado_por -> usuarios.id`
- `pacientes.organizacion_id -> organizaciones.id`
- `citas.paciente_id -> pacientes.id`
- `citas.psicologo_id -> usuarios.id`
- `citas.organizacion_id -> organizaciones.id`
- `evaluaciones.paciente_id -> pacientes.id`
- `evaluaciones.psicologo_id -> usuarios.id`
- `evaluaciones.cita_id -> citas.id`
- `notas_terapia.paciente_id -> pacientes.id`
- `notas_terapia.psicologo_id -> usuarios.id`
- `notas_terapia.cita_id -> citas.id`
- `recordatorios.creado_por -> usuarios.id`
- `recordatorios.asignado_a -> usuarios.id`
- `recordatorios.organizacion_id -> organizaciones.id`

## Observaciones importantes del esquema

- La tabla `usuarios` guarda `password` y `session_token` directamente en la base.
- La tabla `usuarios` maneja `rol`, `organizacion_id`, `ultimo_login` y expiracion de sesion.
- Varias entidades usan borrado logico por `eliminado_en`.
- Hay trazabilidad de citas en `citas_auditoria`.
- `payment_links` y `pagos` sugieren integraciones con pasarelas externas.
- `cola_notificaciones` y `plantillas_notificacion` soportan recordatorios y mensajes.

## Riesgos y cuidado al trabajar sobre este backend

- No asumir que existe Supabase Auth tradicional para login principal.
- No reescribir autenticacion sin revisar antes los RPCs reales en Supabase.
- No asumir que todas las pantallas usan acceso directo a tablas; varias pueden depender de RPCs.
- Sin conocer RLS y funciones exactas, cualquier cambio de frontend que consuma datos debe validarse contra los nombres reales de columnas y contratos de RPC.

## Limitaciones conocidas de este contexto

- No se tienen credenciales validas de usuario final para entrar a la app.
- No se confirmaron las politicas RLS.
- No se confirmo la lista real de funciones SQL existentes en Supabase; solo la lista esperada por la app y el esquema de tablas compartido por el usuario.
- No se ha usado `service_role`, y no debe asumirse acceso administrativo total.

## Recomendacion para futuras sesiones

Si una tarea requiere depuracion profunda del backend o pruebas autenticadas, pedir al usuario uno de estos insumos:

- `email/password` de prueba
- export de funciones SQL o migraciones
- politicas RLS
- logs de Edge Functions

## Regla de trabajo para futuros chats

Usar este archivo como fuente base de contexto. Si la tarea depende de estructura exacta del backend, contrastar este archivo con el codigo actual del proyecto antes de modificar nada.
