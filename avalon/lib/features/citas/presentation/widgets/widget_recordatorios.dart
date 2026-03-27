import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../recordatorios/domain/recordatorio_ex.dart';
import '../../../recordatorios/presentation/providers/recordatorios_provider.dart';
import '../../../../core/theme/app_theme.dart';

class WidgetRecordatorios extends ConsumerWidget {
  const WidgetRecordatorios({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordatoriosExProvider);
    final recordatorios =
        state.recordatorios.where((r) => !r.resuelto).toList();
    final tieneUrgentes = recordatorios.any((r) => r.prioridad == 'urgente');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recordatorios',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Row(
                  children: [
                    if (tieneUrgentes)
                      Container(
                        width: 8.w,
                        height: 8.h,
                        margin: EdgeInsets.only(right: 8.w),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${recordatorios.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (state.error != null)
              Text(
                state.error!,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.error,
                ),
              )
            else if (recordatorios.isEmpty)
              Text(
                'No hay recordatorios activos',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppTheme.textGrey,
                ),
              )
            else
              Column(
                children: recordatorios.take(3).map((recordatorio) {
                  return _RecordatorioItem(recordatorio: recordatorio);
                }).toList(),
              ),
            if (recordatorios.length > 3)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  'Ver todos en Recordatorios ->',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordatorioItem extends StatelessWidget {
  final RecordatorioEx recordatorio;

  const _RecordatorioItem({required this.recordatorio});

  @override
  Widget build(BuildContext context) {
    final color = recordatorio.prioridadColor;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.w,
            height: 8.h,
            margin: EdgeInsets.only(top: 6.h),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recordatorio.titulo,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
                if (recordatorio.descripcion != null)
                  Text(
                    recordatorio.descripcion!,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppTheme.textGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 2.h),
                Text(
                  'Creado por ${recordatorio.creadoPorNombre ?? recordatorio.creadoPor} - ${_tiempoRelativo(recordatorio.fechaRegistro)}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tiempoRelativo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays > 0) return 'Hace ${diferencia.inDays} dias';
    if (diferencia.inHours > 0) return 'Hace ${diferencia.inHours} horas';
    if (diferencia.inMinutes > 0) return 'Hace ${diferencia.inMinutes} minutos';
    return 'Hace unos momentos';
  }
}
