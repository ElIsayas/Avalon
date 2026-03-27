import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/usuario_org.dart';
import '../../../../core/utils/logger.dart';

class UsuariosPlanInfo {
  final int limiteUsuarios;
  final int usuariosUsados;
  final int usuariosDisponibles;
  final bool esIlimitado;

  const UsuariosPlanInfo({
    required this.limiteUsuarios,
    required this.usuariosUsados,
    required this.usuariosDisponibles,
    required this.esIlimitado,
  });

  factory UsuariosPlanInfo.fromJson(Map<String, dynamic> j) => UsuariosPlanInfo(
        limiteUsuarios: (j['limite_usuarios'] as num?)?.toInt() ?? 0,
        usuariosUsados: (j['usuarios_usados'] as num?)?.toInt() ?? 0,
        usuariosDisponibles: (j['usuarios_disponibles'] as num?)?.toInt() ?? 0,
        esIlimitado:
            j['es_ilimitado'] as bool? ?? j['es_platinum'] as bool? ?? false,
      );
}

class UsuariosOrgService {
  final SupabaseClient _client;
  final String _token;

  UsuariosOrgService(this._client, this._token);

  // Obtener todos los usuarios de la org (admin + psicologos + secretarias).
  Future<List<UsuarioOrg>> getUsuarios() async {
    AppLogger.database('Obteniendo usuarios de la organizacion');
    try {
      final primario =
          await _rpcList('get_psicologos_org', params: {'p_token': _token});
      final listaPrimaria = _parseUsuarios(primario);
      if (_incluyeVariosRoles(listaPrimaria)) return listaPrimaria;

      final alterno =
          await _rpcList('get_usuarios_org', params: {'p_token': _token});
      final listaAlterna = _parseUsuarios(alterno);
      if (listaAlterna.isNotEmpty) return listaAlterna;

      // Fallback para entornos admin donde solo existe sa_get_usuarios.
      final sa = await _rpcList('sa_get_usuarios', params: {'p_token': _token});
      final listaSa = _parseUsuarios(sa);
      if (listaSa.isNotEmpty) return listaSa;

      return listaPrimaria;
    } catch (e, st) {
      AppLogger.database('Error obteniendo usuarios: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<UsuariosPlanInfo> getInfoPlan() async {
    try {
      final res =
          await _client.rpc('get_info_plan', params: {'p_token': _token});
      return UsuariosPlanInfo.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e, st) {
      AppLogger.database('Error obteniendo info plan: $e',
          error: e, stackTrace: st);
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
        'p_token': _token,
        'p_nombre': nombre,
        'p_email': email,
        'p_password': password,
        'p_rol': rol,
      };
      if (especialidad != null) {
        params['p_especialidad'] = especialidad;
      }
      if (fechaExpiracion != null) {
        params['p_fecha_expiracion'] =
            fechaExpiracion.toIso8601String().split('T')[0];
      }

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
      final params = <String, dynamic>{
        'p_token': _token,
        'p_usuario_id': userId,
      };
      if (nombre != null) params['p_nombre'] = nombre;
      if (rol != null) params['p_rol'] = rol;
      if (activa != null) params['p_activa'] = activa;
      if (especialidad != null) params['p_especialidad'] = especialidad;
      if (nuevaPassword != null) params['p_nueva_password'] = nuevaPassword;
      if (fechaExpiracion != null) {
        params['p_fecha_expiracion'] =
            fechaExpiracion.toIso8601String().split('T')[0];
      }

      await _client.rpc('sa_editar_usuario', params: params);
    } catch (e, st) {
      AppLogger.database('Error editando usuario: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  List<UsuarioOrg> _parseUsuarios(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((j) => UsuarioOrg.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  bool _incluyeVariosRoles(List<UsuarioOrg> usuarios) {
    if (usuarios.isEmpty) return false;
    final roles = usuarios.map((u) => u.rol).toSet();
    return roles.length > 1 || !roles.contains('psicologo');
  }

  Future<List<dynamic>> _rpcList(
    String fn, {
    required Map<String, dynamic> params,
  }) async {
    try {
      final res = await _client.rpc(fn, params: params);
      if (res is List) return res;
      if (res is Map) return [res];
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
