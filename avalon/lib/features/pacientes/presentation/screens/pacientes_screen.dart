import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/paciente.dart';
import '../providers/paciente_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/layout/responsive.dart';
import 'paciente_form.dart';
import 'paciente_detalle_screen.dart';
import '../../../../features/busqueda/presentation/screens/busqueda_global_screen.dart';

class PacientesScreen extends ConsumerStatefulWidget {
  const PacientesScreen({super.key});

  @override
  ConsumerState<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends ConsumerState<PacientesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pacientesProvider.notifier).cargar();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _irAForm([Paciente? paciente]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PacienteForm(paciente: paciente)),
    ).then((_) => ref.read(pacientesProvider.notifier).cargar());
  }

  void _confirmarEliminar(Paciente p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar paciente'),
        content: Text(
            'Â¿Eliminar a ${p.nombre}? Esta acciÃ³n no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(pacientesProvider.notifier).eliminar(p.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _verDetalle(Paciente p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PacienteDetalleScreen(paciente: p)),
    ).then((_) => ref.read(pacientesProvider.notifier).cargar());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pacientesProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final user = ref.watch(currentUserProvider);
    final puedeCrear = user?.isAdmin == true ||
        user?.isPsicologo == true ||
        user?.isSuperAdmin == true;

    // Mostrar snackbar de Ã©xito/error
    ref.listen(pacientesProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(next.successMessage!),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(pacientesProvider.notifier).clearMessages();
      }
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(next.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(pacientesProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.pacientes),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'BÃºsqueda global',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BusquedaGlobalScreen())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => v.isEmpty
                  ? ref.read(pacientesProvider.notifier).cargar()
                  : ref.read(pacientesProvider.notifier).buscar(v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: context.t.buscarPaciente,
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white.withValues(alpha: 0.8)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(pacientesProvider.notifier).cargar();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
        ),
      ),

      // Stats header
      body: ResponsiveBody(
        maxWidth: kDesktopContentMaxWidth,
        child: Column(
          children: [
            _StatsBar(
                total: state.total, activos: state.activos, isAdmin: isAdmin),

            // Lista
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.pacientes.isEmpty
                      ? _Empty(onCrear: puedeCrear ? () => _irAForm() : null)
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(pacientesProvider.notifier).cargar(),
                          child: ListView.builder(
                            padding: EdgeInsets.all(16.r),
                            itemCount: state.pacientes.length,
                            itemBuilder: (_, i) => _PacienteCard(
                              paciente: state.pacientes[i],
                              onTap: () => _verDetalle(state.pacientes[i]),
                              onEditar: () => _irAForm(state.pacientes[i]),
                              onEliminar: () =>
                                  _confirmarEliminar(state.pacientes[i]),
                              onToggle: () => ref
                                  .read(pacientesProvider.notifier)
                                  .toggleActivo(state.pacientes[i].id),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),

      floatingActionButton: puedeCrear
          ? FloatingActionButton.extended(
              onPressed: () => _irAForm(),
              icon: const Icon(Icons.person_add),
              label: Text(context.t.nuevoPaciente),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

// â”€â”€ WIDGETS INTERNOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatsBar extends StatelessWidget {
  final int total, activos;
  final bool isAdmin;
  const _StatsBar(
      {required this.total, required this.activos, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          _Stat('Total', total.toString(), Icons.people, AppTheme.primary),
          SizedBox(width: 12.w),
          _Stat('Activos', activos.toString(), Icons.check_circle,
              AppTheme.accent),
          SizedBox(width: 12.w),
          _Stat('Inactivos', (total - activos).toString(), Icons.pause_circle,
              AppTheme.textGrey),
          if (isAdmin) ...[
            SizedBox(width: 12.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings,
                      size: 14.sp, color: AppTheme.error),
                  SizedBox(width: 4.w),
                  Text('Admin',
                      style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 4.w),
        Text('$value $label',
            style:
                GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.textDark)),
      ],
    );
  }
}

class _PacienteCard extends StatelessWidget {
  final Paciente paciente;
  final VoidCallback onTap, onEditar, onEliminar, onToggle;

  const _PacienteCard({
    required this.paciente,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24.r,
                backgroundColor: paciente.activo
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : AppTheme.textGrey.withValues(alpha: 0.1),
                child: Text(
                  paciente.iniciales,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color:
                        paciente.activo ? AppTheme.primary : AppTheme.textGrey,
                    fontSize: 15.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(paciente.nombre,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                  color: AppTheme.textDark),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: paciente.activo
                                ? AppTheme.accent.withValues(alpha: 0.15)
                                : AppTheme.textGrey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            paciente.activo
                                ? context.t.activo
                                : context.t.inactivo,
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: paciente.activo
                                  ? AppTheme.accent
                                  : AppTheme.textGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(paciente.email,
                        style: GoogleFonts.inter(
                            fontSize: 12.sp, color: AppTheme.textGrey),
                        overflow: TextOverflow.ellipsis),
                    if (paciente.telefono != null)
                      Text(paciente.telefono!,
                          style: GoogleFonts.inter(
                              fontSize: 12.sp, color: AppTheme.textGrey)),
                  ],
                ),
              ),

              // Acciones
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'editar') onEditar();
                  if (v == 'toggle') onToggle();
                  if (v == 'eliminar') onEliminar();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'editar',
                      child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                          dense: true)),
                  PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                        leading: Icon(paciente.activo
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline),
                        title: Text(paciente.activo ? 'Desactivar' : 'Activar'),
                        dense: true,
                      )),
                  const PopupMenuItem(
                      value: 'eliminar',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Eliminar',
                            style: TextStyle(color: Colors.red)),
                        dense: true,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback? onCrear;
  const _Empty({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 80.sp, color: AppTheme.textGrey.withValues(alpha: 0.4)),
          SizedBox(height: 16.h),
          Text('No hay pacientes',
              style:
                  GoogleFonts.inter(fontSize: 18.sp, color: AppTheme.textGrey)),
          SizedBox(height: 8.h),
          Text('Crea el primero con el botÃ³n +',
              style:
                  GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.textGrey)),
          SizedBox(height: 24.h),
          if (onCrear != null)
            ElevatedButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.person_add),
              label: Text(context.t.nuevoPaciente),
            ),
        ],
      ),
    );
  }
}
