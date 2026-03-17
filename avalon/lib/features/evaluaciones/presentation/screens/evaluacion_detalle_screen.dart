import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/evaluacion.dart';
import '../providers/evaluaciones_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/layout/responsive.dart';

class EvaluacionDetalleScreen extends ConsumerWidget {
  final Evaluacion evaluacion;

  const EvaluacionDetalleScreen({super.key, required this.evaluacion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener otras evaluaciones del mismo paciente + escala para tendencia
    final todas = ref.watch(evaluacionesProvider).evaluaciones;
    final historial = todas
        .where((e) =>
            e.pacienteId == evaluacion.pacienteId &&
            e.escala     == evaluacion.escala)
        .toList()
      ..sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));

    final dummy = evaluacion;
    final severidad = dummy.nivelSeveridad;
    final Color sevColor;
    switch (severidad) {
      case 'Mínima': case 'Leve': sevColor = AppTheme.accent;  break;
      case 'Moderada':            sevColor = AppTheme.warning; break;
      default:                    sevColor = AppTheme.error;
    }

    final items = kItemsEscalas[evaluacion.escala] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${evaluacion.escalaEnum.nombre} — Resultado'),
      ),
      body: ResponsiveBody(
        maxWidth: 720,
        child: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera resultado ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: sevColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: sevColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Text('${evaluacion.puntuacionTotal}',
                      style: GoogleFonts.inter(
                          fontSize: 52.sp,
                          fontWeight: FontWeight.bold,
                          color: sevColor)),
                  Text(
                    evaluacion.escalaEnum.puntuacionMax < 999
                        ? 'de ${evaluacion.escalaEnum.puntuacionMax} puntos'
                        : 'puntos',
                    style: GoogleFonts.inter(
                        fontSize: 13.sp, color: AppTheme.textGrey),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: sevColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(severidad,
                        style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: sevColor)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Metadatos ──────────────────────────────────────────────
            Card(
              child: Padding(
                padding: EdgeInsets.all(14.r),
                child: Column(children: [
                  _Fila('Paciente',
                      evaluacion.pacienteNombre ?? evaluacion.pacienteId),
                  _Fila('Escala',
                      '${evaluacion.escalaEnum.nombre} — ${evaluacion.escalaEnum.descripcion}'),
                  _Fila('Fecha',
                      DateFormat('dd/MM/yyyy HH:mm').format(evaluacion.fechaCreacion)),
                  if (evaluacion.observaciones != null)
                    _Fila('Observaciones', evaluacion.observaciones!),
                ]),
              ),
            ),
            SizedBox(height: 16.h),

            // ── Tendencia histórica ───────────────────────────────────
            if (historial.length > 1) ...[
              Text('Tendencia — ${evaluacion.escalaEnum.nombre}',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: _GraficaTendencia(
                  historial: historial,
                  actual: evaluacion,
                  maxPts: evaluacion.escalaEnum.puntuacionMax,
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // ── Respuestas ─────────────────────────────────────────────
            if (items.isNotEmpty) ...[
              Text('Respuestas detalladas',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              ...items.map((item) {
                final respuesta = evaluacion.respuestas['${item.numero}'];
                final valor = respuesta is int
                    ? respuesta
                    : int.tryParse(respuesta?.toString() ?? '') ?? -1;
                final opcion = valor >= 0 && valor < item.opciones.length
                    ? item.opciones[valor]
                    : 'No respondida';
                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24.w, height: 24.h,
                        decoration: BoxDecoration(
                          color: sevColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${item.numero}',
                              style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: sevColor)),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.pregunta,
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: AppTheme.textGrey,
                                    height: 1.4)),
                            SizedBox(height: 4.h),
                            Row(children: [
                              Text(opcion,
                                  style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500)),
                              if (valor >= 0) ...[
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: _puntColor(valor)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text('$valor',
                                      style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                          color: _puntColor(valor))),
                                ),
                              ],
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
      ),
    );
  }

  Color _puntColor(int v) {
    if (v == 0) return AppTheme.accent;
    if (v == 1) return AppTheme.warning;
    return AppTheme.error;
  }
}

// ── Tendencia de puntuaciones ─────────────────────────────────────────────────
class _GraficaTendencia extends StatelessWidget {
  final List<Evaluacion> historial;
  final Evaluacion actual;
  final int maxPts;

  const _GraficaTendencia({
    required this.historial,
    required this.actual,
    required this.maxPts,
  });

  @override
  Widget build(BuildContext context) {
    final max = maxPts < 999 ? maxPts.toDouble() : 30.0;
    return SizedBox(
      height: 80.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: historial.map((ev) {
          final ratio = (ev.puntuacionTotal / max).clamp(0.0, 1.0);
          final h     = (ratio * 60.h).clamp(4.0, 60.h);
          final isActual = ev.id == actual.id;
          final Color c;
          final nivel = ev.nivelSeveridad;
          if (nivel == 'Mínima' || nivel == 'Leve') c = AppTheme.accent;
          else if (nivel == 'Moderada')              c = AppTheme.warning;
          else                                       c = AppTheme.error;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${ev.puntuacionTotal}',
                    style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: isActual ? FontWeight.bold : FontWeight.normal,
                        color: isActual ? c : AppTheme.textGrey)),
                SizedBox(height: 2.h),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: h,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    color: isActual ? c : c.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                    border: isActual ? Border.all(color: c, width: 2) : null,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(DateFormat('d/M').format(ev.fechaCreacion),
                    style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        color: isActual ? c : AppTheme.textGrey,
                        fontWeight: isActual ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String label, value;
  const _Fila(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 100.w,
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12.sp, color: AppTheme.textGrey))),
            Expanded(
                child: Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 13.sp, fontWeight: FontWeight.w500))),
          ],
        ),
      );
}
