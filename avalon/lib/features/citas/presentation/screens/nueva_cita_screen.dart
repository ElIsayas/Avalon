// lib/features/citas/presentation/screens/nueva_cita_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/cita.dart';
import '../providers/citas_provider.dart';

class NuevaCitaScreen extends ConsumerStatefulWidget {
  const NuevaCitaScreen({super.key});

  @override
  ConsumerState<NuevaCitaScreen> createState() => _NuevaCitaScreenState();
}

class _NuevaCitaScreenState extends ConsumerState<NuevaCitaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Campos del form
  String? _pacienteId;
  String? _pacienteNombre;
  String? _psicologoId;
  String? _psicologoNombre;
  DateTime _fechaHora = DateTime.now().add(const Duration(hours: 1));
  int _duracionMinutos = 50;
  ModalidadCita _modalidad = ModalidadCita.presencial;
  TipoSesion _tipoSesion = TipoSesion.seguimiento;
  String _estado = 'pendiente';
  final _notasCtrl = TextEditingController();
  bool _notificarSms = true;
  bool _notificarEmail = true;
  bool _recordatorio24h = true;
  bool _recordatorio1h = false;

  // Estado UI
  bool _guardando = false;
  String? _conflictoMsg;
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _psicologos = [];
  bool _cargandoDatos = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final client = Supabase.instance.client;
      // Cargar pacientes
      final resPacientes = await client.rpc('get_pacientes',
          params: {'p_token': user.sessionToken});
      // Cargar psicólogos
      final resPsicologos = await client.rpc('get_psicologos_org',
          params: {'p_token': user.sessionToken});

      setState(() {
        _pacientes = (resPacientes as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _psicologos = (resPsicologos as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _cargandoDatos = false;
      });
    } catch (e) {
      setState(() => _cargandoDatos = false);
    }
  }

  // ── Selector de paciente con búsqueda ────────────────────────────────────
  Future<void> _abrirSelectorPaciente() async {
    if (_pacientes.isEmpty) return;
    final seleccionado = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => _SelectorPacienteSheet(pacientes: _pacientes),
    );
    if (seleccionado != null) {
      setState(() {
        _pacienteId = seleccionado['id'].toString();
        _pacienteNombre = seleccionado['nombre'].toString();
      });
    }
  }

  Future<void> _verificarConflicto() async {
    if (_psicologoId == null) return;
    final msg = await ref.read(citasProvider.notifier).verificarConflicto(
          psicologoId: _psicologoId!,
          fechaHora: _fechaHora,
          duracionMinutos: _duracionMinutos,
        );
    setState(() => _conflictoMsg = msg);
  }

  Future<void> _seleccionarFechaHora() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaHora,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaHora),
    );
    if (hora == null || !mounted) return;

    setState(() {
      _fechaHora = DateTime(
          fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    });
    _verificarConflicto();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pacienteId == null || _psicologoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona paciente y psicólogo')));
      return;
    }
    if (_conflictoMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_conflictoMsg!)));
      return;
    }

    setState(() => _guardando = true);
    final error = await ref.read(citasProvider.notifier).crearCita(
          pacienteId:      _pacienteId!,
          psicologoId:     _psicologoId!,
          fechaHora:       _fechaHora,
          duracionMinutos: _duracionMinutos,
          estado:          _estado,
          modalidad:       _modalidad.toDb(),
          tipoSesion:      _tipoSesion.toDb(),
          notas:           _notasCtrl.text.isEmpty ? null : _notasCtrl.text,
          notificarSms:    _notificarSms,
          notificarEmail:  _notificarEmail,
          recordatorio24h: _recordatorio24h,
          recordatorio1h:  _recordatorio1h,
        );
    setState(() => _guardando = false);

    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cita agendada exitosamente'),
          backgroundColor: AppTheme.accent,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nueva cita'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _cargandoDatos
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Seccion('Datos de la cita'),
                    SizedBox(height: 12.h),

                    // ── Paciente ──────────────────────────────────────────
                    _Label('Paciente *'),
                    GestureDetector(
                      onTap: () => _abrirSelectorPaciente(),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.people, color: AppTheme.primary, size: 20.sp),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                _pacienteNombre ?? 'Toca para buscar paciente...',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: _pacienteNombre != null
                                      ? AppTheme.textDark
                                      : AppTheme.textGrey,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: AppTheme.textGrey, size: 20.sp),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // ── Psicólogo ─────────────────────────────────────────
                    _Label('Psicólogo/a *'),
                    DropdownButtonFormField<String>(
                      value: _psicologoId,
                      decoration: _inputDeco('Seleccionar psicólogo'),
                      items: _psicologos.map((p) => DropdownMenuItem(
                            value: p['id'].toString(),
                            child: Text(p['nombre'].toString(),
                                style: GoogleFonts.inter(fontSize: 14.sp)),
                          )).toList(),
                      validator: (v) => v == null ? 'Requerido' : null,
                      onChanged: (v) {
                        setState(() {
                          _psicologoId = v;
                          _psicologoNombre = _psicologos
                              .firstWhere((p) => p['id'].toString() == v)['nombre']
                              .toString();
                        });
                        _verificarConflicto();
                      },
                    ),
                    SizedBox(height: 12.h),

                    // ── Fecha y hora ──────────────────────────────────────
                    _Label('Fecha y hora *'),
                    GestureDetector(
                      onTap: _seleccionarFechaHora,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _conflictoMsg != null
                                ? AppTheme.error
                                : AppTheme.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.calendar_1,
                                color: AppTheme.primary, size: 20.sp),
                            SizedBox(width: 10.w),
                            Text(
                              DateFormat('EEEE d \'de\' MMMM, HH:mm', 'es')
                                  .format(_fechaHora),
                              style: GoogleFonts.inter(fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Advertencia de conflicto ───────────────────────────
                    if (_conflictoMsg != null) ...[
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                              color: AppTheme.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.warning_2,
                                color: AppTheme.error, size: 16.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _conflictoMsg!,
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp, color: AppTheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 12.h),

                    // ── Duración ──────────────────────────────────────────
                    _Label('Duración'),
                    DropdownButtonFormField<int>(
                      value: _duracionMinutos,
                      decoration: _inputDeco(''),
                      items: [30, 45, 50, 60, 90].map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d minutos',
                                style: GoogleFonts.inter(fontSize: 14.sp)),
                          )).toList(),
                      onChanged: (v) {
                        setState(() => _duracionMinutos = v ?? 50);
                        _verificarConflicto();
                      },
                    ),
                    SizedBox(height: 12.h),

                    // ── Tipo de sesión ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Tipo de sesión'),
                              DropdownButtonFormField<TipoSesion>(
                                value: _tipoSesion,
                                decoration: _inputDeco(''),
                                items: TipoSesion.values.map((t) =>
                                    DropdownMenuItem(
                                      value: t,
                                      child: Text(t.label,
                                          style: GoogleFonts.inter(
                                              fontSize: 13.sp)),
                                    )).toList(),
                                onChanged: (v) =>
                                    setState(() => _tipoSesion = v ?? TipoSesion.seguimiento),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Modalidad'),
                              DropdownButtonFormField<ModalidadCita>(
                                value: _modalidad,
                                decoration: _inputDeco(''),
                                items: ModalidadCita.values.map((m) =>
                                    DropdownMenuItem(
                                      value: m,
                                      child: Text(m.label,
                                          style: GoogleFonts.inter(
                                              fontSize: 13.sp)),
                                    )).toList(),
                                onChanged: (v) =>
                                    setState(() => _modalidad = v ?? ModalidadCita.presencial),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // ── Estado ────────────────────────────────────────────
                    _Label('Estado inicial'),
                    DropdownButtonFormField<String>(
                      value: _estado,
                      decoration: _inputDeco(''),
                      items: [
                        DropdownMenuItem(
                            value: 'pendiente',
                            child: Text('Pendiente de confirmación',
                                style: GoogleFonts.inter(fontSize: 13.sp))),
                        DropdownMenuItem(
                            value: 'confirmada',
                            child: Text('Confirmada directamente',
                                style: GoogleFonts.inter(fontSize: 13.sp))),
                      ],
                      onChanged: (v) => setState(() => _estado = v ?? 'pendiente'),
                    ),
                    SizedBox(height: 12.h),

                    // ── Notas ─────────────────────────────────────────────
                    _Label('Notas (opcional)'),
                    TextFormField(
                      controller: _notasCtrl,
                      maxLines: 3,
                      decoration: _inputDeco('Observaciones o instrucciones...'),
                    ),
                    SizedBox(height: 20.h),

                    // ── Notificaciones ────────────────────────────────────
                    _Seccion('Notificaciones al paciente'),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        children: [
                          _CheckItem(
                              value: _notificarEmail,
                              label: 'Email de confirmación',
                              onChanged: (v) =>
                                  setState(() => _notificarEmail = v)),
                          _CheckItem(
                              value: _notificarSms,
                              label: 'SMS de confirmación',
                              onChanged: (v) =>
                                  setState(() => _notificarSms = v)),
                          _CheckItem(
                              value: _recordatorio24h,
                              label: 'Recordatorio 24h antes',
                              onChanged: (v) =>
                                  setState(() => _recordatorio24h = v)),
                          _CheckItem(
                              value: _recordatorio1h,
                              label: 'Recordatorio 1h antes',
                              onChanged: (v) =>
                                  setState(() => _recordatorio1h = v)),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ── Botón guardar ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardando || _conflictoMsg != null
                            ? null
                            : _guardar,
                        child: _guardando
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text('Guardar cita',
                                style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(hintText: hint);
}

// ── Widgets auxiliares del form ───────────────────────────────────────────────

class _Seccion extends StatelessWidget {
  final String titulo;
  const _Seccion(this.titulo);

  @override
  Widget build(BuildContext context) {
    return Text(titulo,
        style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark));
  }
}

class _Label extends StatelessWidget {
  final String texto;
  const _Label(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(texto,
          style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textGrey)),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  const _CheckItem(
      {required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppTheme.primary),
        Text(label, style: GoogleFonts.inter(fontSize: 13.sp)),
      ],
    );
  }
}

// ── Selector de paciente: bottom sheet con búsqueda ──────────────────────────

class _SelectorPacienteSheet extends StatefulWidget {
  final List<Map<String, dynamic>> pacientes;
  const _SelectorPacienteSheet({required this.pacientes});

  @override
  State<_SelectorPacienteSheet> createState() => _SelectorPacienteSheetState();
}

class _SelectorPacienteSheetState extends State<_SelectorPacienteSheet> {
  final _busquedaCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtrados = [];

  @override
  void initState() {
    super.initState();
    _filtrados = widget.pacientes;
    _busquedaCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _filtrar() {
    final q = _busquedaCtrl.text.toLowerCase().trim();
    setState(() {
      _filtrados = q.isEmpty
          ? widget.pacientes
          : widget.pacientes.where((p) {
              final nombre = p['nombre']?.toString().toLowerCase() ?? '';
              final doc = p['numero_documento']?.toString().toLowerCase() ?? '';
              final email = p['email']?.toString().toLowerCase() ?? '';
              return nombre.contains(q) || doc.contains(q) || email.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Barra superior
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Text(
                  'Seleccionar paciente',
                  style: GoogleFonts.inter(
                      fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12.h),
                // Campo de búsqueda
                TextField(
                  controller: _busquedaCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, documento o email...',
                    hintStyle: GoogleFonts.inter(fontSize: 13.sp),
                    prefixIcon: Icon(Iconsax.search_normal, size: 18.sp),
                    suffixIcon: _busquedaCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _busquedaCtrl.clear();
                              _filtrar();
                            },
                          )
                        : null,
                  ),
                ),
                SizedBox(height: 8.h),
                // Contador de resultados
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_filtrados.length} paciente${_filtrados.length != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                        fontSize: 12.sp, color: AppTheme.textGrey),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista de resultados
          Expanded(
            child: _filtrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.people, size: 48.sp, color: AppTheme.textGrey),
                        SizedBox(height: 12.h),
                        Text('Sin resultados',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp, color: AppTheme.textGrey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollCtrl,
                    itemCount: _filtrados.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppTheme.divider),
                    itemBuilder: (ctx, i) {
                      final p = _filtrados[i];
                      final nombre = p['nombre']?.toString() ?? '';
                      final doc = p['numero_documento']?.toString() ?? '';
                      final email = p['email']?.toString() ?? '';
                      final telefono = p['telefono']?.toString();
                      final activo = p['activo'] as bool? ?? true;

                      return ListTile(
                        onTap: () => Navigator.pop(ctx, p),
                        leading: CircleAvatar(
                          radius: 20.r,
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(
                            _iniciales(nombre),
                            style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(nombre,
                                  style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500)),
                            ),
                            if (!activo)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text('Inactivo',
                                    style: GoogleFonts.inter(
                                        fontSize: 9.sp,
                                        color: AppTheme.error)),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (doc.isNotEmpty)
                              Text('Doc: $doc',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: AppTheme.textGrey)),
                            if (telefono != null)
                              Text(telefono,
                                  style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: AppTheme.textGrey)),
                            if (email.isNotEmpty && doc.isEmpty)
                              Text(email,
                                  style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: AppTheme.textGrey)),
                          ],
                        ),
                        trailing: Icon(Icons.chevron_right,
                            color: AppTheme.textGrey, size: 20.sp),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length >= 2 ? 2 : 1).toUpperCase();
  }
}