import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/paciente_service.dart';
import '../../domain/paciente.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

// ── SERVICIO ─────────────────────────────────────────────────────────────────
final pacienteServiceProvider = Provider<PacienteService>((ref) {
  return PacienteService(Supabase.instance.client);
});

// ── ESTADO ───────────────────────────────────────────────────────────────────
class PacientesState {
  final List<Paciente> pacientes;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const PacientesState({
    this.pacientes = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  PacientesState copyWith({
    List<Paciente>? pacientes,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return PacientesState(
      pacientes:      pacientes ?? this.pacientes,
      isLoading:      isLoading ?? this.isLoading,
      error:          clearMessages ? null : error ?? this.error,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
    );
  }

  int get total   => pacientes.length;
  int get activos => pacientes.where((p) => p.activo).length;
}

// ── NOTIFIER ─────────────────────────────────────────────────────────────────
class PacientesNotifier extends StateNotifier<PacientesState> {
  final PacienteService _service;
  final Ref _ref;

  PacientesNotifier(this._service, this._ref) : super(const PacientesState());

  String? get _currentUserId => _ref.read(currentUserProvider)?.id;

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final lista = await _service.getAll();
      state = state.copyWith(pacientes: lista, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<void> buscar(String query) async {
    if (query.trim().isEmpty) { await cargar(); return; }
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final lista = await _service.buscar(query);
      state = state.copyWith(pacientes: lista, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<bool> crear({
    required String nombre,
    required String email,
    required String numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    String? objetivosTerapeuticos,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      state = state.copyWith(error: 'Sesión expirada');
      return false;
    }
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final nuevo = await _service.crear(
        nombre: nombre,
        email: email,
        numeroDocumento: numeroDocumento,
        creadoPor: userId,
        telefono: telefono,
        direccion: direccion,
        fechaNacimiento: fechaNacimiento,
        historialMedico: historialMedico,
        objetivosTerapeuticos: objetivosTerapeuticos,
      );
      state = state.copyWith(
        pacientes: [nuevo, ...state.pacientes],
        isLoading: false,
        successMessage: 'Paciente creado exitosamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> actualizar({
    required String id,
    String? nombre,
    String? email,
    String? numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    String? objetivosTerapeuticos,
    bool? activo,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final actualizado = await _service.actualizar(
        id: id, nombre: nombre, email: email,
        numeroDocumento: numeroDocumento, telefono: telefono,
        direccion: direccion, fechaNacimiento: fechaNacimiento,
        historialMedico: historialMedico,
        objetivosTerapeuticos: objetivosTerapeuticos, activo: activo,
      );
      state = state.copyWith(
        pacientes: state.pacientes.map((p) => p.id == id ? actualizado : p).toList(),
        isLoading: false,
        successMessage: 'Paciente actualizado',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _service.eliminar(id);
      state = state.copyWith(
        pacientes: state.pacientes.where((p) => p.id != id).toList(),
        isLoading: false,
        successMessage: 'Paciente eliminado',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return false;
    }
  }

  Future<void> toggleActivo(String id) async {
    final paciente = state.pacientes.firstWhere((p) => p.id == id);
    final nuevoEstado = !paciente.activo;
    try {
      await _service.toggleActivo(id, nuevoEstado);
      state = state.copyWith(
        pacientes: state.pacientes
            .map((p) => p.id == id ? p.copyWith(activo: nuevoEstado) : p)
            .toList(),
        successMessage: nuevoEstado ? 'Paciente activado' : 'Paciente desactivado',
      );
    } catch (e) {
      state = state.copyWith(error: _msg(e));
    }
  }

  void clearMessages() => state = state.copyWith(clearMessages: true);

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}

// ── PROVIDER ─────────────────────────────────────────────────────────────────
final pacientesProvider = StateNotifierProvider<PacientesNotifier, PacientesState>((ref) {
  return PacientesNotifier(ref.read(pacienteServiceProvider), ref);
});
