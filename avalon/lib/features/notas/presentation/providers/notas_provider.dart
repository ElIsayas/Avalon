import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/notas_service.dart';
import '../../domain/nota_terapia.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

// ── SERVICE ───────────────────────────────────────────────────────────────────
final notasServiceProvider = Provider<NotasService>((ref) {
  final token = ref.watch(currentUserProvider)?.sessionToken ?? '';
  return NotasService(Supabase.instance.client, token);
});

// ── ESTADO ────────────────────────────────────────────────────────────────────
class NotasState {
  final List<NotaTerapia> notas;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  // Filtros activos
  final String? filtroPacienteId;
  final TipoNota? filtroTipo;

  const NotasState({
    this.notas = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.filtroPacienteId,
    this.filtroTipo,
  });

  NotasState copyWith({
    List<NotaTerapia>? notas,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    String? filtroPacienteId,
    TipoNota? filtroTipo,
    bool clearMessages = false,
    bool clearFiltros = false,
  }) => NotasState(
    notas:            notas            ?? this.notas,
    isLoading:        isLoading        ?? this.isLoading,
    isSaving:         isSaving         ?? this.isSaving,
    error:            clearMessages ? null : error            ?? this.error,
    successMessage:   clearMessages ? null : successMessage   ?? this.successMessage,
    filtroPacienteId: clearFiltros  ? null : filtroPacienteId ?? this.filtroPacienteId,
    filtroTipo:       clearFiltros  ? null : filtroTipo       ?? this.filtroTipo,
  );

  // Notas filtradas según los filtros activos
  List<NotaTerapia> get notasFiltradas {
    var lista = notas;
    if (filtroPacienteId != null) {
      lista = lista.where((n) => n.pacienteId == filtroPacienteId).toList();
    }
    if (filtroTipo != null) {
      lista = lista.where((n) => n.tipo == filtroTipo).toList();
    }
    return lista;
  }
}

// ── NOTIFIER ──────────────────────────────────────────────────────────────────
class NotasNotifier extends StateNotifier<NotasState> {
  final NotasService _service;

  NotasNotifier(this._service) : super(const NotasState());

  // Cargar todas las notas de la org (para la tab Notas del bottom nav)
  Future<void> cargarTodas() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final lista = await _service.getTodasLasNotas();
      // Más recientes primero
      lista.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      state = state.copyWith(notas: lista, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  // Cargar notas de un paciente específico (desde historial del paciente)
  Future<void> cargarDespaciente(String pacienteId) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final lista = await _service.getNotasPaciente(pacienteId);
      lista.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      state = state.copyWith(notas: lista, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  // Crear nota nueva
  Future<bool> crear({
    required String pacienteId,
    required String contenido,
    required TipoNota tipo,
    String? citaId,
  }) async {
    if (contenido.trim().isEmpty) {
      state = state.copyWith(error: 'El contenido no puede estar vacío');
      return false;
    }
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final nueva = await _service.crear(
        pacienteId: pacienteId,
        contenido:  contenido.trim(),
        tipo:       tipo.value,
        citaId:     citaId,
      );
      state = state.copyWith(
        notas:          [nueva, ...state.notas],
        isSaving:       false,
        successMessage: 'Nota creada exitosamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  // Actualizar nota existente
  Future<bool> actualizar({
    required String notaId,
    String? contenido,
    TipoNota? tipo,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final actualizada = await _service.actualizar(
        notaId:    notaId,
        contenido: contenido?.trim(),
        tipo:      tipo?.value,
      );
      state = state.copyWith(
        notas: state.notas
            .map((n) => n.id == notaId ? actualizada : n)
            .toList(),
        isSaving:       false,
        successMessage: 'Nota actualizada',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  // Firmar nota (acción irreversible)
  Future<bool> firmar(String notaId) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      await _service.firmar(notaId);
      state = state.copyWith(
        notas: state.notas.map((n) {
          if (n.id != notaId) return n;
          return n.copyWith(firmada: true, firmadaEn: DateTime.now());
        }).toList(),
        isSaving:       false,
        successMessage: 'Nota firmada y bloqueada',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  // Eliminar nota
  Future<bool> eliminar(String notaId) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      await _service.eliminar(notaId);
      state = state.copyWith(
        notas:          state.notas.where((n) => n.id != notaId).toList(),
        isSaving:       false,
        successMessage: 'Nota eliminada',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  // Filtros
  void setFiltroPaciente(String? id) =>
      state = state.copyWith(filtroPacienteId: id);
  void setFiltroTipo(TipoNota? tipo) =>
      state = state.copyWith(filtroTipo: tipo);
  void limpiarFiltros() => state = state.copyWith(clearFiltros: true);
  void clearMessages()   => state = state.copyWith(clearMessages: true);

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}

// ── PROVIDERS ─────────────────────────────────────────────────────────────────
final notasProvider = StateNotifierProvider<NotasNotifier, NotasState>((ref) {
  return NotasNotifier(ref.read(notasServiceProvider));
});

// Provider conveniente para notas de un paciente específico
final notasPacienteProvider =
    StateNotifierProvider.family<NotasNotifier, NotasState, String>(
  (ref, pacienteId) {
    final notifier = NotasNotifier(ref.read(notasServiceProvider));
    notifier.cargarDespaciente(pacienteId);
    return notifier;
  },
);
