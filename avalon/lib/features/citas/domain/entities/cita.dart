import 'package:flutter/material.dart';

enum EstadoCita {
  agendada('agendada', 'Agendada', Colors.blue),
  confirmada('confirmada', 'Confirmada', Colors.green),
  enProgreso('en_progreso', 'En Progreso', Colors.orange),
  completada('completada', 'Completada', Colors.grey),
  cancelada('cancelada', 'Cancelada', Colors.red),
  noAsistio('no_asistio', 'No Asistió', Color(0xFFD32F2F)),
  reprogramada('reprogramada', 'Reprogramada', Colors.purple);

  const EstadoCita(this.value, this.displayName, this.color);
  final String value;
  final String displayName;
  final Color color;

  static EstadoCita fromString(String value) {
    return EstadoCita.values.firstWhere(
      (estado) => estado.value == value,
      orElse: () => EstadoCita.agendada,
    );
  }
}

enum TipoCita {
  inicial('inicial', 'Consulta Inicial'),
  seguimiento('seguimiento', 'Seguimiento'),
  terapia('terapia', 'Terapia'),
  evaluacion('evaluacion', 'Evaluación Psicológica'),
  crisis('crisis', 'Intervención en Crisis'),
  familiar('familiar', 'Terapia Familiar'),
  pareja('pareja', 'Terapia de Pareja'),
  grupal('grupal', 'Terapia Grupal'),
  online('online', 'Consulta Online'),
  presencial('presencial', 'Consulta Presencial');

  const TipoCita(this.value, this.displayName);
  final String value;
  final String displayName;

  static TipoCita fromString(String value) {
    return TipoCita.values.firstWhere(
      (tipo) => tipo.value == value,
      orElse: () => TipoCita.inicial,
    );
  }
}

class Cita {
  final String id;
  final String pacienteId;
  final String psicologoId;
  final DateTime fechaHora;
  final Duration duracion;
  final TipoCita tipo;
  final EstadoCita estado;
  final String? notas;
  final String? motivoConsulta;
  final bool esOnline;
  final String? linkSesion;
  final DateTime fechaCreacion;
  final DateTime? fechaConfirmacion;
  final DateTime? fechaCancelacion;
  final String? motivoCancelacion;
  final double? costo;
  final bool pagada;
  final String? salaVirtual;
  final Map<String, dynamic>? metadata;

  const Cita({
    required this.id,
    required this.pacienteId,
    required this.psicologoId,
    required this.fechaHora,
    required this.duracion,
    required this.tipo,
    required this.estado,
    this.notas,
    this.motivoConsulta,
    this.esOnline = false,
    this.linkSesion,
    required this.fechaCreacion,
    this.fechaConfirmacion,
    this.fechaCancelacion,
    this.motivoCancelacion,
    this.costo,
    this.pagada = false,
    this.salaVirtual,
    this.metadata,
  });

  Cita copyWith({
    String? id,
    String? pacienteId,
    String? psicologoId,
    DateTime? fechaHora,
    Duration? duracion,
    TipoCita? tipo,
    EstadoCita? estado,
    String? notas,
    String? motivoConsulta,
    bool? esOnline,
    String? linkSesion,
    DateTime? fechaCreacion,
    DateTime? fechaConfirmacion,
    DateTime? fechaCancelacion,
    String? motivoCancelacion,
    double? costo,
    bool? pagada,
    String? salaVirtual,
    Map<String, dynamic>? metadata,
  }) {
    return Cita(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      psicologoId: psicologoId ?? this.psicologoId,
      fechaHora: fechaHora ?? this.fechaHora,
      duracion: duracion ?? this.duracion,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      motivoConsulta: motivoConsulta ?? this.motivoConsulta,
      esOnline: esOnline ?? this.esOnline,
      linkSesion: linkSesion ?? this.linkSesion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaConfirmacion: fechaConfirmacion ?? this.fechaConfirmacion,
      fechaCancelacion: fechaCancelacion ?? this.fechaCancelacion,
      motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
      costo: costo ?? this.costo,
      pagada: pagada ?? this.pagada,
      salaVirtual: salaVirtual ?? this.salaVirtual,
      metadata: metadata ?? this.metadata,
    );
  }

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'] as String,
      pacienteId: json['paciente_id'] as String,
      psicologoId: json['psicologo_id'] as String,
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      duracion: Duration(minutes: json['duracion_minutos'] as int? ?? 60),
      tipo: TipoCita.fromString(json['tipo'] as String? ?? 'inicial'),
      estado: EstadoCita.fromString(json['estado'] as String? ?? 'agendada'),
      notas: json['notas'] as String?,
      motivoConsulta: json['motivo_consulta'] as String?,
      esOnline: json['es_online'] as bool? ?? false,
      linkSesion: json['link_sesion'] as String?,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaConfirmacion: json['fecha_confirmacion'] != null
          ? DateTime.parse(json['fecha_confirmacion'] as String)
          : null,
      fechaCancelacion: json['fecha_cancelacion'] != null
          ? DateTime.parse(json['fecha_cancelacion'] as String)
          : null,
      motivoCancelacion: json['motivo_cancelacion'] as String?,
      costo: (json['costo'] as num?)?.toDouble(),
      pagada: json['pagada'] as bool? ?? false,
      salaVirtual: json['sala_virtual'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'psicologo_id': psicologoId,
      'fecha_hora': fechaHora.toIso8601String(),
      'duracion_minutos': duracion.inMinutes,
      'tipo': tipo.value,
      'estado': estado.value,
      'notas': notas,
      'motivo_consulta': motivoConsulta,
      'es_online': esOnline,
      'link_sesion': linkSesion,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_confirmacion': fechaConfirmacion?.toIso8601String(),
      'fecha_cancelacion': fechaCancelacion?.toIso8601String(),
      'motivo_cancelacion': motivoCancelacion,
      'costo': costo,
      'pagada': pagada,
      'sala_virtual': salaVirtual,
      'metadata': metadata,
    };
  }

  // Métodos utilitarios
  DateTime get fechaFin => fechaHora.add(duracion);
  
  bool get esHoy {
    final ahora = DateTime.now();
    return fechaHora.year == ahora.year &&
           fechaHora.month == ahora.month &&
           fechaHora.day == ahora.day;
  }

  bool get esManana {
    final manana = DateTime.now().add(const Duration(days: 1));
    return fechaHora.year == manana.year &&
           fechaHora.month == manana.month &&
           fechaHora.day == manana.day;
  }

  bool get esPasada => fechaHora.isBefore(DateTime.now());

  bool get esHoyOPasada => esHoy || esPasada;

  bool get puedeConfirmar => estado == EstadoCita.agendada && !esPasada;

  bool get puedeCancelar => !esPasada && 
                           (estado == EstadoCita.agendada || estado == EstadoCita.confirmada);

  bool get puedeReprogramar => !esPasada && 
                              (estado == EstadoCita.agendada || estado == EstadoCita.confirmada);

  bool get puedeIniciar => estado == EstadoCita.confirmada && 
                          DateTime.now().isAfter(fechaHora.subtract(const Duration(minutes: 5)));

  String get duracionFormateada {
    if (duracion.inHours >= 1) {
      return '${duracion.inHours}h ${duracion.inMinutes % 60}min';
    }
    return '${duracion.inMinutes}min';
  }

  String get horaFormateada {
    return '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}';
  }

  String get fechaFormateada {
    return '${fechaHora.day}/${fechaHora.month}/${fechaHora.year}';
  }

  String get fechaHoraFormateada {
    return '$fechaFormateada $horaFormateada';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cita &&
        other.id == id &&
        other.pacienteId == pacienteId &&
        other.psicologoId == psicologoId &&
        other.fechaHora == fechaHora &&
        other.duracion == duracion &&
        other.tipo == tipo &&
        other.estado == estado;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      pacienteId,
      psicologoId,
      fechaHora,
      duracion,
      tipo,
      estado,
    );
  }
}
