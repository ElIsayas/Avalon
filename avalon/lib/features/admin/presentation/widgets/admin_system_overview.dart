import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/system_stats.dart';

class AdminSystemOverview extends StatelessWidget {
  final SystemStats stats;

  const AdminSystemOverview({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3498DB),
            const Color(0xFF2980B9),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3498DB).withValues(alpha:0.3),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: Colors.white,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Vista General del Sistema',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _OverviewItem(
                  label: 'Psicólogos',
                  value: stats.totalPsicologos.toString(),
                  icon: Icons.psychology,
                ),
              ),
              Container(
                width: 1,
                height: 60.h,
                color: Colors.white.withValues(alpha:0.3),
              ),
              Expanded(
                child: _OverviewItem(
                  label: 'Pacientes',
                  value: stats.totalPacientes.toString(),
                  icon: Icons.people,
                ),
              ),
              Container(
                width: 1,
                height: 60.h,
                color: Colors.white.withValues(alpha:0.3),
              ),
              Expanded(
                child: _OverviewItem(
                  label: 'Citas Hoy',
                  value: stats.citasHoy.toString(),
                  icon: Icons.calendar_today,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _OverviewItem(
                  label: 'Licencias Activas',
                  value: stats.licenciasActivas.toString(),
                  icon: Icons.verified,
                ),
              ),
              Container(
                width: 1,
                height: 60.h,
                color: Colors.white.withValues(alpha:0.3),
              ),
              Expanded(
                child: _OverviewItem(
                  label: 'Evaluaciones',
                  value: stats.totalEvaluaciones.toString(),
                  icon: Icons.assignment,
                ),
              ),
              Container(
                width: 1,
                height: 60.h,
                color: Colors.white.withValues(alpha:0.3),
              ),
              Expanded(
                child: _OverviewItem(
                  label: 'Notas',
                  value: stats.totalNotas.toString(),
                  icon: Icons.note,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'Última actualización: ${_formatDateTime(stats.lastUpdated)}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.white.withValues(alpha:0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _OverviewItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _OverviewItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24.sp,
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.white.withValues(alpha:0.9),
          ),
        ),
      ],
    );
  }
}
