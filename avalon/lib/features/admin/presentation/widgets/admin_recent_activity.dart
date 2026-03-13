import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminRecentActivity extends StatelessWidget {
  const AdminRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actividad Reciente',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              TextButton(
                onPressed: () {
                  // NOTE: View all activity
                },
                child: Text(
                  'Ver todo',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF3498DB),
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    final activities = [
      _ActivityItem(
        icon: Icons.person_add,
        title: 'Nuevo psicólogo registrado',
        description: 'Dr. Juan Pérez se unió al equipo',
        time: 'Hace 2 horas',
        color: Colors.green,
      ),
      _ActivityItem(
        icon: Icons.calendar_today,
        title: 'Nueva cita agendada',
        description: 'Cita para paciente María García',
        time: 'Hace 3 horas',
        color: Colors.blue,
      ),
      _ActivityItem(
        icon: Icons.assessment,
        title: 'Evaluación completada',
        description: 'Test de ansiedad para paciente',
        time: 'Hace 5 horas',
        color: Colors.orange,
      ),
      _ActivityItem(
        icon: Icons.note,
        title: 'Nota de terapia añadida',
        description: 'Sesión con paciente Carlos López',
        time: 'Ayer',
        color: Colors.purple,
      ),
    ];

    return Column(
      children: activities.map((activity) => _ActivityCard(activity: activity)).toList(),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _ActivityItem activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  activity.description,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.time,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final String title;
  final String description;
  final String time;
  final Color color;

  _ActivityItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.color,
  });
}
