class AppUser {
  final String id;           // public.usuarios.id
  final String authUserId;   // auth.users.id (auth.uid())
  final String nombre;
  final String email;
  final String rol;          // 'admin' o 'user'
  final bool activa;
  final String? licenciaId;
  final String? especialidad;
  final DateTime? fechaRegistro;

  const AppUser({
    required this.id,
    required this.authUserId,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activa,
    this.licenciaId,
    this.especialidad,
    this.fechaRegistro,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:           json['id']?.toString() ?? '',
      authUserId:   json['auth_user_id']?.toString() ?? '',
      nombre:       json['nombre']?.toString() ?? '',
      email:        json['email']?.toString() ?? '',
      rol:          json['rol']?.toString() ?? 'user',
      activa:       json['activa'] as bool? ?? true,
      licenciaId:   json['licencia_id']?.toString(),
      especialidad: json['especialidad']?.toString(),
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'].toString())
          : null,
    );
  }

  bool get isAdmin => rol == 'admin';
  bool get isUser  => rol == 'user';
  String get displayName => nombre.isNotEmpty ? nombre : email;
}
