import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class DesktopLayout2 extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const DesktopLayout2({
    super.key,
    required this.child,
    this.currentRoute = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (left panel)
          Container(
            width: 250.w,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                right: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1.w,
                ),
              ),
            ),
            child: Column(
              children: [
                // Logo/Brand
                Container(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 32.w,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Avalon',
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                // Navigation menu
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      _buildNavItem(
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        route: '/dashboard',
                        isSelected: currentRoute == '/dashboard',
                      ),
                      _buildNavItem(
                        icon: Icons.people,
                        title: 'Mis Pacientes',
                        route: '/mis-pacientes',
                        isSelected: currentRoute == '/mis-pacientes',
                      ),
                      _buildNavItem(
                        icon: Icons.calendar_today,
                        title: 'Citas',
                        route: '/citas',
                        isSelected: currentRoute == '/citas',
                      ),
                      _buildNavItem(
                        icon: Icons.assessment,
                        title: 'Evaluaciones',
                        route: '/evaluaciones',
                        isSelected: currentRoute == '/evaluaciones',
                      ),
                      _buildNavItem(
                        icon: Icons.description,
                        title: 'Reportes',
                        route: '/reportes',
                        isSelected: currentRoute == '/reportes',
                      ),
                      _buildNavItem(
                        icon: Icons.settings,
                        title: 'Configuración',
                        route: '/settings',
                        isSelected: currentRoute == '/settings',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: () {
            // Navigate to route
          },
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20.w,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: isSelected ? Colors.blue : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
