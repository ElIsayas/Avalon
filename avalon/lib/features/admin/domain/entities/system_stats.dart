class SystemStats {
  final int totalPsicologos;
  final int totalPacientes;
  final int totalCitas;
  final int totalEvaluaciones;
  final int totalNotas;
  final int citasHoy;
  final int citasSemana;
  final int licenciasActivas;
  final int licenciasVencidas;
  final DateTime lastUpdated;

  const SystemStats({
    required this.totalPsicologos,
    required this.totalPacientes,
    required this.totalCitas,
    required this.totalEvaluaciones,
    required this.totalNotas,
    required this.citasHoy,
    required this.citasSemana,
    required this.licenciasActivas,
    required this.licenciasVencidas,
    required this.lastUpdated,
  });

  SystemStats copyWith({
    int? totalPsicologos,
    int? totalPacientes,
    int? totalCitas,
    int? totalEvaluaciones,
    int? totalNotas,
    int? citasHoy,
    int? citasSemana,
    int? licenciasActivas,
    int? licenciasVencidas,
    DateTime? lastUpdated,
  }) {
    return SystemStats(
      totalPsicologos: totalPsicologos ?? this.totalPsicologos,
      totalPacientes: totalPacientes ?? this.totalPacientes,
      totalCitas: totalCitas ?? this.totalCitas,
      totalEvaluaciones: totalEvaluaciones ?? this.totalEvaluaciones,
      totalNotas: totalNotas ?? this.totalNotas,
      citasHoy: citasHoy ?? this.citasHoy,
      citasSemana: citasSemana ?? this.citasSemana,
      licenciasActivas: licenciasActivas ?? this.licenciasActivas,
      licenciasVencidas: licenciasVencidas ?? this.licenciasVencidas,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory SystemStats.initial() {
    return SystemStats(
      totalPsicologos: 0,
      totalPacientes: 0,
      totalCitas: 0,
      totalEvaluaciones: 0,
      totalNotas: 0,
      citasHoy: 0,
      citasSemana: 0,
      licenciasActivas: 0,
      licenciasVencidas: 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      totalPsicologos: json['total_psicologos'] as int? ?? 0,
      totalPacientes: json['total_pacientes'] as int? ?? 0,
      totalCitas: json['total_citas'] as int? ?? 0,
      totalEvaluaciones: json['total_evaluaciones'] as int? ?? 0,
      totalNotas: json['total_notas'] as int? ?? 0,
      citasHoy: json['citas_hoy'] as int? ?? 0,
      citasSemana: json['citas_semana'] as int? ?? 0,
      licenciasActivas: json['licencias_activas'] as int? ?? 0,
      licenciasVencidas: json['licencias_vencidas'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_psicologos': totalPsicologos,
      'total_pacientes': totalPacientes,
      'total_citas': totalCitas,
      'total_evaluaciones': totalEvaluaciones,
      'total_notas': totalNotas,
      'citas_hoy': citasHoy,
      'citas_semana': citasSemana,
      'licencias_activas': licenciasActivas,
      'licencias_vencidas': licenciasVencidas,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SystemStats(totalPsicologos: $totalPsicologos, totalPacientes: $totalPacientes, totalCitas: $totalCitas)';
  }
}
