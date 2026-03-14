import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_service.dart';
import '../../domain/app_user.dart';

// ── SERVICIO ─────────────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

// ── ESTADO ───────────────────────────────────────────────────────────────────
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({AppUser? user, bool? isLoading, String? error, bool clearUser = false}) {
    return AuthState(
      user:      clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error:     error,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isAdmin         => user?.isAdmin ?? false;
}

// ── NOTIFIER ─────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;
  AuthNotifier(this._service) : super(const AuthState());

  // Recuperar sesión al abrir la app
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _service.getSessionUser();
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  // Login
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.signIn(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message.contains('Invalid login credentials')
            ? 'Email o contraseña incorrectos'
            : e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Logout
  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(error: null);
}

// ── PROVIDER PRINCIPAL ───────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

// ── PROVIDERS DERIVADOS ──────────────────────────────────────────────────────
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAdmin;
});
