import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_user.dart';
import '../../../../core/utils/logger.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  static const _tokenKey = 'avalon_session_token';

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  // Llama al RPC login(email, password) en Supabase.
  // El RPC valida credenciales, verifica activa + fecha_expiracion,
  // genera un token nuevo (invalidando la sesión anterior en otra PC)
  // y retorna los datos del usuario + token.
  Future<AppUser> signIn(String email, String password) async {
    AppLogger.auth('Intentando login para email: $email');
    
    try {
      final res = await _client.rpc('login', params: {
        'p_email':    email,
        'p_password': password,
      });

      final data = Map<String, dynamic>.from(res as Map);
      AppLogger.auth('Respuesta del RPC login: ${data.keys.toList()}');

      // El RPC retorna { error: '...' } si algo falla
      if (data.containsKey('error')) {
        AppLogger.auth('Error en login RPC: ${data['error']}');
        throw Exception(data['error']);
      }

      // Guardar token en SharedPreferences para persistir entre sesiones
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token'].toString());
      AppLogger.auth('Token guardado exitosamente');

      return AppUser.fromJson(data);
    } catch (e, stackTrace) {
      AppLogger.auth('Error en signIn: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ── VALIDAR SESIÓN AL ABRIR LA APP ────────────────────────────────────────
  // Lee el token guardado localmente y lo valida contra la BD.
  // Si otro dispositivo hizo login después, el token local ya no coincide
  // con session_token en la BD → retorna null → pantalla de login.
  Future<AppUser?> getSessionUser() async {
    AppLogger.auth('Verificando sesión guardada');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token == null || token.isEmpty) {
        AppLogger.auth('No hay token guardado');
        return null;
      }

      AppLogger.auth('Validando token local');
      final res = await _client.rpc('validate_session', params: {
        'p_token': token,
      });

      final data = Map<String, dynamic>.from(res as Map);
      AppLogger.auth('Respuesta validate_session: valid=${data['valid']}');

      if (data['valid'] != true) {
        // Token inválido o sesión cerrada desde otro dispositivo → limpiar local
        AppLogger.auth('Token inválido, limpiando almacenamiento local');
        await prefs.remove(_tokenKey);
        return null;
      }

      // Inyectar el token en el JSON para que AppUser.fromJson lo capture
      data['token'] = token;
      AppLogger.auth('Sesion válida, usuario: ${data['email']}');
      return AppUser.fromJson(data);
    } catch (e, stackTrace) {
      AppLogger.auth('Error en getSessionUser: $e', error: e, stackTrace: stackTrace);
      // En caso de error, limpiamos el token para forzar login
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
      } catch (_) {}
      return null;
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────
  // Borra el token en la BD (invalida la sesión en todos los dispositivos)
  // y limpia SharedPreferences localmente.
  Future<void> signOut(String token) async {
    AppLogger.auth('Iniciando logout');
    
    try {
      await _client.rpc('logout', params: {'p_token': token});
      AppLogger.auth('Logout RPC ejecutado exitosamente');
    } catch (e, stackTrace) {
      AppLogger.auth('Error en logout RPC: $e', error: e, stackTrace: stackTrace);
      // Si falla el RPC igual limpiamos localmente
    } finally {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        AppLogger.auth('Token local eliminado');
      } catch (e, stackTrace) {
        AppLogger.auth('Error limpiando SharedPreferences: $e', error: e, stackTrace: stackTrace);
      }
    }
  }

  // ── TOKEN LOCAL ───────────────────────────────────────────────────────────
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      AppLogger.auth('Token recuperado: ${token != null ? 'EXISTS' : 'NULL'}');
      return token;
    } catch (e, stackTrace) {
      AppLogger.auth('Error obteniendo token almacenado: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
