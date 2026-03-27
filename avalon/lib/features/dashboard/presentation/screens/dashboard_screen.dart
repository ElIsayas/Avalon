import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../citas/presentation/widgets/widget_citas_hoy.dart';
import '../../../citas/presentation/widgets/widget_proximas_citas.dart';
import '../../../citas/presentation/widgets/widget_disponibilidad.dart';
import '../../../citas/presentation/widgets/widget_recordatorios.dart';
import '../../../citas/presentation/providers/citas_provider.dart';
import '../../data/dashboard_service.dart';
import '../../../citas/domain/cita.dart';
import '../../../citas/presentation/screens/cita_detalle_screen.dart';
import '../../../pacientes/domain/paciente.dart';
import '../../../pacientes/presentation/screens/paciente_detalle_screen.dart';
import '../../../../core/navigation/nav_provider.dart';
import '../../../../features/superadmin/presentation/screens/superadmin_screen.dart';
import '../../../../features/busqueda/presentation/screens/busqueda_global_screen.dart';
import '../../../../features/evaluaciones/presentation/screens/evaluaciones_screen.dart';
import '../../../../core/utils/string_utils.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).cargar();
      ref.read(citasProvider.notifier).cargarTodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dash = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avalon'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Búsqueda global',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BusquedaGlobalScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardProvider.notifier).cargar();
              ref.read(citasProvider.notifier).cargarTodo();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).cargar();
          await ref.read(citasProvider.notifier).cargarTodo();
        },
        child: ResponsiveBody(
          maxWidth: kDesktopContentMaxWidth,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tarjeta bienvenida ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.t.hola,
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 14.sp)),
                      SizedBox(height: 2.h),
                      Text(user?.displayName ?? '',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      Row(children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20.r)),
                          child: Text(
                            '${user?.rolEmoji ?? ""} ${user?.rolLabel ?? ""}',
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 12.sp),
                          ),
                        ),
                        if (user?.especialidad != null) ...[
                          SizedBox(width: 8.w),
                          Text(user!.especialidad!,
                              style: GoogleFonts.inter(
                                  color: Colors.white60, fontSize: 12.sp)),
                        ],
                      ]),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                if (dash.error != null) ...[
                  _ErrorBanner(
                    mensaje: dash.error!,
                    onRetry: () async {
                      await ref.read(dashboardProvider.notifier).cargar();
                      await ref.read(citasProvider.notifier).cargarTodo();
                    },
                  ),
                  SizedBox(height: 16.h),
                ],

                if (dash.isLoading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator()))
                else ...[
                  // ── Métricas principales ────────────────────────────
                  Row(children: [
                    _statCard(
                        context.t.pacientes,
                        dash.stats.totalPacientes.toString(),
                        Iconsax.people,
                        AppTheme.primary,
                        sub: '${dash.stats.pacientesActivos} activos',
                        onTap: () =>
                            ref.read(navProvider.notifier).goToPacientes()),
                    SizedBox(width: 10.w),
                    _statCard('Hoy', dash.stats.citasHoy.toString(),
                        Iconsax.calendar_tick, AppTheme.warning,
                        sub: 'citas hoy',
                        onTap: () =>
                            ref.read(navProvider.notifier).goToCitas()),
                    SizedBox(width: 10.w),
                    _statCard('Semana', dash.stats.citasSemana.toString(),
                        Iconsax.calendar_2, AppTheme.secondary,
                        sub: 'esta semana',
                        onTap: () =>
                            ref.read(navProvider.notifier).goToCitas()),
                  ]),
                  SizedBox(height: 10.h),
                  Row(children: [
                    _statCard('Este mes', dash.stats.citasMes.toString(),
                        Iconsax.chart_2, AppTheme.accent,
                        sub: 'este mes',
                        onTap: () =>
                            ref.read(navProvider.notifier).goToCitas()),
                    SizedBox(width: 10.w),
                    _statCard('Notas', dash.stats.notasSemana.toString(),
                        Iconsax.note, AppTheme.warning,
                        sub: 'esta semana',
                        onTap: () =>
                            ref.read(navProvider.notifier).goToNotas()),
                    SizedBox(width: 10.w),
                    _statCard(
                        'Inactivos',
                        (dash.stats.totalPacientes -
                                dash.stats.pacientesActivos)
                            .toString(),
                        Iconsax.user_remove,
                        AppTheme.textGrey,
                        sub: 'pacientes'),
                  ]),
                  SizedBox(height: 20.h),

                  // ── Gráfica citas por día de la semana ──────────────
                  if (dash.stats.citasPorDiaSemana.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.t.citasEstaSemana,
                            style: GoogleFonts.inter(
                                fontSize: 15.sp, fontWeight: FontWeight.w600)),
                        Text(
                            '${DateFormat('d MMM', 'es').format(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)))} — ${DateFormat('d MMM', 'es').format(DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)))}',
                            style: GoogleFonts.inter(
                                fontSize: 11.sp, color: AppTheme.textGrey)),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: _GraficaBarras(
                          datos: dash.stats.citasPorDiaSemana,
                          max: dash.stats.maxCitasDia),
                    ),
                    SizedBox(height: 20.h),
                  ],

                  // ── Próxima cita ────────────────────────────────────
                  if (dash.stats.proximaCita != null) ...[
                    Text(context.t.proximaCita,
                        style: GoogleFonts.inter(
                            fontSize: 15.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8.h),
                    _ProximaCitaCard(
                      cita: dash.stats.proximaCita!,
                      onTap: () {
                        final cita = _tryBuildCita(dash.stats.proximaCita!);
                        if (cita == null) {
                          ref.read(navProvider.notifier).goToCitas();
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CitaDetalleScreen(cita: cita)),
                        );
                      },
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // ── Últimos pacientes ───────────────────────────────
                  if (dash.stats.ultimosPacientes.isNotEmpty) ...[
                    Text(context.t.pacientesRecientes,
                        style: GoogleFonts.inter(
                            fontSize: 15.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        children: dash.stats.ultimosPacientes
                            .map(
                              (p) => _UltimoPacienteRow(
                                p,
                                onTap: () {
                                  final paciente = _tryBuildPaciente(p);
                                  if (paciente == null) {
                                    ref
                                        .read(navProvider.notifier)
                                        .goToPacientes();
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PacienteDetalleScreen(
                                          paciente: paciente),
                                    ),
                                  );
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // ── Widgets de citas ────────────────────────────────
                  const WidgetRecordatorios(),
                  SizedBox(height: 14.h),
                  const WidgetCitasHoy(),
                  SizedBox(height: 14.h),
                  if (user?.isSecretaria == true ||
                      user?.isAdmin == true ||
                      user?.isSuperAdmin == true) ...[
                    const WidgetDisponibilidad(),
                    SizedBox(height: 14.h),
                  ],
                  if (user?.isPsicologo == true) ...[
                    const WidgetProximasCitas(),
                    SizedBox(height: 14.h),
                  ],
                ],

                // ── Módulos ─────────────────────────────────────────────
                SizedBox(height: 4.h),
                Text(context.t.modulos,
                    style: GoogleFonts.inter(
                        fontSize: 15.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 10.h),
                GridView.count(
                  crossAxisCount: context.isDesktop ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: context.isDesktop ? 1.3 : 1.1,
                  children: [
                    _moduloCard(
                        icon: Iconsax.people,
                        label: context.t.pacientes,
                        color: AppTheme.primary,
                        badge: dash.stats.totalPacientes > 0
                            ? dash.stats.totalPacientes.toString()
                            : null,
                        onTap: () =>
                            ref.read(navProvider.notifier).goToPacientes()),
                    _moduloCard(
                        icon: Iconsax.calendar_2,
                        label: 'Citas',
                        color: AppTheme.secondary,
                        badge: dash.stats.citasHoy > 0
                            ? dash.stats.citasHoy.toString()
                            : null,
                        onTap: () =>
                            ref.read(navProvider.notifier).goToCitas()),
                    _moduloCard(
                        icon: Iconsax.note,
                        label: 'Notas',
                        color: AppTheme.warning,
                        onTap: () =>
                            ref.read(navProvider.notifier).goToNotas()),
                    _moduloCard(
                        icon: Iconsax.chart_2,
                        label: context.t.evaluaciones,
                        color: AppTheme.accent,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EvaluacionesScreen()))),
                  ],
                ),

                // Acceso superadmin discreto
                if (user?.isSuperAdmin == true) ...[
                  SizedBox(height: 8.h),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SuperAdminScreen())),
                      icon: Icon(Icons.bolt,
                          size: 14.sp, color: AppTheme.textGrey),
                      label: Text(context.t.consola,
                          style: GoogleFonts.inter(
                              fontSize: 11.sp, color: AppTheme.textGrey)),
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ), // ResponsiveBody
      ),
    );
  }
}

Cita? _tryBuildCita(Map<String, dynamic> data) {
  try {
    return Cita.fromJson(data);
  } catch (_) {
    return null;
  }
}

Paciente? _tryBuildPaciente(Map<String, dynamic> data) {
  final id = data['id']?.toString();
  final nombre = data['nombre']?.toString();
  if (id == null || id.isEmpty || nombre == null || nombre.isEmpty) {
    return null;
  }
  return Paciente(
    id: id,
    nombre: nombre,
    email: data['email']?.toString() ?? '',
    numeroDocumento: data['numero_documento']?.toString() ?? id,
    telefono: data['telefono']?.toString(),
    fechaNacimiento: data['fecha_nacimiento'] != null
        ? DateTime.tryParse(data['fecha_nacimiento'].toString())
        : null,
    direccion: data['direccion']?.toString(),
    historialMedico: data['historial_medico']?.toString(),
    activo: data['activo'] as bool? ?? true,
    fechaRegistro: data['fecha_registro'] != null
        ? DateTime.tryParse(data['fecha_registro'].toString()) ?? DateTime.now()
        : DateTime.now(),
    fechaActualizacion: data['fecha_actualizacion'] != null
        ? DateTime.tryParse(data['fecha_actualizacion'].toString())
        : null,
    creadoPor: data['creado_por']?.toString() ?? '',
    objetivosTerapeuticos: data['objetivos_terapeuticos']?.toString(),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              mensaje,
              style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ── GRÁFICA DE BARRAS ─────────────────────────────────────────────────────────

class _GraficaBarras extends StatelessWidget {
  final List<CitaDiaData> datos;
  final int max;

  const _GraficaBarras({required this.datos, required this.max});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 110.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: datos.map((d) {
          final ratio = max > 0 ? d.cantidad / max : 0.0;
          final barH = (ratio * 72.h).clamp(4.0, 72.h);
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Número encima de la barra (solo si > 0)
                if (d.cantidad > 0)
                  Text('${d.cantidad}',
                      style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color:
                              d.esHoy ? AppTheme.primary : AppTheme.textGrey))
                else
                  SizedBox(height: 12.h),
                SizedBox(height: 2.h),
                // Barra
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: barH,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    color: d.esHoy
                        ? AppTheme.primary
                        : d.cantidad > 0
                            ? AppTheme.primary
                                .withValues(alpha: isDark ? 0.45 : 0.3)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : AppTheme.divider),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(5.r)),
                  ),
                ),
                SizedBox(height: 6.h),
                // Etiqueta del día
                Text(d.dia,
                    style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: d.esHoy ? FontWeight.bold : FontWeight.w400,
                        color: d.esHoy ? AppTheme.primary : AppTheme.textGrey)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── PRÓXIMA CITA ──────────────────────────────────────────────────────────────

class _ProximaCitaCard extends StatelessWidget {
  final Map<String, dynamic> cita;
  final VoidCallback? onTap;
  const _ProximaCitaCard({required this.cita, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fecha = cita['fecha_hora'] != null
        ? DateTime.tryParse(cita['fecha_hora'].toString())
        : null;
    final paciente = cita['paciente_nombre']?.toString() ??
        cita['paciente_id']?.toString() ??
        '—';
    final psicologo = cita['psicologo_nombre']?.toString() ??
        cita['psicologo_id']?.toString() ??
        '';
    final tipo = cita['tipo_sesion']?.toString() ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Iconsax.calendar_tick,
                  color: AppTheme.primary, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paciente,
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  if (psicologo.isNotEmpty)
                    Text('con $psicologo',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp, color: AppTheme.textGrey)),
                  if (tipo.isNotEmpty)
                    Text(tipo,
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: AppTheme.textGrey)),
                ],
              ),
            ),
            if (fecha != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(DateFormat('HH:mm').format(fecha),
                      style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                  Text(DateFormat('dd MMM', 'es').format(fecha),
                      style: GoogleFonts.inter(
                          fontSize: 11.sp, color: AppTheme.textGrey)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── ÚLTIMO PACIENTE ────────────────────────────────────────────────────────────

class _UltimoPacienteRow extends StatelessWidget {
  final Map<String, dynamic> paciente;
  final VoidCallback? onTap;
  const _UltimoPacienteRow(this.paciente, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final nombre = paciente['nombre']?.toString() ?? '—';
    final email = paciente['email']?.toString() ?? '';
    final iniciales = nombre.iniciales;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(iniciales,
                  style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary)),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: GoogleFonts.inter(
                          fontSize: 13.sp, fontWeight: FontWeight.w500)),
                  if (email.isNotEmpty)
                    Text(email,
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: AppTheme.textGrey),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16.sp, color: AppTheme.textGrey),
          ],
        ),
      ),
    );
  }
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────

Widget _statCard(
  String title,
  String value,
  IconData icon,
  Color color, {
  String? sub,
  VoidCallback? onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18.sp),
            SizedBox(height: 6.h),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(sub ?? title,
                style: GoogleFonts.inter(
                    fontSize: 10.sp, color: AppTheme.textGrey),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ),
  );
}

// ── MODULO CARD ───────────────────────────────────────────────────────────────

Widget _moduloCard({
  required IconData icon,
  required String label,
  required Color color,
  String? badge,
  required VoidCallback onTap,
  bool disabled = false,
}) {
  return InkWell(
    onTap: disabled ? null : onTap,
    borderRadius: BorderRadius.circular(12.r),
    child: Container(
      decoration: BoxDecoration(
        color: disabled
            ? AppTheme.textGrey.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: disabled
              ? AppTheme.textGrey.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: disabled ? AppTheme.textGrey : color, size: 30.sp),
                SizedBox(height: 8.h),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: disabled ? AppTheme.textGrey : color)),
                if (disabled)
                  Text('Próximamente',
                      style: GoogleFonts.inter(
                          fontSize: 9.sp, color: AppTheme.textGrey)),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: 8.r,
              right: 8.r,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(10.r)),
                child: Text(badge,
                    style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    ),
  );
}
