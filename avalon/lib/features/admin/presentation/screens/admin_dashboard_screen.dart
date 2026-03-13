import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_quick_actions.dart';
import '../widgets/admin_recent_activity.dart';
import '../widgets/admin_system_overview.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadSystemStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 28.sp),
            SizedBox(width: 12.w),
            Text(
              'Panel de Administración',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'General'),
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.business), text: 'Licencias'),
            Tab(icon: Icon(Icons.analytics), text: 'Estadísticas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(adminProvider.notifier).loadSystemStats();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(adminState),
          _buildUsersTab(adminState),
          _buildLicensesTab(adminState),
          _buildStatsTab(adminState),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AdminState adminState) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Overview
          AdminSystemOverview(stats: adminState.systemStats),
          SizedBox(height: 24.h),
          
          // Quick Actions
          AdminQuickActions(),
          SizedBox(height: 24.h),
          
          // Recent Activity
          AdminRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildUsersTab(AdminState adminState) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Usuarios',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateUserDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // User Stats Cards
          Row(
            children: [
              Expanded(
                child: AdminStatsCard(
                  title: 'Psicólogos',
                  value: adminState.systemStats.totalPsicologos.toString(),
                  icon: Icons.psychology,
                  color: const Color(0xFF3498DB),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: AdminStatsCard(
                  title: 'Pacientes',
                  value: adminState.systemStats.totalPacientes.toString(),
                  icon: Icons.people,
                  color: const Color(0xFF27AE60),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Users List
          _buildUsersList(),
        ],
      ),
    );
  }

  Widget _buildLicensesTab(AdminState adminState) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Licencias',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateLicenseDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Licencia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // License Stats
          Row(
            children: [
              Expanded(
                child: AdminStatsCard(
                  title: 'Licencias Activas',
                  value: adminState.systemStats.licenciasActivas.toString(),
                  icon: Icons.verified,
                  color: const Color(0xFF27AE60),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: AdminStatsCard(
                  title: 'Licencias Vencidas',
                  value: adminState.systemStats.licenciasVencidas.toString(),
                  icon: Icons.error,
                  color: const Color(0xFFE74C3C),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Licenses List
          _buildLicensesList(),
        ],
      ),
    );
  }

  Widget _buildStatsTab(AdminState adminState) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas del Sistema',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 24.h),
          
          // Detailed Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 1.5,
            children: [
              AdminStatsCard(
                title: 'Citas Hoy',
                value: adminState.systemStats.citasHoy.toString(),
                icon: Icons.calendar_today,
                color: const Color(0xFF3498DB),
              ),
              AdminStatsCard(
                title: 'Citas Semana',
                value: adminState.systemStats.citasSemana.toString(),
                icon: Icons.date_range,
                color: const Color(0xFF9B59B6),
              ),
              AdminStatsCard(
                title: 'Evaluaciones',
                value: adminState.systemStats.totalEvaluaciones.toString(),
                icon: Icons.assignment,
                color: const Color(0xFFE67E22),
              ),
              AdminStatsCard(
                title: 'Notas Terapia',
                value: adminState.systemStats.totalNotas.toString(),
                icon: Icons.note,
                color: const Color(0xFF16A085),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    // NOTE: Users list placeholder - implement when needed
    return Container(
      height: 400.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text('Lista de usuarios - Próximamente'),
      ),
    );
  }

  Widget _buildLicensesList() {
    // NOTE: Licenses list placeholder - implement when needed
    return Container(
      height: 400.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text('Lista de licencias - Próximamente'),
      ),
    );
  }

  void _showCreateUserDialog() {
    // NOTE: Create user dialog placeholder - implement when needed
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Usuario'),
        content: const Text('Funcionalidad de creación de usuarios - Próximamente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCreateLicenseDialog() {
    // NOTE: Create license dialog placeholder - implement when needed
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Licencia'),
        content: const Text('Funcionalidad de creación de licencias - Próximamente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
