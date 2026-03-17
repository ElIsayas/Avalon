import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';

class CitaDiaData {
  final String dia;
  final int cantidad;
  final bool esHoy;
  const CitaDiaData({required this.dia, required this.cantidad, this.esHoy = false});
}

class DashboardStats {
  final int totalPacientes;
  final int pacientesActivos;
  final int citasHoy;
  final int citasSemana;
  final int citasMes;
  final int notasSemana;
  final Map<String, dynamic>? proximaCita;
  final List<Map<String, dynamic>> ultimosPacientes;
  final List<CitaDiaData> citasPorDiaSemana;

  const DashboardStats({
    this.totalPacientes = 0,
    this.pacientesActivos = 0,
    this.citasHoy = 0,
    this.citasSemana = 0,
    this.citasMes = 0,
    this.notasSemana = 0,
    this.proximaCita,
    this.ultimosPacientes = const [],
    this.citasPorDiaSemana = const [],
  });

  static const DashboardStats empty = DashboardStats();

  DashboardStats copyWith({
    int? totalPacientes, int? pacientesActivos, int? citasHoy,
    int? citasSemana, int? citasMes, int? notasSemana,
    Map<String, dynamic>? proximaCita,
    List<Map<String, dynamic>>? ultimosPacientes,
    List<CitaDiaData>? citasPorDiaSemana,
  }) => DashboardStats(
    totalPacientes:    totalPacientes    ?? this.totalPacientes,
    pacientesActivos:  pacientesActivos  ?? this.pacientesActivos,
    citasHoy:          citasHoy          ?? this.citasHoy,
    citasSemana:       citasSemana       ?? this.citasSemana,
    citasMes:          citasMes          ?? this.citasMes,
    notasSemana:       notasSemana       ?? this.notasSemana,
    proximaCita:       proximaCita       ?? this.proximaCita,
    ultimosPacientes:  ultimosPacientes  ?? this.ultimosPacientes,
    citasPorDiaSemana: citasPorDiaSemana ?? this.citasPorDiaSemana,
  );

  int get maxCitasDia => citasPorDiaSemana.isEmpty ? 1
    : citasPorDiaSemana.map((d) => d.cantidad).reduce((a, b) => a > b ? a : b).clamp(1, 999);
}

class DashboardService {
  final SupabaseClient _client;
  final String _token;
  DashboardService(this._client, this._token);

  Future<DashboardStats> getStats() async {
    AppLogger.database('Obteniendo estadísticas del dashboard');
    try {
      final res  = await _client.rpc('get_dashboard_stats', params: {'p_token': _token});
      final data = Map<String, dynamic>.from(res as Map);
      if (data.containsKey('error')) throw Exception(data['error']);

      return DashboardStats(
        totalPacientes:    data['total_pacientes']   as int? ?? 0,
        pacientesActivos:  data['pacientes_activos'] as int? ?? 0,
        citasHoy:          data['citas_hoy']         as int? ?? 0,
        citasSemana:       data['citas_semana']      as int? ?? 0,
        citasMes:          data['citas_mes']         as int? ?? 0,
        notasSemana:       data['notas_semana']      as int? ?? 0,
        proximaCita:       data['proxima_cita']      as Map<String, dynamic>?,
        ultimosPacientes:  (data['ultimos_pacientes'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        citasPorDiaSemana: _buildGraficaSemana(data),
      );
    } catch (e, st) {
      AppLogger.database('Error obteniendo estadísticas: $e', error: e, stackTrace: st);
      return DashboardStats.empty;
    }
  }

  List<CitaDiaData> _buildGraficaSemana(Map<String, dynamic> data) {
    final hoy         = DateTime.now();
    final inicioSem   = hoy.subtract(Duration(days: hoy.weekday - 1));
    const etiquetas   = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    final rawPorDia = data['citas_por_dia'] as List?;
    if (rawPorDia != null && rawPorDia.isNotEmpty) {
      final mapa = <String, int>{};
      for (final item in rawPorDia) {
        final m = Map<String, dynamic>.from(item as Map);
        final d = m['dia']?.toString() ?? m['fecha']?.toString() ?? '';
        mapa[d] = (m['cantidad'] as num?)?.toInt() ?? 0;
      }
      return List.generate(7, (i) {
        final dia = inicioSem.add(Duration(days: i));
        final key = '${dia.year}-${dia.month.toString().padLeft(2,'0')}-${dia.day.toString().padLeft(2,'0')}';
        return CitaDiaData(
          dia: etiquetas[i], cantidad: mapa[key] ?? 0,
          esHoy: dia.year == hoy.year && dia.month == hoy.month && dia.day == hoy.day,
        );
      });
    }

    // Fallback visual cuando el RPC no devuelve desglose por día
    final hoyCount = data['citas_hoy']    as int? ?? 0;
    final total    = data['citas_semana'] as int? ?? 0;
    final resto    = (total - hoyCount).clamp(0, 999);
    final diaHoy   = hoy.weekday - 1;
    return List.generate(7, (i) {
      int c = 0;
      if (i == diaHoy) c = hoyCount;
      else if (i < diaHoy && diaHoy > 0) c = (resto / diaHoy).round();
      return CitaDiaData(dia: etiquetas[i], cantidad: c, esHoy: i == diaHoy);
    });
  }
}
