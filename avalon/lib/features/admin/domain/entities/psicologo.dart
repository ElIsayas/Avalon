class Psicologo {
  final String id;
  final String authUserId;
  final String clinicaId;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;
  final DateTime fechaRegistro;

  Psicologo({
    required this.id,
    required this.authUserId,
    required this.clinicaId,
    required this.nombre,
    required this.email,
    this.rol = 'psicologo',
    this.activo = true,
    required this.fechaRegistro,
  });

  factory Psicologo.fromMap(Map<String, dynamic> map) {
    return Psicologo(
      id: map['id'] as String,
      authUserId: map['auth_user_id'] as String,
      clinicaId: map['clinica_id'] as String? ?? '',
      nombre: map['nombre'] as String,
      email: map['email'] as String,
      rol: map['rol'] as String? ?? 'psicologo',
      activo: map['activo'] as bool? ?? true,
      fechaRegistro: DateTime.parse(map['fecha_registro'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'clinica_id': clinicaId,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'activo': activo,
      'fecha_registro': fechaRegistro.toIso8601String(),
    };
  }

  Psicologo copyWith({
    String? id,
    String? authUserId,
    String? clinicaId,
    String? nombre,
    String? email,
    String? rol,
    bool? activo,
    DateTime? fechaRegistro,
  }) {
    return Psicologo(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      clinicaId: clinicaId ?? this.clinicaId,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Psicologo &&
        other.id == id &&
        other.authUserId == authUserId &&
        other.clinicaId == clinicaId &&
        other.nombre == nombre &&
        other.email == email &&
        other.rol == rol &&
        other.activo == activo &&
        other.fechaRegistro == fechaRegistro;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        authUserId.hashCode ^
        clinicaId.hashCode ^
        nombre.hashCode ^
        email.hashCode ^
        rol.hashCode ^
        activo.hashCode ^
        fechaRegistro.hashCode;
  }

  @override
  String toString() {
    return 'Psicologo(id: $id, authUserId: $authUserId, clinicaId: $clinicaId, nombre: $nombre, email: $email, rol: $rol, activo: $activo, fechaRegistro: $fechaRegistro)';
  }
}
