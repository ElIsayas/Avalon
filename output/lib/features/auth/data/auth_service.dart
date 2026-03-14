import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_user.dart';

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
    final res = await _client.rpc('login', params: {
      'p_email':    email,
      'p_password': password,
    });

    final data = Map<String, dynamic>.from(res as Map);

    // El RPC retorna { error: '...' } si algo falla
    if (data.containsKey('error')) {
      throw Exception(data['error']);
    }

    // Guardar token en SharedPreferences para persistir entre sesiones
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, data['token'].toString());

    return AppUser.fromJson(data);
  }

  // ── VALIDAR SESIÓN AL ABRIR LA APP ────────────────────────────────────────
  // Lee el token guardado localmente y lo valida contra la BD.
  // Si otro dispositivo hizo login después, el token local ya no coincide
  // con session_token en la BD → retorna null → pantalla de login.
  Future<AppUser?> getSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) return null;

    final res = await _client.rpc('validate_session', params: {
      'p_token': token,
    });

    final data = Map<String, dynamic>.from(res as Map);

    if (data['valid'] != true) {
      // Token inválido o sesión cerrada desde otro dispositivo → limpiar local
      await prefs.remove(_tokenKey);
      return null;
    }

    // Inyectar el token en el JSON para que AppUser.fromJson lo capture
    data['token'] = token;
    return AppUser.fromJson(data);
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────
  // Borra el token en la BD (invalida la sesión en todos los dispositivos)
  // y limpia SharedPreferences localmente.
  Future<void> signOut(String token) async {
    try {
      await _client.rpc('logout', params: {'p_token': token});
    } catch (_) {
      // Si falla el RPC igual limpiamos localmente
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    }
  }

  // ── TOKEN LOCAL ───────────────────────────────────────────────────────────
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
