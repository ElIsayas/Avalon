class User {
  final String id;
  final String nombre;
  final String email;
  final String password;
  final String? licenciaId;
  final String? deviceId;
  final bool activa;
  final String rol;
  final String? especialidad;
  final String? disponibilidad;
  final DateTime fechaRegistro;

  const User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.password,
    this.licenciaId,
    this.deviceId,
    required this.activa,
    required this.rol,
    this.especialidad,
    this.disponibilidad,
    required this.fechaRegistro,
  });

  User copyWith({
    String? id,
    String? nombre,
    String? email,
    String? password,
    String? licenciaId,
    String? deviceId,
    bool? activa,
    String? rol,
    String? especialidad,
    String? disponibilidad,
    DateTime? fechaRegistro,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      password: password ?? this.password,
      licenciaId: licenciaId ?? this.licenciaId,
      deviceId: deviceId ?? this.deviceId,
      activa: activa ?? this.activa,
      rol: rol ?? this.rol,
      especialidad: especialidad ?? this.especialidad,
      disponibilidad: disponibilidad ?? this.disponibilidad,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      licenciaId: json['licencia_id'] as String?,
      deviceId: json['device_id'] as String?,
      activa: json['activa'] as bool? ?? true,
      rol: json['rol'] as String,
      especialidad: json['especialidad'] as String?,
      disponibilidad: json['disponibilidad'] as String?,
      fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'password': password,
      'licencia_id': licenciaId,
      'device_id': deviceId,
      'activa': activa,
      'rol': rol,
      'especialidad': especialidad,
      'disponibilidad': disponibilidad,
      'fecha_registro': fechaRegistro.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.nombre == nombre &&
        other.email == email &&
        other.password == password &&
        other.licenciaId == licenciaId &&
        other.deviceId == deviceId &&
        other.activa == activa &&
        other.rol == rol &&
        other.especialidad == especialidad &&
        other.disponibilidad == disponibilidad &&
        other.fechaRegistro == fechaRegistro;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nombre,
      email,
      password,
      licenciaId,
      deviceId,
      activa,
      rol,
      especialidad,
      disponibilidad,
      fechaRegistro,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, nombre: $nombre, email: $email, rol: $rol, activa: $activa)';
  }

  // Getters útiles
  bool get isAdmin => rol == 'admin';
  bool get isPsicologo => rol == 'psicologo';
  bool get isActivo => activa;
  String get displayName => nombre;
}
