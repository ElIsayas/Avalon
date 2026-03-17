import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/paciente.dart';
import '../providers/paciente_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/notas/presentation/screens/notas_screen.dart';
import '../../../../features/notas/presentation/screens/nota_editor_screen.dart';
import '../../../../features/notas/presentation/providers/notas_provider.dart';
import '../../../../features/notas/domain/nota_terapia.dart';
import '../../../../features/citas/domain/cita.dart';
import 'paciente_form.dart';

// ── Provider de historia clínica ──────────────────────────────────────────────
final historiaClinicaProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, pacienteId) async {
  final token = ref.read(currentUserProvider)?.sessionToken ?? '';
  final res = await Supabase.instance.client
      .rpc('get_historia_clinica', params: {
    'p_token': token,
    'p_paciente_id': pacienteId,
  });
  return Map<String, dynamic>.from(res as Map);
});

class PacienteDetalleScreen extends ConsumerStatefulWidget {
  final Paciente paciente;

  const PacienteDetalleScreen({super.key, required this.paciente});

  @override
  ConsumerState<PacienteDetalleScreen> createState() =>
      _PacienteDetalleScreenState();
}

class _PacienteDetalleScreenState
    extends ConsumerState<PacienteDetalleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    // Cargar notas del paciente
    Future.microtask(() =>
        ref.read(notasProvider.notifier).cargarDespaciente(widget.paciente.id));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user           = ref.watch(currentUserProvider);
    final puedeEditar    = user?.puedeEliminarPacientes ?? false;
    final puedeEscribir  = user?.puedeEscribirNotas ?? false;
    final historiaAsync  = ref.watch(historiaClinicaProvider(widget.paciente.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paciente.nombre,
            overflow: TextOverflow.ellipsis),
        actions: [
          if (puedeEditar)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PacienteForm(paciente: widget.paciente)),
              ).then((_) => ref.invalidate(
                  historiaClinicaProvider(widget.paciente.id))),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Resumen',  icon: Icon(Icons.person_outline, size: 16)),
            Tab(text: 'Notas',    icon: Icon(Icons.note_outlined, size: 16)),
            Tab(text: 'Citas',    icon: Icon(Icons.calendar_today_outlined, size: 16)),
            Tab(text: 'Ficha',    icon: Icon(Icons.medical_information_outlined, size: 16)),
          ],
        ),
      ),
      body: historiaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          mensaje: e.toString(),
          onRetry: () => ref.invalidate(
              historiaClinicaProvider(widget.paciente.id)),
        ),
        data: (historia) => TabBarView(
          controller: _tabs,
          children: [
            _ResumenTab(paciente: widget.paciente, historia: historia),
            _NotasTab(
              pacienteId: widget.paciente.id,
              puedeEscribir: puedeEscribir,
            ),
            _CitasTab(historia: historia),
            _FichaTab(
              paciente: widget.paciente,
              historia: historia,
              puedeEditar: puedeEditar,
              onActualizar: (ficha) =>
                  _actualizarFicha(context, ref, widget.paciente.id, ficha),
            ),
          ],
        ),
      ),
      floatingActionButton: puedeEscribir && _tabs.index == 1
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NotaEditorScreen(
                          nota: NotaTerapia(
                            id: '',
                            pacienteId: widget.paciente.id,
                            psicologoId: '',
                            contenido: '',
                            tipo: TipoNota.sesion,
                            firmada: false,
                            fechaCreacion: DateTime.now(),
                            fechaActualizacion: DateTime.now(),
                            pacienteNombre: widget.paciente.nombre,
                          ),
                        )),
              ).then((_) =>
                  ref.read(notasProvider.notifier)
                      .cargarDespaciente(widget.paciente.id)),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _actualizarFicha(BuildContext context, WidgetRef ref,
      String pacienteId, Map<String, dynamic> ficha) async {
    try {
      final token = ref.read(currentUserProvider)?.sessionToken ?? '';
      await Supabase.instance.client.rpc('actualizar_ficha_clinica', params: {
        'p_token':      token,
        'p_paciente_id': pacienteId,
        ...ficha,
      });
      ref.invalidate(historiaClinicaProvider(pacienteId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ficha clínica actualizada'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB RESUMEN
// ═══════════════════════════════════════════════════════════════════════════════

class _ResumenTab extends StatelessWidget {
  final Paciente paciente;
  final Map<String, dynamic> historia;

  const _ResumenTab({required this.paciente, required this.historia});

  @override
  Widget build(BuildContext context) {
    final totalNotas   = (historia['total_notas']   as num?)?.toInt()   ?? 0;
    final resumenCitas = historia['resumen_citas']  as Map<String, dynamic>? ?? {};
    final totalCitas   = (resumenCitas['total']     as num?)?.toInt()   ?? 0;
    final proximaCita  = resumenCitas['proxima'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + datos básicos
          _TarjetaPerfil(paciente: paciente),
          SizedBox(height: 16.h),

          // Stats rápidas
          Row(
            children: [
              _StatMini('Citas', totalCitas.toString(),
                  Icons.calendar_today, AppTheme.primary),
              SizedBox(width: 12.w),
              _StatMini('Notas', totalNotas.toString(),
                  Icons.note, AppTheme.warning),
              SizedBox(width: 12.w),
              _StatMini('Activo', paciente.activo ? 'Sí' : 'No',
                  Icons.person, AppTheme.accent),
            ],
          ),
          SizedBox(height: 16.h),

          // Próxima cita
          if (proximaCita != null) ...[
            _SeccionLabel('Próxima cita'),
            _CitaResumenCard(
                data: proximaCita as Map<String, dynamic>, esProxima: true),
            SizedBox(height: 12.h),
          ],

          // Datos de contacto
          _SeccionLabel('Datos de contacto'),
          Card(
            child: Padding(
              padding: EdgeInsets.all(14.r),
              child: Column(
                children: [
                  _InfoFila(Iconsax.sms, 'Email', paciente.email),
                  if (paciente.telefono != null)
                    _InfoFila(Iconsax.call, 'Teléfono', paciente.telefono!),
                  if (paciente.direccion != null)
                    _InfoFila(
                        Iconsax.location, 'Dirección', paciente.direccion!),
                  if (paciente.fechaNacimiento != null)
                    _InfoFila(
                        Iconsax.cake,
                        'Nacimiento',
                        DateFormat('dd/MM/yyyy')
                            .format(paciente.fechaNacimiento!)),
                  _InfoFila(Iconsax.card, 'Documento',
                      paciente.numeroDocumento),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPerfil extends StatelessWidget {
  final Paciente paciente;
  const _TarjetaPerfil({required this.paciente});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30.r,
              backgroundColor: paciente.activo
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : AppTheme.textGrey.withValues(alpha: 0.12),
              child: Text(
                paciente.iniciales,
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: paciente.activo
                      ? AppTheme.primary
                      : AppTheme.textGrey,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paciente.nombre,
                    style: GoogleFonts.inter(
                        fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: paciente.activo
                              ? AppTheme.accent.withValues(alpha: 0.12)
                              : AppTheme.textGrey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          paciente.activo ? 'Activo' : 'Inactivo',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: paciente.activo
                                ? AppTheme.accent
                                : AppTheme.textGrey,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Desde ${DateFormat('MMM yyyy', 'es').format(paciente.fechaRegistro)}',
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                  if (paciente.objetivosTerapeuticos != null) ...[
                    SizedBox(height: 6.h),
                    Text(
                      paciente.objetivosTerapeuticos!,
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, color: AppTheme.textGrey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB NOTAS
// ═══════════════════════════════════════════════════════════════════════════════

class _NotasTab extends ConsumerWidget {
  final String pacienteId;
  final bool puedeEscribir;

  const _NotasTab({required this.pacienteId, required this.puedeEscribir});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notasProvider);
    final notas = state.notas
        .where((n) => n.pacienteId == pacienteId)
        .toList();

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.note, size: 64.sp,
                color: AppTheme.textGrey.withValues(alpha: 0.3)),
            SizedBox(height: 12.h),
            Text('Sin notas aún',
                style:
                    GoogleFonts.inter(fontSize: 16.sp, color: AppTheme.textGrey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: notas.length,
      itemBuilder: (_, i) {
        final n = notas[i];
        return Card(
          margin: EdgeInsets.only(bottom: 10.h),
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            leading: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.note_outlined,
                  color: AppTheme.primary, size: 18.sp),
            ),
            title: Text(
              n.tipo.label,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 13.sp),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                Text(
                  n.contenido,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, color: AppTheme.textGrey),
                ),
                SizedBox(height: 4.h),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(n.fechaCreacion),
                  style: GoogleFonts.inter(
                      fontSize: 10.sp, color: AppTheme.textGrey),
                ),
              ],
            ),
            trailing: n.firmada
                ? Icon(Icons.verified, color: AppTheme.accent, size: 16.sp)
                : null,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB CITAS
// ═══════════════════════════════════════════════════════════════════════════════

class _CitasTab extends StatelessWidget {
  final Map<String, dynamic> historia;

  const _CitasTab({required this.historia});

  @override
  Widget build(BuildContext context) {
    final citas = (historia['citas'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (citas.isEmpty) {
      return Center(
        child: Text('Sin citas registradas',
            style: GoogleFonts.inter(
                fontSize: 16.sp, color: AppTheme.textGrey)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: citas.length,
      itemBuilder: (_, i) => _CitaHistorialCard(data: citas[i]),
    );
  }
}

class _CitaHistorialCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CitaHistorialCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final fecha  = DateTime.tryParse(data['fecha_hora'].toString());
    final estado = data['estado']?.toString() ?? 'agendada';

    final Color estadoColor;
    switch (estado) {
      case 'completada':  estadoColor = AppTheme.primary;   break;
      case 'confirmada':  estadoColor = AppTheme.accent;    break;
      case 'cancelada':   estadoColor = AppTheme.error;     break;
      case 'no_asistio':  estadoColor = AppTheme.error;     break;
      default:            estadoColor = AppTheme.warning;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: fecha != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('dd').format(fecha),
                            style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: estadoColor)),
                        Text(
                            DateFormat('MMM', 'es')
                                .format(fecha)
                                .toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 9.sp, color: estadoColor)),
                      ],
                    )
                  : Icon(Icons.calendar_today,
                      color: estadoColor, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['tipo_sesion']?.toString() ?? 'Sesión',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 13.sp),
                  ),
                  if (fecha != null)
                    Text(
                      DateFormat('HH:mm').format(fecha),
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, color: AppTheme.textGrey),
                    ),
                  if (data['psicologo_nombre'] != null)
                    Text(
                      data['psicologo_nombre'].toString(),
                      style: GoogleFonts.inter(
                          fontSize: 11.sp, color: AppTheme.textGrey),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                estado.replaceAll('_', ' '),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: estadoColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB FICHA CLÍNICA
// ═══════════════════════════════════════════════════════════════════════════════

class _FichaTab extends StatefulWidget {
  final Paciente paciente;
  final Map<String, dynamic> historia;
  final bool puedeEditar;
  final Future<void> Function(Map<String, dynamic>) onActualizar;

  const _FichaTab({
    required this.paciente,
    required this.historia,
    required this.puedeEditar,
    required this.onActualizar,
  });

  @override
  State<_FichaTab> createState() => _FichaTabState();
}

class _FichaTabState extends State<_FichaTab> {
  bool _editando = false;
  late final TextEditingController _motivoCtrl;
  late final TextEditingController _diagnosticoCtrl;
  late final TextEditingController _objetivosCtrl;
  late final TextEditingController _antecedentesCtrl;
  late final TextEditingController _medicacionCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // El RPC get_historia_clinica devuelve los campos clínicos dentro de 'paciente'
    final ficha = (widget.historia['paciente'] as Map<String, dynamic>?) ?? {};
    _motivoCtrl      = TextEditingController(text: ficha['motivo_consulta_inicial']?.toString() ?? '');
    _diagnosticoCtrl = TextEditingController(text: ficha['diagnostico_principal']?.toString() ?? '');
    _objetivosCtrl   = TextEditingController(
        text: ficha['objetivos_terapeuticos']?.toString() ?? widget.paciente.objetivosTerapeuticos ?? '');
    _antecedentesCtrl = TextEditingController(text: ficha['antecedentes_personales']?.toString() ?? '');
    _medicacionCtrl  = TextEditingController(text: ficha['medicacion_actual']?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in [_motivoCtrl, _diagnosticoCtrl, _objetivosCtrl,
        _antecedentesCtrl, _medicacionCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    await widget.onActualizar({
      'p_motivo_consulta_inicial': _motivoCtrl.text.trim(),
      'p_diagnostico_principal':   _diagnosticoCtrl.text.trim(),
      'p_objetivos_terapeuticos':  _objetivosCtrl.text.trim(),
      'p_antecedentes_personales': _antecedentesCtrl.text.trim(),
      'p_medicacion_actual':       _medicacionCtrl.text.trim(),
    });
    setState(() { _guardando = false; _editando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Historial médico del paciente
          if (widget.paciente.historialMedico != null) ...[
            _SeccionLabel('Historial médico'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(14.r),
                child: Text(
                  widget.paciente.historialMedico!,
                  style: GoogleFonts.inter(fontSize: 13.sp, height: 1.6),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Ficha clínica editable
          Row(
            children: [
              Expanded(child: _SeccionLabel('Ficha clínica')),
              if (widget.puedeEditar)
                TextButton.icon(
                  onPressed: _editando
                      ? (_guardando ? null : _guardar)
                      : () => setState(() => _editando = true),
                  icon: _guardando
                      ? SizedBox(
                          width: 14.w, height: 14.h,
                          child: const CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_editando ? Icons.save_outlined : Icons.edit_outlined,
                          size: 16.sp),
                  label: Text(_editando ? 'Guardar' : 'Editar'),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          _CampoFicha('Motivo de consulta',    _motivoCtrl,      _editando),
          _CampoFicha('Diagnóstico',           _diagnosticoCtrl, _editando),
          _CampoFicha('Objetivos terapéuticos', _objetivosCtrl,  _editando),
          _CampoFicha('Antecedentes',          _antecedentesCtrl, _editando),
          _CampoFicha('Medicación actual',     _medicacionCtrl,  _editando),
          if (_editando)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: TextButton(
                onPressed: () => setState(() => _editando = false),
                child: const Text('Cancelar'),
              ),
            ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _CampoFicha extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool editando;

  const _CampoFicha(this.label, this.ctrl, this.editando);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: editando
          ? TextField(
              controller: ctrl,
              maxLines: null,
              minLines: 2,
              decoration: InputDecoration(
                labelText: label,
                alignLabelWithHint: true,
              ),
            )
          : ctrl.text.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textGrey)),
                    SizedBox(height: 4.h),
                    Text(ctrl.text,
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, height: 1.6)),
                  ],
                ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS COMUNES
// ═══════════════════════════════════════════════════════════════════════════════

class _CitaResumenCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool esProxima;

  const _CitaResumenCard({required this.data, this.esProxima = false});

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.tryParse(data['fecha_hora'].toString());
    return Card(
      child: ListTile(
        leading: Icon(
          esProxima ? Iconsax.calendar_tick : Iconsax.calendar_2,
          color: esProxima ? AppTheme.accent : AppTheme.primary,
          size: 22.sp,
        ),
        title: fecha != null
            ? Text(
                DateFormat('EEEE d \'de\' MMMM, HH:mm', 'es').format(fecha),
                style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500),
              )
            : const Text('—'),
        subtitle: data['tipo_sesion'] != null
            ? Text(data['tipo_sesion'].toString(),
                style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.textGrey))
            : null,
      ),
    );
  }
}

class _SeccionLabel extends StatelessWidget {
  final String texto;
  const _SeccionLabel(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 8.h, left: 2.w),
        child: Text(texto,
            style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textGrey,
                letterSpacing: 0.3)),
      );
}

class _StatMini extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatMini(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18.sp),
            SizedBox(height: 4.h),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 18.sp, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: GoogleFonts.inter(fontSize: 10.sp, color: AppTheme.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _InfoFila extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _InfoFila(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: AppTheme.primary),
          SizedBox(width: 10.w),
          SizedBox(
            width: 90.w,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12.sp, color: AppTheme.textGrey)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13.sp, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const _ErrorView({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 48.sp),
            SizedBox(height: 12.h),
            Text('Error cargando historial',
                style: GoogleFonts.inter(fontSize: 15.sp)),
            SizedBox(height: 4.h),
            Text(mensaje,
                style: GoogleFonts.inter(
                    fontSize: 12.sp, color: AppTheme.textGrey),
                textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
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
