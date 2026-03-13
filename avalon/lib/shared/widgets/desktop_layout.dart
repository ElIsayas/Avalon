import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/presentation/providers/user_role_provider.dart';

class DesktopLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const DesktopLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  int _getSelectedIndex() {
    switch (currentRoute) {
      case '/dashboard':
        return 0;
      case '/pacientes':
        return 1;
      case '/citas':
        return 2;
      case '/evaluaciones':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _getSelectedIndex();
    final userRoleInfo = ref.watch(userRoleInfoProvider);
    
    return Scaffold(
      body: Row(
        children: [
          // LEFT SIDEBAR
          Container(
            width: 240.w,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                right: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Logo/Brand
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 32.w,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'AVALON',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    children: [
                      _buildSidebarItem(
                        context: context,
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        index: 0,
                        selectedIndex: selectedIndex,
                        route: '/dashboard',
                        shortcut: 'Ctrl+D',
                      ),
                      _buildSidebarItem(
                        context: context,
                        icon: Icons.people,
                        title: 'Pacientes',
                        index: 1,
                        selectedIndex: selectedIndex,
                        route: '/pacientes',
                        shortcut: 'Ctrl+P',
                      ),
                      _buildSidebarItem(
                        context: context,
                        icon: Icons.calendar_month,
                        title: 'Citas',
                        index: 2,
                        selectedIndex: selectedIndex,
                        route: '/citas',
                        shortcut: 'Ctrl+C',
                      ),
                      _buildSidebarItem(
                        context: context,
                        icon: Icons.assessment,
                        title: 'Evaluaciones',
                        index: 3,
                        selectedIndex: selectedIndex,
                        route: '/evaluaciones',
                        shortcut: 'Ctrl+E',
                      ),
                    ],
                  ),
                ),
                
                // Bottom section with shortcuts info
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atajos de Teclado',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      _buildShortcutItem('Ctrl+D', 'Dashboard'),
                      _buildShortcutItem('Ctrl+P', 'Pacientes'),
                      _buildShortcutItem('Ctrl+C', 'Citas'),
                      _buildShortcutItem('Ctrl+E', 'Evaluaciones'),
                      _buildShortcutItem('Ctrl+N', 'Nueva Cita'),
                      _buildShortcutItem('Ctrl+F', 'Buscar Paciente'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // TOP BAR + CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // TOP BAR
                Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 20.w),
                      Icon(
                        Icons.menu,
                        color: Colors.grey[600],
                        size: 20.w,
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          _getPageTitle(selectedIndex),
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getRoleColor(userRoleInfo['color']).withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: _getRoleColor(userRoleInfo['color']),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              userRoleInfo['icon'],
                              size: 16.w,
                              color: _getRoleColor(userRoleInfo['color']),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              userRoleInfo['displayName'],
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: _getRoleColor(userRoleInfo['color']),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 24.w),
                    ],
                  ),
                ),
                
                // CONTENT AREA
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required int selectedIndex,
    required String route,
    required String shortcut,
  }) {
    final isSelected = selectedIndex == index;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Material(
        color: isSelected ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => _navigateTo(context, route),
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.blue[800] : Colors.grey[600],
                  size: 24.w,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.blue[800] : Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        shortcut,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              shortcut,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (route) => false,
    );
  }

  String _getPageTitle(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Pacientes';
      case 2:
        return 'Citas';
      case 3:
        return 'Evaluaciones';
      default:
        return 'Avalon';
    }
  }

  Color _getRoleColor(String? colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
