import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_service.dart';
import '../../domain/auth_user.dart' as auth;
import '../../../../core/supabase/supabase.dart';

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
  int get hashCode => user.hashCode ^ isLoading.hashCode ^ error.hashCode;
}

// Provider del servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(supabase);
});

// Provider del estado de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Notifier para manejar el estado de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  // Inicializar autenticación manualmente
  Future<void> initialize() async {
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      String errorMessage = 'Error al iniciar sesión';

      // Provide specific error messages based on common authentication errors
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Email o contraseña incorrectos';
      } else if (e.toString().contains('User not found')) {
        errorMessage = 'No existe una cuenta con este email';
      } else if (e.toString().contains('Invalid password')) {
        errorMessage = 'Contraseña incorrecta';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Por favor, confirma tu email antes de iniciar sesión';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage = 'Demasiados intentos. Por favor, espera unos minutos';
      } else {
        errorMessage = 'Email o contraseña incorrectos';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  // Registrar usuario
  Future<void> signUp({
    required String email,
    required String password,
    required String nombre,
    required String numeroDocumento,
    String? clinicaId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        nombre: nombre,
        numeroDocumento: numeroDocumento,
        clinicaId: clinicaId,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      // Mostrar error real para debugging
      print("ERROR REGISTER: $e");

      String errorMessage = 'Error al crear cuenta';

      // Provide specific error messages based on common registration errors
      if (e.toString().contains('User already registered')) {
        errorMessage = 'Ya existe una cuenta con este email';
      } else if (e.toString().contains('duplicate key')) {
        errorMessage = 'El número de documento ya está registrado';
      } else if (e.toString().contains('weak_password')) {
        errorMessage =
            'La contraseña es muy débil. Debe tener al menos 6 caracteres';
      } else if (e.toString().contains('invalid_email')) {
        errorMessage = 'El email no es válido';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage = 'Demasiados intentos. Por favor, espera unos minutos';
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

  // Obtener nombre para mostrar
  String get displayName => state.user?.displayName ?? 'Usuario';
}
