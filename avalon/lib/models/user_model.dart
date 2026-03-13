class User {
  final String id;
  final String nombre;
  final String email;
  final String password;
  final String? licenciaId;
  final String? deviceId;
  final bool? activa;
  final String? rol;
  final String? especialidad;
  final Map<String, dynamic>? disponibilidad;
  final DateTime? fechaRegistro;

  const User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.password,
    this.licenciaId,
    this.deviceId,
    this.activa,
    this.rol,
    this.especialidad,
    this.disponibilidad,
    this.fechaRegistro,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      licenciaId: json['licencia_id'] as String?,
      deviceId: json['device_id'] as String?,
      activa: json['activa'] as bool?,
      rol: json['rol'] as String?,
      especialidad: json['especialidad'] as String?,
      disponibilidad: json['disponibilidad'] as Map<String, dynamic>?,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro'] as String)
          : null,
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
      'fecha_registro': fechaRegistro?.toIso8601String(),
    };
  }

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
    Map<String, dynamic>? disponibilidad,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, nombre: $nombre, email: $email, rol: $rol)';
  }
}
