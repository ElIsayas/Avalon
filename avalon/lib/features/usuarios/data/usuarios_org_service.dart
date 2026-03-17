import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/usuario_org.dart';
import '../../../../core/utils/logger.dart';

class UsuariosOrgService {
  final SupabaseClient _client;
  final String _token;

  UsuariosOrgService(this._client, this._token);

  // Obtener todos los usuarios de la org (psicólogos + secretarias + admin)
  Future<List<UsuarioOrg>> getUsuarios() async {
    AppLogger.database('Obteniendo usuarios de la organización');
    try {
      // Reutilizamos get_psicologos_org que ya devuelve usuarios de la org
      // con los campos que necesitamos. Si devuelve solo psicólogos,
      // usamos sa_get_usuarios con filtro de org (solo admin lo puede llamar).
      // El RPC correcto para admin es crear_usuario / sa_get_usuarios
      final res = await _client.rpc('get_psicologos_org', params: {
        'p_token': _token,
      });
      return (res as List? ?? [])
          .map((j) => UsuarioOrg.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.database('Error obteniendo usuarios: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // Crear nuevo usuario en la org (solo admin)
  Future<void> crearUsuario({
    required String nombre,
    required String email,
    required String password,
    required String rol,
    String? especialidad,
    DateTime? fechaExpiracion,
  }) async {
    AppLogger.database('Creando usuario: $email, rol: $rol');
    try {
      final params = <String, dynamic>{
        'p_token':    _token,
        'p_nombre':   nombre,
        'p_email':    email,
        'p_password': password,
        'p_rol':      rol,
      };
      if (especialidad != null)
        params['p_especialidad'] = especialidad;
      if (fechaExpiracion != null)
        params['p_fecha_expiracion'] =
            fechaExpiracion.toIso8601String().split('T')[0];

      final res = await _client.rpc('crear_usuario', params: params);
      final data = res as Map<String, dynamic>?;
      if (data != null && data.containsKey('error')) {
        throw Exception(data['error']);
      }
    } catch (e, st) {
      AppLogger.database('Error creando usuario: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // Editar usuario (solo admin)
  Future<void> editarUsuario(
    String userId, {
    String? nombre,
    String? rol,
    bool? activa,
    String? especialidad,
    String? nuevaPassword,
    DateTime? fechaExpiracion,
  }) async {
    AppLogger.database('Editando usuario $userId');
    try {
      // Usamos sa_editar_usuario que acepta token y aplica validaciones de org
      final params = <String, dynamic>{
        'p_token':      _token,
        'p_usuario_id': userId,
      };
      if (nombre != null)          params['p_nombre']           = nombre;
      if (rol != null)             params['p_rol']              = rol;
      if (activa != null)          params['p_activa']           = activa;
      if (especialidad != null)    params['p_especialidad']     = especialidad;
      if (nuevaPassword != null)   params['p_nueva_password']   = nuevaPassword;
      if (fechaExpiracion != null) params['p_fecha_expiracion'] =
          fechaExpiracion.toIso8601String().split('T')[0];

      await _client.rpc('sa_editar_usuario', params: params);
    } catch (e, st) {
      AppLogger.database('Error editando usuario: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}
