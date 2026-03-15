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
      final res = await _client.rpc('get_dashboard_stats', params: {'p_token': _token});
      final data = Map<String, dynamic>.from(res as Map);
      
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }
      
      final stats = DashboardStats(
        totalPacientes: data['total_pacientes'] as int? ?? 0,
        pacientesActivos: data['pacientes_activos'] as int? ?? 0,
        citasHoy: data['citas_hoy'] as int? ?? 0,
        citasSemana: data['citas_semana'] as int? ?? 0,
        proximaCita: data['proxima_cita'] as Map<String, dynamic>?,
        ultimosPacientes: (data['ultimos_pacientes'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
      
      AppLogger.database('Estadísticas obtenidas: ${stats.totalPacientes} pacientes');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.database('Error obteniendo estadísticas: $e', error: e, stackTrace: stackTrace);
      return DashboardStats.empty;
    }
  }
}
