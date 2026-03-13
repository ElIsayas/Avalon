class Licencia {
  final String id;
  final String licenseKey;
  final String email;
  final bool activa;
  final DateTime fechaActivacion;
  final DateTime fechaExpiracion;
  final String? usuarioId;

  const Licencia({
    required this.id,
    required this.licenseKey,
    required this.email,
    required this.activa,
    required this.fechaActivacion,
    required this.fechaExpiracion,
    this.usuarioId,
  });

  Licencia copyWith({
    String? id,
    String? licenseKey,
    String? email,
    bool? activa,
    DateTime? fechaActivacion,
    DateTime? fechaExpiracion,
    String? usuarioId,
  }) {
    return Licencia(
      id: id ?? this.id,
      licenseKey: licenseKey ?? this.licenseKey,
      email: email ?? this.email,
      activa: activa ?? this.activa,
      fechaActivacion: fechaActivacion ?? this.fechaActivacion,
      fechaExpiracion: fechaExpiracion ?? this.fechaExpiracion,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }

  factory Licencia.fromJson(Map<String, dynamic> json) {
    return Licencia(
      id: json['id'] as String,
      licenseKey: json['license_key'] as String,
      email: json['email'] as String,
      activa: json['activa'] as bool? ?? true,
      fechaActivacion: DateTime.parse(json['fecha_activacion'] as String),
      fechaExpiracion: DateTime.parse(json['fecha_expiracion'] as String),
      usuarioId: json['usuario_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'license_key': licenseKey,
      'email': email,
      'activa': activa,
      'fecha_activacion': fechaActivacion.toIso8601String(),
      'fecha_expiracion': fechaExpiracion.toIso8601String(),
      'usuario_id': usuarioId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Licencia &&
        other.id == id &&
        other.licenseKey == licenseKey &&
        other.email == email &&
        other.activa == activa &&
        other.fechaActivacion == fechaActivacion &&
        other.fechaExpiracion == fechaExpiracion &&
        other.usuarioId == usuarioId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      licenseKey,
      email,
      activa,
      fechaActivacion,
      fechaExpiracion,
      usuarioId,
    );
  }

  @override
  String toString() {
    return 'Licencia(id: $id, email: $email, activa: $activa, fechaExpiracion: $fechaExpiracion)';
  }

  // Getters útiles
  bool get estaVencida => DateTime.now().isAfter(fechaExpiracion);
  bool get esValida => activa && !estaVencida;
  int get diasRestantes => fechaExpiracion.difference(DateTime.now()).inDays;
  String get estado => esValida ? 'Activa' : (estaVencida ? 'Vencida' : 'Inactiva');
}
