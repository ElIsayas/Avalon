class Cita {
  final String id;
  final String pacienteId;
  final String psicologoId;
  final DateTime fechaHora;
  final int duracionMinutos;
  final String tipo;
  final String estado;
  final String motivoConsulta;
  final String? notas;
  final bool esOnline;
  final String? linkSesion;
  final double? costo;
  final bool pagada;
  final String? resumenSesion;

  const Cita({
    required this.id,
    required this.pacienteId,
    required this.psicologoId,
    required this.fechaHora,
    required this.duracionMinutos,
    required this.tipo,
    required this.estado,
    required this.motivoConsulta,
    this.notas,
    this.esOnline = false,
    this.linkSesion,
    this.costo,
    this.pagada = false,
    this.resumenSesion,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'] as String,
      pacienteId: json['paciente_id'] as String,
      psicologoId: json['psicologo_id'] as String,
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      duracionMinutos: json['duracion_minutos'] as int,
      tipo: json['tipo'] as String,
      estado: json['estado'] as String,
      motivoConsulta: json['motivo_consulta'] as String,
      notas: json['notas'] as String?,
      esOnline: json['es_online'] as bool? ?? false,
      linkSesion: json['link_sesion'] as String?,
      costo: json['costo'] as double?,
      pagada: json['pagada'] as bool? ?? false,
      resumenSesion: json['resumen_sesion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'psicologo_id': psicologoId,
      'fecha_hora': fechaHora.toIso8601String(),
      'duracion_minutos': duracionMinutos,
      'tipo': tipo,
      'estado': estado,
      'motivo_consulta': motivoConsulta,
      'notas': notas,
      'es_online': esOnline,
      'link_sesion': linkSesion,
      'costo': costo,
      'pagada': pagada,
      'resumen_sesion': resumenSesion,
    };
  }

  Cita copyWith({
    String? id,
    String? pacienteId,
    String? psicologoId,
    DateTime? fechaHora,
    int? duracionMinutos,
    String? tipo,
    String? estado,
    String? motivoConsulta,
    String? notas,
    bool? esOnline,
    String? linkSesion,
    double? costo,
    bool? pagada,
    String? resumenSesion,
  }) {
    return Cita(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      psicologoId: psicologoId ?? this.psicologoId,
      fechaHora: fechaHora ?? this.fechaHora,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      motivoConsulta: motivoConsulta ?? this.motivoConsulta,
      notas: notas ?? this.notas,
      esOnline: esOnline ?? this.esOnline,
      linkSesion: linkSesion ?? this.linkSesion,
      costo: costo ?? this.costo,
      pagada: pagada ?? this.pagada,
      resumenSesion: resumenSesion ?? this.resumenSesion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cita && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Cita(id: $id, pacienteId: $pacienteId, fechaHora: $fechaHora, estado: $estado)';
  }
}
