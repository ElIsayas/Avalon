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
  final String creadoPor;
  final String? objetivosTerapeuticos;

  const Paciente({
    required this.id,
    required this.nombre,
    required this.email,
    required this.numeroDocumento,
    this.telefono,
    this.fechaNacimiento,
    this.direccion,
    this.historialMedico,
    required this.activo,
    required this.fechaRegistro,
    this.fechaActualizacion,
    required this.creadoPor,
    this.objetivosTerapeuticos,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id:                    json['id'].toString(),
      nombre:                json['nombre'].toString(),
      email:                 json['email'].toString(),
      numeroDocumento:       json['numero_documento'].toString(),
      telefono:              json['telefono']?.toString(),
      fechaNacimiento:       json['fecha_nacimiento'] != null
          ? DateTime.tryParse(json['fecha_nacimiento'].toString())
          : null,
      direccion:             json['direccion']?.toString(),
      historialMedico:       json['historial_medico']?.toString(),
      activo:                json['activo'] as bool? ?? true,
      fechaRegistro:         DateTime.tryParse(json['fecha_registro'].toString()) ?? DateTime.now(),
      fechaActualizacion:    json['fecha_actualizacion'] != null
          ? DateTime.tryParse(json['fecha_actualizacion'].toString())
          : null,
      creadoPor:             json['creado_por'].toString(),
      objetivosTerapeuticos: json['objetivos_terapeuticos']?.toString(),
    );
  }

  Paciente copyWith({
    String? nombre,
    String? email,
    String? numeroDocumento,
    String? telefono,
    DateTime? fechaNacimiento,
    String? direccion,
    String? historialMedico,
    bool? activo,
    String? objetivosTerapeuticos,
  }) {
    return Paciente(
      id:                    id,
      nombre:                nombre ?? this.nombre,
      email:                 email ?? this.email,
      numeroDocumento:       numeroDocumento ?? this.numeroDocumento,
      telefono:              telefono ?? this.telefono,
      fechaNacimiento:       fechaNacimiento ?? this.fechaNacimiento,
      direccion:             direccion ?? this.direccion,
      historialMedico:       historialMedico ?? this.historialMedico,
      activo:                activo ?? this.activo,
      fechaRegistro:         fechaRegistro,
      fechaActualizacion:    DateTime.now(),
      creadoPor:             creadoPor,
      objetivosTerapeuticos: objetivosTerapeuticos ?? this.objetivosTerapeuticos,
    );
  }

  // Iniciales para el avatar
  String get iniciales {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length >= 2 ? 2 : 1).toUpperCase();
  }
}
