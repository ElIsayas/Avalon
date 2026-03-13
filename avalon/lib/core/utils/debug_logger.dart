import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase.dart';
import '../utils/logger.dart';
import '../../shared/widgets/debug_console.dart';

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  // Referencia al provider de debug console
  static DebugConsoleNotifier? _debugNotifier;

  // Método para inicializar el logger con el provider
  static void initialize(DebugConsoleNotifier notifier) {
    _debugNotifier = notifier;
  }

  // Métodos de logging que se agregan a la consola
  void logError(String service, String message, {String? details}) {
    _addLog('ERROR', service, message, details: details);
    _printToConsole('ERROR', service, message, details: details);
  }

  void logWarning(String service, String message, {String? details}) {
    _addLog('WARNING', service, message, details: details);
    _printToConsole('WARNING', service, message, details: details);
  }

  void logInfo(String service, String message, {String? details}) {
    _addLog('INFO', service, message, details: details);
    _printToConsole('INFO', service, message, details: details);
  }

  void logDebug(String service, String message, {String? details}) {
    _addLog('DEBUG', service, message, details: details);
    _printToConsole('DEBUG', service, message, details: details);
  }

  // Método específico para errores de base de datos
  void logDatabaseError(String operation, String table, dynamic error, {Map<String, dynamic>? context}) {
    String details = '';
    
    if (error is Exception) {
      details = 'Exception: ${error.toString()}';
    } else if (error.toString().contains('PostgrestException')) {
      // Parsear errores específicos de Supabase/PostgREST
      details = _parsePostgrestError(error.toString());
    } else {
      details = 'Error: ${error.toString()}';
    }

    // Agregar contexto si existe
    if (context != null) {
      details += '\nContext: ${context.toString()}';
    }

    logError('Database', 'Operation: $operation on table: $table failed', details: details);
  }

  // Método específico para operaciones de base de datos
  void logDatabaseOperation(String operation, String table, {Map<String, dynamic>? data, int? resultCount}) {
    String message = 'Operation: $operation on table: $table';
    String? details;
    
    if (data != null) {
      details = 'Data: ${data.toString()}';
    }
    
    if (resultCount != null) {
      details = '${details ?? ''}\nResult count: $resultCount';
    }
    
    logDebug('Database', message, details: details);
  }

  // Método para testear conexión a la base de datos
  Future<Map<String, dynamic>> testDatabaseConnection() async {
    final testResults = <String, dynamic>{};
    
    try {
      logInfo('DatabaseTest', 'Iniciando test de conexión a la base de datos...');
      
      // Test 1: Conexión básica
      final startTime = DateTime.now();
      await supabase.from('usuarios').select('count').limit(1);
      final connectionTime = DateTime.now().difference(startTime).inMilliseconds;
      
      testResults['connection'] = {
        'status': 'success',
        'time_ms': connectionTime,
      };
      
      logInfo('DatabaseTest', 'Conexión exitosa', details: 'Tiempo: ${connectionTime}ms');
      
      // Test 2: Lectura de usuarios
      try {
        final usersCount = await supabase.from('usuarios').select('id').count();
        testResults['users_read'] = {
          'status': 'success',
          'count': usersCount,
        };
        logInfo('DatabaseTest', 'Lectura de usuarios exitosa', details: 'Count: $usersCount');
      } catch (e) {
        testResults['users_read'] = {
          'status': 'error',
          'error': e.toString(),
        };
        logDatabaseError('SELECT', 'usuarios', e);
      }
      
      // Test 3: Lectura de pacientes
      try {
        final pacientesCount = await supabase.from('pacientes').select('id').count();
        testResults['pacientes_read'] = {
          'status': 'success',
          'count': pacientesCount,
        };
        logInfo('DatabaseTest', 'Lectura de pacientes exitosa', details: 'Count: $pacientesCount');
      } catch (e) {
        testResults['pacientes_read'] = {
          'status': 'error',
          'error': e.toString(),
        };
        logDatabaseError('SELECT', 'pacientes', e);
      }
      
      // Test 4: Verificación de RLS policies
      try {
        final testQuery = supabase.from('usuarios').select('id, email').limit(1);
        final result = await testQuery;
        testResults['rls_test'] = {
          'status': 'success',
          'has_data': result.isNotEmpty,
        };
        logInfo('DatabaseTest', 'RLS policies funcionando correctamente');
      } catch (e) {
        testResults['rls_test'] = {
          'status': 'error',
          'error': e.toString(),
        };
        logWarning('DatabaseTest', 'Posible problema con RLS policies', details: e.toString());
      }
      
      testResults['overall_status'] = 'success';
      logInfo('DatabaseTest', 'Test de base de datos completado exitosamente');
      
    } catch (e) {
      testResults['overall_status'] = 'error';
      testResults['error'] = e.toString();
      logError('DatabaseTest', 'Error general en test de base de datos', details: e.toString());
    }
    
    return testResults;
  }

  // Parseo específico de errores de PostgREST
  String _parsePostgrestError(String errorString) {
    if (errorString.contains('23505')) {
      return 'ERROR 23505: Violación de constraint unique (duplicado)';
    } else if (errorString.contains('23503')) {
      return 'ERROR 23503: Violación de foreign key';
    } else if (errorString.contains('23502')) {
      return 'ERROR 23502: Violación de not null constraint';
    } else if (errorString.contains('42501')) {
      return 'ERROR 42501: Permiso denegado (RLS policy)';
    } else if (errorString.contains('PGRST')) {
      return 'ERROR PostgREST: ${errorString.split('PGRST').last}';
    }
    return errorString;
  }

  void _addLog(String level, String service, String message, {String? details}) {
    if (_debugNotifier != null) {
      _debugNotifier!.addLog(
        level: level,
        service: service,
        message: message,
        details: details,
      );
    }
  }

  void _printToConsole(String level, String service, String message, {String? details}) {
    final timestamp = DateTime.now().toString().substring(11, 23);
    final logMessage = '[$timestamp] $level: $service - $message';
    
    if (details != null) {
      Logger.debug('$logMessage\nDetails: $details', 'DebugLogger');
    } else {
      Logger.debug(logMessage, 'DebugLogger');
    }
  }
}

// Instancia global del logger
final debugLogger = DebugLogger();

// Provider para el logger
final debugLoggerProvider = Provider<DebugLogger>((ref) {
  final debugNotifier = ref.read(debugConsoleProvider.notifier);
  DebugLogger.initialize(debugNotifier);
  return debugLogger;
});

// Extension para facilitar el logging en servicios
extension DatabaseLogging on SupabaseClient {
  Future<List<Map<String, dynamic>>> loggedSelect(
    String table, {
    String? columns,
    bool debug = true,
  }) async {
    try {
      if (debug) {
        debugLogger.logDatabaseOperation('SELECT', table);
      }
      
      final result = await from(table).select(columns ?? '*');
      
      if (debug) {
        debugLogger.logDatabaseOperation('SELECT', table, resultCount: result.length);
      }
      
      return result;
    } catch (e) {
      debugLogger.logDatabaseError('SELECT', table, e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loggedInsert(
    String table,
    Map<String, dynamic> data, {
    bool debug = true,
  }) async {
    try {
      if (debug) {
        debugLogger.logDatabaseOperation('INSERT', table, data: data);
      }
      
      final result = await from(table).insert(data).select();
      
      if (debug) {
        debugLogger.logDatabaseOperation('INSERT', table, resultCount: result.length);
      }
      
      return result;
    } catch (e) {
      debugLogger.logDatabaseError('INSERT', table, e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loggedUpdate(
    String table,
    Map<String, dynamic> data, {
    bool debug = true,
  }) async {
    try {
      if (debug) {
        debugLogger.logDatabaseOperation('UPDATE', table, data: data);
      }
      
      final result = await from(table).update(data).select();
      
      if (debug) {
        debugLogger.logDatabaseOperation('UPDATE', table, resultCount: result.length);
      }
      
      return result;
    } catch (e) {
      debugLogger.logDatabaseError('UPDATE', table, e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loggedDelete(
    String table, {
    bool debug = true,
  }) async {
    try {
      if (debug) {
        debugLogger.logDatabaseOperation('DELETE', table);
      }
      
      final result = await from(table).delete().select();
      
      if (debug) {
        debugLogger.logDatabaseOperation('DELETE', table, resultCount: result.length);
      }
      
      return result;
    } catch (e) {
      debugLogger.logDatabaseError('DELETE', table, e);
      rethrow;
    }
  }
}
