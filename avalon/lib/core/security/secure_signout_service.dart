import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Servicio de cierre de sesión seguro e independiente
/// No depende de Supabase Auth ni de servicios externos
class SecureSignOutService {
  static final SecureSignOutService _instance = SecureSignOutService._internal();
  factory SecureSignOutService() => _instance;
  SecureSignOutService._internal();

  final Logger _logger = Logger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Claves para almacenamiento seguro
  static const String _deviceIdKey = 'device_id';
  static const String _userEmailKey = 'user_email';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _sessionDataKey = 'session_data';
  static const String _userProfileKey = 'user_profile';
  static const String _tempCredentialsKey = 'temp_credentials';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastLoginKey = 'last_login';
  static const String _rememberMeKey = 'remember_me';

  /// Método principal de cierre de sesión seguro
  Future<void> signOut({
    bool clearAllData = false,
    bool keepDeviceInfo = false,
    String? customLogMessage,
  }) async {
    final stopwatch = Stopwatch()..start();
    String? deviceId;
    
    try {
      // 1. Obtener device_id para logging antes de limpiar
      deviceId = await _secureStorage.read(key: _deviceIdKey);
      
      // 2. Registrar inicio del proceso de signOut
      _logSignOutStart(deviceId, customLogMessage);
      
      // 3. Ejecutar limpieza en orden de seguridad
      await _executeSecureCleanup(clearAllData, keepDeviceInfo);
      
      // 4. Verificar que los datos sensibles fueron eliminados
      await _verifyCleanup();
      
      // 5. Registrar completion exitoso
      _logSignOutSuccess(deviceId, stopwatch.elapsedMilliseconds);
      
    } catch (e, stackTrace) {
      // 6. Manejar errores y garantizar completion
      await _handleSignOutError(e, stackTrace, deviceId, stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }

  /// Limpieza segura de datos sensibles
  Future<void> _executeSecureCleanup(bool clearAllData, bool keepDeviceInfo) async {
    // Fase 1: Limpiar datos de sesión inmediatos (más críticos)
    await _cleanupSessionData();
    
    // Fase 2: Limpiar credenciales de autenticación
    await _cleanupAuthCredentials();
    
    // Fase 3: Limpiar datos temporales y cache
    await _cleanupTempData();
    
    // Fase 4: Limpiar preferencias de usuario (si se solicita)
    if (clearAllData) {
      await _cleanupUserPreferences();
    }
    
    // Fase 5: Limpiar device_id (si no se debe mantener)
    if (!keepDeviceInfo) {
      await _cleanupDeviceInfo();
    }
  }

  /// Limpiar datos de sesión
  Future<void> _cleanupSessionData() async {
    try {
      await _secureStorage.delete(key: _sessionDataKey);
      await _secureStorage.delete(key: _authTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      
      // También limpiar de SharedPreferences si existe
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionDataKey);
      await prefs.remove(_authTokenKey);
      await prefs.remove(_refreshTokenKey);
      
      _logger.d('Session data cleaned successfully');
    } catch (e) {
      _logger.e('Error cleaning session data: $e');
      // No lanzar excepción para continuar con el proceso
    }
  }

  /// Limpiar credenciales de autenticación
  Future<void> _cleanupAuthCredentials() async {
    try {
      await _secureStorage.delete(key: _userEmailKey);
      await _secureStorage.delete(key: _tempCredentialsKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _rememberMeKey);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userEmailKey);
      await prefs.remove(_tempCredentialsKey);
      await prefs.remove(_biometricEnabledKey);
      await prefs.remove(_rememberMeKey);
      
      _logger.d('Auth credentials cleaned successfully');
    } catch (e) {
      _logger.e('Error cleaning auth credentials: $e');
    }
  }

  /// Limpiar datos temporales y cache
  Future<void> _cleanupTempData() async {
    try {
      await _secureStorage.delete(key: _lastLoginKey);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastLoginKey);
      
      // Limpiar cualquier cache temporal que pueda existir
      await prefs.remove('temp_cache');
      await prefs.remove('navigation_state');
      await prefs.remove('form_data');
      
      _logger.d('Temp data cleaned successfully');
    } catch (e) {
      _logger.e('Error cleaning temp data: $e');
    }
  }

  /// Limpiar preferencias de usuario
  Future<void> _cleanupUserPreferences() async {
    try {
      await _secureStorage.delete(key: _userProfileKey);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      
      // Limpiar otras preferencias guardadas
      await prefs.remove('theme_preference');
      await prefs.remove('language_preference');
      await prefs.remove('notification_settings');
      await prefs.remove('privacy_settings');
      
      _logger.d('User preferences cleaned successfully');
    } catch (e) {
      _logger.e('Error cleaning user preferences: $e');
    }
  }

  /// Limpiar información del dispositivo
  Future<void> _cleanupDeviceInfo() async {
    try {
      await _secureStorage.delete(key: _deviceIdKey);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceIdKey);
      await prefs.remove('device_info');
      await prefs.remove('app_version');
      
      _logger.d('Device info cleaned successfully');
    } catch (e) {
      _logger.e('Error cleaning device info: $e');
    }
  }

  /// Verificar que los datos sensibles fueron eliminados
  Future<void> _verifyCleanup() async {
    try {
      final secureKeys = [
        _authTokenKey,
        _refreshTokenKey,
        _sessionDataKey,
        _userEmailKey,
        _tempCredentialsKey,
      ];
      
      final prefs = await SharedPreferences.getInstance();
      bool hasRemainingData = false;
      
      for (final key in secureKeys) {
        final secureValue = await _secureStorage.read(key: key);
        final prefValue = prefs.getString(key);
        
        if (secureValue != null || prefValue != null) {
          hasRemainingData = true;
          _logger.w('Remaining sensitive data found for key: $key');
          
          // Intentar eliminar nuevamente
          await _secureStorage.delete(key: key);
          await prefs.remove(key);
        }
      }
      
      if (!hasRemainingData) {
        _logger.d('Cleanup verification: All sensitive data removed');
      }
    } catch (e) {
      _logger.e('Error during cleanup verification: $e');
    }
  }

  /// Manejar errores durante el signOut
  Future<void> _handleSignOutError(
    Object error,
    StackTrace stackTrace,
    String? deviceId,
    int elapsedMs,
  ) async {
    _logger.e(
      'SignOut error occurred',
      error: error,
      stackTrace: stackTrace,
    );
    
    // Intentar limpieza de emergencia
    try {
      await _emergencyCleanup();
    } catch (e) {
      _logger.e('Emergency cleanup failed: $e');
    }
    
    // Registrar error pero no bloquear el flujo
    _logSignOutError(deviceId, elapsedMs, error.toString());
  }

  /// Limpieza de emergencia si falla el proceso normal
  Future<void> _emergencyCleanup() async {
    try {
      // Limpiar todas las claves conocidas de forma agresiva
      final allKeys = [
        _deviceIdKey,
        _userEmailKey,
        _authTokenKey,
        _refreshTokenKey,
        _sessionDataKey,
        _userProfileKey,
        _tempCredentialsKey,
        _biometricEnabledKey,
        _lastLoginKey,
        _rememberMeKey,
      ];
      
      for (final key in allKeys) {
        await _secureStorage.delete(key: key);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _logger.w('Emergency cleanup completed');
    } catch (e) {
      _logger.e('Emergency cleanup failed: $e');
    }
  }

  /// Métodos de logging seguros
  void _logSignOutStart(String? deviceId, String? customMessage) {
    final message = customMessage ?? 'User initiated signOut';
    _logger.i('🔒 SIGNOUT START: $message ${deviceId != null ? '(device: $deviceId)' : ''}');
  }

  void _logSignOutSuccess(String? deviceId, int elapsedMs) {
    _logger.i(
      '✅ SIGNOUT SUCCESS: Completed in ${elapsedMs}ms '
      '${deviceId != null ? '(device: $deviceId)' : ''}',
    );
  }

  void _logSignOutError(String? deviceId, int elapsedMs, String error) {
    _logger.e(
      '❌ SIGNOUT ERROR: Failed after ${elapsedMs}ms - $error '
      '${deviceId != null ? '(device: $deviceId)' : ''}',
    );
  }

  /// Métodos utilitarios
  Future<bool> isUserLoggedIn() async {
    try {
      final token = await _secureStorage.read(key: _authTokenKey);
      final sessionData = await _secureStorage.read(key: _sessionDataKey);
      return token != null || sessionData != null;
    } catch (e) {
      _logger.e('Error checking login status: $e');
      return false;
    }
  }

  Future<String?> getCurrentDeviceId() async {
    try {
      return await _secureStorage.read(key: _deviceIdKey);
    } catch (e) {
      _logger.e('Error getting device ID: $e');
      return null;
    }
  }

  Future<Map<String, String>> getStoredUserInfo() async {
    try {
      final Map<String, String> userInfo = {};
      
      final email = await _secureStorage.read(key: _userEmailKey);
      final deviceId = await _secureStorage.read(key: _deviceIdKey);
      final lastLogin = await _secureStorage.read(key: _lastLoginKey);
      
      if (email != null) userInfo['email'] = email;
      if (deviceId != null) userInfo['device_id'] = deviceId;
      if (lastLogin != null) userInfo['last_login'] = lastLogin;
      
      return userInfo;
    } catch (e) {
      _logger.e('Error getting user info: $e');
      return {};
    }
  }

  /// Método para limpiar solo datos específicos (para casos especiales)
  Future<void> clearSpecificData(List<String> keys) async {
    try {
      for (final key in keys) {
        await _secureStorage.delete(key: key);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      }
      
      _logger.d('Specific data cleared for keys: $keys');
    } catch (e) {
      _logger.e('Error clearing specific data: $e');
    }
  }
}
