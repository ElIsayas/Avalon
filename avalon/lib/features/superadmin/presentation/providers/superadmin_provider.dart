import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/superadmin_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── SERVICE PROVIDER ──────────────────────────────────────────────────────────
final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  final token = ref.watch(currentUserProvider)?.sessionToken ?? '';
  return SuperAdminService(Supabase.instance.client, token);
});

// ── ESTADO ────────────────────────────────────────────────────────────────────
class SuperAdminState {
  final SaMetricas? metricas;
  final List<SaOrganizacion> organizaciones;
  final List<SaUsuario> usuarios;
  final List<SaPago> pagos;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const SuperAdminState({
    this.metricas,
    this.organizaciones = const [],
    this.usuarios = const [],
    this.pagos = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  SuperAdminState copyWith({
    SaMetricas? metricas,
    List<SaOrganizacion>? organizaciones,
    List<SaUsuario>? usuarios,
    List<SaPago>? pagos,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) =>
      SuperAdminState(
        metricas: metricas ?? this.metricas,
        organizaciones: organizaciones ?? this.organizaciones,
        usuarios: usuarios ?? this.usuarios,
        pagos: pagos ?? this.pagos,
        isLoading: isLoading ?? this.isLoading,
        error: clearMessages ? null : error ?? this.error,
        successMessage:
            clearMessages ? null : successMessage ?? this.successMessage,
      );
}

// ── NOTIFIER ──────────────────────────────────────────────────────────────────
class SuperAdminNotifier extends StateNotifier<SuperAdminState> {
  final SuperAdminService _svc;
  SuperAdminNotifier(this._svc) : super(const SuperAdminState());

  // ── Carga inicial ────────────────────────────────────────────────────
  Future<void> cargarTodo() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final results = await Future.wait([
        _svc.getMetricas(),
        _svc.getOrganizaciones(),
      ]);
      state = state.copyWith(
        metricas: results[0] as SaMetricas,
        organizaciones: results[1] as List<SaOrganizacion>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<void> cargarUsuarios({String? orgId}) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final lista = await _svc.getUsuarios(orgId: orgId);
      state = state.copyWith(usuarios: lista, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<void> cargarPagos({String? orgId}) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final lista = await _svc.getPagos(orgId: orgId);
      state = state.copyWith(pagos: lista, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  // ── Organizaciones ───────────────────────────────────────────────────
  Future<bool> crearOrganizacion(String nombre) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _svc.crearOrganizacion(nombre);
      await cargarTodo();
      state = state.copyWith(successMessage: 'Organización "$nombre" creada');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> editarOrganizacion(String orgId,
      {String? nombre, bool? activa}) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _svc.editarOrganizacion(orgId, nombre: nombre, activa: activa);
      await cargarTodo();
      state = state.copyWith(successMessage: 'Organización actualizada');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> cambiarPlan(String orgId, String plan,
      {DateTime? vencimiento, int? maxCustom}) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _svc.cambiarPlan(orgId, plan,
          vencimiento: vencimiento, maxCustom: maxCustom);
      await cargarTodo();
      state = state.copyWith(successMessage: 'Plan actualizado a $plan');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> ajustarLimitePlatinum(String orgId, int nuevoMax) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _svc.ajustarLimitePlatinum(orgId, nuevoMax);
      await cargarTodo();
      state = state.copyWith(
          successMessage: 'Límite actualizado a $nuevoMax usuarios');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return false;
    }
  }

  // ── Usuarios ─────────────────────────────────────────────────────────
  Future<bool> crearUsuario({
    required String orgId,
    required String nombre,
    required String email,
    required String password,
    String rol = 'psicologo',
    String? especialidad,
    DateTime? fechaExpiracion,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _svc.crearUsuario(
        orgId: orgId,
        nombre: nombre,
        email: email,
        password: password,
        rol: rol,
        especialidad: especialidad,
        fechaExpiracion: fechaExpiracion,
      );
      await cargarUsuarios();
      state = state.copyWith(successMessage: 'Usuario "$nombre" creado');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> editarUsuario(
    String userId, {
    String? nombre,
    String? rol,
    bool? activa,
    String? especialidad,
    DateTime? fechaExpiracion,
    String? nuevaPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _svc.editarUsuario(
        userId,
        nombre: nombre,
        rol: rol,
        activa: activa,
        especialidad: especialidad,
        fechaExpiracion: fechaExpiracion,
        nuevaPassword: nuevaPassword,
      );
      // Actualizar localmente para respuesta inmediata
      state = state.copyWith(
        usuarios: state.usuarios.map((u) {
          if (u.id != userId) return u;
          return SaUsuario(
            id: u.id,
            nombre: nombre ?? u.nombre,
            email: u.email,
            rol: rol ?? u.rol,
            activa: activa ?? u.activa,
            especialidad: especialidad ?? u.especialidad,
            organizacion: u.organizacion,
            organizacionId: u.organizacionId,
            ultimoLogin: u.ultimoLogin,
            fechaExpiracion: fechaExpiracion ?? u.fechaExpiracion,
          );
        }).toList(),
        isLoading: false,
        successMessage: 'Usuario actualizado',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(clearMessages: true);
  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}

// ── PROVIDER ──────────────────────────────────────────────────────────────────
final superAdminProvider =
    StateNotifierProvider<SuperAdminNotifier, SuperAdminState>((ref) {
  return SuperAdminNotifier(ref.read(superAdminServiceProvider));
});
