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
      print("DEBUG: Iniciando signUp en Supabase Auth...");

      // 1. Crear usuario en Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      print(
        "DEBUG: Respuesta de Auth: ${response.user != null ? 'Usuario creado' : 'Usuario null'}",
      );
      print("DEBUG: User ID: ${response.user?.id}");
      print(
        "DEBUG: Session: ${response.session != null ? 'Sesión activa' : 'Sin sesión'}",
      );

      if (response.user != null) {
        // 2. Crear registro en nuestra tabla usuarios
        print("DEBUG: Insertando en tabla usuarios...");
        print("DEBUG: auth_user_id: ${response.user!.id}");
        print("DEBUG: nombre: $nombre");
        print("DEBUG: email: $email");
        print("DEBUG: numero_documento: $numeroDocumento");
        print("DEBUG: clinica_id: $clinicaId");

        try {
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

          print("DEBUG: Usuario insertado correctamente en tabla usuarios");
          return auth.AuthUser.fromMap({
            ...response.user!.toJson(),
            ...userData,
          });
        } catch (dbError) {
          print("DEBUG: Error al insertar en tabla usuarios: $dbError");

          // Si falla la inserción en la BD, eliminar el usuario de Auth para mantener consistencia
          try {
            await _client.auth.admin.deleteUser(response.user!.id);
            print("DEBUG: Usuario eliminado de Auth debido a error en BD");
          } catch (deleteError) {
            print("DEBUG: Error al eliminar usuario de Auth: $deleteError");
          }

          rethrow;
        }
      } else {
        throw Exception('Error al registrar usuario: respuesta nula');
      }
    } catch (e) {
      print("DEBUG: Error en signUp: $e");
      print("DEBUG: Error type: ${e.runtimeType}");

      if (e is PostgrestException) {
        print("DEBUG: Postgrest code: ${e.code}");
        print("DEBUG: Postgrest message: ${e.message}");
        print("DEBUG: Postgrest details: ${e.details}");
        print("DEBUG: Postgrest hint: ${e.hint}");
      } else if (e is AuthException) {
        print("DEBUG: Auth code: ${e.code}");
        print("DEBUG: Auth message: ${e.message}");
      }

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
