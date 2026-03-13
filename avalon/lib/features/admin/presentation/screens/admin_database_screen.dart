import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/database_test_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';

class AdminDatabaseScreen extends ConsumerStatefulWidget {
  const AdminDatabaseScreen({super.key});

  @override
  ConsumerState<AdminDatabaseScreen> createState() => _AdminDatabaseScreenState();
}

class _AdminDatabaseScreenState extends ConsumerState<AdminDatabaseScreen> {
  final DatabaseTestService _databaseService = DatabaseTestService(Supabase.instance.client);
  
  Map<String, dynamic>? _connectionTest;
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _psicologosData;
  Map<String, dynamic>? _performanceTest;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runAllTests();
  }

  Future<void> _runAllTests() async {
    setState(() => _isLoading = true);
    
    try {
      // Ejecutar todos los tests en paralelo
      final results = await Future.wait([
        _databaseService.testConnection(),
        _databaseService.getUserStats(),
        _databaseService.getPsicologosWithPatients(),
        _databaseService.performanceTest(),
      ]);
      
      setState(() {
        _connectionTest = results[0];
        _userStats = results[1];
        _psicologosData = results[2];
        _performanceTest = results[3];
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('❌ Error running tests: $e', 'AdminDatabaseScreen');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.rol == 'admin';
    
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text('Acceso Denegado')),
        body: Center(
          child: Text('No tienes permisos de administrador'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Administración', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        foregroundColor: Colors.red,
        actions: [
          IconButton(
            onPressed: _runAllTests,
            icon: Icon(Icons.refresh),
            tooltip: 'Actualizar Tests',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con info del admin
                  _buildAdminHeader(authState),
                  SizedBox(height: 24.h),
                  
                  // Test de Conexión
                  _buildConnectionTest(),
                  SizedBox(height: 24.h),
                  
                  // Estadísticas de Usuarios
                  _buildUserStats(),
                  SizedBox(height: 24.h),
                  
                  // Psicólogos y Pacientes
                  _buildPsicologosWithPatients(),
                  SizedBox(height: 24.h),
                  
                  // Test de Rendimiento
                  _buildPerformanceTest(),
                ],
              ),
            ),
    );
  }

  Widget _buildAdminHeader(authState) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withValues(alpha: 0.1), Colors.red.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.red, size: 32.w),
              SizedBox(width: 12.w),
              Text(
                'Panel de Administrador',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Usuario: ${authState.user?.nombre ?? "Desconocido"}',
            style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.grey[700]),
          ),
          Text(
            'Email: ${authState.user?.email ?? "Desconocido"}',
            style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          Text(
            'Rol: ${authState.user?.rol?.toUpperCase() ?? "DESCONOCIDO"}',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTest() {
    if (_connectionTest == null) return SizedBox();
    
    final success = _connectionTest!['success'] == true;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                  size: 24.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Test de Conexión',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (success) ...[
              _buildInfoRow('Estado', _connectionTest!['message'], Colors.green),
              _buildInfoRow('Tiempo de Respuesta', '${_connectionTest!['responseTime']}ms', Colors.blue),
              _buildInfoRow('Total Usuarios', '${_connectionTest!['totalUsers']}', Colors.purple),
            ] else ...[
              _buildInfoRow('Estado', _connectionTest!['message'], Colors.red),
              _buildInfoRow('Error', _connectionTest!['error'] ?? 'Desconocido', Colors.red),
            ],
            _buildInfoRow('Timestamp', _connectionTest!['timestamp'], Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    if (_userStats == null || _userStats!['error'] != null) return SizedBox();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue, size: 24.w),
                SizedBox(width: 8.w),
                Text(
                  'Estadísticas de Usuarios',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _buildStatCard('Total', '${_userStats!['totalUsers']}', Colors.purple)),
                SizedBox(width: 12.w),
                Expanded(child: _buildStatCard('Admins', '${_userStats!['adminUsers']}', Colors.red)),
                SizedBox(width: 12.w),
                Expanded(child: _buildStatCard('Psicólogos', '${_userStats!['psicologoUsers']}', Colors.blue)),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(child: _buildStatCard('Activos', '${_userStats!['activeUsers']}', Colors.green)),
                SizedBox(width: 12.w),
                Expanded(child: _buildStatCard('Inactivos', '${_userStats!['inactiveUsers']}', Colors.grey)),
                SizedBox(width: 12.w),
                Expanded(child: _buildStatCard('Recientes', '${_userStats!['recentUsers']}', Colors.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPsicologosWithPatients() {
    if (_psicologosData == null || _psicologosData!['error'] != null) return SizedBox();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.teal, size: 24.w),
                SizedBox(width: 8.w),
                Text(
                  'Psicólogos y sus Pacientes',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                Spacer(),
                Text(
                  'Total: ${_psicologosData!['totalPsicologos']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...(_psicologosData!['psicologos'] as List).map((psicologo) => _buildPsicologoCard(psicologo)),
          ],
        ),
      ),
    );
  }

  Widget _buildPsicologoCard(Map<String, dynamic> psicologo) {
    final hasError = psicologo['error'] != null;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.withValues(alpha: 0.05) : Colors.teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasError ? Colors.red.withValues(alpha: 0.3) : Colors.teal.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, color: Colors.white, size: 20.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      psicologo['nombre'] ?? 'Sin nombre',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      psicologo['email'] ?? 'Sin email',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasError)
                Icon(Icons.error, color: Colors.red, size: 20.w),
            ],
          ),
          SizedBox(height: 12.h),
          if (!hasError) ...[
            Row(
              children: [
                _buildMiniStat('Pacientes', '${psicologo['totalPacientes']}', Colors.blue),
                SizedBox(width: 12.w),
                _buildMiniStat('Activos', '${psicologo['pacientesActivos']}', Colors.green),
                SizedBox(width: 12.w),
                _buildMiniStat('Inactivos', '${(psicologo['totalPacientes'] ?? 0) - (psicologo['pacientesActivos'] ?? 0)}', Colors.grey),
              ],
            ),
            if ((psicologo['pacientes'] as List).isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                'Últimos pacientes:',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4.h),
              ...(psicologo['pacientes'] as List).take(3).map((paciente) => Padding(
                padding: EdgeInsets.only(left: 8.w, top: 2.h),
                child: Text(
                  '• ${paciente['nombre']} (${paciente['activo'] == true ? 'Activo' : 'Inactivo'})',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              )),
              if ((psicologo['pacientes'] as List).length > 3)
                Padding(
                  padding: EdgeInsets.only(left: 8.w, top: 2.h),
                  child: Text(
                    '• ... y ${((psicologo['pacientes'] as List).length - 3)} más',
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
            ],
          ] else ...[
            Text(
              'Error al cargar pacientes: ${psicologo['error']}',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTest() {
    if (_performanceTest == null || _performanceTest!['error'] != null) return SizedBox();
    
    final tests = _performanceTest!['tests'] as Map<String, dynamic>;
    final performance = _performanceTest!['performance'];
    final avgTime = _performanceTest!['averageTime'];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.orange, size: 24.w),
                SizedBox(width: 8.w),
                Text(
                  'Test de Rendimiento',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: performance == 'Excellent' ? Colors.green : 
                           performance == 'Good' ? Colors.yellow : Colors.red,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    performance,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'Tiempo promedio: ${avgTime}ms',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 12.h),
            ...tests.entries.map((entry) => _buildPerformanceRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(String test, int time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              _formatTestName(test),
              style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (time / 1000).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                time < 100 ? Colors.green : time < 500 ? Colors.yellow : Colors.red,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '${time}ms',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: time < 100 ? Colors.green : time < 500 ? Colors.yellow : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTestName(String test) {
    switch (test) {
      case 'simpleQuery': return 'Consulta Simple';
      case 'filteredQuery': return 'Consulta Filtrada';
      case 'orderedQuery': return 'Consulta Ordenada';
      case 'complexQuery': return 'Consulta Compleja';
      default: return test;
    }
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
