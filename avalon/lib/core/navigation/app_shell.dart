import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../navigation/nav_provider.dart';
import '../layout/responsive.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/pacientes/presentation/screens/pacientes_screen.dart';
import '../../features/citas/presentation/screens/citas_screen.dart';
import '../../features/notas/presentation/screens/notas_screen.dart';
import '../../features/configuracion/presentation/screens/configuracion_screen.dart';
import '../../features/recordatorios/presentation/providers/recordatorios_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../i18n/app_strings.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = <Widget>[
    DashboardScreen(),
    PacientesScreen(),
    CitasScreen(),
    NotasScreen(),
    ConfiguracionScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return context.isDesktop
        ? const _DesktopShell(screens: _screens)
        : const _MobileShell(screens: _screens);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOBILE SHELL — BottomNavigationBar (igual que antes)
// ═══════════════════════════════════════════════════════════════════════════
class _MobileShell extends ConsumerWidget {
  final List<Widget> screens;
  const _MobileShell({required this.screens});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);
    final pendientes = ref.watch(recordatoriosExProvider.select(
      (s) => s.recordatorios.where((r) => !r.resuelto).length,
    ));

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: _MobileBottomBar(
        currentIndex: currentIndex,
        badgeCount: pendientes,
        onTap: (i) => ref.read(navProvider.notifier).goTo(AppTab.values[i]),
      ),
    );
  }
}

class _MobileBottomBar extends StatelessWidget {
  final int currentIndex, badgeCount;
  final ValueChanged<int> onTap;
  const _MobileBottomBar(
      {required this.currentIndex,
      required this.badgeCount,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(top: BorderSide(color: AppTheme.divider)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MobileNavItem(
                  icon: Iconsax.home_2,
                  activeIcon: Iconsax.home_25,
                  label: context.t.inicio,
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _MobileNavItem(
                  icon: Iconsax.people,
                  activeIcon: Iconsax.people5,
                  label: context.t.pacientes,
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _MobileNavItem(
                  icon: Iconsax.calendar_2,
                  activeIcon: Iconsax.calendar_25,
                  label: context.t.citas,
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  badge: badgeCount > 0 ? badgeCount : null),
              _MobileNavItem(
                  icon: Iconsax.note,
                  activeIcon: Iconsax.note_25,
                  label: context.t.notas,
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _MobileNavItem(
                  icon: Iconsax.setting_2,
                  activeIcon: Iconsax.setting_25,
                  label: context.t.config,
                  index: 4,
                  currentIndex: currentIndex,
                  onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, currentIndex;
  final ValueChanged<int> onTap;
  final int? badge;

  const _MobileNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final color = isActive ? AppTheme.primary : AppTheme.textGrey;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(clipBehavior: Clip.none, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: isActive
                      ? BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        )
                      : null,
                  child: Icon(isActive ? activeIcon : icon,
                      color: color, size: 22.sp),
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: EdgeInsets.all(3.r),
                      decoration: const BoxDecoration(
                          color: AppTheme.error, shape: BoxShape.circle),
                      constraints:
                          BoxConstraints(minWidth: 16.w, minHeight: 16.h),
                      child: Text(badge! > 9 ? '9+' : '$badge',
                          style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ),
                  ),
              ]),
              SizedBox(height: 2.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: color),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DESKTOP SHELL — Sidebar + contenido principal
// ═══════════════════════════════════════════════════════════════════════════
class _DesktopShell extends ConsumerWidget {
  final List<Widget> screens;
  const _DesktopShell({required this.screens});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);
    final user = ref.watch(currentUserProvider);
    final pendientes = ref.watch(recordatoriosExProvider.select(
      (s) => s.recordatorios.where((r) => !r.resuelto).length,
    ));

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────
          _DesktopSidebar(
            currentIndex: currentIndex,
            badgeCount: pendientes,
            userName: user?.displayName ?? '',
            userRole: user?.rolLabel ?? '',
            userInitials: user?.iniciales ?? '?',
            onTap: (i) => ref.read(navProvider.notifier).goTo(AppTab.values[i]),
            onLogout: () => ref.read(authProvider.notifier).signOut(),
          ),
          // ── Divisor ────────────────────────────────────────────────
          const VerticalDivider(width: 1, color: AppTheme.divider),
          // ── Contenido ─────────────────────────────────────────────
          Expanded(
            child: IndexedStack(index: currentIndex, children: screens),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int currentIndex, badgeCount;
  final String userName, userRole, userInitials;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.badgeCount,
    required this.userName,
    required this.userRole,
    required this.userInitials,
    required this.onTap,
    required this.onLogout,
  });

  static const _items = [
    (Iconsax.home_2, Iconsax.home_25, 'Inicio', 0),
    (Iconsax.people, Iconsax.people5, 'Pacientes', 1),
    (Iconsax.calendar_2, Iconsax.calendar_25, 'Citas', 2),
    (Iconsax.note, Iconsax.note_25, 'Notas', 3),
    (Iconsax.setting_2, Iconsax.setting_25, 'Config', 4),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2A) : Colors.white;

    return Container(
      width: kSidebarWidth,
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo / marca ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.psychology, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Avalon',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary)),
            ]),
          ),
          const Divider(height: 16),

          // ── Perfil compacto ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Text(userInitials,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text(userRole,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppTheme.textGrey)),
                ],
              )),
            ]),
          ),
          const Divider(height: 16),

          // ── Items de navegación ──────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: _items.map((item) {
                final (icon, activeIcon, label, index) = item;
                final isActive = currentIndex == index;
                final hasBadge = index == 2 && badgeCount > 0;

                return InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isActive
                          ? Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.2))
                          : null,
                    ),
                    child: Row(children: [
                      Icon(isActive ? activeIcon : icon,
                          size: 20,
                          color:
                              isActive ? AppTheme.primary : AppTheme.textGrey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(label,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? AppTheme.primary
                                    : AppTheme.textGrey)),
                      ),
                      if (hasBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$badgeCount',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Cerrar sesión ────────────────────────────────────────
          const Divider(height: 1),
          InkWell(
            onTap: onLogout,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(children: [
                const Icon(Iconsax.logout, size: 18, color: AppTheme.error),
                const SizedBox(width: 12),
                Text(context.t.cerrarSesion,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
