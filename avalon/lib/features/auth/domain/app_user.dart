class AppUser {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool activa;
  final String? especialidad;
  final DateTime? fechaRegistro;
  final DateTime? fechaExpiracion;

  // Token de sesión — se guarda en SharedPreferences, no en la BD directamente
  final String sessionToken;

  const AppUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activa,
    required this.sessionToken,
    this.especialidad,
    this.fechaRegistro,
    this.fechaExpiracion,
  });

  /// Construye AppUser desde la respuesta JSON del RPC `login` o `validate_session`
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:              json['id']?.toString() ?? '',
      nombre:          json['nombre']?.toString() ?? '',
      email:           json['email']?.toString() ?? '',
      rol:             json['rol']?.toString() ?? 'psicologo',
      activa:          json['activa'] as bool? ?? true,
      sessionToken:    json['token']?.toString() ?? '',
      especialidad:    json['especialidad']?.toString(),
      fechaRegistro:   json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'].toString())
          : null,
      fechaExpiracion: json['fecha_expiracion'] != null
          ? DateTime.tryParse(json['fecha_expiracion'].toString())
          : null,
    );
  }

  bool get isAdmin     => rol == 'admin';
  bool get isPsicologo => rol == 'psicologo';
  String get displayName => nombre.isNotEmpty ? nombre : email;

  /// Iniciales para avatares
  String get iniciales {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Días restantes de acceso (null = sin expiración)
  int? get diasRestantes {
    if (fechaExpiracion == null) return null;
    return fechaExpiracion!.difference(DateTime.now()).inDays;
  }

  /// Copia con campos actualizados
  AppUser copyWith({String? nombre, String? especialidad}) {
    return AppUser(
      id:              id,
      nombre:          nombre ?? this.nombre,
      email:           email,
      rol:             rol,
      activa:          activa,
      sessionToken:    sessionToken,
      especialidad:    especialidad ?? this.especialidad,
      fechaRegistro:   fechaRegistro,
      fechaExpiracion: fechaExpiracion,
    );
  }
}
