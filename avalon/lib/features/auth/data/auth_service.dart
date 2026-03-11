import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_user.dart' as auth;

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  // Iniciar sesión
  Future<auth.AuthUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Obtener datos adicionales del usuario desde nuestra tabla
        final userData = await _client
            .from('usuarios')
            .select('*')
            .eq('auth_user_id', response.user!.id)
            .single();

        return auth.AuthUser.fromMap({...response.user!.toJson(), ...userData});
      } else {
        throw Exception('Error al iniciar sesión');
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Registrar usuario
  Future<auth.AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String nombre,
    required String numeroDocumento,
    String? clinicaId,
  }) async {
    try {
      // 1. Crear usuario en Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // 2. Crear registro en nuestra tabla usuarios
        final userData = await _client
            .from('usuarios')
            .insert({
              'auth_user_id': response.user!.id,
              'nombre': nombre,
              'email': email,
              'numero_documento': numeroDocumento,
              'clinica_id': clinicaId,
              'rol': 'psicologo', // Rol por defecto
              'activo': true,
            })
            .select()
            .single();

        return auth.AuthUser.fromMap({...response.user!.toJson(), ...userData});
      } else {
        throw Exception('Error al registrar usuario');
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Obtener usuario actual
  Future<auth.AuthUser?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        try {
          final userData = await _client
              .from('usuarios')
              .select('*')
              .eq('auth_user_id', user.id)
              .single();

          return auth.AuthUser.fromMap({...user.toJson(), ...userData});
        } catch (e) {
          // Si la tabla usuarios no existe o hay error, devolver usuario básico
          return auth.AuthUser.fromMap(user.toJson());
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Error al enviar correo de recuperación: $e');
    }
  }

  // Manejar errores de autenticación
  String _handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Credenciales incorrectas';
        case 'User not found':
          return 'Usuario no encontrado';
        case 'Email already registered':
          return 'El email ya está registrado';
        case 'Password should be at least 6 characters':
          return 'La contraseña debe tener al menos 6 caracteres';
        case 'Invalid email':
          return 'Email inválido';
        default:
          return error.message;
      }
    }
    return 'Error de autenticación: $error';
  }

  // Stream para escuchar cambios en la autenticación
  Stream<auth.AuthUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncMap((session) async {
      if (session.session?.user != null) {
        return await getCurrentUser();
      }
      return null;
    });
  }
}
