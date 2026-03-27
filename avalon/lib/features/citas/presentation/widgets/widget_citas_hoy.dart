import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/citas_provider.dart';
import '../../domain/cita.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/cita_ui_utils.dart';

class WidgetCitasHoy extends ConsumerWidget {
  const WidgetCitasHoy({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citasState = ref.watch(citasProvider);
    final citasHoy = citasState.citasHoy;

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
                  'Citas de hoy',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${citasHoy.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (citasState.cargando)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (citasState.error != null)
              Text(
                citasState.error!,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.error,
                ),
              )
            else if (citasHoy.isEmpty)
              Text(
                'Sin citas programadas hoy',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppTheme.textGrey,
                ),
              )
            else
              Column(
                children: citasHoy.take(4).map((cita) {
                  return _CitaHoyItem(cita: cita);
                }).toList(),
              ),
            if (citasHoy.length > 4)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  'Ver todas en Citas →',
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

class _CitaHoyItem extends StatelessWidget {
  final Cita cita;

  const _CitaHoyItem({required this.cita});

  @override
  Widget build(BuildContext context) {
    final estadoColor = cita.estado.color;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: estadoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                DateFormat('HH:mm').format(cita.fechaHora),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: estadoColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cita.pacienteNombre ?? cita.pacienteId,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'con ${cita.psicologoNombre ?? cita.psicologoId}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          _EstadoChip(estado: cita.estado),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final EstadoCita estado;

  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = estado.color;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        estado.label,
        style: GoogleFonts.inter(
          fontSize: 8.sp,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
