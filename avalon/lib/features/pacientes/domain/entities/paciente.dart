class Paciente {
  final String id;
  final String nombre;
  final String email;
  final String? numeroDocumento;
  final String? telefono;
  final String? direccion;
  final DateTime? fechaNacimiento;
  final String? historialMedico;
  final DateTime fechaRegistro;
  final bool activo;

  const Paciente({
    required this.id,
    required this.nombre,
    required this.email,
    this.numeroDocumento,
    this.telefono,
    this.direccion,
    this.fechaNacimiento,
    this.historialMedico,
    required this.fechaRegistro,
    this.activo = true,
  });

  Paciente copyWith({
    String? id,
    String? nombre,
    String? email,
    String? numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    DateTime? fechaRegistro,
    bool? activo,
  }) {
    return Paciente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      historialMedico: historialMedico ?? this.historialMedico,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      activo: activo ?? this.activo,
    );
  }

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'] as String)
          : null,
      historialMedico: json['historial_medico'] as String?,
      fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'historial_medico': historialMedico,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'activo': activo,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Paciente &&
        other.id == id &&
        other.nombre == nombre &&
        other.email == email &&
        other.telefono == telefono &&
        other.direccion == direccion &&
        other.fechaNacimiento == fechaNacimiento &&
        other.historialMedico == historialMedico &&
        other.fechaRegistro == fechaRegistro &&
        other.activo == activo;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nombre,
      email,
      telefono,
      direccion,
      fechaNacimiento,
      historialMedico,
      fechaRegistro,
      activo,
    );
  }
}
