import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_service.dart';
import '../../domain/auth_user.dart' as auth;
import '../../../../core/utils/logger.dart';

// Estado de autenticación
class AuthState {
  final auth.AuthUser? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({auth.AuthUser? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.user == user &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => (user?.hashCode ?? 0) ^ isLoading.hashCode ^ (error?.hashCode ?? 0);

  bool get isAuthenticated => user != null;
}

// Notifier de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  // Inicializar sesión desde SharedPreferences
  Future<void> initializeAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authService.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Iniciar sesión
  Future<void> signIn(String email, String password) async {
    Logger.info('🔐 PROVIDER DEBUG: Iniciando signIn', 'AuthNotifier');
    Logger.info('📧 PROVIDER DEBUG: Email recibido: "$email"', 'AuthNotifier');
    Logger.info('🔒 PROVIDER DEBUG: Password recibido: "${password.isNotEmpty ? "***" : "EMPTY"}"', 'AuthNotifier');
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      Logger.info('🔄 PROVIDER DEBUG: Llamando a authService.signInWithEmailAndPassword', 'AuthNotifier');
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      
      // Guardar sesión en SharedPreferences
      await _authService.saveSession(user);
      
      Logger.info('✅ PROVIDER DEBUG: Login exitoso, user: ${user.nombre}', 'AuthNotifier');
      Logger.info('✅ PROVIDER DEBUG: User rol: ${user.rol}', 'AuthNotifier');
      Logger.info('✅ PROVIDER DEBUG: User ID: ${user.id}', 'AuthNotifier');
      
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      Logger.error('💥 PROVIDER DEBUG: Error en signIn', 'AuthNotifier');
      Logger.error('💥 PROVIDER DEBUG: Error: $e', 'AuthNotifier');
      String errorMessage = 'Error al iniciar sesión';

      // Provide specific error messages based on common authentication errors
      if (e.toString().contains('Email o contraseña incorrectos')) {
        errorMessage = 'Email o contraseña incorrectos';
      } else if (e.toString().contains('Usuario no encontrado')) {
        errorMessage = 'No existe una cuenta con este email';
      } else if (e.toString().contains('inactivo')) {
        errorMessage = 'Usuario inactivo. Contacte al administrador.';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  // Registrar usuario
  Future<void> signUp({
    required String email,
    required String password,
    required String nombre,
    required String licenseKey,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        nombre: nombre,
        licenseKey: licenseKey,
      );
      
      // Guardar sesión en SharedPreferences
      await _authService.saveSession(user);
      
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      String errorMessage = 'Error al registrar usuario';

      if (e.toString().contains('duplicate key')) {
        errorMessage = 'El email ya está registrado';
      } else if (e.toString().contains('Licencia inválida')) {
        errorMessage = 'Licencia inválida o inactiva';
        errorMessage = 'Clínica no encontrada. Contacte al administrador';
      } else if (e.toString().contains('Clínica desactivada')) {
        errorMessage = 'Clínica desactivada. Contacte al administrador';
      } else if (e.toString().contains('suscripción activa')) {
        errorMessage = 'La clínica no tiene una suscripción activa';
      } else if (e.toString().contains('vinculado a ninguna clínica')) {
        errorMessage = 'El usuario no está vinculado a ninguna clínica. Contacte al administrador';
      } else {
        // Mostrar el error real en lugar del mensaje genérico
        errorMessage = e.toString();
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signOut();
      state = AuthState(); // Resetear estado
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      String errorMessage = 'Error al restablecer contraseña';

      // Provide specific error messages based on common password reset errors
      if (e.toString().contains('User not found')) {
        errorMessage = 'No existe una cuenta con este email';
      } else if (e.toString().contains('invalid_email')) {
        errorMessage = 'El email no es válido';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage = 'Demasiados intentos. Por favor, espera unos minutos';
      } else {
        errorMessage = 'No se pudo enviar el email de restablecimiento';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  // Limpiar errores
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Establecer error personalizado
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  // Verificar si está autenticado
  bool get isAuthenticated => state.user != null;

  // Verificar si es psicólogo
  bool get isPsicologo => state.user?.isPsicologo ?? false;

  // Verificar si es administrador
  bool get isAdmin => state.user?.isAdministrador ?? false;

  // Obtener rol del usuario
  String? get userRole => state.user?.rol;

  // Verificar si el usuario está activo
  bool get isUserActive => state.user?.isActivo ?? false;

  // Obtener nombre para mostrar
  String get displayName => state.user?.displayName ?? 'Usuario';

  // Obtener ID de la clínica
  String? get clinicaId => state.user?.clinicaId;

  // Verificar si tiene rol específico
  bool hasRole(String role) => state.user?.rol == role;

  // Verificar si puede acceder a funciones de administrador
  bool get canAccessAdmin => isAuthenticated && isAdmin && isUserActive;

  // Verificar si puede acceder a funciones de psicólogo
  bool get canAccessPsicologo => isAuthenticated && isPsicologo && isUserActive;
}

// Provider de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
