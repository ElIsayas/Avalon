enum TipoNota {
  sesion('sesion', 'Sesión'),
  seguimiento('seguimiento', 'Seguimiento'),
  evaluacion('evaluacion', 'Evaluación'),
  interconsulta('interconsulta', 'Interconsulta'),
  administrativa('administrativa', 'Administrativa');

  const TipoNota(this.value, this.label);
  final String value;
  final String label;

  static TipoNota fromString(String v) => TipoNota.values.firstWhere(
    (e) => e.value == v,
    orElse: () => TipoNota.sesion,
  );
}

class NotaTerapia {
  final String id;
  final String pacienteId;
  final String psicologoId;
  final String? citaId;
  final String contenido;
  final TipoNota tipo;
  final bool firmada;
  final DateTime? firmadaEn;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  // Campos enriquecidos del JOIN (get_notas_paciente los devuelve)
  final String? pacienteNombre;
  final String? psicologoNombre;

  const NotaTerapia({
    required this.id,
    required this.pacienteId,
    required this.psicologoId,
    this.citaId,
    required this.contenido,
    required this.tipo,
    required this.firmada,
    this.firmadaEn,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.pacienteNombre,
    this.psicologoNombre,
  });

  factory NotaTerapia.fromJson(Map<String, dynamic> j) => NotaTerapia(
    id:                  j['id'].toString(),
    pacienteId:          j['paciente_id'].toString(),
    psicologoId:         j['psicologo_id'].toString(),
    citaId:              j['cita_id']?.toString(),
    contenido:           j['contenido']?.toString() ?? '',
    tipo:                TipoNota.fromString(j['tipo']?.toString() ?? 'sesion'),
    firmada:             j['firmada'] as bool? ?? false,
    firmadaEn:           j['firmada_en'] != null
        ? DateTime.tryParse(j['firmada_en'].toString()) : null,
    fechaCreacion:       DateTime.tryParse(j['fecha_creacion'].toString()) ?? DateTime.now(),
    fechaActualizacion:  DateTime.tryParse(j['fecha_actualizacion'].toString()) ?? DateTime.now(),
    pacienteNombre:      j['paciente_nombre']?.toString(),
    psicologoNombre:     j['psicologo_nombre']?.toString(),
  );

  NotaTerapia copyWith({
    String? contenido,
    TipoNota? tipo,
    bool? firmada,
    DateTime? firmadaEn,
  }) => NotaTerapia(
    id: id, pacienteId: pacienteId, psicologoId: psicologoId,
    citaId: citaId,
    contenido: contenido ?? this.contenido,
    tipo: tipo ?? this.tipo,
    firmada: firmada ?? this.firmada,
    firmadaEn: firmadaEn ?? this.firmadaEn,
    fechaCreacion: fechaCreacion,
    fechaActualizacion: DateTime.now(),
    pacienteNombre: pacienteNombre,
    psicologoNombre: psicologoNombre,
  );
}
