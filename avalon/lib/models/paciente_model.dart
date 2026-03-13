class Paciente {
  final String id;
  final String nombre;
  final String email;
  final String numeroDocumento;
  final String? telefono;
  final DateTime? fechaNacimiento;
  final String? direccion;
  final String? historialMedico;
  final bool activo;
  final DateTime fechaRegistro;
  final DateTime? fechaActualizacion;
  final String? licenciaId;
  final String? deviceId;
  final String? creadoPor;
  final Map<String, dynamic>? metadata;
  final String? objetivosTerapeuticos;
  final String? progreso;

  const Paciente({
    required this.id,
    required this.nombre,
    required this.email,
    required this.numeroDocumento,
    this.telefono,
    this.fechaNacimiento,
    this.direccion,
    this.historialMedico,
    this.activo = true,
    required this.fechaRegistro,
    this.fechaActualizacion,
    this.licenciaId,
    this.deviceId,
    this.creadoPor,
    this.metadata,
    this.objetivosTerapeuticos,
    this.progreso,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      numeroDocumento: json['numero_documento']?.toString() ?? '',
      telefono: json['telefono'] as String?,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'] as String)
          : null,
      direccion: json['direccion'] as String?,
      historialMedico: json['historial_medico'] as String?,
      activo: json['activo'] as bool? ?? true,
      fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'] as String)
          : null,
      licenciaId: json['licencia_id'] as String?,
      deviceId: json['device_id'] as String?,
      creadoPor: json['creado_por'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      objetivosTerapeuticos: json['objetivos_terapeuticos'] as String?,
      progreso: json['progreso'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'numero_documento': numeroDocumento,
      'telefono': telefono,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'direccion': direccion,
      'historial_medico': historialMedico,
      'activo': activo,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
      'licencia_id': licenciaId,
      'device_id': deviceId,
      'creado_por': creadoPor,
      'metadata': metadata,
      'objetivos_terapeuticos': objetivosTerapeuticos,
      'progreso': progreso,
    };
  }

  Paciente copyWith({
    String? id,
    String? nombre,
    String? email,
    String? numeroDocumento,
    String? telefono,
    DateTime? fechaNacimiento,
    String? direccion,
    String? historialMedico,
    bool? activo,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    String? licenciaId,
    String? deviceId,
    String? creadoPor,
    Map<String, dynamic>? metadata,
    String? objetivosTerapeuticos,
    String? progreso,
  }) {
    return Paciente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      direccion: direccion ?? this.direccion,
      historialMedico: historialMedico ?? this.historialMedico,
      activo: activo ?? this.activo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      licenciaId: licenciaId ?? this.licenciaId,
      deviceId: deviceId ?? this.deviceId,
      creadoPor: creadoPor ?? this.creadoPor,
      metadata: metadata ?? this.metadata,
      objetivosTerapeuticos: objetivosTerapeuticos ?? this.objetivosTerapeuticos,
      progreso: progreso ?? this.progreso,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Paciente && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Paciente(id: $id, nombre: $nombre, email: $email, activo: $activo)';
  }
}
