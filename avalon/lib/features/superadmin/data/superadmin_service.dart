import 'package:supabase_flutter/supabase_flutter.dart';

// ── MODELOS ───────────────────────────────────────────────────────────────────

class SaMetricas {
  final int totalOrgs;
  final int orgsActivas;
  final int totalUsuarios;
  final int totalPacientes;
  final double ingresoTotal;
  final double ingresosMes;
  final int pagosMes;
  final List<Map<String, dynamic>> orgsPorPlan;
  final List<Map<String, dynamic>> ultimosPagos;

  const SaMetricas({
    required this.totalOrgs,
    required this.orgsActivas,
    required this.totalUsuarios,
    required this.totalPacientes,
    required this.ingresoTotal,
    required this.ingresosMes,
    required this.pagosMes,
    required this.orgsPorPlan,
    required this.ultimosPagos,
  });

  factory SaMetricas.fromJson(Map<String, dynamic> j) => SaMetricas(
    totalOrgs:      (j['total_orgs']      as num?)?.toInt()    ?? 0,
    orgsActivas:    (j['orgs_activas']    as num?)?.toInt()    ?? 0,
    totalUsuarios:  (j['total_usuarios']  as num?)?.toInt()    ?? 0,
    totalPacientes: (j['total_pacientes'] as num?)?.toInt()    ?? 0,
    ingresoTotal:   double.tryParse(j['ingresos_total'].toString()) ?? 0,
    ingresosMes:    double.tryParse(j['ingresos_mes'].toString())   ?? 0,
    pagosMes:       (j['pagos_mes']       as num?)?.toInt()    ?? 0,
    orgsPorPlan:    (j['orgs_por_plan']   as List?)?.cast<Map<String, dynamic>>() ?? [],
    ultimosPagos:   (j['ultimos_pagos']   as List?)?.cast<Map<String, dynamic>>() ?? [],
  );
}

class SaOrganizacion {
  final String id;
  final String nombre;
  final bool activa;
  final String planNombre;
  final DateTime? fechaVencimiento;
  final int? maxCustom;
  final int totalUsuarios;
  final int totalPacientes;
  final double ingresos;
  final DateTime? fechaCreacion;

  const SaOrganizacion({
    required this.id,
    required this.nombre,
    required this.activa,
    required this.planNombre,
    required this.totalUsuarios,
    required this.totalPacientes,
    required this.ingresos,
    this.fechaVencimiento,
    this.maxCustom,
    this.fechaCreacion,
  });

  factory SaOrganizacion.fromJson(Map<String, dynamic> j) => SaOrganizacion(
    id:               j['id'].toString(),
    nombre:           j['nombre'].toString(),
    activa:           j['activa'] as bool? ?? true,
    planNombre:       j['plan_nombre'].toString(),
    totalUsuarios:    (j['total_usuarios']  as num?)?.toInt() ?? 0,
    totalPacientes:   (j['total_pacientes'] as num?)?.toInt() ?? 0,
    ingresos:         double.tryParse(j['ingresos'].toString()) ?? 0,
    maxCustom:        j['max_custom'] as int?,
    fechaVencimiento: j['fecha_vencimiento'] != null
        ? DateTime.tryParse(j['fecha_vencimiento'].toString()) : null,
    fechaCreacion:    j['fecha_creacion'] != null
        ? DateTime.tryParse(j['fecha_creacion'].toString()) : null,
  );

  bool get vencida =>
      fechaVencimiento != null && fechaVencimiento!.isBefore(DateTime.now());
}

class SaUsuario {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool activa;
  final String? especialidad;
  final String organizacion;
  final String organizacionId;
  final DateTime? ultimoLogin;
  final DateTime? fechaExpiracion;

  const SaUsuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activa,
    required this.organizacion,
    required this.organizacionId,
    this.especialidad,
    this.ultimoLogin,
    this.fechaExpiracion,
  });

  factory SaUsuario.fromJson(Map<String, dynamic> j) => SaUsuario(
    id:              j['id'].toString(),
    nombre:          j['nombre'].toString(),
    email:           j['email'].toString(),
    rol:             j['rol'].toString(),
    activa:          j['activa'] as bool? ?? true,
    especialidad:    j['especialidad']?.toString(),
    organizacion:    j['organizacion'].toString(),
    organizacionId:  j['organizacion_id'].toString(),
    ultimoLogin:     j['ultimo_login'] != null
        ? DateTime.tryParse(j['ultimo_login'].toString()) : null,
    fechaExpiracion: j['fecha_expiracion'] != null
        ? DateTime.tryParse(j['fecha_expiracion'].toString()) : null,
  );

  String get rolLabel {
    switch (rol) {
      case 'admin':      return 'Admin';
      case 'psicologo':  return 'Psicólogo';
      case 'secretaria': return 'Secretaria';
      case 'superadmin': return 'Superadmin';
      default:           return rol;
    }
  }
}

class SaPago {
  final String orgNombre;
  final String planNombre;
  final String pasarela;
  final double monto;
  final String moneda;
  final String estado;
  final int meses;
  final DateTime? fechaPago;
  final String pasarelaPagoId;

  const SaPago({
    required this.orgNombre,
    required this.planNombre,
    required this.pasarela,
    required this.monto,
    required this.moneda,
    required this.estado,
    required this.meses,
    required this.pasarelaPagoId,
    this.fechaPago,
  });

  factory SaPago.fromJson(Map<String, dynamic> j) => SaPago(
    orgNombre:       j['org_nombre'].toString(),
    planNombre:      j['plan_nombre'].toString(),
    pasarela:        j['pasarela'].toString(),
    monto:           double.tryParse(j['monto'].toString()) ?? 0,
    moneda:          j['moneda'].toString(),
    estado:          j['estado'].toString(),
    meses:           j['meses'] as int? ?? 1,
    pasarelaPagoId:  j['pasarela_pago_id'].toString(),
    fechaPago:       j['fecha_pago'] != null
        ? DateTime.tryParse(j['fecha_pago'].toString()) : null,
  );
}

// ── SERVICE ───────────────────────────────────────────────────────────────────

class SuperAdminService {
  final SupabaseClient _client;
  final String _token;

  SuperAdminService(this._client, this._token);

  Future<SaMetricas> getMetricas() async {
    final res = await _client.rpc('sa_get_metricas', params: {'p_token': _token});
    return SaMetricas.fromJson(res as Map<String, dynamic>);
  }

  Future<List<SaOrganizacion>> getOrganizaciones() async {
    final res = await _client.rpc('sa_get_organizaciones', params: {'p_token': _token});
    return (res as List).map((j) => SaOrganizacion.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> crearOrganizacion(String nombre) async {
    await _client.rpc('sa_crear_organizacion', params: {'p_token': _token, 'p_nombre': nombre});
  }

  Future<void> editarOrganizacion(String orgId, {String? nombre, bool? activa}) async {
    await _client.rpc('sa_editar_organizacion', params: {
      'p_token': _token, 'p_org_id': orgId,
      if (nombre != null) 'p_nombre': nombre,
      if (activa != null) 'p_activa': activa,
    });
  }

  Future<void> cambiarPlan(String orgId, String plan, {DateTime? vencimiento, int? maxCustom}) async {
    await _client.rpc('cambiar_plan', params: {
      'p_token':            _token,
      'p_org_id':           orgId,
      'p_nuevo_plan':       plan,
      if (vencimiento != null) 'p_fecha_vencimiento': vencimiento.toIso8601String().split('T')[0],
      if (maxCustom != null)   'p_max_custom': maxCustom,
    });
  }

  Future<void> ajustarLimitePlatinum(String orgId, int nuevoMax) async {
    await _client.rpc('ajustar_limite_platinum', params: {
      'p_token': _token, 'p_org_id': orgId, 'p_nuevo_max': nuevoMax,
    });
  }

  Future<List<SaUsuario>> getUsuarios({String? orgId}) async {
    final res = await _client.rpc('sa_get_usuarios', params: {
      'p_token': _token,
      if (orgId != null) 'p_org_id': orgId,
    });
    return (res as List).map((j) => SaUsuario.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> crearUsuario({
    required String orgId,
    required String nombre,
    required String email,
    required String password,
    String rol = 'psicologo',
    String? especialidad,
    DateTime? fechaExpiracion,
  }) async {
    await _client.rpc('sa_crear_usuario', params: {
      'p_token':    _token,
      'p_org_id':   orgId,
      'p_nombre':   nombre,
      'p_email':    email,
      'p_password': password,
      'p_rol':      rol,
      if (especialidad != null)    'p_especialidad':      especialidad,
      if (fechaExpiracion != null) 'p_fecha_expiracion':  fechaExpiracion.toIso8601String().split('T')[0],
    });
  }

  Future<void> editarUsuario(String userId, {
    String? nombre, String? rol, bool? activa,
    String? especialidad, DateTime? fechaExpiracion, String? nuevaPassword,
  }) async {
    await _client.rpc('sa_editar_usuario', params: {
      'p_token':       _token,
      'p_usuario_id':  userId,
      if (nombre != null)          'p_nombre':            nombre,
      if (rol != null)             'p_rol':               rol,
      if (activa != null)          'p_activa':            activa,
      if (especialidad != null)    'p_especialidad':      especialidad,
      if (fechaExpiracion != null) 'p_fecha_expiracion':  fechaExpiracion.toIso8601String().split('T')[0],
      if (nuevaPassword != null)   'p_nueva_password':    nuevaPassword,
    });
  }

  Future<List<SaPago>> getPagos({String? orgId}) async {
    final res = await _client.rpc('sa_get_pagos', params: {
      'p_token': _token,
      if (orgId != null) 'p_org_id': orgId,
    });
    return (res as List).map((j) => SaPago.fromJson(j as Map<String, dynamic>)).toList();
  }
}
