class NotaTerapia {
  final String id;
  final String pacienteId;
  final String psicologoId;
  final String? citaId;
  final DateTime fecha;
  final String notas;
  final String? objetivos;
  final String? progreso;

  const NotaTerapia({
    required this.id,
    required this.pacienteId,
    required this.psicologoId,
    this.citaId,
    required this.fecha,
    required this.notas,
    this.objetivos,
    this.progreso,
  });

  NotaTerapia copyWith({
    String? id,
    String? pacienteId,
    String? psicologoId,
    String? citaId,
    DateTime? fecha,
    String? notas,
    String? objetivos,
    String? progreso,
  }) {
    return NotaTerapia(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      psicologoId: psicologoId ?? this.psicologoId,
      citaId: citaId ?? this.citaId,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
      objetivos: objetivos ?? this.objetivos,
      progreso: progreso ?? this.progreso,
    );
  }

  factory NotaTerapia.fromJson(Map<String, dynamic> json) {
    return NotaTerapia(
      id: json['id'] as String,
      pacienteId: json['paciente_id'] as String,
      psicologoId: json['psicologo_id'] as String,
      citaId: json['cita_id'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      notas: json['notas'] as String,
      objetivos: json['objetivos'] as String?,
      progreso: json['progreso'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'psicologo_id': psicologoId,
      'cita_id': citaId,
      'fecha': fecha.toIso8601String(),
      'notas': notas,
      'objetivos': objetivos,
      'progreso': progreso,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotaTerapia &&
        other.id == id &&
        other.pacienteId == pacienteId &&
        other.psicologoId == psicologoId &&
        other.citaId == citaId &&
        other.fecha == fecha &&
        other.notas == notas &&
        other.objetivos == objetivos &&
        other.progreso == progreso;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      pacienteId,
      psicologoId,
      citaId,
      fecha,
      notas,
      objetivos,
      progreso,
    );
  }

  @override
  String toString() {
    return 'NotaTerapia(id: $id, pacienteId: $pacienteId, psicologoId: $psicologoId, fecha: $fecha)';
  }
}
