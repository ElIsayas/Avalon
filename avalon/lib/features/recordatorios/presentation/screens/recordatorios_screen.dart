import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../providers/recordatorios_provider.dart';
import '../../domain/recordatorio_ex.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/usuarios/presentation/providers/usuarios_org_provider.dart';

class RecordatoriosScreen extends ConsumerStatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  ConsumerState<RecordatoriosScreen> createState() =>
      _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends ConsumerState<RecordatoriosScreen> {
  CategoriaRecordatorio? _filtroCategoria;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(recordatoriosExProvider.notifier).cargar();
      ref.read(usuariosOrgProvider.notifier).cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(recordatoriosExProvider);
    final user    = ref.watch(currentUserProvider);
    final esAdmin = user?.puedeGestionarUsuarios ?? false;

    var lista = state.recordatorios;
    if (_filtroCategoria != null) {
      lista = lista.where((r) => r.categoria == _filtroCategoria).toList();
    }

    // Snackbars
    ref.listen(recordatoriosExProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.successMessage!),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(recordatoriosExProvider.notifier).clearMessages();
      }
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(recordatoriosExProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(context.t.recordatorios),
            if (state.countUrgentes > 0) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text('${state.countUrgentes} urgentes',
                    style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Toggle mostrar resueltos
          IconButton(
            icon: Icon(state.mostrarResueltos
                ? Icons.check_circle
                : Icons.check_circle_outline),
            tooltip: state.mostrarResueltos
                ? 'Ocultar resueltos'
                : 'Mostrar resueltos',
            onPressed: () =>
                ref.read(recordatoriosExProvider.notifier).toggleMostrarResueltos(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(recordatoriosExProvider.notifier).cargar(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CatChip('Todos', null, _filtroCategoria,
                      (v) => setState(() => _filtroCategoria = v)),
                  ...CategoriaRecordatorio.values.map((c) => _CatChip(
                        c.label, c, _filtroCategoria,
                        (v) => setState(() => _filtroCategoria = v),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _desktopWrap(
        context,
        state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : lista.isEmpty
              ? _EmptyState(onCrear: () => _showCrearDialog())
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(recordatoriosExProvider.notifier).cargar(),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.r),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => _RecordatorioCard(
                      rec: lista[i],
                      esAdmin: esAdmin,
                      onResolver: () =>
                          ref.read(recordatoriosExProvider.notifier)
                              .resolver(lista[i].id),
                      onEliminar: esAdmin
                          ? () => ref
                              .read(recordatoriosExProvider.notifier)
                              .eliminar(lista[i].id)
                          : null,
                    ),
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCrearDialog,
        icon: const Icon(Icons.add_alarm),
        label: Text(context.t.nuevoRecordatorio),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCrearDialog() {
    final usuarios = ref.read(usuariosOrgProvider).usuarios;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => _FormRecordatorio(
        usuarios: usuarios,
        currentUserId: ref.read(currentUserProvider)?.id ?? '',
        onGuardar: (datos) async {
          final ok = await ref.read(recordatoriosExProvider.notifier).crear(
                titulo:           datos.titulo,
                descripcion:      datos.descripcion,
                prioridad:        datos.prioridad,
                categoria:        datos.categoria,
                asignadoA:        datos.asignadoA,
                fechaVencimiento: datos.fechaVencimiento,
              );
          if (ok && mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

// ── WIDGETS ───────────────────────────────────────────────────────────────────

class _CatChip extends StatelessWidget {
  final String label;
  final CategoriaRecordatorio? value;
  final CategoriaRecordatorio? selected;
  final ValueChanged<CategoriaRecordatorio?> onTap;

  const _CatChip(this.label, this.value, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(isSelected ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppTheme.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _RecordatorioCard extends StatelessWidget {
  final RecordatorioEx rec;
  final bool esAdmin;
  final VoidCallback onResolver;
  final VoidCallback? onEliminar;

  const _RecordatorioCard({
    required this.rec,
    required this.esAdmin,
    required this.onResolver,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final color = rec.prioridadColor;
    final vencido = rec.estaVencido;
    final venceHoy = rec.venceHoy;

    return AnimatedOpacity(
      opacity: rec.resuelto ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        margin: EdgeInsets.only(bottom: 10.h),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Franja de color de prioridad
              Container(
                width: 4.w,
                decoration: BoxDecoration(
                  color: rec.resuelto ? AppTheme.textGrey : color,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    bottomLeft: Radius.circular(12.r),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila 1: Categoría + prioridad + estado
                      Row(
                        children: [
                          _BadgeCategoria(rec.categoria),
                          SizedBox(width: 6.w),
                          if (vencido && !rec.resuelto)
                            _BadgeVencido()
                          else if (venceHoy && !rec.resuelto)
                            _BadgeHoy(),
                          const Spacer(),
                          if (!rec.resuelto)
                            _BadgePrioridad(rec.prioridad, color)
                          else
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text('Resuelto',
                                  style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // Título
                      Text(
                        rec.titulo,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          decoration: rec.resuelto
                              ? TextDecoration.lineThrough
                              : null,
                          color: rec.resuelto
                              ? AppTheme.textGrey
                              : AppTheme.textDark,
                        ),
                      ),

                      // Descripción
                      if (rec.descripcion != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          rec.descripcion!,
                          style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: AppTheme.textGrey,
                              height: 1.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 8.h),

                      // Footer: creado por, asignado a, vencimiento
                      Row(
                        children: [
                          Icon(Iconsax.clock, size: 11.sp, color: AppTheme.textGrey),
                          SizedBox(width: 3.w),
                          Text(
                            _tiempoRelativo(rec.fechaRegistro),
                            style: GoogleFonts.inter(
                                fontSize: 10.sp, color: AppTheme.textGrey),
                          ),
                          if (rec.fechaVencimiento != null) ...[
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.alarm,
                              size: 11.sp,
                              color: vencido ? AppTheme.error : AppTheme.textGrey,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              DateFormat('dd/MM/yy').format(rec.fechaVencimiento!),
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: vencido ? AppTheme.error : AppTheme.textGrey,
                                fontWeight: vencido ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                          if (rec.asignadoANombre != null) ...[
                            SizedBox(width: 8.w),
                            Icon(Iconsax.user, size: 11.sp, color: AppTheme.primary),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                rec.asignadoANombre!,
                                style: GoogleFonts.inter(
                                    fontSize: 10.sp, color: AppTheme.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            const Spacer(),

                          // Acciones
                          if (!rec.resuelto)
                            GestureDetector(
                              onTap: onResolver,
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check,
                                    size: 14.sp, color: AppTheme.accent),
                              ),
                            ),
                          if (onEliminar != null) ...[
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: onEliminar,
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.delete_outline,
                                    size: 14.sp, color: AppTheme.error),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tiempoRelativo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inDays > 0) return 'Hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes}m';
    return 'Ahora';
  }
}

class _BadgeCategoria extends StatelessWidget {
  final CategoriaRecordatorio cat;
  const _BadgeCategoria(this.cat);

  Color get _color {
    switch (cat) {
      case CategoriaRecordatorio.paciente: return AppTheme.primary;
      case CategoriaRecordatorio.admin:    return const Color(0xFFD97706);
      case CategoriaRecordatorio.cita:     return AppTheme.secondary;
      case CategoriaRecordatorio.tarea:    return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(cat.label,
            style: GoogleFonts.inter(
                fontSize: 10.sp, color: _color, fontWeight: FontWeight.w600)),
      );
}

class _BadgePrioridad extends StatelessWidget {
  final String prioridad;
  final Color color;
  const _BadgePrioridad(this.prioridad, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          prioridad == 'urgente' ? '🔴 Urgente' :
          prioridad == 'normal'  ? '🟡 Normal' : '🟢 Baja',
          style: GoogleFonts.inter(
              fontSize: 10.sp, color: color, fontWeight: FontWeight.w600),
        ),
      );
}

class _BadgeVencido extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text('⚠ Vencido',
            style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.error,
                fontWeight: FontWeight.w600)),
      );
}

class _BadgeHoy extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text('⏰ Hoy',
            style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.warning,
                fontWeight: FontWeight.w600)),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCrear;
  const _EmptyState({required this.onCrear});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.notification,
                size: 72.sp,
                color: AppTheme.textGrey.withValues(alpha: 0.3)),
            SizedBox(height: 16.h),
            Text(context.t.sinRecordatorios,
                style: GoogleFonts.inter(
                    fontSize: 16.sp, color: AppTheme.textGrey)),
            SizedBox(height: 8.h),
            Text('Crea uno con el botón +',
                style: GoogleFonts.inter(
                    fontSize: 13.sp, color: AppTheme.textGrey)),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add_alarm),
              label: Text(context.t.nuevoRecordatorio),
            ),
          ],
        ),
      );
}

// ── Formulario de creación ────────────────────────────────────────────────────

class _FormData {
  final String titulo;
  final String? descripcion;
  final String prioridad;
  final CategoriaRecordatorio categoria;
  final String? asignadoA;
  final DateTime? fechaVencimiento;

  const _FormData({
    required this.titulo,
    this.descripcion,
    required this.prioridad,
    required this.categoria,
    this.asignadoA,
    this.fechaVencimiento,
  });
}

class _FormRecordatorio extends StatefulWidget {
  final List<dynamic> usuarios;
  final String currentUserId;
  final Future<void> Function(_FormData) onGuardar;

  const _FormRecordatorio({
    required this.usuarios,
    required this.currentUserId,
    required this.onGuardar,
  });

  @override
  State<_FormRecordatorio> createState() => _FormRecordatorioState();
}

class _FormRecordatorioState extends State<_FormRecordatorio> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  String _prioridad = 'normal';
  CategoriaRecordatorio _categoria = CategoriaRecordatorio.tarea;
  String? _asignadoA;
  DateTime? _fechaVenc;
  bool _guardando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20.w, right: 20.w, top: 20.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40.w, height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            Text(context.t.nuevoRecordatorio,
                style: GoogleFonts.inter(
                    fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),

            // Título
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título *',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            SizedBox(height: 12.h),

            // Descripción
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 12.h),

            // Prioridad
            DropdownButtonFormField<String>(
              value: _prioridad,
              decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  prefixIcon: Icon(Icons.flag_outlined)),
              items: const [
                DropdownMenuItem(value: 'baja',    child: Text('🟢 Baja')),
                DropdownMenuItem(value: 'normal',  child: Text('🟡 Normal')),
                DropdownMenuItem(value: 'urgente', child: Text('🔴 Urgente')),
              ],
              onChanged: (v) => setState(() => _prioridad = v!),
            ),
            SizedBox(height: 12.h),

            // Categoría
            DropdownButtonFormField<CategoriaRecordatorio>(
              value: _categoria,
              decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined)),
              items: CategoriaRecordatorio.values
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            SizedBox(height: 12.h),

            // Asignar a (si hay usuarios cargados)
            if (widget.usuarios.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _asignadoA,
                decoration: const InputDecoration(
                    labelText: 'Asignar a (opcional)',
                    prefixIcon: Icon(Icons.person_outline)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...widget.usuarios.map((u) => DropdownMenuItem(
                        value: u.id as String,
                        child: Text(u.nombre as String),
                      )),
                ],
                onChanged: (v) => setState(() => _asignadoA = v),
              ),
              SizedBox(height: 12.h),
            ],

            // Fecha de vencimiento
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _fechaVenc = picked);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.alarm, color: AppTheme.primary, size: 20.sp),
                    SizedBox(width: 10.w),
                    Text(
                      _fechaVenc != null
                          ? 'Vence: ${DateFormat('dd/MM/yyyy').format(_fechaVenc!)}'
                          : 'Fecha de vencimiento (opcional)',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: _fechaVenc != null
                            ? AppTheme.textDark
                            : AppTheme.textGrey,
                      ),
                    ),
                    const Spacer(),
                    if (_fechaVenc != null)
                      GestureDetector(
                        onTap: () => setState(() => _fechaVenc = null),
                        child: Icon(Icons.close,
                            size: 18.sp, color: AppTheme.textGrey),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Botón
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Crear recordatorio'),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_tituloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El título es obligatorio')));
      return;
    }
    setState(() => _guardando = true);
    await widget.onGuardar(_FormData(
      titulo:           _tituloCtrl.text.trim(),
      descripcion:      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      prioridad:        _prioridad,
      categoria:        _categoria,
      asignadoA:        _asignadoA,
      fechaVencimiento: _fechaVenc,
    ));
    setState(() => _guardando = false);
  }
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
