import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/usuarios_org_service.dart';
import '../../domain/usuario_org.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final usuariosOrgServiceProvider = Provider<UsuariosOrgService>((ref) {
  final token = ref.watch(currentUserProvider)?.sessionToken ?? '';
  return UsuariosOrgService(Supabase.instance.client, token);
});

class UsuariosOrgState {
  final List<UsuarioOrg> usuarios;
  final bool isLoading;
  final bool isSaving;
  final int limiteUsuarios;
  final int usuariosUsados;
  final int usuariosDisponibles;
  final bool esPlanIlimitado;
  final String? error;
  final String? successMessage;

  const UsuariosOrgState({
    this.usuarios = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.limiteUsuarios = 0,
    this.usuariosUsados = 0,
    this.usuariosDisponibles = 0,
    this.esPlanIlimitado = false,
    this.error,
    this.successMessage,
  });

  UsuariosOrgState copyWith({
    List<UsuarioOrg>? usuarios,
    bool? isLoading,
    bool? isSaving,
    int? limiteUsuarios,
    int? usuariosUsados,
    int? usuariosDisponibles,
    bool? esPlanIlimitado,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) =>
      UsuariosOrgState(
        usuarios: usuarios ?? this.usuarios,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        limiteUsuarios: limiteUsuarios ?? this.limiteUsuarios,
        usuariosUsados: usuariosUsados ?? this.usuariosUsados,
        usuariosDisponibles: usuariosDisponibles ?? this.usuariosDisponibles,
        esPlanIlimitado: esPlanIlimitado ?? this.esPlanIlimitado,
        error: clearMessages ? null : error ?? this.error,
        successMessage:
            clearMessages ? null : successMessage ?? this.successMessage,
      );

  // Contadores por rol
  int get totalPsicologos => usuarios.where((u) => u.rol == 'psicologo').length;
  int get totalSecretarias =>
      usuarios.where((u) => u.rol == 'secretaria').length;
  int get totalAdmins => usuarios.where((u) => u.rol == 'admin').length;
  int get totalActivos => usuarios.where((u) => u.activa).length;
  bool get limiteAlcanzado =>
      !esPlanIlimitado &&
      limiteUsuarios > 0 &&
      usuariosUsados >= limiteUsuarios;
}

class UsuariosOrgNotifier extends StateNotifier<UsuariosOrgState> {
  final UsuariosOrgService _service;

  UsuariosOrgNotifier(this._service) : super(const UsuariosOrgState());

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final results = await Future.wait([
        _service.getUsuarios(),
        _service.getInfoPlan(),
      ]);
      final lista = results[0] as List<UsuarioOrg>;
      final plan = results[1] as UsuariosPlanInfo;
      lista.sort((a, b) => a.nombre.compareTo(b.nombre));
      state = state.copyWith(
        usuarios: lista,
        isLoading: false,
        limiteUsuarios: plan.limiteUsuarios,
        usuariosUsados: plan.usuariosUsados,
        usuariosDisponibles: plan.usuariosDisponibles,
        esPlanIlimitado: plan.esIlimitado,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<bool> crear({
    required String nombre,
    required String email,
    required String password,
    required String rol,
    String? especialidad,
    DateTime? fechaExpiracion,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final plan = await _service.getInfoPlan();
      if (!plan.esIlimitado && plan.usuariosDisponibles <= 0) {
        state = state.copyWith(
          isSaving: false,
          error: 'LÃ­mite de usuarios alcanzado para el plan actual',
          limiteUsuarios: plan.limiteUsuarios,
          usuariosUsados: plan.usuariosUsados,
          usuariosDisponibles: plan.usuariosDisponibles,
          esPlanIlimitado: plan.esIlimitado,
        );
        return false;
      }
      await _service.crearUsuario(
        nombre: nombre,
        email: email,
        password: password,
        rol: rol,
        especialidad: especialidad,
        fechaExpiracion: fechaExpiracion,
      );
      await cargar();
      state = state.copyWith(
          isSaving: false, successMessage: 'Usuario "$nombre" creado');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> editar(
    String userId, {
    String? nombre,
    String? rol,
    bool? activa,
    String? especialidad,
    String? nuevaPassword,
    DateTime? fechaExpiracion,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      await _service.editarUsuario(
        userId,
        nombre: nombre,
        rol: rol,
        activa: activa,
        especialidad: especialidad,
        nuevaPassword: nuevaPassword,
        fechaExpiracion: fechaExpiracion,
      );
      // Actualizar localmente para respuesta inmediata
      state = state.copyWith(
        usuarios: state.usuarios.map((u) {
          if (u.id != userId) return u;
          return UsuarioOrg(
            id: u.id,
            nombre: nombre ?? u.nombre,
            email: u.email,
            rol: rol ?? u.rol,
            activa: activa ?? u.activa,
            especialidad: especialidad ?? u.especialidad,
            fechaExpiracion: fechaExpiracion ?? u.fechaExpiracion,
            ultimoLogin: u.ultimoLogin,
          );
        }).toList(),
        isSaving: false,
        successMessage: 'Usuario actualizado',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(clearMessages: true);
  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}

final usuariosOrgProvider =
    StateNotifierProvider<UsuariosOrgNotifier, UsuariosOrgState>((ref) {
  return UsuariosOrgNotifier(ref.read(usuariosOrgServiceProvider));
});
