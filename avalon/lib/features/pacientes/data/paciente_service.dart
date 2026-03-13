import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/paciente.dart';
import '../../../core/utils/logger.dart';

class PacienteService {
  final SupabaseClient _supabase;

  PacienteService(this._supabase);

  // Método de prueba para verificar conexión con la base de datos
  Future<Map<String, dynamic>> testDatabaseConnection() async {
    try {
      Logger.debug('🧪 TEST: Iniciando test de conexión a la base de datos', 'PacienteService');
      
      // Test 1: Verificar si podemos conectar a la tabla pacientes
      final testQuery = _supabase
          .from('pacientes')
          .select('count')
          .limit(1);
      
      final countResult = await testQuery;
      Logger.debug('🧪 TEST: Query de conteo ejecutado: $countResult', 'PacienteService');
      
      // Test 2: Intentar obtener TODOS los pacientes sin filtros
      final allPatientsQuery = _supabase
          .from('pacientes')
          .select('*')
          .limit(10);
      
      final allPatientsResult = await allPatientsQuery;
      Logger.debug('🧪 TEST: Query de todos los pacientes: $allPatientsResult', 'PacienteService');
      
      // Test 3: Verificar estructura de la tabla
      final structureQuery = _supabase
          .from('pacientes')
          .select('id, nombre, email, numero_documento, activo, creado_por, fecha_registro')
          .limit(5);
      
      final structureResult = await structureQuery;
      Logger.debug('🧪 TEST: Estructura de pacientes: $structureResult', 'PacienteService');
      
      return {
        'success': true,
        'count_result': countResult,
        'all_patients': allPatientsResult,
        'structure_result': structureResult,
        'message': 'Conexión exitosa a la base de datos'
      };
    } catch (e) {
      Logger.error('🧪 TEST: Error en test de conexión: $e', 'PacienteService');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error en la conexión a la base de datos'
      };
    }
  }

  Future<List<Paciente>> getPacientes({String? userId, String? userRole}) async {
    try {
      Logger.debug('📋 PACIENTE DEBUG: Iniciando carga de pacientes', 'PacienteService');
      Logger.debug('📋 PACIENTE DEBUG: userId: $userId, userRole: $userRole', 'PacienteService');
      
      // PRIMERO: Test sin filtros para ver si hay datos
      Logger.debug('📋 PACIENTE DEBUG: Test sin filtros', 'PacienteService');
      var testQuery = _supabase
          .from('pacientes')
          .select('*');
      
      final testResponse = await testQuery.order('fecha_registro', ascending: false);
      Logger.debug('📋 PACIENTE DEBUG: Test sin filtros - Response type: ${testResponse.runtimeType}', 'PacienteService');
      Logger.debug('📋 PACIENTE DEBUG: Test sin filtros - Response data: $testResponse', 'PacienteService');
      Logger.debug('📋 PACIENTE DEBUG: Test sin filtros - Count: ${testResponse.length}', 'PacienteService');
      
      // AHORA: Aplicar filtros según el rol
      var query = _supabase
          .from('pacientes')
          .select('*');
      
      // Filter by role: admin sees all, psicologo sees only their patients
      if ((userRole == 'psicologo' || userRole == 'user') && userId != null) {
        Logger.debug('📋 PACIENTE DEBUG: Aplicando filtro por psicologo/user, userId: $userId', 'PacienteService');
        query = query.eq('creado_por', userId);
      } else if (userRole == 'admin') {
        Logger.debug('📋 PACIENTE DEBUG: Usuario admin, sin filtro', 'PacienteService');
      } else {
        Logger.debug('📋 PACIENTE DEBUG: Rol desconocido o userId nulo, sin filtro', 'PacienteService');
      }
      
      Logger.debug('📋 PACIENTE DEBUG: Ejecutando query con filtros...', 'PacienteService');
      final response = await query.order('fecha_registro', ascending: false);

      Logger.debug('📋 PACIENTE DEBUG: Response type: ${response.runtimeType}', 'PacienteService');
      Logger.debug('📋 PACIENTE DEBUG: Response data: $response', 'PacienteService');
      Logger.debug('📋 PACIENTE DEBUG: Response count: ${response.length}', 'PacienteService');
      
      // Supabase always returns a list, so we can directly map it
      final pacientes = (response as List).map((json) {
        Logger.debug('📋 PACIENTE DEBUG: Processing JSON: $json', 'PacienteService');
        return Paciente.fromJson(json);
      }).toList();
      
      Logger.debug('📋 PACIENTE DEBUG: Pacientes mapeados: ${pacientes.length}', 'PacienteService');
      
      return pacientes;
    } catch (e) {
      Logger.error('❌ PACIENTE DEBUG: Error al cargar pacientes: $e', 'PacienteService');
      // Return empty list on error to prevent app crash
      return [];
    }
  }

  Future<Paciente> getPacienteById(String id) async {
    try {
      final response = await _supabase
          .from('pacientes')
          .select('*')
          .eq('id', id)
          .single();

      return Paciente.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar paciente: $e');
    }
  }

  Future<Paciente> createPaciente({
    required String nombre,
    required String email,
    required String numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    String? licenciaId,
    String? deviceId,
    String? creadoPor,
    String? objetivosTerapeuticos,
    String? progreso,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final pacienteData = {
        'nombre': nombre,
        'email': email,
        'numero_documento': numeroDocumento,
        'telefono': telefono,
        'direccion': direccion,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'historial_medico': historialMedico,
        'fecha_registro': DateTime.now().toIso8601String(),
        'fecha_actualizacion': DateTime.now().toIso8601String(),
        'activo': true,
        'licencia_id': licenciaId,
        'device_id': deviceId,
        'creado_por': creadoPor,
        'objetivos_terapeuticos': objetivosTerapeuticos,
        'progreso': progreso,
        'metadata': metadata,
      };

      final response = await _supabase
          .from('pacientes')
          .insert(pacienteData)
          .select()
          .single();

      return Paciente.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear paciente: $e');
    }
  }

  Future<Paciente> updatePaciente({
    required String id,
    String? nombre,
    String? email,
    String? numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    bool? activo,
    String? licenciaId,
    String? deviceId,
    String? objetivosTerapeuticos,
    String? progreso,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (nombre != null) updateData['nombre'] = nombre;
      if (email != null) updateData['email'] = email;
      if (numeroDocumento != null) updateData['numero_documento'] = numeroDocumento;
      if (telefono != null) updateData['telefono'] = telefono;
      if (direccion != null) updateData['direccion'] = direccion;
      if (fechaNacimiento != null) updateData['fecha_nacimiento'] = fechaNacimiento.toIso8601String();
      if (historialMedico != null) updateData['historial_medico'] = historialMedico;
      if (activo != null) updateData['activo'] = activo;
      if (licenciaId != null) updateData['licencia_id'] = licenciaId;
      if (deviceId != null) updateData['device_id'] = deviceId;
      if (objetivosTerapeuticos != null) updateData['objetivos_terapeuticos'] = objetivosTerapeuticos;
      if (progreso != null) updateData['progreso'] = progreso;
      if (metadata != null) updateData['metadata'] = metadata;
      
      // Always update fecha_actualizacion on modification
      updateData['fecha_actualizacion'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('pacientes')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
      return Paciente.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar paciente: $e');
    }
  }

  Future<void> deletePaciente(String id) async {
    try {
      await _supabase
          .from('pacientes')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar paciente: $e');
    }
  }

  Future<void> desactivarPaciente(String id) async {
    try {
      await _supabase
          .from('pacientes')
          .update({
            'activo': false,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al desactivar paciente: $e');
    }
  }

  Future<List<Paciente>> buscarPacientes(String query) async {
    try {
      final response = await _supabase
          .from('pacientes')
          .select('*')
          .or('nombre.ilike.%$query%,email.ilike.%$query%,telefono.ilike.%$query%,numero_documento.ilike.%$query%')
          .order('fecha_registro', ascending: false);

      return response.map((json) => Paciente.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al buscar pacientes: $e');
    }
  }

  Future<List<Paciente>> getPacientesActivos() async {
    try {
      final response = await _supabase
          .from('pacientes')
          .select('*')
          .eq('activo', true)
          .order('fecha_registro', ascending: false);

      return response.map((json) => Paciente.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar pacientes activos: $e');
    }
  }

  Future<int> getTotalPacientes({String? userId, String? userRole}) async {
    try {
      var query = _supabase
          .from('pacientes')
          .select('id');
      
      // Filter by role: admin sees all, psicologo/user sees only their patients
      if ((userRole == 'psicologo' || userRole == 'user') && userId != null) {
        query = query.eq('creado_por', userId);
      }
      
      final response = await query.count();

      return response.count;
    } catch (e) {
      throw Exception('Error al obtener total de pacientes: $e');
    }
  }

  Future<int> getPacientesActivosCount({String? userId, String? userRole}) async {
    try {
      var query = _supabase
          .from('pacientes')
          .select('id')
          .eq('activo', true);
      
      // Filter by role: admin sees all, psicologo sees only their patients
      if ((userRole == 'psicologo' || userRole == 'user') && userId != null) {
        query = query.eq('creado_por', userId);
      }
      
      final response = await query.count();

      return response.count;
    } catch (e) {
      throw Exception('Error al obtener count de pacientes activos: $e');
    }
  }

  // New methods for enhanced functionality
  Future<List<Paciente>> getPacientesRecientes({int dias = 30}) async {
    try {
      final fechaLimite = DateTime.now().subtract(Duration(days: dias));
      
      final response = await _supabase
          .from('pacientes')
          .select('*')
          .gte('fecha_registro', fechaLimite.toIso8601String())
          .order('fecha_registro', ascending: false);

      return response.map((json) => Paciente.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar pacientes recientes: $e');
    }
  }

  Future<bool> emailExists(String email, {String? excludeId}) async {
    try {
      var query = _supabase
          .from('pacientes')
          .select('id')
          .eq('email', email);

      // Exclude current patient when checking for duplicates during update
      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      return response.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar email: $e');
    }
  }

  Future<bool> numeroDocumentoExists(String numeroDocumento, {String? excludeId}) async {
    try {
      var query = _supabase
          .from('pacientes')
          .select('id')
          .eq('numero_documento', numeroDocumento);

      // Exclude current patient when checking for duplicates during update
      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      return response.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar número de documento: $e');
    }
  }

  // Método para obtener información del usuario que creó el paciente
  Future<Map<String, dynamic>?> getCreadorInfo(String creadorPor) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select('id, nombre, email, rol')
          .eq('id', creadorPor)
          .maybeSingle();

      return response;
    } catch (e) {
      Logger.error('❌ Error al obtener información del creador: $e', 'PacienteService');
      return null;
    }
  }

  // Método para cambiar el estado de un paciente (activo/inactivo)
  Future<void> togglePacienteStatus(String id) async {
    try {
      // Primero obtener el estado actual del paciente
      final pacienteActual = await _supabase
          .from('pacientes')
          .select('activo')
          .eq('id', id)
          .single();

      final nuevoEstado = !(pacienteActual['activo'] as bool);

      // Actualizar el estado
      await _supabase
          .from('pacientes')
          .update({'activo': nuevoEstado})
          .eq('id', id);

      Logger.info('✅ Estado del paciente $id actualizado a: $nuevoEstado', 'PacienteService');
    } catch (e) {
      Logger.error('❌ Error al cambiar estado del paciente: $e', 'PacienteService');
      throw Exception('Error al cambiar estado del paciente: $e');
    }
  }
}
