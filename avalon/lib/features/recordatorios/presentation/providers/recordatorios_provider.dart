import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/recordatorio_ex.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';

// ── SERVICE ───────────────────────────────────────────────────────────────────
class RecordatoriosExService {
  final SupabaseClient _client;
  final String _token;

  RecordatoriosExService(this._client, this._token);

  Future<List<RecordatorioEx>> getRecordatorios(
      {bool incluirResueltos = false}) async {
    try {
      final res = await _client.rpc('get_recordatorios', params: {
        'p_token': _token,
      });
      final lista = (res as List? ?? [])
          .map((j) => RecordatorioEx.fromJson(j as Map<String, dynamic>))
          .toList();
      return incluirResueltos
          ? lista
          : lista.where((r) => !r.resuelto).toList();
    } catch (e, st) {
      AppLogger.database('Error obteniendo recordatorios: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> crear({
    required String titulo,
    String? descripcion,
    String prioridad = 'normal',
    String categoria = 'tarea',
    String? asignadoA,
    DateTime? fechaVencimiento,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_token': _token,
        'p_titulo': titulo,
        'p_prioridad': prioridad,
      };
      if (descripcion != null) params['p_descripcion'] = descripcion;
      if (asignadoA != null) params['p_asignado_a'] = asignadoA;
      if (fechaVencimiento != null) {
        params['p_fecha_vencimiento'] =
            fechaVencimiento.toIso8601String().split('T')[0];
      }
      // categoria se pasa si el RPC lo acepta
      params['p_categoria'] = categoria;

      final res = await _client.rpc('crear_recordatorio', params: params);
      final data = res as Map<String, dynamic>?;
      if (data != null && data.containsKey('error')) {
        throw Exception(data['error']);
      }
    } catch (e, st) {
      AppLogger.database('Error creando recordatorio: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> resolver(String id) async {
    try {
      final res = await _client.rpc('resolver_recordatorio', params: {
        'p_token': _token,
        'p_recordatorio_id': id,
      });
      final data = res as Map<String, dynamic>?;
      if (data != null && data.containsKey('error')) {
        throw Exception(data['error']);
      }
    } catch (e, st) {
      AppLogger.database('Error resolviendo recordatorio: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> eliminar(String id) async {
    try {
      final res = await _client.rpc('eliminar_recordatorio', params: {
        'p_token': _token,
        'p_recordatorio_id': id,
      });
      final data = res as Map<String, dynamic>?;
      if (data != null && data.containsKey('error')) {
        throw Exception(data['error']);
      }
    } catch (e, st) {
      AppLogger.database('Error eliminando recordatorio: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> editar({
    required String id,
    String? titulo,
    String? descripcion,
    String? prioridad,
    String? categoria,
    String? asignadoA,
    DateTime? fechaVencimiento,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_token': _token,
        'p_recordatorio_id': id,
      };
      if (titulo != null) params['p_titulo'] = titulo;
      params['p_descripcion'] = descripcion;
      if (prioridad != null) params['p_prioridad'] = prioridad;
      if (categoria != null) params['p_categoria'] = categoria;
      params['p_asignado_a'] = asignadoA;
      params['p_fecha_vencimiento'] =
          fechaVencimiento?.toIso8601String().split('T')[0];

      final res = await _client.rpc('editar_recordatorio', params: params);
      final data = res as Map<String, dynamic>?;
      if (data != null && data.containsKey('error')) {
        throw Exception(data['error']);
      }
    } catch (e, st) {
      AppLogger.database('Error editando recordatorio: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }
}

// ── ESTADO ────────────────────────────────────────────────────────────────────
class RecordatoriosState {
  final List<RecordatorioEx> recordatorios;
  final bool isLoading;
  final bool isSaving;
  final bool mostrarResueltos;
  final String? error;
  final String? successMessage;

  const RecordatoriosState({
    this.recordatorios = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.mostrarResueltos = false,
    this.error,
    this.successMessage,
  });

  RecordatoriosState copyWith({
    List<RecordatorioEx>? recordatorios,
    bool? isLoading,
    bool? isSaving,
    bool? mostrarResueltos,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) =>
      RecordatoriosState(
        recordatorios: recordatorios ?? this.recordatorios,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        mostrarResueltos: mostrarResueltos ?? this.mostrarResueltos,
        error: clearMessages ? null : error ?? this.error,
        successMessage:
            clearMessages ? null : successMessage ?? this.successMessage,
      );

  List<RecordatorioEx> get pendientes =>
      recordatorios.where((r) => !r.resuelto).toList();
  int get countUrgentes =>
      pendientes.where((r) => r.prioridad == 'urgente').length;
  int get countVencidos => pendientes.where((r) => r.estaVencido).length;
}

// ── NOTIFIER ──────────────────────────────────────────────────────────────────
class RecordatoriosNotifier extends StateNotifier<RecordatoriosState> {
  final RecordatoriosExService _service;

  RecordatoriosNotifier(this._service) : super(const RecordatoriosState());

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final lista = await _service.getRecordatorios(
          incluirResueltos: state.mostrarResueltos);
      lista.sort((a, b) {
        // Urgentes primero, luego por fecha de vencimiento, luego por registro
        if (a.prioridad == 'urgente' && b.prioridad != 'urgente') return -1;
        if (b.prioridad == 'urgente' && a.prioridad != 'urgente') return 1;
        if (a.fechaVencimiento != null && b.fechaVencimiento != null) {
          return a.fechaVencimiento!.compareTo(b.fechaVencimiento!);
        }
        return b.fechaRegistro.compareTo(a.fechaRegistro);
      });
      state = state.copyWith(recordatorios: lista, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<bool> crear({
    required String titulo,
    String? descripcion,
    String prioridad = 'normal',
    CategoriaRecordatorio categoria = CategoriaRecordatorio.tarea,
    String? asignadoA,
    DateTime? fechaVencimiento,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      await _service.crear(
        titulo: titulo,
        descripcion: descripcion,
        prioridad: prioridad,
        categoria: categoria.value,
        asignadoA: asignadoA,
        fechaVencimiento: fechaVencimiento,
      );
      await cargar();
      state = state.copyWith(
          isSaving: false, successMessage: 'Recordatorio creado');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  Future<void> resolver(String id) async {
    try {
      await _service.resolver(id);
      state = state.copyWith(
        recordatorios: state.recordatorios
            .map((r) => r.id == id
                ? RecordatorioEx(
                    id: r.id,
                    organizacionId: r.organizacionId,
                    creadoPor: r.creadoPor,
                    asignadoA: r.asignadoA,
                    titulo: r.titulo,
                    descripcion: r.descripcion,
                    prioridad: r.prioridad,
                    categoria: r.categoria,
                    resuelto: true,
                    fechaVencimiento: r.fechaVencimiento,
                    fechaRegistro: r.fechaRegistro,
                    creadoPorNombre: r.creadoPorNombre,
                    asignadoANombre: r.asignadoANombre,
                  )
                : r)
            .toList(),
        successMessage: 'Marcado como resuelto',
      );
    } catch (e) {
      state = state.copyWith(error: _msg(e));
    }
  }

  Future<void> eliminar(String id) async {
    try {
      await _service.eliminar(id);
      state = state.copyWith(
        recordatorios: state.recordatorios.where((r) => r.id != id).toList(),
        successMessage: 'Recordatorio eliminado',
      );
    } catch (e) {
      state = state.copyWith(error: _msg(e));
    }
  }

  Future<bool> editar({
    required String id,
    required String titulo,
    String? descripcion,
    String prioridad = 'normal',
    CategoriaRecordatorio categoria = CategoriaRecordatorio.tarea,
    String? asignadoA,
    DateTime? fechaVencimiento,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      await _service.editar(
        id: id,
        titulo: titulo,
        descripcion: descripcion,
        prioridad: prioridad,
        categoria: categoria.value,
        asignadoA: asignadoA,
        fechaVencimiento: fechaVencimiento,
      );
      await cargar();
      state = state.copyWith(
          isSaving: false, successMessage: 'Recordatorio actualizado');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  void toggleMostrarResueltos() {
    state = state.copyWith(mostrarResueltos: !state.mostrarResueltos);
    cargar();
  }

  void clearMessages() => state = state.copyWith(clearMessages: true);
  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}

// ── PROVIDERS ─────────────────────────────────────────────────────────────────
final recordatoriosExServiceProvider = Provider<RecordatoriosExService>((ref) {
  final token = ref.watch(currentUserProvider)?.sessionToken ?? '';
  return RecordatoriosExService(Supabase.instance.client, token);
});

final recordatoriosExProvider =
    StateNotifierProvider<RecordatoriosNotifier, RecordatoriosState>((ref) {
  return RecordatoriosNotifier(ref.read(recordatoriosExServiceProvider));
});
