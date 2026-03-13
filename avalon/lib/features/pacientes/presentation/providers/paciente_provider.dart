import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/paciente.dart';
import '../../data/paciente_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final pacienteServiceProvider = Provider<PacienteService>((ref) {
  return PacienteService(Supabase.instance.client);
});

class PacientesState {
  final List<Paciente> pacientes;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final int totalCount;
  final int activeCount;

  const PacientesState({
    this.pacientes = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.totalCount = 0,
    this.activeCount = 0,
  });

  PacientesState copyWith({
    List<Paciente>? pacientes,
    bool? isLoading,
    String? error,
    String? successMessage,
    int? totalCount,
    int? activeCount,
  }) {
    return PacientesState(
      pacientes: pacientes ?? this.pacientes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage,
      totalCount: totalCount ?? this.totalCount,
      activeCount: activeCount ?? this.activeCount,
    );
  }
}

class PacientesNotifier extends StateNotifier<PacientesState> {
  final PacienteService _service;
  final Ref _ref;

  PacientesNotifier(this._service, this._ref) : super(const PacientesState());

  Future<void> loadPacientes() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Get current user info for filtering
      final authState = _ref.read(authProvider);
      final currentUser = authState.user;
      final userId = currentUser?.id;
      final userRole = currentUser?.rol;
      
      Logger.debug('🔐 PACIENTE PROVIDER DEBUG: userId: $userId, userRole: $userRole', 'PacientesNotifier');
      
      final pacientes = await _service.getPacientes(
        userId: userId,
        userRole: userRole,
      );
      final totalCount = await _service.getTotalPacientes(userId: userId, userRole: userRole);
      final activeCount = await _service.getPacientesActivosCount(userId: userId, userRole: userRole);
      
      state = state.copyWith(
        pacientes: pacientes,
        isLoading: false,
        totalCount: totalCount,
        activeCount: activeCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadPacientesActivos() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final pacientes = await _service.getPacientesActivos();
      final totalCount = await _service.getTotalPacientes();
      final activeCount = await _service.getPacientesActivosCount();
      
      state = state.copyWith(
        pacientes: pacientes,
        isLoading: false,
        totalCount: totalCount,
        activeCount: activeCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> buscarPacientes(String query) async {
    if (query.trim().isEmpty) {
      await loadPacientes();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final pacientes = await _service.buscarPacientes(query);
      
      state = state.copyWith(
        pacientes: pacientes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createPaciente({
    required String nombre,
    required String email,
    required String numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    String? licenciaId,
    String? deviceId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      final nuevoPaciente = await _service.createPaciente(
        nombre: nombre,
        email: email,
        numeroDocumento: numeroDocumento,
        telefono: telefono,
        direccion: direccion,
        fechaNacimiento: fechaNacimiento,
        historialMedico: historialMedico,
        licenciaId: licenciaId,
        deviceId: deviceId,
        creadoPor: psicologoId, // Use authenticated user ID
      );
      
      final updatedPacientes = [nuevoPaciente, ...state.pacientes];
      final totalCount = state.totalCount + 1;
      final activeCount = state.activeCount + 1;
      
      state = state.copyWith(
        pacientes: updatedPacientes,
        isLoading: false,
        successMessage: 'Paciente creado exitosamente',
        totalCount: totalCount,
        activeCount: activeCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updatePaciente({
    required String id,
    String? nombre,
    String? email,
    String? numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    bool? activo,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      final pacienteActualizado = await _service.updatePaciente(
        id: id,
        nombre: nombre,
        email: email,
        numeroDocumento: numeroDocumento,
        telefono: telefono,
        direccion: direccion,
        fechaNacimiento: fechaNacimiento,
        historialMedico: historialMedico,
        activo: activo,
      );
      
      final updatedPacientes = state.pacientes.map((p) {
        return p.id == id ? pacienteActualizado : p;
      }).toList();
      
      state = state.copyWith(
        pacientes: updatedPacientes,
        isLoading: false,
        successMessage: 'Paciente actualizado exitosamente',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deletePaciente(String id) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _service.deletePaciente(id);
      
      final updatedPacientes = state.pacientes.where((p) => p.id != id).toList();
      final totalCount = state.totalCount - 1;
      final pacienteEliminado = state.pacientes.firstWhere((p) => p.id == id);
      final activeCount = pacienteEliminado.activo ? state.activeCount - 1 : state.activeCount;
      
      state = state.copyWith(
        pacientes: updatedPacientes,
        isLoading: false,
        successMessage: 'Paciente eliminado exitosamente',
        totalCount: totalCount,
        activeCount: activeCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> togglePacienteStatus(String id) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _service.togglePacienteStatus(id);
      
      final updatedPacientes = state.pacientes.map((p) {
        if (p.id == id) {
          final newActivo = !p.activo;
          return p.copyWith(activo: newActivo);
        }
        return p;
      }).toList();
      
      final pacienteActualizado = updatedPacientes.firstWhere((p) => p.id == id);
      final activeCount = pacienteActualizado.activo 
          ? state.activeCount + 1 
          : state.activeCount - 1;
      
      state = state.copyWith(
        pacientes: updatedPacientes,
        isLoading: false,
        successMessage: 'Estado del paciente actualizado exitosamente',
        activeCount: activeCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> desactivarPaciente(String id) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _service.desactivarPaciente(id);
      
      final updatedPacientes = state.pacientes.map((p) {
        return p.id == id ? p.copyWith(activo: false) : p;
      }).toList();
      
      state = state.copyWith(
        pacientes: updatedPacientes,
        isLoading: false,
        successMessage: 'Paciente desactivado exitosamente',
        activeCount: state.activeCount - 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearMessages() {
    if (state.error != null || state.successMessage != null) {
      state = state.copyWith(error: null, successMessage: null);
    }
  }

  void updatePacientes(List<Paciente> pacientes) {
    state = state.copyWith(pacientes: pacientes);
  }
}

final pacientesProvider = StateNotifierProvider<PacientesNotifier, PacientesState>((ref) {
  return PacientesNotifier(ref.read(pacienteServiceProvider), ref);
});

final pacienteByIdProvider = FutureProvider.family<Paciente, String>((ref, id) async {
  final service = ref.watch(pacienteServiceProvider);
  return await service.getPacienteById(id);
});
