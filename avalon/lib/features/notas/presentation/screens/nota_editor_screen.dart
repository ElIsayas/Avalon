import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/nota_terapia.dart';
import '../providers/notas_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class NotaEditorScreen extends ConsumerStatefulWidget {
  final NotaTerapia? nota; // null = crear, not null = editar

  const NotaEditorScreen({super.key, this.nota});

  @override
  ConsumerState<NotaEditorScreen> createState() => _NotaEditorScreenState();
}

class _NotaEditorScreenState extends ConsumerState<NotaEditorScreen> {
  final _contenidoCtrl = TextEditingController();
  TipoNota _tipo       = TipoNota.sesion;

  // Selector de paciente
  String? _pacienteId;
  String? _pacienteNombre;
  List<Map<String, dynamic>> _pacientes = [];
  bool _cargandoPacientes = true;

  // Modo edición solo cuando la nota tiene un id real (no vacío)
  bool get _esEdicion => widget.nota != null && widget.nota!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      // Modo edición — cargar datos existentes
      final n = widget.nota!;
      _contenidoCtrl.text = n.contenido;
      _tipo               = n.tipo;
      _pacienteId         = n.pacienteId;
      _pacienteNombre     = n.pacienteNombre ?? n.pacienteId;
      _cargandoPacientes  = false;
    } else if (widget.nota != null && widget.nota!.pacienteId.isNotEmpty) {
      // Modo crear con paciente pre-seleccionado desde historial
      _pacienteId         = widget.nota!.pacienteId;
      _pacienteNombre     = widget.nota!.pacienteNombre ?? widget.nota!.pacienteId;
      _tipo               = widget.nota!.tipo;
      _cargandoPacientes  = false;
    } else {
      _cargarPacientes();
    }
  }

  @override
  void dispose() {
    _contenidoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPacientes() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .rpc('get_pacientes', params: {'p_token': user.sessionToken});
      setState(() {
        _pacientes = (res as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _cargandoPacientes = false;
      });
    } catch (_) {
      setState(() => _cargandoPacientes = false);
    }
  }

  Future<void> _abrirSelectorPaciente() async {
    if (_pacientes.isEmpty) return;
    final sel = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => _SelectorPacienteSheet(pacientes: _pacientes),
    );
    if (sel != null) {
      setState(() {
        _pacienteId     = sel['id'].toString();
        _pacienteNombre = sel['nombre'].toString();
      });
    }
  }

  Future<void> _guardar() async {
    if (_contenidoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('El contenido no puede estar vacío')));
      return;
    }

    bool ok;
    if (_esEdicion) {
      ok = await ref.read(notasProvider.notifier).actualizar(
            notaId:    widget.nota!.id,
            contenido: _contenidoCtrl.text,
            tipo:      _tipo,
          );
    } else {
      if (_pacienteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecciona un paciente')));
        return;
      }
      ok = await ref.read(notasProvider.notifier).crear(
            pacienteId: _pacienteId!,
            contenido:  _contenidoCtrl.text,
            tipo:       _tipo,
          );
    }

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar nota' : 'Nueva nota'),
        actions: [
          if (state.isSaving)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _guardar,
              child: Text(
                _esEdicion ? 'Guardar' : 'Crear',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _desktopWrap(
        context,
        _cargandoPacientes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Paciente (solo al crear) ───────────────────────────
                  if (!_esEdicion) ...[
                    _Label('Paciente *'),
                    GestureDetector(
                      onTap: _abrirSelectorPaciente,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.people,
                                color: AppTheme.primary, size: 20.sp),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                _pacienteNombre ??
                                    'Toca para seleccionar paciente...',
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
                    SizedBox(height: 16.h),
                  ],

                  // ── Tipo de nota ───────────────────────────────────────
                  _Label('Tipo de nota'),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: TipoNota.values.map((t) {
                      final sel = _tipo == t;
                      return GestureDetector(
                        onTap: () => setState(() => _tipo = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 7.h),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.primary
                                : AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.primary
                                  : AppTheme.primary
                                      .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            t.label,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: sel ? Colors.white : AppTheme.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16.h),

                  // ── Contenido ──────────────────────────────────────────
                  _Label('Contenido de la nota *'),
                  SizedBox(height: 6.h),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: TextField(
                      controller: _contenidoCtrl,
                      maxLines: null,
                      minLines: 12,
                      keyboardType: TextInputType.multiline,
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, height: 1.6),
                      decoration: InputDecoration(
                        hintText:
                            'Escribe aquí las observaciones, avances, y conclusiones de la sesión...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 14.sp, color: AppTheme.textGrey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Contador de caracteres
                  Align(
                    alignment: Alignment.centerRight,
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _contenidoCtrl,
                      builder: (_, val, __) => Text(
                        '${val.text.length} caracteres',
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: AppTheme.textGrey),
                      ),
                    ),
                  ),

                  // ── Error ──────────────────────────────────────────────
                  if (state.error != null) ...[
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(state.error!,
                          style: TextStyle(
                              color: AppTheme.error, fontSize: 13.sp)),
                    ),
                  ],
                  SizedBox(height: 32.h),

                  // ── Botón guardar ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: state.isSaving ? null : _guardar,
                      child: state.isSaving
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : Text(
                              _esEdicion ? 'Guardar cambios' : 'Crear nota'),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.textGrey,
        ),
      );
}

// ── Selector de paciente ──────────────────────────────────────────────────────

class _SelectorPacienteSheet extends StatefulWidget {
  final List<Map<String, dynamic>> pacientes;
  const _SelectorPacienteSheet({required this.pacientes});

  @override
  State<_SelectorPacienteSheet> createState() => _SelectorPacienteSheetState();
}

class _SelectorPacienteSheetState extends State<_SelectorPacienteSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _filtrados = [];

  @override
  void initState() {
    super.initState();
    _filtrados = widget.pacientes;
    _ctrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _filtrar() {
    final q = _ctrl.text.toLowerCase().trim();
    setState(() {
      _filtrados = q.isEmpty
          ? widget.pacientes
          : widget.pacientes.where((p) {
              final nombre = p['nombre']?.toString().toLowerCase() ?? '';
              final doc    = p['numero_documento']?.toString().toLowerCase() ?? '';
              return nombre.contains(q) || doc.contains(q);
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
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Column(
              children: [
                Container(
                  width: 40.w, height: 4.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Text('Seleccionar paciente',
                    style: GoogleFonts.inter(
                        fontSize: 16.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 12.h),
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o documento...',
                    prefixIcon:
                        Icon(Icons.search, size: 18.sp),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              itemCount: _filtrados.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppTheme.divider),
              itemBuilder: (ctx, i) {
                final p = _filtrados[i];
                return ListTile(
                  onTap: () => Navigator.pop(ctx, p),
                  leading: CircleAvatar(
                    radius: 18.r,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      _iniciales(p['nombre']?.toString() ?? ''),
                      style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary),
                    ),
                  ),
                  title: Text(p['nombre']?.toString() ?? '',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, fontWeight: FontWeight.w500)),
                  subtitle: Text(p['numero_documento']?.toString() ?? '',
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, color: AppTheme.textGrey)),
                  trailing: Icon(Icons.chevron_right,
                      color: AppTheme.textGrey, size: 18.sp),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _iniciales(String nombre) {
    final p = nombre.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return nombre.substring(0, nombre.length >= 2 ? 2 : 1).toUpperCase();
  }
}

Widget _desktopWrap(BuildContext context, Widget child) {
  if (!context.isDesktop) return child;
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: child,
    ),
  );
}
