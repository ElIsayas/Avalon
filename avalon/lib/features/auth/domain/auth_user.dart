class AuthUser {
  final String id;
  final String email;
  final String? nombre;
  final String? numeroDocumento;
  final String? clinicaId;
  final String? clinicaNombre;
  final String? dispositivoId;
  final String? rol;
  final bool? activo;
  final DateTime? fechaRegistro;

  AuthUser({
    required this.id,
    required this.email,
    this.nombre,
    this.numeroDocumento,
    this.clinicaId,
    this.clinicaNombre,
    this.dispositivoId,
    this.rol,
    this.activo,
    this.fechaRegistro,
  });

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      nombre: map['nombre']?.toString(),
      numeroDocumento: map['numero_documento']?.toString(),
      clinicaId: map['clinica_id']?.toString(),
      clinicaNombre: map['clinica_nombre']?.toString(),
      dispositivoId: map['dispositivo_id']?.toString(),
      rol: map['rol']?.toString(),
      activo: map['activo'] as bool?,
      fechaRegistro: map['fecha_registro'] != null 
          ? DateTime.tryParse(map['fecha_registro'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'numero_documento': numeroDocumento,
      'clinica_id': clinicaId,
      'clinica_nombre': clinicaNombre,
      'dispositivo_id': dispositivoId,
      'rol': rol,
      'activo': activo,
      'fecha_registro': fechaRegistro?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AuthUser(id: $id, email: $email, nombre: $nombre, rol: $rol)';
  }

  // Getters útiles
  bool get isPsicologo => rol == 'psicologo';
  bool get isAdministrador => rol == 'administrador';
  bool get isActivo => activo ?? false;
  String get displayName => nombre ?? email;
}
