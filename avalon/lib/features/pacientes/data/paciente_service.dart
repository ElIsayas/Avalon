import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/paciente.dart';
import '../../../core/constants/app_constants.dart';

class PacienteService {
  final SupabaseClient _client;
  PacienteService(this._client);

  // ── LECTURA ───────────────────────────────────────────────────────────────
  // RLS filtra automáticamente: admin ve todos, user solo los suyos
  Future<List<Paciente>> getAll() async {
    final res = await _client
        .from(AppConstants.tablePacientes)
        .select()
        .order('fecha_registro', ascending: false);
    return res.map((j) => Paciente.fromJson(j)).toList();
  }

  Future<List<Paciente>> buscar(String query) async {
    final res = await _client
        .from(AppConstants.tablePacientes)
        .select()
        .or('nombre.ilike.%$query%,email.ilike.%$query%,numero_documento.ilike.%$query%,telefono.ilike.%$query%')
        .order('nombre');
    return res.map((j) => Paciente.fromJson(j)).toList();
  }

  Future<Paciente> getById(String id) async {
    final res = await _client
        .from(AppConstants.tablePacientes)
        .select()
        .eq('id', id)
        .single();
    return Paciente.fromJson(res);
  }

  // ── ESCRITURA ─────────────────────────────────────────────────────────────
  Future<Paciente> crear({
    required String nombre,
    required String email,
    required String numeroDocumento,
    required String creadoPor, // public.usuarios.id del usuario autenticado
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    String? objetivosTerapeuticos,
  }) async {
    final data = <String, dynamic>{
      'nombre':           nombre,
      'email':            email,
      'numero_documento': numeroDocumento,
      'creado_por':       creadoPor,
      'activo':           true,
      'fecha_registro':   DateTime.now().toIso8601String(),
      'fecha_actualizacion': DateTime.now().toIso8601String(),
    };

    if (telefono?.isNotEmpty ?? false)     data['telefono']    = telefono;
    if (direccion?.isNotEmpty ?? false)    data['direccion']   = direccion;
    if (historialMedico?.isNotEmpty ?? false) data['historial_medico'] = historialMedico;
    if (objetivosTerapeuticos?.isNotEmpty ?? false) data['objetivos_terapeuticos'] = objetivosTerapeuticos;
    if (fechaNacimiento != null) data['fecha_nacimiento'] = fechaNacimiento.toIso8601String().split('T')[0];

    final res = await _client
        .from(AppConstants.tablePacientes)
        .insert(data)
        .select()
        .single();
    return Paciente.fromJson(res);
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
    final data = <String, dynamic>{
      'fecha_actualizacion': DateTime.now().toIso8601String(),
    };
    if (nombre != null)                data['nombre']           = nombre;
    if (email != null)                 data['email']            = email;
    if (numeroDocumento != null)       data['numero_documento'] = numeroDocumento;
    if (telefono != null)              data['telefono']         = telefono;
    if (direccion != null)             data['direccion']        = direccion;
    if (historialMedico != null)       data['historial_medico'] = historialMedico;
    if (objetivosTerapeuticos != null) data['objetivos_terapeuticos'] = objetivosTerapeuticos;
    if (activo != null)                data['activo']           = activo;
    if (fechaNacimiento != null)       data['fecha_nacimiento'] = fechaNacimiento.toIso8601String().split('T')[0];

    final res = await _client
        .from(AppConstants.tablePacientes)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Paciente.fromJson(res);
  }

  Future<void> eliminar(String id) async {
    await _client.from(AppConstants.tablePacientes).delete().eq('id', id);
  }

  Future<void> toggleActivo(String id, bool activo) async {
    await _client.from(AppConstants.tablePacientes).update({
      'activo': activo,
      'fecha_actualizacion': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
