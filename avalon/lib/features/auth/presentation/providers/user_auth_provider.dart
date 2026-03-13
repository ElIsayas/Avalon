import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/logger.dart';

/// Estado de autenticación de usuarios
class UserAuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  UserAuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserAuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
  }) {
    return UserAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAuthState &&
        other.user == user &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => user.hashCode ^ isLoading.hashCode ^ error.hashCode;

  bool get isAuthenticated => user != null;
  String get displayName => user?.nombre ?? 'Usuario';
  String get userEmail => user?.email ?? '';
  String get userRole => user?.rol ?? 'user';
}

/// Provider del servicio de usuarios
final userServiceProvider = Provider<UserService>((ref) {
  Logger.debug('🔧 INIT DEBUG: Creando UserService...', 'UserAuthProvider');
  final client = Supabase.instance.client;
  Logger.debug('🌐 INIT DEBUG: Supabase Client inicializado', 'UserAuthProvider');
  Logger.debug('📡 INIT DEBUG: Servicio de usuarios listo', 'UserAuthProvider');
  return UserService(client);
});

/// Provider del estado de autenticación de usuarios
final userAuthProvider = StateNotifierProvider<UserAuthNotifier, UserAuthState>((ref) {
  final userService = ref.watch(userServiceProvider);
  return UserAuthNotifier(userService);
});

/// Notifier para manejar el estado de autenticación de usuarios
class UserAuthNotifier extends StateNotifier<UserAuthState> {
  final UserService _userService;

  UserAuthNotifier(this._userService) : super(UserAuthState());

  /// Verificar si el usuario tiene licencia activa
  Future<bool> checkUserLicense() async {
    if (state.user == null) return false;
    
    try {
      Logger.debug('🔍 PROVIDER DEBUG: Verificando licencia para usuario ${state.user!.id}', 'UserAuthProvider');
      return await _userService.checkActiveLicense(state.user!.id);
    } catch (e) {
      Logger.error('💥 PROVIDER CATCH: Error verificando licencia: $e', 'UserAuthProvider');
      return false;
    }
  }

  /// Crear usuario
  Future<bool> createUser({
    required String nombre,
    required String email,
    required String password,
    String? deviceId,  // Opcional
  }) async {
    Logger.debug('🔄 PROVIDER DEBUG: Iniciando createUser...', 'UserAuthProvider');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _userService.createUser(
        nombre: nombre,
        email: email,
        password: password,
        deviceId: deviceId,  // Pasar deviceId opcional
      );

      Logger.debug('📊 PROVIDER DEBUG: Respuesta del servicio - Success: ${response.success}', 'UserAuthProvider');

      if (response.success && response.user != null) {
        Logger.info('✅ PROVIDER SUCCESS: Usuario creado exitosamente', 'UserAuthProvider');
        Logger.debug('👤 PROVIDER USER: ID=${response.user!.id}, Nombre=${response.user!.nombre}, Email=${response.user!.email}', 'UserAuthProvider');
        
        state = state.copyWith(
          isLoading: false,
          user: response.user,
          error: null,
        );
        return true;
      } else {
        Logger.warning('❌ PROVIDER ERROR: ${response.error}', 'UserAuthProvider');
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Error desconocido',
        );
        return false;
      }
    } catch (e) {
      Logger.error('💥 PROVIDER CATCH: Error creando usuario: $e', 'UserAuthProvider');
      Logger.debug('🔧 PROVIDER STACK: ${StackTrace.current}', 'UserAuthProvider');
      state = state.copyWith(
        isLoading: false,
        error: 'Error creando usuario: $e',
      );
      return false;
    }
  }

  /// Iniciar sesión
  Future<bool> signIn({
    required String email,  // Cambiado de username a email
    required String password,
  }) async {
    Logger.debug('🔄 PROVIDER DEBUG: Iniciando signIn...', 'UserAuthProvider');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _userService.authenticateUser(
        email: email,  // Parámetro corregido
        password: password,
      );

      Logger.debug('📊 PROVIDER DEBUG: Respuesta del servicio - Success: ${response.success}', 'UserAuthProvider');

      if (response.success && response.user != null) {
        Logger.info('✅ PROVIDER SUCCESS: Login exitoso', 'UserAuthProvider');
        Logger.debug('👤 PROVIDER USER: ID=${response.user!.id}, Email=${response.user!.email}', 'UserAuthProvider');
        
        state = state.copyWith(
          isLoading: false,
          user: response.user,
          error: null,
        );
        return true;
      } else {
        Logger.warning('❌ PROVIDER ERROR: ${response.error}', 'UserAuthProvider');
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Error desconocido',
        );
        return false;
      }
    } catch (e) {
      Logger.error('💥 PROVIDER CATCH: Error iniciando sesión: $e', 'UserAuthProvider');
      Logger.debug('🔧 PROVIDER STACK: ${StackTrace.current}', 'UserAuthProvider');
      state = state.copyWith(
        isLoading: false,
        error: 'Error iniciando sesión: $e',
      );
      return false;
    }
  }

  /// Cerrar sesión
  void signOut() {
    state = UserAuthState();
  }

  /// Limpiar errores
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Actualizar usuario
  Future<bool> updateUser(Map<String, dynamic> updates) async {
    if (state.user == null) return false;

    try {
      final success = await _userService.updateUser(
        state.user!.id,
        updates,
      );

      if (success) {
        // Recargar datos del usuario
        final updatedUser = await _userService.getUserById(state.user!.id);
        if (updatedUser != null) {
          state = state.copyWith(user: updatedUser);
        }
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'Error actualizando usuario: $e');
      return false;
    }
  }

  /// Asignar licencia al usuario
  Future<bool> assignLicense(String licenseId) async {
    if (state.user == null) return false;

    try {
      final success = await _userService.assignExistingLicenseToUser(
        userId: state.user!.id,
        licenseKey: licenseId,
      );

      if (success) {
        // Recargar datos del usuario
        final updatedUser = await _userService.getUserById(state.user!.id);
        if (updatedUser != null) {
          state = state.copyWith(user: updatedUser);
        }
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'Error asignando licencia: $e');
      return false;
    }
  }

  /// Verificar si el usuario tiene licencia
  bool get hasLicense => state.user?.licenciaId != null;

  /// Obtener ID de licencia del usuario
  String? get licenseId => state.user?.licenciaId;
}
