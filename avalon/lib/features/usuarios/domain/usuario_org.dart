class UsuarioOrg {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool activa;
  final String? especialidad;
  final DateTime? fechaExpiracion;
  final DateTime? ultimoLogin;

  const UsuarioOrg({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activa,
    this.especialidad,
    this.fechaExpiracion,
    this.ultimoLogin,
  });

  factory UsuarioOrg.fromJson(Map<String, dynamic> j) => UsuarioOrg(
        id:               j['id'].toString(),
        nombre:           j['nombre'].toString(),
        email:            j['email'].toString(),
        rol:              j['rol'].toString(),
        activa:           j['activa'] as bool? ?? true,
        especialidad:     j['especialidad']?.toString(),
        fechaExpiracion:  j['fecha_expiracion'] != null
            ? DateTime.tryParse(j['fecha_expiracion'].toString())
            : null,
        ultimoLogin:      j['ultimo_login'] != null
            ? DateTime.tryParse(j['ultimo_login'].toString())
            : null,
      );

  String get rolLabel {
    switch (rol) {
      case 'admin':      return 'Administrador';
      case 'psicologo':  return 'Psicólogo';
      case 'secretaria': return 'Secretaria';
      default:           return rol;
    }
  }

  String get rolEmoji {
    switch (rol) {
      case 'admin':      return '👑';
      case 'psicologo':  return '🧠';
      case 'secretaria': return '📋';
      default:           return '👤';
    }
  }

  String get iniciales {
    final p = nombre.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return nombre.substring(0, nombre.length >= 2 ? 2 : 1).toUpperCase();
  }
}
