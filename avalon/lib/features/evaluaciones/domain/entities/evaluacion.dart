class Evaluacion {
  final String id;
  final String pacienteId;
  final String psicologoId;
  final String? citaId;
  final String tipoTest;
  final DateTime fechaRealizacion;
  final Map<String, dynamic>? resultados;
  final String? observaciones;

  const Evaluacion({
    required this.id,
    required this.pacienteId,
    required this.psicologoId,
    this.citaId,
    required this.tipoTest,
    required this.fechaRealizacion,
    this.resultados,
    this.observaciones,
  });

  Evaluacion copyWith({
    String? id,
    String? pacienteId,
    String? psicologoId,
    String? citaId,
    String? tipoTest,
    DateTime? fechaRealizacion,
    Map<String, dynamic>? resultados,
    String? observaciones,
  }) {
    return Evaluacion(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      psicologoId: psicologoId ?? this.psicologoId,
      citaId: citaId ?? this.citaId,
      tipoTest: tipoTest ?? this.tipoTest,
      fechaRealizacion: fechaRealizacion ?? this.fechaRealizacion,
      resultados: resultados ?? this.resultados,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  factory Evaluacion.fromJson(Map<String, dynamic> json) {
    return Evaluacion(
      id: json['id'] as String,
      pacienteId: json['paciente_id'] as String,
      psicologoId: json['psicologo_id'] as String,
      citaId: json['cita_id'] as String?,
      tipoTest: json['tipo_test'] as String,
      fechaRealizacion: DateTime.parse(json['fecha_realizacion'] as String),
      resultados: json['resultados'] as Map<String, dynamic>?,
      observaciones: json['observaciones'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'psicologo_id': psicologoId,
      'cita_id': citaId,
      'tipo_test': tipoTest,
      'fecha_realizacion': fechaRealizacion.toIso8601String(),
      'resultados': resultados,
      'observaciones': observaciones,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Evaluacion &&
        other.id == id &&
        other.pacienteId == pacienteId &&
        other.psicologoId == psicologoId &&
        other.citaId == citaId &&
        other.tipoTest == tipoTest &&
        other.fechaRealizacion == fechaRealizacion &&
        other.resultados == resultados &&
        other.observaciones == observaciones;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      pacienteId,
      psicologoId,
      citaId,
      tipoTest,
      fechaRealizacion,
      resultados,
      observaciones,
    );
  }

  @override
  String toString() {
    return 'Evaluacion(id: $id, pacienteId: $pacienteId, psicologoId: $psicologoId, tipoTest: $tipoTest, fechaRealizacion: $fechaRealizacion)';
  }
}
