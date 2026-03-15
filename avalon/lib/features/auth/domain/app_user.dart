class AppUser {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool activa;
  final String? especialidad;
  final String? organizacionId;
  final DateTime? fechaRegistro;
  final DateTime? fechaExpiracion;
  final String sessionToken;
  final String? plan;
  final int? limiteUsuarios;

  const AppUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activa,
    required this.sessionToken,
    this.especialidad,
    this.organizacionId,
    this.fechaRegistro,
    this.fechaExpiracion,
    this.plan,
    this.limiteUsuarios,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:              json['id']?.toString() ?? '',
      nombre:          json['nombre']?.toString() ?? '',
      email:           json['email']?.toString() ?? '',
      rol:             json['rol']?.toString() ?? 'psicologo',
      activa:          json['activa'] as bool? ?? true,
      sessionToken:    json['token']?.toString() ?? '',
      especialidad:    json['especialidad']?.toString(),
      organizacionId:  json['organizacion_id']?.toString(),
      plan:            json['plan']?.toString(),
      limiteUsuarios:  json['limite_usuarios'] as int?,
      fechaRegistro:   json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'].toString()) : null,
      fechaExpiracion: json['fecha_expiracion'] != null
          ? DateTime.tryParse(json['fecha_expiracion'].toString()) : null,
    );
  }

  // ── Rol helpers ───────────────────────────────────────────────────────
  bool get isAdmin      => rol == 'admin';
  bool get isPsicologo  => rol == 'psicologo';
  bool get isSecretaria => rol == 'secretaria';
  bool get isSuperAdmin => rol == 'superadmin';

  bool get puedeVerHistorial      => rol != 'secretaria';
  bool get puedeEscribirNotas     => rol == 'psicologo' || rol == 'admin' || rol == 'superadmin';
  bool get puedeEliminarPacientes => rol != 'secretaria';
  bool get puedeGestionarUsuarios => rol == 'admin' || rol == 'superadmin';

  // ── Plan helpers ──────────────────────────────────────────────────────
  bool get esPlanGratis      => plan == 'gratis' || plan == null;
  bool get esPlanPlatinum    => plan == 'platinum';

  String get planLabel {
    switch (plan) {
      case 'gratis':     return 'Gratis';
      case 'basico':     return 'Básico';
      case 'pro':        return 'Pro';
      case 'enterprise': return 'Enterprise';
      case 'platinum':   return 'Platinum';
      default:           return plan ?? 'Gratis';
    }
  }

  String get displayName => nombre.isNotEmpty ? nombre : email;

  String get rolLabel {
    switch (rol) {
      case 'admin':      return 'Administrador';
      case 'psicologo':  return 'Psicólogo';
      case 'secretaria': return 'Secretaria';
      case 'superadmin': return 'Super Admin';
      default:           return rol;
    }
  }

  String get rolEmoji {
    switch (rol) {
      case 'admin':      return '👑';
      case 'psicologo':  return '🧠';
      case 'secretaria': return '📋';
      case 'superadmin': return '⚡';
      default:           return '👤';
    }
  }

  String get iniciales {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return nombre.substring(0, nombre.length >= 2 ? 2 : 1).toUpperCase();
  }

  int? get diasRestantes {
    if (fechaExpiracion == null) return null;
    return fechaExpiracion!.difference(DateTime.now()).inDays;
  }

  AppUser copyWith({String? nombre, String? especialidad}) {
    return AppUser(
      id: id, nombre: nombre ?? this.nombre, email: email, rol: rol,
      activa: activa, sessionToken: sessionToken,
      especialidad: especialidad ?? this.especialidad,
      organizacionId: organizacionId, fechaRegistro: fechaRegistro,
      fechaExpiracion: fechaExpiracion, plan: plan, limiteUsuarios: limiteUsuarios,
    );
  }
}
