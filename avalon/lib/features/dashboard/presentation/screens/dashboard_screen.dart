// ── REEMPLAZA el Container del logo/bienvenida en DashboardScreen ────────────
// Envuelve el Container de bienvenida en un GestureDetector:
//
// GestureDetector(
//   onLongPress: () {
//     if (user?.isSuperAdmin == true) {
//       Navigator.push(context,
//         MaterialPageRoute(builder: (_) => const SuperAdminScreen()));
//     }
//   },
//   child: Container(   // <-- tu Container de bienvenida existente
//     ...
//   ),
// )
//
// Agrega el import al inicio del archivo:
// import '../../../superadmin/presentation/screens/superadmin_screen.dart';

// ── TAMBIÉN agrega esto en el body del dashboard (después del GridView) ───────
// Para que el superadmin vea el acceso visualmente (discreto, solo para él):
//
// if (user?.isSuperAdmin == true)
//   Padding(
//     padding: EdgeInsets.only(top: 8.h),
//     child: Center(
//       child: TextButton.icon(
//         onPressed: () => Navigator.push(context,
//             MaterialPageRoute(builder: (_) => const SuperAdminScreen())),
//         icon: Icon(Icons.bolt, size: 14.sp, color: AppTheme.textGrey),
//         label: Text('Consola', style: GoogleFonts.inter(
//             fontSize: 11.sp, color: AppTheme.textGrey)),
//       ),
//     ),
//   ),

// ── SNIPPET COMPLETO para copiar/pegar en dashboard_screen.dart ──────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../citas/presentation/widgets/widget_citas_hoy.dart';
import '../../../citas/presentation/widgets/widget_proximas_citas.dart';
import '../../../citas/presentation/widgets/widget_disponibilidad.dart';
import '../../../citas/presentation/widgets/widget_recordatorios.dart';
import '../../../citas/presentation/providers/citas_provider.dart';
import '../../data/dashboard_service.dart';
import '../../../pacientes/presentation/screens/pacientes_screen.dart';
import '../../../citas/presentation/screens/citas_screen.dart';
import '../../../../features/superadmin/presentation/screens/superadmin_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dash = ref.watch(dashboardProvider);

    if (!dash.isLoading && dash.stats == DashboardStats.empty) {
      Future.microtask(() {
        ref.read(dashboardProvider.notifier).cargar();
        ref.read(citasProvider.notifier).cargarTodo();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avalon'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(dashboardProvider.notifier).cargar()),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).cargar(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Tarjeta de bienvenida (tap largo → consola superadmin) ──
              GestureDetector(
                onLongPress: () {
                  if (user?.isSuperAdmin == true) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SuperAdminScreen()));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¡Bienvenido!',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14.sp)),
                      SizedBox(height: 4.h),
                      Text(user?.displayName ?? '',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 22.sp,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      Row(children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20.r)),
                          child: Text(
                            '${user?.rolEmoji ?? ""} ${user?.rolLabel ?? ""}',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12.sp),
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
              ),
              SizedBox(height: 20.h),

              // ── Stats ──
              if (dash.isLoading)
                const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()))
              else ...[
                Row(children: [
                  _StatCard('Pacientes', dash.stats.totalPacientes.toString(),
                      Icons.people, AppTheme.primary),
                  SizedBox(width: 12.w),
                  _StatCard('Activos', dash.stats.pacientesActivos.toString(),
                      Icons.check_circle_outline, AppTheme.accent),
                ]),
                SizedBox(height: 12.h),
                Row(children: [
                  _StatCard('Citas hoy', dash.stats.citasHoy.toString(),
                      Icons.today, AppTheme.warning),
                  SizedBox(width: 12.w),
                  _StatCard('Esta semana', dash.stats.citasSemana.toString(),
                      Icons.date_range, AppTheme.secondary),
                ]),

                if (dash.stats.proximaCita != null) ...[
                  SizedBox(height: 20.h),
                  Text('Próxima cita', style: GoogleFonts.inter(
                      fontSize: 16.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8.h),
                  _ProximaCitaCard(cita: dash.stats.proximaCita!),
                ],

                if (dash.stats.ultimosPacientes.isNotEmpty) ...[
                  SizedBox(height: 20.h),
                  Text('Pacientes recientes', style: GoogleFonts.inter(
                      fontSize: 16.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8.h),
                  ...dash.stats.ultimosPacientes.map((p) => _UltimoPacienteRow(p)),
                ],

                // ── Widgets de Citas ──
                SizedBox(height: 20.h),
                
                // Recordatorios (visible para todos)
                WidgetRecordatorios(),
                
                SizedBox(height: 16.h),
                
                // Citas de hoy (visible para todos)
                WidgetCitasHoy(),
                
                SizedBox(height: 16.h),
                
                // Disponibilidad (solo para secretaria/admin/superadmin)
                if (user?.isSecretaria == true || user?.isAdmin == true || user?.isSuperAdmin == true) ...[
                  WidgetDisponibilidad(),
                  SizedBox(height: 16.h),
                ],
                
                // Próximas citas (solo para psicólogos)
                if (user?.isPsicologo == true) ...[
                  WidgetProximasCitas(),
                  SizedBox(height: 16.h),
                ],
              ],

              SizedBox(height: 20.h),
              Text('Módulos', style: GoogleFonts.inter(
                  fontSize: 16.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 12.h),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12.w, mainAxisSpacing: 12.h,
                childAspectRatio: 1.1,
                children: [
                  _ModuloCard(icon: Icons.people, label: 'Pacientes',
                      color: AppTheme.primary,
                      badge: dash.stats.totalPacientes > 0
                          ? dash.stats.totalPacientes.toString() : null,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PacientesScreen()))),
                  _ModuloCard(icon: Icons.calendar_today, label: 'Citas',
                      color: AppTheme.secondary,
                      badge: dash.stats.citasHoy > 0
                          ? dash.stats.citasHoy.toString() : null,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CitasScreen()))),
                  _ModuloCard(icon: Icons.note_alt, label: 'Notas',
                      color: AppTheme.warning, onTap: () {}, disabled: true),
                  _ModuloCard(icon: Icons.assessment, label: 'Evaluaciones',
                      color: AppTheme.accent, onTap: () {}, disabled: true),
                ],
              ),

              // ── Acceso discreto a consola (solo superadmin) ──
              if (user?.isSuperAdmin == true) ...[
                SizedBox(height: 8.h),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SuperAdminScreen())),
                    icon: Icon(Icons.bolt, size: 14.sp, color: AppTheme.textGrey),
                    label: Text('Consola', style: GoogleFonts.inter(
                        fontSize: 11.sp, color: AppTheme.textGrey)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGETS AUXILIARES ────────────────────────────────────────────────────────
  Widget _StatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 8.h),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: color)),
            SizedBox(height: 4.h),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _ProximaCitaCard({required Map<String, dynamic> cita}) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppTheme.primary, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Próxima cita',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500)),
                Text('Datos de ejemplo',
                    style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _UltimoPacienteRow(Map<String, dynamic> paciente) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Icon(Icons.person, color: AppTheme.primary, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paciente ejemplo',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500)),
                Text('Reciente',
                    style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ModuloCard({
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
          color: disabled ? AppTheme.textGrey.withOpacity(0.1) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: disabled ? AppTheme.textGrey.withOpacity(0.2) : color.withOpacity(0.2),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: disabled ? AppTheme.textGrey : color,
                    size: 32.sp,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: disabled ? AppTheme.textGrey : color,
                    ),
                  ),
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
                    color: color,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widgets existentes se mantienen igual (StatCard, ProximaCitaCard, etc.)
// Solo copia el bloque de GestureDetector y el TextButton de consola en tu
// dashboard_screen.dart actual.
