import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/nota_terapia.dart';
import '../../data/nota_terapia_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final notaTerapiaServiceProvider = Provider<NotaTerapiaService>((ref) {
  return NotaTerapiaService(Supabase.instance.client);
});

class NotasTerapiaState {
  final List<NotaTerapia> notas;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final int totalCount;
  final int esteMesCount;

  const NotasTerapiaState({
    this.notas = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.totalCount = 0,
    this.esteMesCount = 0,
  });

  NotasTerapiaState copyWith({
    List<NotaTerapia>? notas,
    bool? isLoading,
    String? error,
    String? successMessage,
    int? totalCount,
    int? esteMesCount,
  }) {
    return NotasTerapiaState(
      notas: notas ?? this.notas,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage,
      totalCount: totalCount ?? this.totalCount,
      esteMesCount: esteMesCount ?? this.esteMesCount,
    );
  }
}

class NotasTerapiaNotifier extends StateNotifier<NotasTerapiaState> {
  final NotaTerapiaService _service;
  final Ref _ref;

  NotasTerapiaNotifier(this._service, this._ref) : super(const NotasTerapiaState());

  Future<void> loadNotasTerapia({bool forceRefresh = false}) async {
    if (!forceRefresh && state.notas.isNotEmpty) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      final notas = await _service.getNotasTerapia();
      
      // Apply role-based filtering at provider level
      final filteredNotas = psicologoId != null
          ? notas.where((n) => n.psicologoId == psicologoId).toList()
          : notas; // Admin sees all
      
      final totalCount = filteredNotas.length;
      final esteMes = DateTime.now().month;
      final esteMesCount = filteredNotas
          .where((n) => n.fecha.month == esteMes)
          .length;
      
      state = state.copyWith(
        notas: filteredNotas,
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

  Future<void> loadNotasPorPaciente(String pacienteId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      final notas = await _service.getNotasPorPaciente(pacienteId);
      
      // Apply role-based filtering at provider level
      final filteredNotas = psicologoId != null
          ? notas.where((n) => n.psicologoId == psicologoId).toList()
          : notas; // Admin sees all
      
      state = state.copyWith(
        notas: filteredNotas,
        isLoading: false,
        totalCount: filteredNotas.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createNotaTerapia({
    required String pacienteId,
    required DateTime fecha,
    required String notas,
    String? citaId,
    String? objetivos,
    String? progreso,
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
      
      final nuevaNota = await _service.createNotaTerapia(
        pacienteId: pacienteId,
        psicologoId: psicologoId,
        fecha: fecha,
        notas: notas,
        citaId: citaId,
        objetivos: objetivos,
        progreso: progreso,
      );
      
      final updatedNotas = [nuevaNota, ...state.notas];
      final totalCount = state.totalCount + 1;
      
      final esteMes = DateTime.now().month;
      final esteMesCount = nuevaNota.fecha.month == esteMes
          ? state.esteMesCount + 1
          : state.esteMesCount;
      
      state = state.copyWith(
        notas: updatedNotas,
        isLoading: false,
        successMessage: 'Nota de terapia creada exitosamente',
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

  Future<void> updateNotaTerapia({
    required String id,
    DateTime? fecha,
    String? notas,
    String? objetivos,
    String? progreso,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      // Check if user has permission to update this note
      final nota = state.notas.firstWhere((n) => n.id == id);
      if (psicologoId != null && nota.psicologoId != psicologoId) {
        state = state.copyWith(
          isLoading: false,
          error: 'No tienes permiso para editar esta nota',
        );
        return;
      }
      
      final notaActualizada = await _service.updateNotaTerapia(
        id: id,
        fecha: fecha,
        notas: notas,
        objetivos: objetivos,
        progreso: progreso,
      );
      
      final updatedNotas = state.notas
          .map((n) => n.id == id ? notaActualizada : n)
          .toList();
      
      state = state.copyWith(
        notas: updatedNotas,
        isLoading: false,
        successMessage: 'Nota de terapia actualizada exitosamente',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteNotaTerapia(String id) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      // Check if user has permission to delete this note
      final nota = state.notas.firstWhere((n) => n.id == id);
      if (psicologoId != null && nota.psicologoId != psicologoId) {
        state = state.copyWith(
          isLoading: false,
          error: 'No tienes permiso para eliminar esta nota',
        );
        return;
      }
      
      await _service.deleteNotaTerapia(id);
      
      final updatedNotas = state.notas.where((n) => n.id != id).toList();
      final totalCount = state.totalCount - 1;
      
      final esteMes = DateTime.now().month;
      final esteMesCount = nota.fecha.month == esteMes
          ? state.esteMesCount - 1
          : state.esteMesCount;
      
      state = state.copyWith(
        notas: updatedNotas,
        isLoading: false,
        successMessage: 'Nota de terapia eliminada exitosamente',
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

  Future<void> buscarNotasTerapia(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      final notas = await _service.buscarNotasTerapia(query);
      
      // Apply role-based filtering at provider level
      final filteredNotas = psicologoId != null
          ? notas.where((n) => n.psicologoId == psicologoId).toList()
          : notas; // Admin sees all
      
      state = state.copyWith(
        notas: filteredNotas,
        isLoading: false,
        totalCount: filteredNotas.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadNotasPorCita(String citaId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      final notas = await _service.getNotasPorCita(citaId);
      
      // Apply role-based filtering at provider level
      final filteredNotas = psicologoId != null
          ? notas.where((n) => n.psicologoId == psicologoId).toList()
          : notas; // Admin sees all
      
      state = state.copyWith(
        notas: filteredNotas,
        isLoading: false,
        totalCount: filteredNotas.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadNotasPorRango(DateTime inicio, DateTime fin) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authState = _ref.read(authProvider);
      final psicologoId = authState.user?.id;
      
      final notas = await _service.getNotasPorRango(inicio, fin);
      
      // Apply role-based filtering at provider level
      final filteredNotas = psicologoId != null
          ? notas.where((n) => n.psicologoId == psicologoId).toList()
          : notas; // Admin sees all
      
      state = state.copyWith(
        notas: filteredNotas,
        isLoading: false,
        totalCount: filteredNotas.length,
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

final notasTerapiaProvider = StateNotifierProvider<NotasTerapiaNotifier, NotasTerapiaState>((ref) {
  return NotasTerapiaNotifier(ref.read(notaTerapiaServiceProvider), ref);
});
