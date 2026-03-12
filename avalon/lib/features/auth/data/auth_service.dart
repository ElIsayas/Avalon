import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_user.dart' as auth;

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /*
  =========================
  LOGIN
  =========================
  */
  Future<auth.AuthUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('No se pudo iniciar sesión');
      }

      print("LOGIN OK: ${response.user!.id}");

      // Obtener datos de tabla usuarios
      final userData = await _client
          .from('usuarios')
          .select()
          .eq('auth_user_id', response.user!.id)
          .maybeSingle();

      if (userData == null) {
        throw Exception('Perfil de usuario no encontrado');
      }

      return auth.AuthUser.fromMap({
        ...response.user!.toJson(),
        ...userData,
      });
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /*
  =========================
  REGISTRO
  =========================
  */
  Future<auth.AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String nombre,
    required String numeroDocumento,
    String? clinicaId,
  }) async {
    try {
      print("SIGNUP: creando usuario en auth");

      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception("No se pudo crear el usuario");
      }

      print("AUTH USER ID: ${response.user!.id}");

      // Insertar perfil en tabla usuarios
      final userData = await _client
          .from('usuarios')
          .insert({
            'auth_user_id': response.user!.id,
            'nombre': nombre,
            'email': email,
            'numero_documento': numeroDocumento,
            'clinica_id': clinicaId,
            'rol': 'psicologo',
            'activo': true,
          })
          .select()
          .single();

      print("Usuario creado en tabla usuarios");

      return auth.AuthUser.fromMap({
        ...response.user!.toJson(),
        ...userData,
      });
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /*
  =========================
  USUARIO ACTUAL
  =========================
  */
  Future<auth.AuthUser?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;

      if (user == null) {
        return null;
      }

      final userData = await _client
          .from('usuarios')
          .select()
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (userData == null) {
        return auth.AuthUser.fromMap(user.toJson());
      }

      return auth.AuthUser.fromMap({
        ...user.toJson(),
        ...userData,
      });
    } catch (_) {
      return null;
    }
  }

  /*
  =========================
  LOGOUT
  =========================
  */
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /*
  =========================
  RECUPERAR CONTRASEÑA
  =========================
  */
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /*
  =========================
  STREAM DE AUTENTICACIÓN
  =========================
  */
  Stream<auth.AuthUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;

      if (user == null) {
        return null;
      }

      return await getCurrentUser();
    });
  }

  /*
  =========================
  MANEJO DE ERRORES
  =========================
  */
  String _handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'invalid_credentials':
          return 'Email o contraseña incorrectos';

        case 'user_already_exists':
          return 'El email ya está registrado';

        case 'email_not_confirmed':
          return 'Debes confirmar tu email';

        case 'over_email_send_rate_limit':
          return 'Demasiados intentos, espera unos segundos';

        default:
          return error.message;
      }
    }

    if (error is PostgrestException) {
      if (error.code == '23505') {
        return 'El número de documento ya está registrado';
      }
    }

    return "Error de autenticación";
  }
}