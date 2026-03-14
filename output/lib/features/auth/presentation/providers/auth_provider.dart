import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_service.dart';
import '../../domain/app_user.dart';

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
    bool clearUser  = false,
    bool clearError = false,
  }) {
    return AuthState(
      user:      clearUser  ? null  : user      ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error:     clearError ? null  : error     ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isAdmin         => user?.isAdmin ?? false;
  bool get isPsicologo     => user?.isPsicologo ?? false;
}

// ── NOTIFIER ──────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState());

  // Llamado por AuthWrapper al iniciar la app
  // Verifica si el token guardado localmente sigue siendo válido en la BD
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _service.getSessionUser();
      state = state.copyWith(user: user, isLoading: false, clearError: true);
    } catch (_) {
      // Si falla la conexión al validar, no cerramos sesión — mostramos login
      state = state.copyWith(isLoading: false);
    }
  }

  // Login con email + password
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.signIn(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Logout: invalida el token en BD y limpia localmente
  Future<void> signOut() async {
    final token = state.user?.sessionToken ?? '';
    await _service.signOut(token);
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
