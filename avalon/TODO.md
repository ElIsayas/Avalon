# ⚕ AVALON — TODO.md
# Plan de Ediciones y Trabajo Pendiente · Android

> **Última actualización:** 2026-03-26  
> **Estado general:** App compilando e instalando en Android ✅ — Supabase conectado ✅  
> **Orden de ejecución:** Seguir numeración. Dentro de cada edición, respetar el orden de subtareas.

---

## Leyenda de estados

| Símbolo | Significado |
|---|---|
| `[ ]` | Pendiente |
| `[x]` | Completado |
| `[~]` | En progreso |
| `[!]` | Bloqueado — requiere acción externa (Supabase, etc.) |

---

---

# EDICIONES INMEDIATAS
> Errores visuales y bugs confirmados en el dispositivo Android real.

---

## EDICIÓN 1 — Botón duplicado en Notas

**Prioridad:** 🔴 Alta  
**Archivo:** `lib/features/notas/presentation/screens/notas_screen.dart`  
**Problema:** Aparecen 2 botones "Nueva nota" simultáneamente — uno en el widget `_Empty` y otro como `FloatingActionButton`.

### Tareas

- [ ] **1.1** En `notas_screen.dart`, localizar el widget `_Empty` al final del archivo
- [ ] **1.2** Eliminar el bloque completo `if (!hayFiltro && onCrear != null)` que contiene el `ElevatedButton.icon` de "+ Nueva nota" dentro de `_Empty`
- [ ] **1.3** El `FloatingActionButton.extended` del `Scaffold` permanece intacto — es el único botón que debe existir

**Resultado esperado del widget `_Empty` después del fix:**
```dart
class _Empty extends StatelessWidget {
  final bool hayFiltro;
  final VoidCallback? onCrear;

  const _Empty({required this.hayFiltro, this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hayFiltro ? Icons.search_off : Iconsax.note,
            size: 72.sp,
            color: AppTheme.textGrey.withValues(alpha: 0.35),
          ),
          SizedBox(height: 16.h),
          Text(
            hayFiltro ? 'Sin resultados' : context.t.sinNotas,
            style: GoogleFonts.inter(fontSize: 18.sp, color: AppTheme.textGrey),
          ),
          SizedBox(height: 8.h),
          Text(
            hayFiltro
                ? 'Intenta con otro filtro o búsqueda'
                : context.t.crearNota,
            style: GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.textGrey),
          ),
          // SIN botón aquí — el FAB del Scaffold lo maneja
        ],
      ),
    );
  }
}
```

---

## EDICIÓN 2 — Botón duplicado en Evaluaciones

**Prioridad:** 🔴 Alta  
**Archivo:** `lib/features/evaluaciones/presentation/screens/evaluaciones_screen.dart`  
**Problema:** Aparecen 2 botones "Nueva evaluación" simultáneamente — uno en `_Empty` y otro como `FloatingActionButton`.

### Tareas

- [ ] **2.1** En `evaluaciones_screen.dart`, localizar el widget `_Empty` al final del archivo
- [ ] **2.2** Eliminar el bloque `if (puedeCrear)` que contiene el `ElevatedButton.icon` de "Nueva evaluación" dentro de `_Empty`
- [ ] **2.3** El `FloatingActionButton.extended` del `Scaffold` permanece intacto

**Resultado esperado del widget `_Empty` después del fix:**
```dart
class _Empty extends StatelessWidget {
  final bool puedeCrear;
  final VoidCallback onCrear;

  const _Empty({required this.puedeCrear, required this.onCrear});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.chart_2, size: 72.sp,
            color: AppTheme.textGrey.withValues(alpha: 0.3)),
        SizedBox(height: 16.h),
        Text(context.t.sinEvaluaciones,
            style: GoogleFonts.inter(fontSize: 18.sp, color: AppTheme.textGrey)),
        SizedBox(height: 8.h),
        Text('Registra la primera con el botón +',
            style: GoogleFonts.inter(fontSize: 13.sp, color: AppTheme.textGrey)),
        // SIN botón aquí — el FAB del Scaffold lo maneja
      ],
    ),
  );
}
```

---

## EDICIÓN 3 — Snackbars/Logs que desaparecen automáticamente (5 segundos)

**Prioridad:** 🔴 Alta  
**Problema:** Los snackbars de "Proceso completado" quedan fijos en pantalla indefinidamente.  
**Archivos afectados:** Todos los archivos en `lib/` que contengan `SnackBar(`

### Tareas

- [ ] **3.1** Buscar en **todos** los archivos de `lib/` el patrón `SnackBar(` que no tenga `duration:` definido
- [ ] **3.2** Agregar `duration: const Duration(seconds: 5)` a cada uno

**Archivos confirmados con SnackBars:**

| Archivo | Cantidad aproximada |
|---|---|
| `notas_screen.dart` | 2 |
| `pacientes_screen.dart` | 2 |
| `evaluaciones_screen.dart` | 2 |
| `recordatorios_screen.dart` | 2 |
| `usuarios_screen.dart` | 2 |
| `cita_detalle_screen.dart` | 2 |
| `nota_editor_screen.dart` | 2 |
| `paciente_detalle_screen.dart` | 1 |
| `nueva_cita_screen.dart` | 2 |
| `superadmin_screen.dart` | 2 |

**Patrón a aplicar en cada SnackBar:**
```dart
// ANTES:
SnackBar(
  content: Text('Mensaje'),
  backgroundColor: AppTheme.accent,
  behavior: SnackBarBehavior.floating,
)

// DESPUÉS:
SnackBar(
  content: Text('Mensaje'),
  duration: const Duration(seconds: 5), // ← agregar esto
  backgroundColor: AppTheme.accent,
  behavior: SnackBarBehavior.floating,
)
```

---

## EDICIÓN 4 — Fix error de permisos en Pagos y Suscripciones

**Prioridad:** 🔴 Alta  
**Error exacto:**
```
PostgrestException(message: permission denied for table planes,
code: 42501, details: Unauthorized, hint: null)
```
**Causa:** El código hace `.from('planes').select(...)` directamente pero las RLS policies de Supabase no permiten acceso anónimo a esa tabla.

### Parte A — Código Flutter

**Archivo:** `lib/features/pagos/data/payment_service.dart`

- [ ] **4.1** Localizar el método `getPlanes()` en `payment_service.dart`
- [ ] **4.2** Reemplazar el acceso directo a la tabla por una llamada RPC:

```dart
// ELIMINAR ESTO (acceso directo que falla por RLS):
Future<List<PlanDisponible>> getPlanes() async {
  final res = await _client
      .from('planes')
      .select('nombre, max_usuarios_normales, max_admins, precio_referencia, activo')
      .eq('activo', true)
      .order('precio_referencia');
  // ...
}

// REEMPLAZAR POR ESTO (via RPC con token autenticado):
Future<List<PlanDisponible>> getPlanes() async {
  final res = await _client
      .rpc('get_planes', params: {'p_token': _token});

  const labels = {
    'inicio':      'Inicio',
    'starter':     'Starter',
    'profesional': 'Profesional',
    'clinica':     'Clínica',
    'corporativo': 'Corporativo',
    'ilimitado':   'Ilimitado',
  };

  return (res as List).map((j) => PlanDisponible(
    nombre:      j['nombre'].toString(),
    label:       labels[j['nombre']] ?? j['nombre'].toString(),
    maxUsuarios: j['max_usuarios_normales'] as int? ?? 0,
    maxAdmins:   j['max_admins'] as int? ?? 0,
    precio:      double.tryParse(j['precio_referencia'].toString()) ?? 0,
    activo:      j['activo'] as bool? ?? true,
  )).where((p) => p.nombre != 'inicio').toList();
}
```

### Parte B — Supabase (acción en el dashboard de Supabase)

- [ ] **4.3** Ir al **SQL Editor** de Supabase y ejecutar:

```sql
CREATE OR REPLACE FUNCTION get_planes(p_token text)
RETURNS TABLE (
  nombre text,
  max_usuarios_normales int,
  max_admins int,
  precio_referencia numeric,
  activo boolean
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Validar que la sesión sea válida
  PERFORM validate_session(p_token);

  RETURN QUERY
  SELECT
    p.nombre,
    p.max_usuarios_normales,
    p.max_admins,
    p.precio_referencia,
    p.activo
  FROM planes p
  WHERE p.activo = true
  ORDER BY p.precio_referencia;
END;
$$;
```

- [ ] **4.4** Verificar que el RPC `get_planes` aparece en la sección **Database → Functions** de Supabase
- [ ] **4.5** Probar desde la app — la pantalla de Pagos debe cargar sin error

---

## EDICIÓN 5 — Traducción completa al inglés

**Prioridad:** 🟡 Media  
**Archivo principal:** `lib/core/i18n/app_strings.dart`  
**Problema:** La traducción al inglés existe parcialmente — la pantalla Settings muestra mezcla de español e inglés.

### Parte A — Completar `app_strings.dart`

- [ ] **5.1** Abrir `app_strings.dart` y localizar la clase/map de strings en inglés (`en`)
- [ ] **5.2** Agregar o corregir **todos** los siguientes strings en la versión inglés:

```dart
// ── NAVEGACIÓN ──────────────────────────────────────────────
inicio             → 'Home'
pacientes          → 'Patients'
citas              → 'Appointments'
notas              → 'Notes'
configuracion      → 'Settings'
config             → 'Settings'

// ── DASHBOARD ───────────────────────────────────────────────
hola               → 'Hello'
modulos            → 'Modules'
citasHoy           → 'Today\'s appointments'
citasEstaSemana    → 'This week\'s appointments'
proximaCita        → 'Next appointment'
pacientesRecientes → 'Recent patients'
evaluaciones       → 'Evaluations'
consola            → 'Console'

// ── PACIENTES ───────────────────────────────────────────────
nuevoPaciente      → 'New patient'
buscarPaciente     → 'Search patient...'
activo             → 'Active'
inactivo           → 'Inactive'

// ── CITAS ───────────────────────────────────────────────────
calendario         → 'Calendar'
lista              → 'List'
psicologos         → 'Psychologists'
diasSemana         → ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']

// ── NOTAS ───────────────────────────────────────────────────
sinNotas           → 'No notes yet'
crearNota          → 'Create the first note with the + button'
nuevaNota          → 'New note'
todas              → 'All'

// ── EVALUACIONES ────────────────────────────────────────────
sinEvaluaciones    → 'No evaluations yet'
nuevaEvaluacion    → 'New evaluation'

// ── RECORDATORIOS ───────────────────────────────────────────
recordatorios      → 'Reminders'
sinRecordatorios   → 'No reminders'
nuevoRecordatorio  → 'New reminder'

// ── CONFIGURACIÓN ───────────────────────────────────────────
miPerfil           → 'My profile'
apariencia         → 'Appearance'
modoOscuro         → 'Dark mode'
activado           → 'Enabled'
desactivado        → 'Disabled'
tamanoTexto        → 'Text size'
idioma             → 'Language'
notificaciones     → 'Notifications'
herramientas       → 'Tools'
miEquipo           → 'My team'
gestionarUsuarios  → 'Manage users'
acercaDe           → 'About'
cerrarSesion       → 'Log out'
cerrarSesionConf   → 'Are you sure you want to log out?'

// ── USUARIOS ────────────────────────────────────────────────
equipoConsultorio  → 'Practice team'
nuevoUsuario       → 'New user'
editarUsuario      → 'Edit user'
nombreCompleto     → 'Full name'
guardarCambios     → 'Save changes'
crearUsuario       → 'Create user'

// ── COMUNES ─────────────────────────────────────────────────
cancelar           → 'Cancel'
guardar            → 'Save'
eliminar           → 'Delete'
editar             → 'Edit'
confirmar          → 'Confirm'
error              → 'Error'
exito              → 'Success'
```

### Parte B — Reemplazar strings hardcodeados en español

- [ ] **5.3** `configuracion_screen.dart` — reemplazar estos strings hardcodeados por `context.t.`:

| String hardcodeado actual | Reemplazar por |
|---|---|
| `'Recordatorios de citas'` | `context.t.recordatoriosCitas` |
| `'Antes de cada cita programada'` | `context.t.antesDeCardaCita` |
| `'Alertas de tareas pendientes'` | `context.t.alertasTareas` |
| `'Notificaciones del sistema'` | `context.t.notifSistema` |
| `'Actualizaciones y avisos'` | `context.t.actualizacionesYAvisos` |
| `'Versión de la app'` | `context.t.versionApp` |
| `'Política de privacidad'` | `context.t.politicaPrivacidad` |
| `'Términos de uso'` | `context.t.terminosUso` |
| `'Avalon · Plataforma de gestión psicológica'` | `context.t.taglineApp` |

- [ ] **5.4** `nueva_cita_screen.dart` — reemplazar:

| String hardcodeado actual | Reemplazar por |
|---|---|
| `'Cita agendada exitosamente'` | `context.t.citaAgendada` |
| `'Selecciona paciente y psicólogo'` | `context.t.seleccionaPacientePsicologo` |
| `'Nueva cita'` | `context.t.nuevaCita` |

- [ ] **5.5** `nota_editor_screen.dart` — reemplazar:

| String hardcodeado actual | Reemplazar por |
|---|---|
| `'El contenido no puede estar vacío'` | `context.t.contenidoVacio` |
| `'Selecciona un paciente'` | `context.t.seleccionaPaciente` |
| `'Nueva nota'` | `context.t.nuevaNota` |
| `'Editar nota'` | `context.t.editarNota` |
| `'Crear'` | `context.t.crear` |
| `'Guardar'` | `context.t.guardar` |

- [ ] **5.6** Agregar los strings nuevos de las tareas 5.3–5.5 al `app_strings.dart` en **ambos idiomas** (es + en)
- [ ] **5.7** Compilar y verificar que al cambiar idioma a inglés en Settings toda la app cambia sin strings en español visibles

---

## EDICIÓN 6 — Optimización de rendimiento Android

**Prioridad:** 🟢 Normal  
**Archivos:** `main.dart`, `app_shell.dart`, `dashboard_screen.dart` y pantallas principales

### 6.1 — Cache de imágenes en `main.dart`

- [ ] **6.1.1** En `main.dart`, después de `WidgetsFlutterBinding.ensureInitialized()`, agregar configuración de cache:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimización: configurar cache de imágenes
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB

  await initializeDateFormatting('es', null);
  await initializeDateFormatting('en', null);
  // ... resto igual
}
```

### 6.2 — Reducir rebuilds innecesarios en `AppShell`

- [ ] **6.2.1** En `app_shell.dart`, en `_MobileShell`, reemplazar el watch del provider de recordatorios para que solo reconstruya cuando cambia el **número** de pendientes, no toda la lista:

```dart
// ANTES:
final recordatorios = ref.watch(citasProvider.select((s) => s.recordatorios));
final pendientes = recordatorios.where((r) => !r.resuelto).length;

// DESPUÉS — un solo select que devuelve directamente el int:
final pendientes = ref.watch(
  citasProvider.select(
    (s) => s.recordatorios.where((r) => !r.resuelto).length,
  ),
);
```

- [ ] **6.2.2** Aplicar el mismo cambio en `_DesktopShell` si tiene el mismo patrón

### 6.3 — Mover carga de datos fuera del `build()` en Dashboard

- [ ] **6.3.1** En `dashboard_screen.dart`, convertir de `ConsumerWidget` a `ConsumerStatefulWidget`
- [ ] **6.3.2** Mover la carga inicial a `initState` y eliminar el `if` dentro de `build()`:

```dart
// CAMBIO COMPLETO DE dashboard_screen.dart — clase principal:

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Carga inicial — se ejecuta UNA sola vez
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).cargar();
      ref.read(citasProvider.notifier).cargarTodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dash = ref.watch(dashboardProvider);
    // ELIMINAR el bloque if (!dash.isLoading && dash.stats == ...) que había aquí
    // El build solo lee estado, nunca dispara cargas
    // ... resto del build igual
  }
}
```

### 6.4 — Agregar `const` constructors donde faltan

- [ ] **6.4.1** En `login_screen.dart`, agregar `const` a todos los widgets estáticos:
```dart
// ANTES:               DESPUÉS:
Icon(Icons.search)  →  const Icon(Icons.search)
SizedBox(height: 16) → const SizedBox(height: 16)
Text('Avalon')      →  const Text('Avalon')
```

- [ ] **6.4.2** Aplicar lo mismo en `app_shell.dart` — los items de navegación `_items` ya son `const`, verificar el resto
- [ ] **6.4.3** Correr `dart fix --apply` para aplicar correcciones automáticas de `const` en todo el proyecto:
```bash
dart fix --apply
```

---

---

# BACKLOG — Trabajo futuro identificado

> Estas tareas están identificadas y especificadas pero **no son urgentes** para el release actual.  
> Moverlas a EDICIONES INMEDIATAS cuando sea el momento.

---

## BACKLOG 1 — Escalas psicológicas incompletas

**Archivo:** `lib/features/evaluaciones/domain/evaluacion.dart`  
**Problema:** `kItemsEscalas` solo tiene preguntas para PHQ-9 y GAD-7. Las escalas HAMA, BDI-II y PSQI están en el enum pero sin preguntas — el formulario queda vacío al seleccionarlas.

- [ ] Implementar 14 ítems de **HAMA** (Hamilton Anxiety Rating Scale) — opciones 0–4, máximo 56 puntos
- [ ] Implementar 21 ítems de **BDI-II** (Beck Depression Inventory) — opciones 0–3, máximo 63 puntos
- [ ] Implementar 9 componentes de **PSQI** (Pittsburgh Sleep Quality Index) — máximo 21 puntos
- [ ] Implementar lógica de severidad para cada escala nueva
- [ ] Deshabilitar escalas sin ítems en el selector hasta que estén completas

---

## BACKLOG 2 — Recuperación de contraseña

**Archivo:** `lib/features/auth/presentation/screens/login_screen.dart`  
**Tarea:** Agregar botón "Olvidé mi contraseña" que llame a `Supabase.auth.resetPasswordForEmail()`

---

## BACKLOG 3 — Notificaciones push reales Android

**Archivos:** `configuracion_screen.dart`, `AndroidManifest.xml`  
**Problema:** Los toggles de notificaciones solo guardan en `SharedPreferences` — no hay implementación real.

- [ ] Integrar `firebase_messaging` o `flutter_local_notifications`
- [ ] Solicitar permiso `POST_NOTIFICATIONS` en Android 13+
- [ ] Crear canales de notificación Android: `"citas"` y `"recordatorios"`
- [ ] Implementar scheduling local para recordatorios de citas (1h antes, 24h antes)

---

## BACKLOG 4 — Pantalla de Pagos funcional

**Archivo:** `lib/features/pagos/presentation/screens/pagos_screen.dart` (crear)

- [ ] Mostrar plan actual: nombre, vencimiento, días restantes, límite de usuarios
- [ ] Barra de progreso: usuariosUsados / limiteUsuarios
- [ ] Alerta si plan vencido o próximo a vencer (≤ 7 días)
- [ ] Listar planes disponibles con precios
- [ ] Botón de pago → MercadoPago → retorno con deep link
- [ ] Historial de pagos

---

## BACKLOG 5 — Reprogramación de citas

**Archivo:** `lib/features/citas/presentation/screens/cita_detalle_screen.dart`  
**Problema:** El botón "Reprogramar" aparece pero no hace nada al seleccionar el estado.

- [ ] Al cambiar estado a `"reprogramada"`, abrir picker de fecha/hora
- [ ] Crear nueva cita vinculada a la original
- [ ] Marcar la cita original como reprogramada

---

## BACKLOG 6 — Búsqueda global server-side

**Archivo:** `lib/features/busqueda/presentation/screens/busqueda_global_screen.dart`  
**Problema:** Solo busca en datos ya cargados en memoria — resultados incompletos si los providers no han cargado.

- [ ] Cambiar `ref.read()` por `ref.watch()` en los providers
- [ ] Implementar debounce de 300ms en el TextField
- [ ] Implementar `operator==` y `hashCode` en `Cita` para deduplicación correcta
- [ ] Agregar búsqueda de Recordatorios y Evaluaciones

---

## BACKLOG 7 — Unificación modelo de Recordatorios

**Archivos:** `citas_provider.dart`, `recordatorios_provider.dart`  
**Problema:** Existen dos modelos: `Recordatorio` (viejo, en citas) y `RecordatorioEx` (nuevo, en recordatorios).

- [ ] Eliminar `Recordatorio` viejo de `citas/domain/cita.dart`
- [ ] Actualizar `recordatoriosProvider` en `citas_provider.dart` para usar `RecordatorioEx`
- [ ] Actualizar badge del bottom nav en `AppShell` para usar el modelo nuevo

---

## BACKLOG 8 — Seguridad de credenciales

**Archivos:** `app_constants.dart`, `auth_service.dart`

- [ ] Migrar `sessionToken` de `SharedPreferences` a `flutter_secure_storage`
- [ ] Implementar manejo de sesión expirada con redirección a login y mensaje claro
- [ ] Diferenciar error de red vs sesión vencida en `auth_wrapper.dart`

---

## BACKLOG 9 — Tests

**Archivo:** `test/widget_test.dart`

- [ ] Reemplazar `MyApp` por `AvalonApp` en el test base
- [ ] Test de `AuthProvider`: login exitoso, login fallido, sesión expirada
- [ ] Test de `CitasProvider`: crear, actualizar, verificar conflicto
- [ ] Test de `PacientesProvider`: cargar, buscar, crear, eliminar
- [ ] Smoke test: arranque → AppShell visible sin errores
- [ ] Test de navegación tab a tab

---

## BACKLOG 10 — Limpieza técnica

- [ ] Consolidar función `_desktopWrap()` copiada en 7+ archivos → mover a `lib/core/layout/responsive.dart`
- [ ] Consolidar función `_iniciales(String nombre)` en `lib/core/utils/string_utils.dart`
- [ ] Crear extensión `EstadoCita.color` y `EstadoCita.label` para reemplazar los 4 switch idénticos
- [ ] Eliminar `_DetalleSheet` de `pacientes_screen.dart` — clase nunca instanciada
- [ ] Renombrar `cargarDespaciente` → `cargarDePaciente` en `notas_provider.dart`
- [ ] Corregir condición siempre-verdadera: `final isLast = paciente == paciente` en `dashboard_screen.dart`

---

---

# RESUMEN DE ESTADO

## Ediciones inmediatas

| # | Edición | Archivos | Estado |
|---|---|---|---|
| 1 | Botón duplicado en Notas | `notas_screen.dart` | `[ ]` Pendiente |
| 2 | Botón duplicado en Evaluaciones | `evaluaciones_screen.dart` | `[ ]` Pendiente |
| 3 | Snackbars auto-dismiss 5s | Todos los archivos con `SnackBar(` | `[ ]` Pendiente |
| 4 | Fix error Pagos RLS | `payment_service.dart` + Supabase SQL | `[ ]` Pendiente |
| 5 | Traducción completa EN | `app_strings.dart` + screens | `[ ]` Pendiente |
| 6 | Optimización rendimiento Android | `main.dart`, `app_shell.dart`, `dashboard_screen.dart` | `[ ]` Pendiente |

## Orden de ejecución recomendado

```
1 → 2 → 3 → 4 → 6 → 5
```
> Dejar la traducción (5) al final porque es la que toca más archivos simultáneamente.

## Bugs activos confirmados en dispositivo

| Bug | Causa | Fix en edición |
|---|---|---|
| Snackbars permanentes en pantalla | Sin `duration:` definido | Edición 3 |
| 2 botones "Nueva nota" | `ElevatedButton` en `_Empty` + FAB | Edición 1 |
| 2 botones "Nueva evaluación" | `ElevatedButton` en `_Empty` + FAB | Edición 2 |
| `permission denied for table planes` | Acceso directo a tabla sin RLS | Edición 4 |

---

> **Avalon Android · TODO.md**  
> Actualizar este archivo marcando `[x]` cada tarea completada.