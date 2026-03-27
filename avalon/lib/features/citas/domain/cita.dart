enum EstadoCita {
  agendada('agendada'),
  confirmada('confirmada'),
  enProgreso('en_progreso'),
  completada('completada'),
  cancelada('cancelada'),
  noAsistio('no_asistio'),
  reprogramada('reprogramada');

  const EstadoCita(this.value);
  final String value;

  static EstadoCita fromString(String value) {
    return EstadoCita.values.firstWhere(
      (estado) => estado.value == value,
      orElse: () => EstadoCita.agendada,
    );
  }
}

enum ModalidadCita {
  presencial('presencial', 'Presencial'),
  online('online', 'Online');

  const ModalidadCita(this.value, this.label);
  final String value;
  final String label;

  static ModalidadCita fromString(String value) {
    return ModalidadCita.values.firstWhere(
      (modalidad) => modalidad.value == value,
      orElse: () => ModalidadCita.presencial,
    );
  }

  String toDb() => value;
}

enum TipoSesion {
  inicial('inicial', 'Inicial'),
  seguimiento('seguimiento', 'Seguimiento'),
  emergencia('emergencia', 'Emergencia'),
  evaluacion('evaluacion', 'Evaluación'),
  terapiaFamiliar('terapia_familiar', 'Terapia Familiar'),
  terapiaPareja('terapia_pareja', 'Terapia de Pareja');

  const TipoSesion(this.value, this.label);
  final String value;
  final String label;

  static TipoSesion fromString(String value) {
    return TipoSesion.values.firstWhere(
      (tipo) => tipo.value == value,
      orElse: () => TipoSesion.seguimiento,
    );
  }

  String toDb() => value;
}

class Cita {
  final String id;
  final String pacienteId;
  final String psicologoId;
  final DateTime fechaHora;
  final int duracionMinutos;
  final TipoSesion tipoSesion;
  final EstadoCita estado;
  final ModalidadCita modalidad;
  final String? motivoConsulta;
  final String? notas;
  final String? creadoPor;
  final String? organizacionId;
  final String? tokenConfirmacion;
  final bool confirmadoPaciente;
  final DateTime? eliminadoEn;
  final DateTime fechaActualizacion;
  final DateTime fechaCreacion;
  // Campos enriquecidos — devueltos por vista_citas_completa / get_citas
  final String? pacienteNombre;
  final String? psicologoNombre;

  const Cita({
    required this.id,
    required this.pacienteId,
    required this.psicologoId,
    required this.fechaHora,
    required this.duracionMinutos,
    required this.tipoSesion,
    required this.estado,
    required this.modalidad,
    this.motivoConsulta,
    this.notas,
    this.creadoPor,
    this.organizacionId,
    this.tokenConfirmacion,
    this.confirmadoPaciente = false,
    this.eliminadoEn,
    required this.fechaActualizacion,
    required this.fechaCreacion,
    this.pacienteNombre,
    this.psicologoNombre,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    final fechaHoraParseada =
        DateTime.tryParse(json['fecha_hora'].toString())?.toLocal() ??
            DateTime.now();
    final fechaActualizacionParseada =
        DateTime.tryParse(json['fecha_actualizacion'].toString())?.toLocal() ??
            DateTime.now();
    final fechaCreacionParseada =
        DateTime.tryParse(json['fecha_creacion'].toString())?.toLocal() ??
            DateTime.now();
    return Cita(
      id: json['id']?.toString() ?? '',
      pacienteId: json['paciente_id']?.toString() ?? '',
      psicologoId: json['psicologo_id']?.toString() ?? '',
      fechaHora: fechaHoraParseada,
      duracionMinutos: json['duracion_minutos'] as int? ?? 50,
      tipoSesion: TipoSesion.fromString(
          json['tipo_sesion']?.toString() ?? 'seguimiento'),
      estado: EstadoCita.fromString(json['estado']?.toString() ?? 'agendada'),
      modalidad: ModalidadCita.fromString(
          json['modalidad']?.toString() ?? 'presencial'),
      motivoConsulta: json['motivo_consulta']?.toString(),
      notas: json['notas']?.toString(),
      creadoPor: json['creado_por']?.toString(),
      organizacionId: json['organizacion_id']?.toString(),
      tokenConfirmacion: json['token_confirmacion']?.toString(),
      confirmadoPaciente: json['confirmado_paciente'] as bool? ?? false,
      eliminadoEn: json['eliminado_en'] != null
          ? DateTime.tryParse(json['eliminado_en'].toString())?.toLocal()
          : null,
      fechaActualizacion: fechaActualizacionParseada,
      fechaCreacion: fechaCreacionParseada,
      // Nombres del JOIN (vista_citas_completa / get_citas enriquecido)
      pacienteNombre: json['paciente_nombre']?.toString(),
      psicologoNombre: json['psicologo_nombre']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'psicologo_id': psicologoId,
      'fecha_hora': fechaHora.toIso8601String(),
      'duracion_minutos': duracionMinutos,
      'tipo_sesion': tipoSesion.value,
      'estado': estado.value,
      'modalidad': modalidad.value,
      'motivo_consulta': motivoConsulta,
      'notas': notas,
      'creado_por': creadoPor,
      'organizacion_id': organizacionId,
      'token_confirmacion': tokenConfirmacion,
      'confirmado_paciente': confirmadoPaciente,
      'eliminado_en': eliminadoEn?.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  Cita copyWith({
    String? id,
    String? pacienteId,
    String? psicologoId,
    DateTime? fechaHora,
    int? duracionMinutos,
    TipoSesion? tipoSesion,
    EstadoCita? estado,
    ModalidadCita? modalidad,
    bool? esOnline,
    String? motivoConsulta,
    String? notas,
    String? creadoPor,
    String? organizacionId,
    String? tokenConfirmacion,
    bool? confirmadoPaciente,
    DateTime? eliminadoEn,
    DateTime? fechaActualizacion,
    DateTime? fechaCreacion,
    String? pacienteNombre,
    String? psicologoNombre,
  }) {
    return Cita(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      psicologoId: psicologoId ?? this.psicologoId,
      fechaHora: fechaHora ?? this.fechaHora,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      tipoSesion: tipoSesion ?? this.tipoSesion,
      estado: estado ?? this.estado,
      modalidad: modalidad ?? this.modalidad,
      motivoConsulta: motivoConsulta ?? this.motivoConsulta,
      notas: notas ?? this.notas,
      creadoPor: creadoPor ?? this.creadoPor,
      organizacionId: organizacionId ?? this.organizacionId,
      tokenConfirmacion: tokenConfirmacion ?? this.tokenConfirmacion,
      confirmadoPaciente: confirmadoPaciente ?? this.confirmadoPaciente,
      eliminadoEn: eliminadoEn ?? this.eliminadoEn,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      pacienteNombre: pacienteNombre ?? this.pacienteNombre,
      psicologoNombre: psicologoNombre ?? this.psicologoNombre,
    );
  }

  String get tipoLabel => tipoSesion.label;

  String get estadoLabel {
    switch (estado) {
      case EstadoCita.agendada:
        return 'Agendada';
      case EstadoCita.confirmada:
        return 'Confirmada';
      case EstadoCita.enProgreso:
        return 'En Progreso';
      case EstadoCita.completada:
        return 'Completada';
      case EstadoCita.cancelada:
        return 'Cancelada';
      case EstadoCita.noAsistio:
        return 'No Asistió';
      case EstadoCita.reprogramada:
        return 'Reprogramada';
    }
  }

  bool get esHoy {
    final ahora = DateTime.now();
    return fechaHora.year == ahora.year &&
        fechaHora.month == ahora.month &&
        fechaHora.day == ahora.day;
  }

  bool get estaPasandoAhora {
    final ahora = DateTime.now();
    final fin = fechaHora.add(Duration(minutes: duracionMinutos));
    return ahora.isAfter(fechaHora.subtract(const Duration(minutes: 5))) &&
        ahora.isBefore(fin);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Cita && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class DisponibilidadPsicologo {
  final String psicologoId;
  final String nombre;
  final String? especialidad;
  final bool estaDisponible;
  final DateTime? proximaCita;
  final String? estadoActual;

  const DisponibilidadPsicologo({
    required this.psicologoId,
    required this.nombre,
    this.especialidad,
    required this.estaDisponible,
    this.proximaCita,
    this.estadoActual,
  });

  factory DisponibilidadPsicologo.fromJson(Map<String, dynamic> json) {
    return DisponibilidadPsicologo(
      psicologoId: json['psicologo_id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      especialidad: json['especialidad']?.toString(),
      estaDisponible: json['esta_disponible'] as bool? ?? true,
      proximaCita: json['proxima_cita'] != null
          ? DateTime.tryParse(json['proxima_cita'].toString())
          : null,
      estadoActual: json['estado_actual']?.toString(),
    );
  }

  DisponibilidadPsicologo copyWith({
    String? psicologoId,
    String? nombre,
    String? especialidad,
    bool? estaDisponible,
    DateTime? proximaCita,
    String? estadoActual,
  }) {
    return DisponibilidadPsicologo(
      psicologoId: psicologoId ?? this.psicologoId,
      nombre: nombre ?? this.nombre,
      especialidad: especialidad ?? this.especialidad,
      estaDisponible: estaDisponible ?? this.estaDisponible,
      proximaCita: proximaCita ?? this.proximaCita,
      estadoActual: estadoActual ?? this.estadoActual,
    );
  }
}
