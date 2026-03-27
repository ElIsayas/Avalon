# Avalon

Aplicacion Flutter para gestion psicologica orientada a Android.

## Estado actual

- Plataforma objetivo: Android.
- Modulos principales: Auth, Dashboard, Pacientes, Citas, Notas, Evaluaciones, Recordatorios, Usuarios, Pagos y SuperAdmin.
- Backend esperado: Supabase (RPC + Edge Functions).

## Requisitos

- Flutter 3.22+ (canal estable)
- Dart SDK 3.x
- Android Studio + SDK 34
- JDK 17

## Configuracion de entorno

Este proyecto usa variables por `--dart-define` para secretos:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Ejemplo:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tu_clave_anon
```

Tambien puedes usar `.env` para desarrollo local (ignorarlo en git).

## Instalacion y ejecucion (Android)

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d android
```

## Roles funcionales

- `superadmin`: gestion global de organizaciones, usuarios y pagos.
- `admin`: gestion de organizacion y usuarios.
- `psicologo`: flujo clinico completo.
- `secretaria`: operaciones asistidas segun permisos del backend.

## Backend requerido (Supabase)

RPCs minimos esperados:

- Auth: `login`, `validate_session`, `logout`, `get_user_id_from_token`
- Dashboard: `get_dashboard_stats`
- Pacientes: `get_pacientes`, `buscar_pacientes`, `crear_paciente`, `actualizar_paciente`, `eliminar_paciente`, `get_historia_clinica`, `actualizar_ficha_clinica`
- Citas: `get_citas`, `get_citas_hoy`, `get_citas_semana`, `crear_cita`, `actualizar_cita`, `verificar_conflicto_cita`, `get_auditoria_cita`
- Notas: `get_notas_paciente`, `crear_nota`, `actualizar_nota`, `firmar_nota`, `eliminar_nota`
- Evaluaciones: `get_evaluaciones`, `crear_evaluacion`, `eliminar_evaluacion`
- Recordatorios: `get_recordatorios`, `crear_recordatorio`, `resolver_recordatorio`, `eliminar_recordatorio`
- Usuarios/SuperAdmin: `get_psicologos_org` o `get_usuarios_org`, `sa_get_metricas`, `sa_get_organizaciones`, `sa_get_usuarios`, `sa_get_pagos`, `cambiar_plan`
- Pagos: `get_info_plan`, `get_historial_pagos`, Edge Function `crear-preferencia-mp`

## Estructura recomendada de secretos

- No hardcodear credenciales en codigo fuente.
- Guardar tokens de sesion en almacenamiento seguro (`flutter_secure_storage`).
- Mantener `key.properties` y keystores fuera del repositorio.
