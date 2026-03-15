import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/citas_provider.dart';
import '../../domain/cita.dart';
import '../../../../core/theme/app_theme.dart';

class WidgetDisponibilidad extends ConsumerWidget {
  const WidgetDisponibilidad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disponibilidad = ref.watch(disponibilidadProvider);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disponibilidad',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 12.h),
            if (disponibilidad.isEmpty)
              Text(
                'No hay psicólogos disponibles',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppTheme.textGrey,
                ),
              )
            else
              Column(
                children: disponibilidad.take(4).map((psicologo) {
                  return _PsicologoDisponibilidadItem(psicologo: psicologo);
                }).toList(),
              ),
            if (disponibilidad.length > 4)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  'Ver todos en Psicólogos →',
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

class _PsicologoDisponibilidadItem extends StatelessWidget {
  final DisponibilidadPsicologo psicologo;

  const _PsicologoDisponibilidadItem({required this.psicologo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: psicologo.estaDisponible ? AppTheme.accent : AppTheme.warning,
            child: Text(
              psicologo.nombre.iniciales,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  psicologo.nombre,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
                if (psicologo.especialidad != null)
                  Text(
                    psicologo.especialidad!,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppTheme.textGrey,
                    ),
                  ),
                if (psicologo.proximaCita != null)
                  Text(
                    'Próxima: ${DateFormat('HH:mm').format(psicologo.proximaCita!)}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.textGrey,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: psicologo.estaDisponible ? AppTheme.accent : AppTheme.warning,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                psicologo.estaDisponible ? 'Libre' : 'Ocupado',
                style: GoogleFonts.inter(
                  fontSize: 8.sp,
                  color: psicologo.estaDisponible ? AppTheme.accent : AppTheme.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on String {
  String get iniciales {
    final partes = trim().split(' ');
    if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return substring(0, length >= 2 ? 2 : 1).toUpperCase();
  }
}
