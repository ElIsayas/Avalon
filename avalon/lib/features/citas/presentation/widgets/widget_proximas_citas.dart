import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/citas_provider.dart';
import '../../domain/cita.dart';
import '../../../../core/theme/app_theme.dart';

class WidgetProximasCitas extends ConsumerWidget {
  const WidgetProximasCitas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proximasCitas = ref.watch(citasProvider.select((state) => state.proximasCitasPsicologo));
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis próximas citas',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 12.h),
            if (proximasCitas.isEmpty)
              Text(
                'No tienes próximas citas',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppTheme.textGrey,
                ),
              )
            else
              Column(
                children: proximasCitas.take(3).map((cita) {
                  return _ProximaCitaItem(cita: cita);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProximaCitaItem extends StatelessWidget {
  final Cita cita;

  const _ProximaCitaItem({required this.cita});

  @override
  Widget build(BuildContext context) {
    final esHoy = cita.esHoy;
    final esManana = _esManana(cita.fechaHora);
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(cita.fechaHora),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    DateFormat('MMM', 'es').format(cita.fechaHora).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('HH:mm').format(cita.fechaHora),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (esHoy)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'HOY',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent,
                            ),
                          ),
                        )
                      else if (esManana)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'MAÑANA',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warning,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    cita.pacienteId,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${cita.tipoSesion.label} • ${cita.modalidad.label}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _esManana(DateTime fecha) {
    final ahora = DateTime.now();
    final manana = DateTime(ahora.year, ahora.month, ahora.day + 1);
    return fecha.year == manana.year && 
           fecha.month == manana.month && 
           fecha.day == manana.day;
  }
}
