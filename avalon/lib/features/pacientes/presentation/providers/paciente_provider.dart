import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/paciente.dart';
import '../../data/paciente_service.dart';

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

  PacientesNotifier(this._service) : super(const PacientesState());

  Future<void> loadPacientes() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final pacientes = await _service.getPacientes();
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
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      final nuevoPaciente = await _service.createPaciente(
        nombre: nombre,
        email: email,
        numeroDocumento: numeroDocumento,
        telefono: telefono,
        direccion: direccion,
        fechaNacimiento: fechaNacimiento,
        historialMedico: historialMedico,
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
    state = state.copyWith(error: null, successMessage: null);
  }
}

final pacientesProvider = StateNotifierProvider<PacientesNotifier, PacientesState>((ref) {
  final service = ref.watch(pacienteServiceProvider);
  return PacientesNotifier(service);
});

final pacienteByIdProvider = FutureProvider.family<Paciente, String>((ref, id) async {
  final service = ref.watch(pacienteServiceProvider);
  return await service.getPacienteById(id);
});
