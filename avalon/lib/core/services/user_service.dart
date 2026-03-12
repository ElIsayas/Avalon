import 'package:supabase_flutter/supabase_flutter.dart';

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
      print('🔍 DEBUG: Intentando crear usuario...');
      print('📧 Email: $email');
      print('👤 Nombre: $nombre');
      print('🔐 Rol: $rol');
      print('📱 Device ID: ${deviceId ?? "NO PROPORCIONADO"}');

      // Primero, verificar si hay licencia disponible para este correo
      print('🔍 DEBUG: Buscando licencia disponible para email: $email');
      
      // Buscar licencia activa sin asignar
      final licensesResponse = await _client
          .from('licencias')
          .select()
          .eq('email', email)
          .eq('activa', true);

      final licenses = licensesResponse as List;
      print('📋 DEBUG: Licencias encontradas: ${licenses.length}');
      
      // Buscar licencia sin usuario_id asignado
      final availableLicense = licenses.isEmpty ? null : 
        licenses.firstWhere((license) => license['usuario_id'] == null);

      print('📋 DEBUG: Licencia disponible: $availableLicense');

      if (availableLicense == null) {
        print('❌ ERROR: No hay licencia disponible para este email');
        return AuthResponse.error('No se puede registrar: no hay una licencia disponible asociada a este correo. Contacte al administrador.');
      }

      // Verificar si el email ya existe en usuarios
      print('🔍 DEBUG: Verificando si email ya existe...');
      final existingUser = await _client
          .from('usuarios')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        print('❌ ERROR: Email ya registrado');
        return AuthResponse.error('El email ya está registrado');
      }

      print('✅ DEBUG: Licencia disponible y email único, creando usuario...');
      
      // Crear usuario y vincular licencia
      final userData = {
        'nombre': nombre,
        'email': email,
        'password': password, // En producción, esto debería estar hasheado
        'rol': rol,
        'activa': true,
        'licencia_id': availableLicense['id'], // Vincular licencia inmediatamente
        if (deviceId != null) 'device_id': deviceId,  // Agregar device_id si se proporciona
      };

      print('📝 DEBUG: Datos a insertar: ${userData.keys.toList()}');

      final response = await _client
          .from('usuarios')
          .insert(userData)
          .select()
          .single();

      print('📋 DEBUG: Respuesta de Supabase: $response');

      if (response != null) {
        // Actualizar licencia para marcarla como asignada
        await _client
            .from('licencias')
            .update({
              'usuario_id': response['id'],
              'fecha_activacion': DateTime.now().toIso8601String(),
            })
            .eq('id', availableLicense['id']);

        print('✅ SUCCESS: Licencia asignada a usuario');
        print('📋 DEBUG: Licencia actualizada - Usuario ID: ${response['id']}, Licencia ID: ${availableLicense['id']}');
        
        final user = AppUser.fromJson(response);
        print('✅ SUCCESS: Usuario creado con ID: ${user.id}');
        return AuthResponse.success(user);
      } else {
        print('❌ ERROR: Error al crear el usuario');
        return AuthResponse.error('Error al crear el usuario');
      }
    } catch (e) {
      print('💥 CATCH ERROR: Error creando usuario: $e');
      print('🔧 STACK TRACE: ${StackTrace.current}');
      return AuthResponse.error('Error: $e');
    }
  }

  /// Autenticar usuario
  Future<AuthResponse> authenticateUser({
    required String email,  // Cambiado de username a email
    required String password,
  }) async {
    try {
      print('🔍 DEBUG: Intentando autenticar usuario...');
      print('📧 Email: $email');
      print('🔐 Password: ${password.isNotEmpty ? "***PROVIDED***" : "EMPTY"}');

      // Buscar usuario por email
      print('🔍 DEBUG: Buscando usuario en tabla usuarios...');
      final userData = await _client
          .from('usuarios')
          .select()
          .eq('email', email)
          .eq('password', password) // En producción, usar hash
          .eq('activa', true)
          .maybeSingle();

      print('📋 DEBUG: Respuesta de Supabase: $userData');

      if (userData != null) {
        final user = AppUser.fromJson(userData);
        print('✅ SUCCESS: Usuario encontrado - ID: ${user.id}, Email: ${user.email}');
        
        // Verificar si tiene licencia activa
        print('🔍 DEBUG: Verificando licencia activa...');
        final hasActiveLicense = await checkActiveLicense(user.id);
        print('📋 DEBUG: ¿Tiene licencia activa? $hasActiveLicense');
        
        if (!hasActiveLicense) {
          print('❌ ERROR: Usuario no tiene licencia activa');
          return AuthResponse.error('El usuario no tiene una licencia activa. Contacte al administrador.');
        }
        
        print('✅ SUCCESS: Usuario con licencia activa - Acceso permitido');
        return AuthResponse.success(user);
      } else {
        print('❌ ERROR: Credenciales incorrectas o usuario inactivo');
        return AuthResponse.error('Credenciales incorrectas o usuario inactivo');
      }
    } catch (e) {
      print('💥 CATCH ERROR: Error autenticando usuario: $e');
      print('🔧 STACK TRACE: ${StackTrace.current}');
      return AuthResponse.error('Error: $e');
    }
  }

  /// Verificar si el usuario tiene una licencia activa
  Future<bool> checkActiveLicense(String userId) async {
    try {
      print('🔍 DEBUG: Verificando licencia para usuario: $userId');
      
      // Buscar licencia activa para este usuario
      final licenseData = await _client
          .from('licencias')
          .select()
          .eq('usuario_id', userId)
          .eq('activa', true)
          .maybeSingle();

      print('📋 DEBUG: Datos de licencia: $licenseData');
      
      if (licenseData == null) {
        print('❌ DEBUG: No se encontró licencia activa');
        return false;
      }

      // Verificar que la licencia no esté expirada
      final expirationDate = licenseData?['fecha_expiracion'];
      if (expirationDate != null) {
        final expDate = DateTime.parse(expirationDate);
        if (expDate.isBefore(DateTime.now())) {
          print('❌ DEBUG: Licencia expirada - Expira: $expDate');
          return false;
        }
        print('✅ DEBUG: Licencia válida - Expira: $expDate');
      } else {
        print('⚠️ DEBUG: Licencia sin fecha de expiración (permanente)');
      }

      print('✅ DEBUG: Licencia activa verificada');
      return true;
    } catch (e) {
      print('💥 CATCH ERROR: Error verificando licencia: $e');
      return false;
    }
  }

  /// Asignar licencia existente a usuario
  Future<bool> assignExistingLicenseToUser({
    required String userId,
    required String licenseKey,
  }) async {
    try {
      print('🔧 DEBUG: Asignando licencia existente $licenseKey a usuario $userId');
      
      // Buscar licencia existente
      final licenseData = await _client
          .from('licencias')
          .select()
          .eq('license_key', licenseKey)
          .eq('activa', true)
          .maybeSingle();

      if (licenseData == null) {
        print('❌ DEBUG: Licencia no existe o no está activa');
        return false;
      }

      // Asignar licencia al usuario
      await _client
          .from('usuarios')
          .update({'licencia_id': licenseData['id']})
          .eq('id', userId);

      print('✅ DEBUG: Licencia existente asignada exitosamente');
      return true;
    } catch (e) {
      print('💥 CATCH ERROR: Error asignando licencia existente: $e');
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
      print('Error obteniendo usuario: $e');
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
      print('Error actualizando usuario: $e');
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
      print('Error desactivando usuario: $e');
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
      print('Error asignando licencia: $e');
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
      print('Error obteniendo usuarios: $e');
      return [];
    }
  }
}
