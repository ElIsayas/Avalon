import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_service.dart';
import '../../../../core/security/secure_signout_service.dart';

/// Provider para el servicio de signOut seguro
final secureSignOutServiceProvider = Provider<SecureSignOutService>((ref) {
  return SecureSignOutService();
});

/// Provider para el servicio de autenticación con signOut seguro
final secureAuthProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

/// Estado de autenticación segura
class SecureAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? deviceId;
  final Map<String, String>? userInfo;

  const SecureAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.deviceId,
    this.userInfo,
  });

  SecureAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? deviceId,
    Map<String, String>? userInfo,
  }) {
    return SecureAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      deviceId: deviceId ?? this.deviceId,
      userInfo: userInfo ?? this.userInfo,
    );
  }
}

/// Notifier para manejar la autenticación segura
class SecureAuthNotifier extends StateNotifier<SecureAuthState> {
  final AuthService _authService;
  final SecureSignOutService _secureSignOutService;

  SecureAuthNotifier(this._authService, this._secureSignOutService)
      : super(const SecureAuthState());

  /// Iniciar sesión
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.signInWithEmailAndPassword(email, password);
      
      // Obtener información del dispositivo después del login
      final deviceId = await _secureSignOutService.getCurrentDeviceId();
      final userInfo = await _secureSignOutService.getStoredUserInfo();
      
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        deviceId: deviceId,
        userInfo: userInfo,
      );
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Cerrar sesión de forma segura
  Future<void> signOut({
    bool clearAllData = false,
    bool keepDeviceInfo = false,
    String? customLogMessage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.signOut(
        clearAllData: clearAllData,
        keepDeviceInfo: keepDeviceInfo,
        customLogMessage: customLogMessage,
      );
      
      state = const SecureAuthState(isAuthenticated: false);
    } catch (e) {
      // El signOut siempre completa, pero registramos el error
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
      
      // Forzar estado no autenticado
      state = const SecureAuthState(isAuthenticated: false);
    }
  }

  /// Cerrar sesión completamente (limpia todo)
  Future<void> signOutCompletely({String? reason}) async {
    await signOut(
      clearAllData: true,
      keepDeviceInfo: false,
      customLogMessage: reason ?? 'Complete signOut from provider',
    );
  }

  /// Verificar estado de autenticación actual
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final hasSession = await _authService.hasActiveSession();
      
      if (hasSession) {
        final deviceId = await _secureSignOutService.getCurrentDeviceId();
        final userInfo = await _secureSignOutService.getStoredUserInfo();
        
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          deviceId: deviceId,
          userInfo: userInfo,
        );
      } else {
        state = const SecureAuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Limpiar mensajes de error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refrescar información del usuario
  Future<void> refreshUserInfo() async {
    try {
      final deviceId = await _secureSignOutService.getCurrentDeviceId();
      final userInfo = await _secureSignOutService.getStoredUserInfo();
      
      state = state.copyWith(
        deviceId: deviceId,
        userInfo: userInfo,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider para el notifier de autenticación segura
final secureAuthNotifierProvider = StateNotifierProvider<SecureAuthNotifier, SecureAuthState>((ref) {
  final authService = ref.watch(secureAuthProvider);
  final secureSignOutService = ref.watch(secureSignOutServiceProvider);
  return SecureAuthNotifier(authService, secureSignOutService);
});

/// Stream para escuchar cambios de autenticación
final authStateStreamProvider = StreamProvider<bool>((ref) async* {
  final secureSignOutService = ref.watch(secureSignOutServiceProvider);
  
  while (true) {
    await Future.delayed(const Duration(seconds: 1));
    final isLoggedIn = await secureSignOutService.isUserLoggedIn();
    yield isLoggedIn;
  }
});
