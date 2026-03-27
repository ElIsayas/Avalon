import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/dashboard_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── SERVICIO ──────────────────────────────────────────────────────────────────
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final token = ref.watch(currentUserProvider)?.sessionToken ?? '';
  return DashboardService(Supabase.instance.client, token);
});

// ── ESTADO ────────────────────────────────────────────────────────────────────
class DashboardState {
  final DashboardStats stats;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.stats = DashboardStats.empty,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── NOTIFIER ──────────────────────────────────────────────────────────────────
class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardService _service;

  DashboardNotifier(this._service) : super(const DashboardState()) {
    cargar();
  }

  Future<void> cargar() async {
    AppLogger.database('Cargando estadísticas del dashboard');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final stats = await _service.getStats();
      state = state.copyWith(stats: stats, isLoading: false);
      AppLogger.database('Estadísticas cargadas exitosamente');
    } catch (e, stackTrace) {
      AppLogger.database('Error cargando estadísticas: $e',
          error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── PROVIDER PRINCIPAL ────────────────────────────────────────────────────────
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.read(dashboardServiceProvider));
});
