import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_service.dart';
import '../../domain/entities/psicologo.dart';
import '../../domain/entities/system_stats.dart';
import '../../../../core/supabase/supabase.dart';

// Estados para la administración
class AdminState {
  final List<Psicologo> psicologos;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? estadisticas;
  final SystemStats systemStats;

  AdminState({
    this.psicologos = const [],
    this.isLoading = false,
    this.error,
    this.estadisticas,
    SystemStats? systemStats,
  }) : systemStats = systemStats ?? SystemStats.initial();

  AdminState copyWith({
    List<Psicologo>? psicologos,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? estadisticas,
    SystemStats? systemStats,
  }) {
    return AdminState(
      psicologos: psicologos ?? this.psicologos,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      estadisticas: estadisticas ?? this.estadisticas,
      systemStats: systemStats ?? this.systemStats,
    );
  }
}

// Provider del servicio de administración
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(supabase);
});

// Provider del estado de administración
final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final service = ref.watch(adminServiceProvider);
  return AdminNotifier(service);
});

class AdminNotifier extends StateNotifier<AdminState> {
  final AdminService _service;
  static const String yuseClinicaId = 'yuse-clinica-id'; // ID de la clínica Yuse

  AdminNotifier(this._service) : super(AdminState()) {
    _loadData();
  }

  // Cargar datos iniciales
  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final psicologos = await _service.getPsicologosByClinica(yuseClinicaId);
      final estadisticas = await _service.getEstadisticasPsicologos(yuseClinicaId);
      
      state = state.copyWith(
        psicologos: psicologos,
        estadisticas: estadisticas,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Cargar estadísticas del sistema
  Future<void> loadSystemStats() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // NOTE: Using mock data for system stats - implement actual database loading when needed
      final mockStats = SystemStats(
        totalPsicologos: state.psicologos.length,
        totalPacientes: 150, // Mock data
        totalCitas: 450, // Mock data
        totalEvaluaciones: 89, // Mock data
        totalNotas: 234, // Mock data
        citasHoy: 12, // Mock data
        citasSemana: 67, // Mock data
        licenciasActivas: 5, // Mock data
        licenciasVencidas: 2, // Mock data
        lastUpdated: DateTime.now(),
      );
      
      state = state.copyWith(
        systemStats: mockStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Refrescar datos
  Future<void> refresh() async {
    await _loadData();
    await loadSystemStats();
  }

  // Crear un nuevo psicólogo
  Future<bool> crearPsicologo({
    required String nombre,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final nuevoPsicologo = await _service.crearPsicologo(
        nombre: nombre,
        email: email,
        password: password,
        clinicaId: yuseClinicaId,
      );

      // Actualizar lista y estadísticas
      final nuevaLista = [nuevoPsicologo, ...state.psicologos];
      final nuevasEstadisticas = await _service.getEstadisticasPsicologos(yuseClinicaId);
      
      state = state.copyWith(
        psicologos: nuevaLista,
        estadisticas: nuevasEstadisticas,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Eliminar un psicólogo
  Future<bool> eliminarPsicologo(String psicologoId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.eliminarPsicologo(psicologoId);

      // Actualizar lista y estadísticas
      final nuevaLista = state.psicologos.where((p) => p.id != psicologoId).toList();
      final nuevasEstadisticas = await _service.getEstadisticasPsicologos(yuseClinicaId);
      
      state = state.copyWith(
        psicologos: nuevaLista,
        estadisticas: nuevasEstadisticas,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Verificar si se pueden crear más psicólogos
  Future<bool> puedeCrearPsicologo() async {
    try {
      return await _service.puedeCrearPsicologo(yuseClinicaId);
    } catch (e) {
      return false;
    }
  }

  // Verificar si un email ya existe
  Future<bool> emailExists(String email) async {
    try {
      return await _service.emailExists(email);
    } catch (e) {
      return false;
    }
  }

  // Limpiar errores
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Método de diagnóstico
  Future<Map<String, dynamic>> diagnosticar() async {
    try {
      return await _service.diagnosticarConexion();
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

// Provider para verificar si se puede crear psicólogos
final puedeCrearPsicologoProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.puedeCrearPsicologo('yuse-clinica-id');
});

// Provider para obtener espacios disponibles
final espaciosDisponiblesProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.getEspaciosDisponibles('yuse-clinica-id');
});

// Provider de diagnóstico
final diagnosticoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.diagnosticarConexion();
});
