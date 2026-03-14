import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/paciente.dart';
import '../../../../core/utils/logger.dart';
// Acceso mediado 100% por RPCs — sin acceso directo a tablas

class PacienteService {
  final SupabaseClient _client;
  final String _token;

  PacienteService(this._client, this._token);

  // ── LECTURA ───────────────────────────────────────────────────────────────

  Future<List<Paciente>> getAll() async {
    AppLogger.database('Obteniendo todos los pacientes');
    try {
      final res = await _client.rpc('get_pacientes', params: {'p_token': _token});
      final pacientes = (res as List).map((j) => Paciente.fromJson(j as Map<String, dynamic>)).toList();
      AppLogger.database('Pacientes obtenidos: ${pacientes.length}');
      return pacientes;
    } catch (e, stackTrace) {
      AppLogger.database('Error obteniendo pacientes: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Paciente>> buscar(String query) async {
    AppLogger.database('Buscando pacientes con query: $query');
    try {
      final res = await _client.rpc('buscar_pacientes', params: {
        'p_token': _token,
        'p_query': query,
      });
      final pacientes = (res as List).map((j) => Paciente.fromJson(j as Map<String, dynamic>)).toList();
      AppLogger.database('Búsqueda completada: ${pacientes.length} resultados');
      return pacientes;
    } catch (e, stackTrace) {
      AppLogger.database('Error en búsqueda de pacientes: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ── ESCRITURA ─────────────────────────────────────────────────────────────

  Future<Paciente> crear({
    required String nombre,
    required String email,
    required String numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    String? objetivosTerapeuticos,
  }) async {
    AppLogger.database('Creando paciente: $nombre, email: $email');
    
    try {
      final params = <String, dynamic>{
        'p_token':            _token,
        'p_nombre':           nombre,
        'p_email':            email,
        'p_numero_documento': numeroDocumento,
      };
      if (telefono != null)              params['p_telefono']               = telefono;
      if (direccion != null)             params['p_direccion']              = direccion;
      if (historialMedico != null)       params['p_historial_medico']       = historialMedico;
      if (objetivosTerapeuticos != null) params['p_objetivos_terapeuticos'] = objetivosTerapeuticos;
      if (fechaNacimiento != null)       params['p_fecha_nacimiento']       = fechaNacimiento.toIso8601String().split('T')[0];

      final res   = await _client.rpc('crear_paciente', params: params);
      final lista = res as List;
      final paciente = Paciente.fromJson(lista.first as Map<String, dynamic>);
      AppLogger.database('Paciente creado exitosamente: ${paciente.id}');
      return paciente;
    } catch (e, stackTrace) {
      AppLogger.database('Error creando paciente: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Paciente> actualizar({
    required String id,
    String? nombre,
    String? email,
    String? numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    String? objetivosTerapeuticos,
    bool? activo,
  }) async {
    final params = <String, dynamic>{'p_token': _token, 'p_id': id};
    if (nombre != null)                params['p_nombre']                = nombre;
    if (email != null)                 params['p_email']                 = email;
    if (numeroDocumento != null)       params['p_numero_documento']      = numeroDocumento;
    if (telefono != null)              params['p_telefono']              = telefono;
    if (direccion != null)             params['p_direccion']             = direccion;
    if (historialMedico != null)       params['p_historial_medico']      = historialMedico;
    if (objetivosTerapeuticos != null) params['p_objetivos_terapeuticos']= objetivosTerapeuticos;
    if (activo != null)                params['p_activo']                = activo;
    if (fechaNacimiento != null)       params['p_fecha_nacimiento']      = fechaNacimiento.toIso8601String().split('T')[0];

    final res   = await _client.rpc('actualizar_paciente', params: params);
    final lista = res as List;
    return Paciente.fromJson(lista.first as Map<String, dynamic>);
  }

  Future<void> eliminar(String id) async {
    AppLogger.database('Eliminando paciente: $id');
    try {
      await _client.rpc('eliminar_paciente', params: {'p_token': _token, 'p_id': id});
      AppLogger.database('Paciente eliminado exitosamente');
    } catch (e, stackTrace) {
      AppLogger.database('Error eliminando paciente: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> toggleActivo(String id, bool activo) async {
    AppLogger.database('Cambiando estado activo del paciente $id a: $activo');
    try {
      await _client.rpc('actualizar_paciente', params: {
        'p_token':  _token,
        'p_id':     id,
        'p_activo': activo,
      });
      AppLogger.database('Estado del paciente actualizado exitosamente');
    } catch (e, stackTrace) {
      AppLogger.database('Error actualizando estado del paciente: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
