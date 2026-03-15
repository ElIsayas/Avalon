import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/citas_provider.dart';
import '../../domain/cita.dart';
import '../../../../core/theme/app_theme.dart';

class WidgetCitasHoy extends ConsumerWidget {
  const WidgetCitasHoy({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citasHoy = ref.watch(citasProvider.select((state) => state.citasHoy));
    
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
                    color: AppTheme.primary.withOpacity(0.1),
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
            if (citasHoy.isEmpty)
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
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: _getEstadoColor(cita.estado).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                DateFormat('HH:mm').format(cita.fechaHora),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: _getEstadoColor(cita.estado),
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
                  cita.pacienteId,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'con ${cita.psicologoId}',
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

  Color _getEstadoColor(EstadoCita estado) {
    switch (estado) {
      case EstadoCita.agendada:
        return AppTheme.warning;
      case EstadoCita.confirmada:
      case EstadoCita.enProgreso:
        return AppTheme.accent;
      case EstadoCita.cancelada:
      case EstadoCita.noAsistio:
        return AppTheme.error;
      case EstadoCita.completada:
        return AppTheme.primary;
      case EstadoCita.reprogramada:
        return AppTheme.secondary;
    }
  }
}

class _EstadoChip extends StatelessWidget {
  final EstadoCita estado;

  const _EstadoChip({required this.estado});

  String _getEstadoLabel(EstadoCita estado) {
    switch (estado) {
      case EstadoCita.agendada: return 'Agendada';
      case EstadoCita.confirmada: return 'Confirmada';
      case EstadoCita.enProgreso: return 'En Progreso';
      case EstadoCita.completada: return 'Completada';
      case EstadoCita.cancelada: return 'Cancelada';
      case EstadoCita.noAsistio: return 'No Asistió';
      case EstadoCita.reprogramada: return 'Reprogramada';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.primary;
    switch (estado) {
      case EstadoCita.agendada:
        color = AppTheme.warning;
        break;
      case EstadoCita.confirmada:
      case EstadoCita.enProgreso:
        color = AppTheme.accent;
        break;
      case EstadoCita.cancelada:
      case EstadoCita.noAsistio:
        color = AppTheme.error;
        break;
      case EstadoCita.completada:
        color = AppTheme.primary;
        break;
      case EstadoCita.reprogramada:
        color = AppTheme.secondary;
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        _getEstadoLabel(estado),
        style: GoogleFonts.inter(
          fontSize: 8.sp,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
