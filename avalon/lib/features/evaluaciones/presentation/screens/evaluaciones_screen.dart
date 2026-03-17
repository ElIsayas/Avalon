import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../domain/evaluacion.dart';
import '../providers/evaluaciones_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'evaluacion_form_screen.dart';
import 'evaluacion_detalle_screen.dart';

class EvaluacionesScreen extends ConsumerStatefulWidget {
  final String? pacienteIdFiltro;
  final String? pacienteNombreFiltro;

  const EvaluacionesScreen({
    super.key,
    this.pacienteIdFiltro,
    this.pacienteNombreFiltro,
  });

  @override
  ConsumerState<EvaluacionesScreen> createState() => _EvaluacionesScreenState();
}

class _EvaluacionesScreenState extends ConsumerState<EvaluacionesScreen> {
  EscalaEvaluacion? _filtroEscala;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(evaluacionesProvider.notifier)
        .cargar(pacienteId: widget.pacienteIdFiltro));
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(evaluacionesProvider);
    final user    = ref.watch(currentUserProvider);
    final puedeCrear = user?.puedeEscribirNotas ?? false;

    var lista = state.evaluaciones;
    if (widget.pacienteIdFiltro != null) {
      lista = lista
          .where((e) => e.pacienteId == widget.pacienteIdFiltro)
          .toList();
    }
    if (_filtroEscala != null) {
      lista = lista.where((e) => e.escalaEnum == _filtroEscala).toList();
    }

    // Snackbars
    ref.listen(evaluacionesProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.successMessage!),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(evaluacionesProvider.notifier).clearMessages();
      }
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(evaluacionesProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pacienteNombreFiltro != null
            ? 'Evaluaciones · ${widget.pacienteNombreFiltro}'
            : context.t.evaluaciones),
        automaticallyImplyLeading: widget.pacienteIdFiltro != null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(evaluacionesProvider.notifier)
                .cargar(pacienteId: widget.pacienteIdFiltro),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _Chip('Todas', null, _filtroEscala,
                    (v) => setState(() => _filtroEscala = v)),
                ...EscalaEvaluacion.values
                    .where((e) => e != EscalaEvaluacion.personalizada)
                    .map((e) => _Chip(e.nombre, e, _filtroEscala,
                        (v) => setState(() => _filtroEscala = v))),
              ]),
            ),
          ),
        ),
      ),
      body: _desktopWrap(
        context,
        state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : lista.isEmpty
              ? _Empty(
                  puedeCrear: puedeCrear,
                  onCrear: () => _crearEvaluacion(),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(evaluacionesProvider.notifier)
                      .cargar(pacienteId: widget.pacienteIdFiltro),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.r),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => _EvaluacionCard(
                      ev: lista[i],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EvaluacionDetalleScreen(evaluacion: lista[i]))),
                      onEliminar: puedeCrear
                          ? () => _confirmarEliminar(lista[i])
                          : null,
                    ),
                  ),
                ),
      ),
      floatingActionButton: puedeCrear
          ? FloatingActionButton.extended(
              onPressed: _crearEvaluacion,
              icon: const Icon(Icons.add_chart),
              label: Text(context.t.nuevaEvaluacion),
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _crearEvaluacion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluacionFormScreen(
          pacienteIdInicial: widget.pacienteIdFiltro,
          pacienteNombreInicial: widget.pacienteNombreFiltro,
        ),
      ),
    ).then((_) => ref
        .read(evaluacionesProvider.notifier)
        .cargar(pacienteId: widget.pacienteIdFiltro));
  }

  void _confirmarEliminar(Evaluacion ev) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evaluación'),
        content: Text(
            '¿Eliminar esta evaluación ${ev.escalaEnum.nombre} de '
            '${ev.pacienteNombre ?? ev.pacienteId}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(evaluacionesProvider.notifier).eliminar(ev.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── WIDGETS ───────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final EscalaEvaluacion? value;
  final EscalaEvaluacion? selected;
  final ValueChanged<EscalaEvaluacion?> onTap;

  const _Chip(this.label, this.value, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () => onTap(sel ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? AppTheme.accent : Colors.white)),
      ),
    );
  }
}

class _EvaluacionCard extends StatelessWidget {
  final Evaluacion ev;
  final VoidCallback onTap;
  final VoidCallback? onEliminar;

  const _EvaluacionCard(
      {required this.ev, required this.onTap, this.onEliminar});

  Color get _severidadColor {
    final nivel = ev.nivelSeveridad;
    if (nivel == 'Mínima' || nivel == 'Leve') return AppTheme.accent;
    if (nivel == 'Moderada') return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final maxPts = ev.escalaEnum.puntuacionMax;
    final pct    = maxPts > 0
        ? (ev.puntuacionTotal / maxPts).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
              Row(children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(ev.escalaEnum.nombre,
                      style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent)),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    ev.pacienteNombre ?? ev.pacienteId,
                    style: GoogleFonts.inter(
                        fontSize: 13.sp, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onEliminar != null)
                  GestureDetector(
                    onTap: onEliminar,
                    child: Icon(Icons.delete_outline,
                        size: 18.sp, color: AppTheme.textGrey),
                  ),
              ]),
              SizedBox(height: 10.h),

              // Puntuación + barra de progreso
              Row(children: [
                Text('${ev.puntuacionTotal}',
                    style: GoogleFonts.inter(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: _severidadColor)),
                if (maxPts < 999) ...[
                  Text(' / $maxPts',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, color: AppTheme.textGrey)),
                ],
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _severidadColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(ev.nivelSeveridad,
                      style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: _severidadColor)),
                ),
              ]),

              if (maxPts < 999) ...[
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6.h,
                    backgroundColor: AppTheme.divider,
                    valueColor: AlwaysStoppedAnimation(_severidadColor),
                  ),
                ),
              ],

              SizedBox(height: 8.h),
              Row(children: [
                Icon(Iconsax.clock, size: 12.sp, color: AppTheme.textGrey),
                SizedBox(width: 4.w),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(ev.fechaCreacion),
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: AppTheme.textGrey),
                ),
                if (ev.observaciones != null) ...[
                  SizedBox(width: 12.w),
                  Icon(Icons.notes_outlined, size: 12.sp, color: AppTheme.textGrey),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

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
                style: GoogleFonts.inter(
                    fontSize: 18.sp, color: AppTheme.textGrey)),
            SizedBox(height: 8.h),
            Text('Registra la primera con el botón +',
                style: GoogleFonts.inter(
                    fontSize: 13.sp, color: AppTheme.textGrey)),
            if (puedeCrear) ...[
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: onCrear,
                icon: const Icon(Icons.add_chart),
                label: Text(context.t.nuevaEvaluacion),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent),
              ),
            ],
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
