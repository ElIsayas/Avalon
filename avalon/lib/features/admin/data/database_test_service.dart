import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart';

class DatabaseTestService {
  final SupabaseClient _client;

  DatabaseTestService(this._client);

  // Test de conexión a la base de datos
  Future<Map<String, dynamic>> testConnection() async {
    try {
      Logger.info('🔍 TESTING DATABASE CONNECTION...', 'DatabaseTestService');
      
      // 1. Test básico de conexión
      final startTime = DateTime.now();
      final result = await _client.from('usuarios').select('count').single();
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      Logger.info('✅ Connection successful', 'DatabaseTestService');
      Logger.info('📊 Total users: ${result['count']}', 'DatabaseTestService');
      Logger.info('⚡ Response time: ${responseTime}ms', 'DatabaseTestService');
      
      return {
        'success': true,
        'message': 'Conexión exitosa',
        'responseTime': responseTime,
        'totalUsers': result['count'],
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Connection failed', 'DatabaseTestService');
      Logger.error('💥 Error: $e', 'DatabaseTestService');
      
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Obtener estadísticas de usuarios
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      Logger.info('📊 GETTING USER STATS...', 'DatabaseTestService');
      
      // Total de usuarios
      final totalResult = await _client.from('usuarios').select('count').single();
      final totalUsers = totalResult['count'];
      
      // Usuarios por rol
      final adminResult = await _client.from('usuarios').select('count').eq('rol', 'admin').single();
      final psicologoResult = await _client.from('usuarios').select('count').eq('rol', 'psicologo').single();
      
      // Usuarios activos
      final activeResult = await _client.from('usuarios').select('count').eq('activa', true).single();
      
      // Usuarios recientes (últimos 7 días)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentResult = await _client
          .from('usuarios')
          .select('count')
          .gte('fecha_registro', sevenDaysAgo.toIso8601String())
          .single();
      
      final stats = {
        'totalUsers': totalUsers,
        'adminUsers': adminResult['count'],
        'psicologoUsers': psicologoResult['count'],
        'activeUsers': activeResult['count'],
        'recentUsers': recentResult['count'],
        'inactiveUsers': totalUsers - activeResult['count'],
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      Logger.info('✅ User stats retrieved', 'DatabaseTestService');
      Logger.info('📊 Total: ${stats['totalUsers']}, Admin: ${stats['adminUsers']}, Psicologo: ${stats['psicologoUsers']}', 'DatabaseTestService');
      
      return stats;
    } catch (e) {
      Logger.error('❌ Error getting user stats', 'DatabaseTestService');
      Logger.error('💥 Error: $e', 'DatabaseTestService');
      
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Obtener todos los psicólogos con sus pacientes
  Future<Map<String, dynamic>> getPsicologosWithPatients() async {
    try {
      Logger.info('👥 GETTING PSICOLOGOS WITH PATIENTS...', 'DatabaseTestService');
      
      // Obtener todos los psicólogos
      final psicologos = await _client
          .from('usuarios')
          .select('id, nombre, email, rol, activa, fecha_registro')
          .eq('rol', 'psicologo')
          .eq('activa', true)
          .order('fecha_registro', ascending: false);
      
      // Para cada psicólogo, obtener sus pacientes
      final List<Map<String, dynamic>> psicologosWithPatients = [];
      
      for (var psicologo in psicologos) {
        try {
          // Obtener pacientes creados por este psicólogo
          final pacientes = await _client
              .from('pacientes')
              .select('id, nombre, email, activo, fecha_registro')
              .eq('creado_por', psicologo['id'])
              .order('fecha_registro', ascending: false);
          
          psicologosWithPatients.add({
            ...psicologo,
            'pacientes': pacientes,
            'totalPacientes': pacientes.length,
            'pacientesActivos': pacientes.where((p) => p['activo'] == true).length,
          });
          
        } catch (e) {
          Logger.warning('⚠️ Error getting patients for psicologo ${psicologo['id']}: $e', 'DatabaseTestService');
          psicologosWithPatients.add({
            ...psicologo,
            'pacientes': [],
            'totalPacientes': 0,
            'pacientesActivos': 0,
            'error': e.toString(),
          });
        }
      }
      
      final result = {
        'totalPsicologos': psicologosWithPatients.length,
        'psicologos': psicologosWithPatients,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      Logger.info('✅ Psicologos with patients retrieved', 'DatabaseTestService');
      Logger.info('👤 Total psicologos: ${result['totalPsicologos']}', 'DatabaseTestService');
      
      return result;
    } catch (e) {
      Logger.error('❌ Error getting psicologos with patients', 'DatabaseTestService');
      Logger.error('💥 Error: $e', 'DatabaseTestService');
      
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Test de rendimiento de consultas
  Future<Map<String, dynamic>> performanceTest() async {
    try {
      Logger.info('⚡ RUNNING PERFORMANCE TEST...', 'DatabaseTestService');
      
      final tests = <String, dynamic>{};
      
      // Test 1: Consulta simple
      var start = DateTime.now();
      await _client.from('usuarios').select('count').single();
      tests['simpleQuery'] = DateTime.now().difference(start).inMilliseconds;
      
      // Test 2: Consulta con filtro
      start = DateTime.now();
      await _client.from('usuarios').select('*').eq('rol', 'admin').single();
      tests['filteredQuery'] = DateTime.now().difference(start).inMilliseconds;
      
      // Test 3: Consulta con orden
      start = DateTime.now();
      await _client.from('usuarios').select('*').order('fecha_registro').limit(10);
      tests['orderedQuery'] = DateTime.now().difference(start).inMilliseconds;
      
      // Test 4: Consulta compleja
      start = DateTime.now();
      await _client.from('usuarios').select('*').eq('activa', true).order('fecha_registro').limit(5);
      tests['complexQuery'] = DateTime.now().difference(start).inMilliseconds;
      
      final avgTime = tests.values.fold<int>(0, (sum, time) => sum + (time as int)) / tests.length;
      
      final result = {
        'tests': tests,
        'averageTime': avgTime.round(),
        'performance': avgTime < 100 ? 'Excellent' : avgTime < 500 ? 'Good' : 'Needs Improvement',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      Logger.info('✅ Performance test completed', 'DatabaseTestService');
      Logger.info('⚡ Average time: ${result['averageTime']}ms', 'DatabaseTestService');
      
      return result;
    } catch (e) {
      Logger.error('❌ Performance test failed', 'DatabaseTestService');
      Logger.error('💥 Error: $e', 'DatabaseTestService');
      
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
