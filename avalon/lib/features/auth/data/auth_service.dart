import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_user.dart' as auth;
import '../../../core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  // Iniciar sesión con autenticación personalizada
  Future<auth.AuthUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      Logger.info('🔐 CUSTOM AUTH: Iniciando signIn', 'AuthService');
      Logger.info('📧 CUSTOM AUTH: Email recibido: "$email"', 'AuthService');
      Logger.info('🔒 CUSTOM AUTH: Password recibido: "${password.isNotEmpty ? "***" : "EMPTY"}"', 'AuthService');

      // Consultar tabla usuarios directamente
      final response = await _client
          .from('usuarios')
          .select()
          .eq('email', email)
          .eq('password', password) // En producción, usar hash
          .eq('activa', true)
          .maybeSingle();

      Logger.info('📊 CUSTOM AUTH: Response type: ${response.runtimeType}', 'AuthService');
      Logger.info('👤 CUSTOM AUTH: Response data: $response', 'AuthService');

      if (response == null) {
        Logger.error('❌ CUSTOM AUTH: Usuario no encontrado o inactivo', 'AuthService');
        throw Exception('Email o contraseña incorrectos');
      }

      Logger.info('✅ CUSTOM AUTH: Usuario encontrado', 'AuthService');
      Logger.info('👤 CUSTOM AUTH: Nombre: ${response['nombre']}', 'AuthService');
      Logger.info('🔑 CUSTOM AUTH: Rol: ${response['rol']}', 'AuthService');

      // Corregir rol si es 'user'
      String rol = response['rol'] == 'user' ? 'psicologo' : response['rol'];
      
      // Crear AuthUser personalizado
      final authUserMap = {
        'id': response['id'].toString(),
        'email': response['email'],
        'nombre': response['nombre'],
        'rol': rol,
        'licencia_id': response['licencia_id'],
        'device_id': response['device_id'],
        'activo': response['activa'],
        'especialidad': response['especialidad'],
        'disponibilidad': response['disponibilidad'],
        'fecha_registro': response['fecha_registro'],
      };

      final authUser = auth.AuthUser.fromMap(authUserMap);
      
      Logger.info('✅ CUSTOM AUTH: Login exitoso', 'AuthService');
      Logger.info('👤 CUSTOM AUTH: User: ${authUser.nombre}', 'AuthService');
      Logger.info('🔑 CUSTOM AUTH: Rol: ${authUser.rol}', 'AuthService');
      
      return authUser;
    } catch (e) {
      Logger.error('💥 CUSTOM AUTH: Error en signIn', 'AuthService');
      Logger.error('💥 CUSTOM AUTH: Error: $e', 'AuthService');
      rethrow;
    }
  }

  // Registrar usuario
  Future<auth.AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String nombre,
    required String licenseKey,
  }) async {
    try {
      Logger.info('🔐 CUSTOM AUTH: Iniciando signUp', 'AuthService');
      
      // Validar licencia
      final licenseValidation = await _validateLicense(licenseKey);
      if (!licenseValidation['valid']) {
        throw Exception('Licencia inválida o inactiva');
      }

      // Insertar usuario en tabla usuarios
      final response = await _client
          .from('usuarios')
          .insert({
            'nombre': nombre,
            'email': email,
            'password': password, // En producción, usar hash
            'licencia_id': licenseValidation['clinica_id'],
            'rol': 'psicologo', // Por defecto
            'activa': true,
            'fecha_registro': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      Logger.info('✅ CUSTOM AUTH: Usuario creado exitosamente', 'AuthService');

      // Corregir rol si es 'user'
      String rol = response['rol'] == 'user' ? 'psicologo' : response['rol'];
      
      // Crear AuthUser personalizado
      final authUserMap = {
        'id': response['id'].toString(),
        'email': response['email'],
        'nombre': response['nombre'],
        'rol': rol,
        'licencia_id': response['licencia_id'],
        'device_id': response['device_id'],
        'activo': response['activa'],
        'especialidad': response['especialidad'],
        'disponibilidad': response['disponibilidad'],
        'fecha_registro': response['fecha_registro'],
      };

      final authUser = auth.AuthUser.fromMap(authUserMap);
      
      return authUser;
    } catch (e) {
      Logger.error('💥 CUSTOM AUTH: Error en signUp', 'AuthService');
      Logger.error('💥 CUSTOM AUTH: Error: $e', 'AuthService');
      rethrow;
    }
  }

  // Obtener usuario actual desde SharedPreferences
  Future<auth.AuthUser?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userEmail = prefs.getString('userEmail');
      final userRole = prefs.getString('userRole');
      final userName = prefs.getString('userName');

      if (userId == null || userEmail == null) {
        return null;
      }

      final authUserMap = {
        'id': userId,
        'email': userEmail,
        'nombre': userName ?? '',
        'rol': userRole, // Mantener el rol original sin cambiar
      };

      return auth.AuthUser.fromMap(authUserMap);
    } catch (e) {
      Logger.error('💥 CUSTOM AUTH: Error en getCurrentUser', 'AuthService');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Logger.info('🚪 CUSTOM AUTH: Sesión cerrada', 'AuthService');
    } catch (e) {
      Logger.error('💥 CUSTOM AUTH: Error en signOut', 'AuthService');
    }
  }

  // Guardar sesión en SharedPreferences
  Future<void> saveSession(auth.AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id);
      await prefs.setString('userEmail', user.email);
      if (user.rol != null) {
        await prefs.setString('userRole', user.rol!);
      }
      if (user.nombre != null) {
        await prefs.setString('userName', user.nombre!);
      }
      Logger.info('💾 CUSTOM AUTH: Sesión guardada', 'AuthService');
    } catch (e) {
      Logger.error('💥 CUSTOM AUTH: Error guardando sesión', 'AuthService');
    }
  }

  // Validar licencia
  Future<Map<String, dynamic>> _validateLicense(String licenseKey) async {
    try {
      final response = await _client
          .from('licencias')
          .select('clinica_id, estado, max_usuarios')
          .eq('license_key', licenseKey)
          .maybeSingle();

      if (response == null) {
        return {'valid': false, 'error': 'Licencia no encontrada'};
      }

      if (response['estado'] != 'activa') {
        return {'valid': false, 'error': 'Licencia inactiva'};
      }

      return {
        'valid': true,
        'clinica_id': response['clinica_id'],
        'max_users': response['max_usuarios']
      };
    } catch (e) {
      Logger.error('💥 CUSTOM AUTH: Error validando licencia', 'AuthService');
      return {'valid': false, 'error': 'Error validando licencia'};
    }
  }

  // Reset password (placeholder)
  Future<void> resetPassword(String email) async {
    // Implementar lógica de reset de password si es necesario
    Logger.info('🔄 CUSTOM AUTH: Reset password solicitado para $email', 'AuthService');
  }
}
