import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/cita.dart';
import '../providers/citas_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class CitaDetalleScreen extends ConsumerStatefulWidget {
  final Cita cita;
  const CitaDetalleScreen({super.key, required this.cita});

  @override
  ConsumerState<CitaDetalleScreen> createState() => _CitaDetalleScreenState();
}

class _CitaDetalleScreenState extends ConsumerState<CitaDetalleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _auditoria = [];
  bool _cargandoAuditoria = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _cargarAuditoria();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cargarAuditoria() async {
    setState(() => _cargandoAuditoria = true);
    try {
      final token = ref.read(currentUserProvider)?.sessionToken ?? '';
      final res = await Supabase.instance.client
          .rpc('get_auditoria_cita', params: {
        'p_token':   token,
        'p_cita_id': widget.cita.id,
      });
      setState(() {
        _auditoria = (res as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _cargandoAuditoria = false;
      });
    } catch (_) {
      setState(() => _cargandoAuditoria = false);
    }
  }

  // Estados a los que se puede transicionar según el estado actual
  List<EstadoCita> _estadosDisponibles(EstadoCita actual) {
    switch (actual) {
      case EstadoCita.agendada:
        return [EstadoCita.confirmada, EstadoCita.cancelada, EstadoCita.reprogramada];
      case EstadoCita.confirmada:
        return [EstadoCita.enProgreso, EstadoCita.cancelada, EstadoCita.noAsistio];
      case EstadoCita.enProgreso:
        return [EstadoCita.completada, EstadoCita.noAsistio];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final puedeCambiarEstado = user?.isSecretaria == true ||
        user?.isAdmin == true || user?.isSuperAdmin == true ||
        user?.isPsicologo == true;

    // Leer cita actualizada del provider
    final citasState = ref.watch(citasProvider);
    final cita = citasState.citasHoy
            .cast<Cita?>()
            .firstWhere((c) => c?.id == widget.cita.id, orElse: () => null) ??
        citasState.citasSemana
            .cast<Cita?>()
            .firstWhere((c) => c?.id == widget.cita.id, orElse: () => null) ??
        widget.cita;

    final estadosDisp = _estadosDisponibles(cita.estado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de cita'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Información'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab 1: Información ──────────────────────────────────────
          SingleChildScrollView(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado actual + cambio
                _EstadoCard(
                  cita: cita,
                  estadosDisponibles: estadosDisp,
                  puedeCambiar: puedeCambiarEstado,
                  onCambiarEstado: (nuevoEstado) =>
                      _cambiarEstado(context, cita, nuevoEstado),
                ),
                SizedBox(height: 16.h),

                // Datos de la cita
                _SeccionLabel('Datos de la cita'),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Column(
                      children: [
                        _Fila(Iconsax.calendar_2, 'Fecha y hora',
                            DateFormat('EEEE d \'de\' MMMM, HH:mm', 'es')
                                .format(cita.fechaHora)),
                        _Fila(Iconsax.timer_1, 'Duración',
                            '${cita.duracionMinutos} minutos'),
                        _Fila(Iconsax.document_text, 'Tipo',
                            cita.tipoSesion.label),
                        _Fila(Iconsax.location, 'Modalidad',
                            cita.modalidad.label),
                        if (cita.motivoConsulta != null)
                          _Fila(Iconsax.note_text, 'Motivo',
                              cita.motivoConsulta!),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Personas
                _SeccionLabel('Involucrados'),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Column(
                      children: [
                        _Fila(Iconsax.user, 'Paciente',
                            cita.pacienteNombre ?? cita.pacienteId),
                        _Fila(Iconsax.people, 'Psicólogo/a',
                            cita.psicologoNombre ?? cita.psicologoId),
                        _Fila(
                          Icons.verified_user_outlined,
                          'Confirmada por paciente',
                          cita.confirmadoPaciente ? 'Sí ✓' : 'No',
                          valueColor: cita.confirmadoPaciente
                              ? AppTheme.accent
                              : AppTheme.textGrey,
                        ),
                      ],
                    ),
                  ),
                ),

                // Notas
                if (cita.notas != null) ...[
                  SizedBox(height: 16.h),
                  _SeccionLabel('Notas de la cita'),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(14.r),
                      child: Text(cita.notas!,
                          style: GoogleFonts.inter(
                              fontSize: 13.sp, height: 1.6)),
                    ),
                  ),
                ],

                SizedBox(height: 32.h),
              ],
            ),
          ),

          // ── Tab 2: Historial de cambios ─────────────────────────────
          _cargandoAuditoria
              ? const Center(child: CircularProgressIndicator())
              : _auditoria.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.clock,
                              size: 64.sp,
                              color: AppTheme.textGrey.withValues(alpha: 0.3)),
                          SizedBox(height: 12.h),
                          Text('Sin historial de cambios',
                              style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  color: AppTheme.textGrey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.r),
                      itemCount: _auditoria.length,
                      itemBuilder: (_, i) =>
                          _AuditoriaItem(data: _auditoria[i]),
                    ),
        ],
      ),
    );
  }

  Future<void> _cambiarEstado(
      BuildContext context, Cita cita, EstadoCita nuevo) async {
    String? motivo;
    if (nuevo == EstadoCita.cancelada) {
      motivo = await _pedirMotivo(context, 'Motivo de cancelación');
      if (motivo == null) return; // canceló el diálogo
    }

    await ref.read(citasProvider.notifier).actualizarCita(
          citaId: cita.id,
          estado: nuevo.value,
          motivoCancelacion: motivo,
        );
    await _cargarAuditoria();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Estado actualizado a: ${_estadoLabel(nuevo)}'),
        backgroundColor: AppTheme.accent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<String?> _pedirMotivo(BuildContext context, String titulo) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Escribe el motivo...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Confirmar')),
        ],
      ),
    );
  }

  String _estadoLabel(EstadoCita e) {
    switch (e) {
      case EstadoCita.agendada:     return 'Agendada';
      case EstadoCita.confirmada:   return 'Confirmada';
      case EstadoCita.enProgreso:   return 'En progreso';
      case EstadoCita.completada:   return 'Completada';
      case EstadoCita.cancelada:    return 'Cancelada';
      case EstadoCita.noAsistio:    return 'No asistió';
      case EstadoCita.reprogramada: return 'Reprogramada';
    }
  }
}

// ── WIDGETS ───────────────────────────────────────────────────────────────────

class _EstadoCard extends StatelessWidget {
  final Cita cita;
  final List<EstadoCita> estadosDisponibles;
  final bool puedeCambiar;
  final Function(EstadoCita) onCambiarEstado;

  const _EstadoCard({
    required this.cita,
    required this.estadosDisponibles,
    required this.puedeCambiar,
    required this.onCambiarEstado,
  });

  Color get _color {
    switch (cita.estado) {
      case EstadoCita.agendada:     return AppTheme.warning;
      case EstadoCita.confirmada:
      case EstadoCita.enProgreso:   return AppTheme.accent;
      case EstadoCita.completada:   return AppTheme.primary;
      case EstadoCita.cancelada:
      case EstadoCita.noAsistio:    return AppTheme.error;
      case EstadoCita.reprogramada: return AppTheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.h,
                decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
              ),
              SizedBox(width: 8.w),
              Text(
                cita.estadoLabel,
                style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: _color),
              ),
            ],
          ),
          if (puedeCambiar && estadosDisponibles.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text('Cambiar a:',
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: AppTheme.textGrey)),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: estadosDisponibles.map((e) {
                final c = _colorEstado(e);
                return GestureDetector(
                  onTap: () => onCambiarEstado(e),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: c.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _estadoLabel(e),
                      style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: c,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _colorEstado(EstadoCita e) {
    switch (e) {
      case EstadoCita.confirmada:   return AppTheme.accent;
      case EstadoCita.enProgreso:   return AppTheme.primary;
      case EstadoCita.completada:   return AppTheme.primary;
      case EstadoCita.cancelada:    return AppTheme.error;
      case EstadoCita.noAsistio:    return AppTheme.error;
      case EstadoCita.reprogramada: return AppTheme.secondary;
      default:                      return AppTheme.textGrey;
    }
  }

  String _estadoLabel(EstadoCita e) {
    switch (e) {
      case EstadoCita.confirmada:   return 'Confirmar';
      case EstadoCita.enProgreso:   return 'Iniciar sesión';
      case EstadoCita.completada:   return 'Completar';
      case EstadoCita.cancelada:    return 'Cancelar';
      case EstadoCita.noAsistio:    return 'No asistió';
      case EstadoCita.reprogramada: return 'Reprogramar';
      default:                      return e.value;
    }
  }
}

class _AuditoriaItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AuditoriaItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final fecha = data['fecha'] != null
        ? DateTime.tryParse(data['fecha'].toString())
        : null;
    final cambio   = data['cambio']?.toString()    ?? data['accion']?.toString() ?? '—';
    final usuario  = data['usuario']?.toString()   ?? data['realizado_por']?.toString() ?? '';
    final estadoAntes  = data['estado_antes']?.toString();
    final estadoDespues = data['estado_despues']?.toString();

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Column(children: [
            Container(
              width: 10.w,
              height: 10.h,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 1.w, height: 40.h, color: AppTheme.divider),
          ]),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cambio,
                    style: GoogleFonts.inter(
                        fontSize: 13.sp, fontWeight: FontWeight.w500)),
                if (estadoAntes != null && estadoDespues != null)
                  Row(children: [
                    _MiniChip(estadoAntes, AppTheme.textGrey),
                    Icon(Icons.arrow_forward,
                        size: 12.sp, color: AppTheme.textGrey),
                    _MiniChip(estadoDespues, AppTheme.primary),
                  ]),
                SizedBox(height: 2.h),
                Text(
                  '${usuario.isNotEmpty ? '$usuario · ' : ''}${fecha != null ? DateFormat('dd/MM/yy HH:mm').format(fecha) : ''}',
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniChip(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(right: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 10.sp, color: color, fontWeight: FontWeight.w500)),
      );
}

class _SeccionLabel extends StatelessWidget {
  final String text;
  const _SeccionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 8.h, left: 2.w),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textGrey,
                letterSpacing: 0.3)),
      );
}

class _Fila extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _Fila(this.icon, this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(children: [
          Icon(icon, size: 16.sp, color: AppTheme.primary),
          SizedBox(width: 10.w),
          SizedBox(
              width: 110.w,
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, color: AppTheme.textGrey))),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppTheme.textDark)),
          ),
        ]),
      );
}

// Helper de responsive para este screen
Widget _desktopWrap(BuildContext context, Widget child) {
  if (!context.isDesktop) return child;
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: child,
    ),
  );
}
