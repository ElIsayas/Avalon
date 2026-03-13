import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/evaluacion.dart';
import '../../data/evaluacion_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final evaluacionServiceProvider = Provider<EvaluacionService>((ref) {
  return EvaluacionService(Supabase.instance.client);
});

class EvaluacionesState {
  final List<Evaluacion> evaluaciones;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final int totalCount;
  final int esteMesCount;

  const EvaluacionesState({
    this.evaluaciones = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.totalCount = 0,
    this.esteMesCount = 0,
  });

  EvaluacionesState copyWith({
    List<Evaluacion>? evaluaciones,
    bool? isLoading,
    String? error,
    String? successMessage,
    int? totalCount,
    int? esteMesCount,
  }) {
    return EvaluacionesState(
      evaluaciones: evaluaciones ?? this.evaluaciones,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage,
      totalCount: totalCount ?? this.totalCount,
      esteMesCount: esteMesCount ?? this.esteMesCount,
    );
  }
}

class EvaluacionesNotifier extends StateNotifier<EvaluacionesState> {
  final EvaluacionService _service;
  final Ref _ref;

  EvaluacionesNotifier(this._service, this._ref) : super(const EvaluacionesState());

  Future<void> loadEvaluaciones({bool forceRefresh = false}) async {
    if (!forceRefresh && state.evaluaciones.isNotEmpty) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      final evaluaciones = await _service.getEvaluaciones();
      
      // Apply role-based filtering at provider level
      final filteredEvaluaciones = psicologoId != null
          ? evaluaciones.where((e) => e.psicologoId == psicologoId).toList()
          : evaluaciones; // Admin sees all
      
      final totalCount = filteredEvaluaciones.length;
      final esteMes = DateTime.now().month;
      final esteMesCount = filteredEvaluaciones
          .where((e) => e.fechaRealizacion.month == esteMes)
          .length;
      
      state = state.copyWith(
        evaluaciones: filteredEvaluaciones,
        isLoading: false,
        totalCount: totalCount,
        esteMesCount: esteMesCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadEvaluacionesPorPaciente(String pacienteId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      final evaluaciones = await _service.getEvaluacionesPorPaciente(pacienteId);
      
      // Apply role-based filtering at provider level
      final filteredEvaluaciones = psicologoId != null
          ? evaluaciones.where((e) => e.psicologoId == psicologoId).toList()
          : evaluaciones; // Admin sees all
      
      state = state.copyWith(
        evaluaciones: filteredEvaluaciones,
        isLoading: false,
        totalCount: filteredEvaluaciones.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createEvaluacion({
    required String pacienteId,
    required String tipoTest,
    required DateTime fechaRealizacion,
    String? citaId,
    String? resultados,
    String? observaciones,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      if (psicologoId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Usuario no autenticado',
        );
        return;
      }
      
      final nuevaEvaluacion = await _service.createEvaluacion(
        pacienteId: pacienteId,
        psicologoId: psicologoId,
        tipoTest: tipoTest,
        fechaRealizacion: fechaRealizacion,
        citaId: citaId,
        resultados: resultados,
        observaciones: observaciones,
      );
      
      final updatedEvaluaciones = [nuevaEvaluacion, ...state.evaluaciones];
      final totalCount = state.totalCount + 1;
      
      final esteMes = DateTime.now().month;
      final esteMesCount = nuevaEvaluacion.fechaRealizacion.month == esteMes
          ? state.esteMesCount + 1
          : state.esteMesCount;
      
      state = state.copyWith(
        evaluaciones: updatedEvaluaciones,
        isLoading: false,
        successMessage: 'Evaluación creada exitosamente',
        totalCount: totalCount,
        esteMesCount: esteMesCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateEvaluacion({
    required String id,
    String? tipoTest,
    DateTime? fechaRealizacion,
    String? citaId,
    String? resultados,
    String? observaciones,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      // Check if user has permission to update this evaluation
      final evaluacion = state.evaluaciones.firstWhere((e) => e.id == id);
      if (psicologoId != null && evaluacion.psicologoId != psicologoId) {
        state = state.copyWith(
          isLoading: false,
          error: 'No tienes permiso para editar esta evaluación',
        );
        return;
      }
      
      final evaluacionActualizada = await _service.updateEvaluacion(
        id: id,
        tipoTest: tipoTest,
        fechaRealizacion: fechaRealizacion,
        citaId: citaId,
        resultados: resultados,
        observaciones: observaciones,
      );
      
      final updatedEvaluaciones = state.evaluaciones
          .map((e) => e.id == id ? evaluacionActualizada : e)
          .toList();
      
      state = state.copyWith(
        evaluaciones: updatedEvaluaciones,
        isLoading: false,
        successMessage: 'Evaluación actualizada exitosamente',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteEvaluacion(String id) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      // Check if user has permission to delete this evaluation
      final evaluacion = state.evaluaciones.firstWhere((e) => e.id == id);
      if (psicologoId != null && evaluacion.psicologoId != psicologoId) {
        state = state.copyWith(
          isLoading: false,
          error: 'No tienes permiso para eliminar esta evaluación',
        );
        return;
      }
      
      await _service.deleteEvaluacion(id);
      
      final updatedEvaluaciones = state.evaluaciones.where((e) => e.id != id).toList();
      final totalCount = state.totalCount - 1;
      
      final esteMes = DateTime.now().month;
      final esteMesCount = evaluacion.fechaRealizacion.month == esteMes
          ? state.esteMesCount - 1
          : state.esteMesCount;
      
      state = state.copyWith(
        evaluaciones: updatedEvaluaciones,
        isLoading: false,
        successMessage: 'Evaluación eliminada exitosamente',
        totalCount: totalCount,
        esteMesCount: esteMesCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> buscarEvaluaciones(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      final evaluaciones = await _service.buscarEvaluaciones(query);
      
      // Apply role-based filtering at provider level
      final filteredEvaluaciones = psicologoId != null
          ? evaluaciones.where((e) => e.psicologoId == psicologoId).toList()
          : evaluaciones; // Admin sees all
      
      state = state.copyWith(
        evaluaciones: filteredEvaluaciones,
        isLoading: false,
        totalCount: filteredEvaluaciones.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadEvaluacionesPorTipo(String tipoTest) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      final evaluaciones = await _service.getEvaluacionesPorTipo(tipoTest);
      
      // Apply role-based filtering at provider level
      final filteredEvaluaciones = psicologoId != null
          ? evaluaciones.where((e) => e.psicologoId == psicologoId).toList()
          : evaluaciones; // Admin sees all
      
      state = state.copyWith(
        evaluaciones: filteredEvaluaciones,
        isLoading: false,
        totalCount: filteredEvaluaciones.length,
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

final evaluacionesProvider = StateNotifierProvider<EvaluacionesNotifier, EvaluacionesState>((ref) {
  return EvaluacionesNotifier(ref.read(evaluacionServiceProvider), ref);
});
