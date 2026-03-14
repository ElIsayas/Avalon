import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pacientes/presentation/screens/pacientes_screen.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avalon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¡Bienvenido!',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14.sp)),
                  SizedBox(height: 4.h),
                  Text(user?.displayName ?? '',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      user?.isAdmin == true ? '👑 Administrador' : '🧠 Psicólogo',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text('Módulos',
                style: GoogleFonts.inter(
                    fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            SizedBox(height: 12.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.1,
              children: [
                _ModuloCard(
                  icon: Icons.people,
                  label: 'Pacientes',
                  color: AppTheme.primary,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PacientesScreen())),
                ),
                _ModuloCard(icon: Icons.calendar_today, label: 'Citas',
                    color: AppTheme.secondary, onTap: () {}, disabled: true),
                _ModuloCard(icon: Icons.note_alt, label: 'Notas',
                    color: AppTheme.warning, onTap: () {}, disabled: true),
                _ModuloCard(icon: Icons.assessment, label: 'Evaluaciones',
                    color: AppTheme.accent, onTap: () {}, disabled: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuloCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool disabled;
  const _ModuloCard({required this.icon, required this.label, required this.color,
      required this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: disabled
                      ? AppTheme.textGrey.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: disabled ? AppTheme.textGrey : color, size: 28.sp),
              ),
              SizedBox(height: 10.h),
              Text(label, style: GoogleFonts.inter(
                  fontSize: 13.sp, fontWeight: FontWeight.w600,
                  color: disabled ? AppTheme.textGrey : AppTheme.textDark)),
              if (disabled)
                Text('Próximamente',
                    style: GoogleFonts.inter(fontSize: 10.sp, color: AppTheme.textGrey)),
            ],
          ),
        ),
      ),
    );
  }
}
