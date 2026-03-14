import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/paciente.dart';
// Acceso mediado 100% por RPCs — sin acceso directo a tablas

class PacienteService {
  final SupabaseClient _client;
  final String _token;

  PacienteService(this._client, this._token);

  // ── LECTURA ───────────────────────────────────────────────────────────────

  Future<List<Paciente>> getAll() async {
    final res = await _client.rpc('get_pacientes', params: {'p_token': _token});
    return (res as List).map((j) => Paciente.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Paciente>> buscar(String query) async {
    final res = await _client.rpc('buscar_pacientes', params: {
      'p_token': _token,
      'p_query': query,
    });
    return (res as List).map((j) => Paciente.fromJson(j as Map<String, dynamic>)).toList();
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
    return Paciente.fromJson(lista.first as Map<String, dynamic>);
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
    await _client.rpc('eliminar_paciente', params: {'p_token': _token, 'p_id': id});
  }

  Future<void> toggleActivo(String id, bool activo) async {
    await _client.rpc('actualizar_paciente', params: {
      'p_token':  _token,
      'p_id':     id,
      'p_activo': activo,
    });
  }
}
