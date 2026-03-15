import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';

class DashboardStats {
  final int totalPacientes;
  final int pacientesActivos;
  final int citasHoy;
  final int citasSemana;
  final Map<String, dynamic>? proximaCita;
  final List<Map<String, dynamic>> ultimosPacientes;

  const DashboardStats({
    this.totalPacientes = 0,
    this.pacientesActivos = 0,
    this.citasHoy = 0,
    this.citasSemana = 0,
    this.proximaCita,
    this.ultimosPacientes = const [],
  });

  static const DashboardStats empty = DashboardStats();

  DashboardStats copyWith({
    int? totalPacientes,
    int? pacientesActivos,
    int? citasHoy,
    int? citasSemana,
    Map<String, dynamic>? proximaCita,
    List<Map<String, dynamic>>? ultimosPacientes,
  }) {
    return DashboardStats(
      totalPacientes: totalPacientes ?? this.totalPacientes,
      pacientesActivos: pacientesActivos ?? this.pacientesActivos,
      citasHoy: citasHoy ?? this.citasHoy,
      citasSemana: citasSemana ?? this.citasSemana,
      proximaCita: proximaCita ?? this.proximaCita,
      ultimosPacientes: ultimosPacientes ?? this.ultimosPacientes,
    );
  }
}

class DashboardService {
  final SupabaseClient _client;
  final String _token;

  DashboardService(this._client, this._token);

  Future<DashboardStats> getStats() async {
    AppLogger.database('Obteniendo estadísticas del dashboard');
    
    try {
      // Por ahora, datos de ejemplo. Luego implementar RPCs reales
      final stats = DashboardStats(
        totalPacientes: 0,
        pacientesActivos: 0,
        citasHoy: 0,
        citasSemana: 0,
        ultimosPacientes: [],
      );
      
      AppLogger.database('Estadísticas obtenidas: ${stats.totalPacientes} pacientes');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.database('Error obteniendo estadísticas: $e', error: e, stackTrace: stackTrace);
      return DashboardStats.empty;
    }
  }
}
