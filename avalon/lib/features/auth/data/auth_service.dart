import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/app_user.dart';
import '../../../core/constants/app_constants.dart';

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  // ── LOGIN ────────────────────────────────────────────────────────────────
  Future<AppUser> signIn(String email, String password) async {
    // 1. Autenticar con Supabase Auth → activa auth.uid() para RLS
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user == null) throw Exception('Credenciales incorrectas');

    // 2. Cargar perfil desde public.usuarios
    final data = await _client
        .from(AppConstants.tableUsuarios)
        .select()
        .eq('auth_user_id', res.user!.id)
        .eq('activa', true)
        .maybeSingle();

    if (data == null) {
      await _client.auth.signOut();
      throw Exception('Usuario no encontrado o inactivo');
    }

    return AppUser.fromJson(data);
  }

  // ── LOGOUT ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── SESIÓN ACTIVA ────────────────────────────────────────────────────────
  // Recupera el usuario si Supabase Auth tiene sesión guardada (ej. al reabrir app)
  Future<AppUser?> getSessionUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final data = await _client
        .from(AppConstants.tableUsuarios)
        .select()
        .eq('auth_user_id', authUser.id)
        .eq('activa', true)
        .maybeSingle();

    if (data == null) return null;
    return AppUser.fromJson(data);
  }
}
