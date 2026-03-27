import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_service.dart';
import '../../domain/app_user.dart';
import '../../../../core/utils/logger.dart';

// ── SERVICIO ──────────────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

// ── ESTADO ────────────────────────────────────────────────────────────────────
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isPsicologo => user?.isPsicologo ?? false;
}

// ── NOTIFIER ──────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState());

  // Llamado por AuthWrapper al iniciar la app
  // Verifica si el token guardado localmente sigue siendo válido en la BD
  Future<void> initialize() async {
    AppLogger.auth('Inicializando auth provider');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.getSessionUser();
      if (user != null) {
        AppLogger.auth('Usuario recuperado: ${user.email}, rol: ${user.rol}');
      } else {
        AppLogger.auth('No hay sesión activa');
      }
      state = state.copyWith(user: user, isLoading: false, clearError: true);
    } on SessionExpiredException catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        error: e.message,
      );
    } on NetworkAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        error: e.message,
      );
    } catch (e, stackTrace) {
      AppLogger.auth('Error inicializando auth: $e',
          error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  // Login con email + password
  Future<void> signIn(String email, String password) async {
    AppLogger.auth('Iniciando signIn desde provider');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.signIn(email, password);
      AppLogger.auth('Login exitoso: ${user.email}, rol: ${user.rol}');
      state = state.copyWith(user: user, isLoading: false);
    } on NetworkAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e, stackTrace) {
      AppLogger.auth('Error en signIn provider: $e',
          error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.sendPasswordReset(email);
      state = state.copyWith(isLoading: false);
    } on NetworkAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Logout: invalida el token en BD y limpia localmente
  Future<void> signOut() async {
    AppLogger.auth('Iniciando logout desde provider');
    final token = state.user?.sessionToken ?? '';
    try {
      await _service.signOut(token);
      AppLogger.auth('Logout exitoso');
    } catch (e, stackTrace) {
      AppLogger.auth('Error en logout provider: $e',
          error: e, stackTrace: stackTrace);
    }
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── PROVIDER PRINCIPAL ────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

// ── PROVIDERS DERIVADOS ───────────────────────────────────────────────────────
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAdmin;
});
