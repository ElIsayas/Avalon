import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// Modelo de Usuario para la tabla usuarios
class AppUser {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String? licenciaId;
  final bool activa;
  final String? deviceId;  // Nuevo campo opcional

  AppUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.licenciaId,
    required this.activa,
    this.deviceId,  // Nuevo campo opcional
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      rol: json['rol']?.toString() ?? 'user',
      licenciaId: json['licencia_id']?.toString(),
      activa: json['activa'] as bool? ?? true,
      deviceId: json['device_id']?.toString(),  // Nuevo campo opcional
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'licencia_id': licenciaId,
      'activa': activa,
      'device_id': deviceId,  // Nuevo campo opcional
    };
  }
}

/// Respuesta de autenticación
class AuthResponse {
  final bool success;
  final String? error;
  final AppUser? user;

  AuthResponse({
    required this.success,
    this.error,
    this.user,
  });

  factory AuthResponse.success(AppUser user) {
    return AuthResponse(
      success: true,
      user: user,
    );
  }

  factory AuthResponse.error(String error) {
    return AuthResponse(
      success: false,
      error: error,
    );
  }
}

/// Servicio para gestionar usuarios en la tabla usuarios
class UserService {
  final SupabaseClient _client;

  UserService(this._client);

  /// Crear usuario en la tabla usuarios
  Future<AuthResponse> createUser({
    required String nombre,
    required String email,
    required String password,
    String? deviceId,  // Opcional
    String rol = 'user',
  }) async {
    try {
      Logger.debug('Intentando crear usuario...', 'UserService');
      Logger.debug('Email: $email', 'UserService');
      Logger.debug('Nombre: $nombre', 'UserService');
      Logger.debug('Rol: $rol', 'UserService');
      Logger.debug('Device ID: ${deviceId ?? "NO PROPORCIONADO"}', 'UserService');

      // Primero, verificar si hay licencia disponible para este correo
      Logger.debug('Buscando licencia disponible para email: $email', 'UserService');
      
      // Buscar licencia activa sin asignar
      final licensesResponse = await _client
          .from('licencias')
          .select()
          .eq('email', email)
          .eq('activa', true);

      final licenses = licensesResponse as List;
      Logger.debug('Licencias encontradas: ${licenses.length}', 'UserService');
      
      // Buscar licencia sin usuario_id asignado
      final availableLicense = licenses.isEmpty ? null : 
        licenses.firstWhere((license) => license['usuario_id'] == null);

      Logger.debug('Licencia disponible: $availableLicense', 'UserService');

      if (availableLicense == null) {
        Logger.error('No hay licencia disponible para este email', 'UserService');
        return AuthResponse.error('No se puede registrar: no hay una licencia disponible asociada a este correo. Contacte al administrador.');
      }

      // Verificar si el email ya existe en usuarios
      Logger.debug('Verificando si email ya existe...', 'UserService');
      final existingUser = await _client
          .from('usuarios')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        Logger.error('Email ya registrado', 'UserService');
        return AuthResponse.error('El email ya está registrado');
      }

      Logger.debug('Licencia disponible y email único, creando usuario...', 'UserService');
      
      // Crear usuario y vincular licencia
      final userData = {
        'nombre': nombre,
        'email': email,
        'password': password, // En producción, esto debería estar hasheado
        'rol': rol,
        'activa': true,
        'licencia_id': availableLicense['id'], // Vincular licencia inmediatamente
        if (deviceId?.isNotEmpty ?? false) 'device_id': deviceId,  // Agregar device_id si se proporciona
      };

      Logger.debug('Datos a insertar: ${userData.keys.toList()}', 'UserService');

      final response = await _client
          .from('usuarios')
          .insert(userData)
          .select()
          .single();

      Logger.debug('Respuesta de Supabase: $response', 'UserService');

      // Actualizar licencia para marcarla como asignada
      await _client
          .from('licencias')
          .update({
            'usuario_id': response['id'],
            'fecha_activacion': DateTime.now().toIso8601String(),
          })
          .eq('id', availableLicense['id']);

      Logger.info('Licencia asignada a usuario', 'UserService');
      Logger.debug('Licencia actualizada - Usuario ID: ${response['id']}, Licencia ID: ${availableLicense['id']}', 'UserService');
      
      final user = AppUser.fromJson(response);
      Logger.info('Usuario creado con ID: ${user.id}', 'UserService');
      return AuthResponse.success(user);
    } catch (e) {
      Logger.error('Error creando usuario: $e', 'UserService', e, StackTrace.current);
      return AuthResponse.error('Error: $e');
    }
  }

  /// Autenticar usuario
  Future<AuthResponse> authenticateUser({
    required String email,  // Cambiado de username a email
    required String password,
  }) async {
    try {
      Logger.debug('Intentando autenticar usuario...', 'UserService');
      Logger.debug('Email: $email', 'UserService');
      Logger.debug('Password: ${password.isNotEmpty ? "***PROVIDED***" : "EMPTY"}', 'UserService');

      // Buscar usuario por email
      Logger.debug('Buscando usuario en tabla usuarios...', 'UserService');
      final userData = await _client
          .from('usuarios')
          .select()
          .eq('email', email)
          .eq('password', password) // En producción, usar hash
          .eq('activa', true)
          .maybeSingle();

      Logger.debug('Respuesta de Supabase: $userData', 'UserService');

      if (userData != null) {
        final user = AppUser.fromJson(userData);
        Logger.info('Usuario encontrado - ID: ${user.id}, Email: ${user.email}', 'UserService');
        
        // Verificar si tiene licencia activa
        Logger.debug('Verificando licencia activa...', 'UserService');
        final hasActiveLicense = await checkActiveLicense(user.id);
        Logger.debug('¿Tiene licencia activa? $hasActiveLicense', 'UserService');
        
        if (!hasActiveLicense) {
          Logger.error('Usuario no tiene licencia activa', 'UserService');
          return AuthResponse.error('El usuario no tiene una licencia activa. Contacte al administrador.');
        }
        
        Logger.info('Usuario con licencia activa - Acceso permitido', 'UserService');
        return AuthResponse.success(user);
      } else {
        Logger.error('Credenciales incorrectas o usuario inactivo', 'UserService');
        return AuthResponse.error('Credenciales incorrectas o usuario inactivo');
      }
    } catch (e) {
      Logger.error('Error autenticando usuario: $e', 'UserService', e, StackTrace.current);
      return AuthResponse.error('Error: $e');
    }
  }

  /// Verificar si el usuario tiene una licencia activa
  Future<bool> checkActiveLicense(String userId) async {
    try {
      Logger.debug('Verificando licencia para usuario: $userId', 'UserService');
      
      // Buscar licencia activa para este usuario
      final licenseData = await _client
          .from('licencias')
          .select()
          .eq('usuario_id', userId)
          .eq('activa', true)
          .maybeSingle();

      Logger.debug('Datos de licencia: $licenseData', 'UserService');
      
      if (licenseData == null) {
        Logger.debug('No se encontró licencia activa', 'UserService');
        return false;
      }

      // Verificar que la licencia no esté expirada
      final expirationDate = licenseData['fecha_expiracion'];
      if (expirationDate != null) {
        final expDate = DateTime.parse(expirationDate);
        if (expDate.isBefore(DateTime.now())) {
          Logger.debug('Licencia expirada - Expira: $expDate', 'UserService');
          return false;
        }
        Logger.debug('Licencia válida - Expira: $expDate', 'UserService');
      } else {
        Logger.debug('Licencia sin fecha de expiración (permanente)', 'UserService');
      }

      Logger.debug('Licencia activa verificada', 'UserService');
      return true;
    } catch (e) {
      Logger.error('Error verificando licencia: $e', 'UserService');
      return false;
    }
  }

  /// Asignar licencia existente a usuario
  Future<bool> assignExistingLicenseToUser({
    required String userId,
    required String licenseKey,
  }) async {
    try {
      Logger.debug('Asignando licencia existente $licenseKey a usuario $userId', 'UserService');
      
      // Buscar licencia existente
      final licenseData = await _client
          .from('licencias')
          .select()
          .eq('license_key', licenseKey)
          .eq('activa', true)
          .maybeSingle();

      if (licenseData == null) {
        Logger.debug('Licencia no existe o no está activa', 'UserService');
        return false;
      }

      // Asignar licencia al usuario
      await _client
          .from('usuarios')
          .update({'licencia_id': licenseData['id']})
          .eq('id', userId);

      Logger.debug('Licencia existente asignada exitosamente', 'UserService');
      return true;
    } catch (e) {
      Logger.error('Error asignando licencia existente: $e', 'UserService');
      return false;
    }
  }

  /// Obtener usuario por ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final userData = await _client
          .from('usuarios')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userData != null) {
        return AppUser.fromJson(userData);
      }
      return null;
    } catch (e) {
      Logger.error('Error obteniendo usuario: $e', 'UserService');
      return null;
    }
  }

  /// Actualizar usuario
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('usuarios')
          .update(updates)
          .eq('id', userId);
      return true;
    } catch (e) {
      Logger.error('Error actualizando usuario: $e', 'UserService');
      return false;
    }
  }

  /// Desactivar usuario
  Future<bool> deactivateUser(String userId) async {
    try {
      await _client
          .from('usuarios')
          .update({'activa': false})
          .eq('id', userId);
      return true;
    } catch (e) {
      Logger.error('Error desactivando usuario: $e', 'UserService');
      return false;
    }
  }

  /// Asignar licencia a usuario
  Future<bool> assignLicenseToUser(String userId, String licenseId) async {
    try {
      await _client
          .from('usuarios')
          .update({'licencia_id': licenseId})
          .eq('id', userId);
      return true;
    } catch (e) {
      Logger.error('Error asignando licencia: $e', 'UserService');
      return false;
    }
  }

  /// Obtener todos los usuarios (para admin)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final userData = await _client
          .from('usuarios')
          .select()
          .order('created_at', ascending: false);

      return userData.map((data) => AppUser.fromJson(data)).toList();
    } catch (e) {
      Logger.error('Error obteniendo usuarios: $e', 'UserService');
      return [];
    }
  }
}
