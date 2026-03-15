import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';

// ── MODELOS ───────────────────────────────────────────────────────────────────

class PlanDisponible {
  final String nombre;
  final String label;
  final int maxUsuarios;
  final int maxAdmins;
  final double precio;
  final bool activo;

  const PlanDisponible({
    required this.nombre,
    required this.label,
    required this.maxUsuarios,
    required this.maxAdmins,
    required this.precio,
    required this.activo,
  });

  String get precioFormateado {
    if (precio == 0) return 'Gratis';
    final n = precio.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '\$$n COP/mes';
  }

  String get adminsLabel => maxAdmins == 0
      ? 'Sin administrador'
      : '$maxAdmins admin${maxAdmins > 1 ? "s" : ""}';
}

class PreferenciaMp {
  final String preferenceId;
  final String initPoint;        // URL producción
  final String sandboxInitPoint; // URL pruebas

  const PreferenciaMp({
    required this.preferenceId,
    required this.initPoint,
    required this.sandboxInitPoint,
  });

  factory PreferenciaMp.fromJson(Map<String, dynamic> j) => PreferenciaMp(
    preferenceId:      j['preference_id'].toString(),
    initPoint:         j['init_point'].toString(),
    sandboxInitPoint:  j['sandbox_init_point']?.toString() ?? j['init_point'].toString(),
  );
}

class PlanInfo {
  final String plan;
  final bool vencido;
  final DateTime? fechaVencimiento;
  final int? diasRestantes;
  final int limiteUsuarios;
  final int usuariosUsados;
  final int usuariosDisponibles;
  final int limiteAdmins;
  final int adminsUsados;
  final bool esIlimitado;
  final int? maxCustom;

  const PlanInfo({
    required this.plan,
    required this.vencido,
    required this.limiteUsuarios,
    required this.usuariosUsados,
    required this.usuariosDisponibles,
    required this.limiteAdmins,
    required this.adminsUsados,
    required this.esIlimitado,
    this.fechaVencimiento,
    this.diasRestantes,
    this.maxCustom,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> j) => PlanInfo(
    plan:                j['plan'].toString(),
    vencido:             j['vencido']             as bool? ?? false,
    limiteUsuarios:      j['limite_usuarios']      as int?  ?? 2,
    usuariosUsados:      j['usuarios_usados']      as int?  ?? 0,
    usuariosDisponibles: j['usuarios_disponibles'] as int?  ?? 0,
    limiteAdmins:        j['limite_admins']        as int?  ?? 0,
    adminsUsados:        j['admins_usados']        as int?  ?? 0,
    esIlimitado:         j['es_platinum']          as bool? ?? false,
    maxCustom:           j['max_custom']           as int?,
    diasRestantes:       j['dias_restantes']       as int?,
    fechaVencimiento:    j['fecha_vencimiento'] != null
        ? DateTime.tryParse(j['fecha_vencimiento'].toString()) : null,
  );

  String get planLabel {
    switch (plan) {
      case 'inicio':      return 'Inicio';
      case 'starter':     return 'Starter';
      case 'profesional': return 'Profesional';
      case 'clinica':     return 'Clínica';
      case 'corporativo': return 'Corporativo';
      case 'ilimitado':   return 'Ilimitado';
      default:            return plan;
    }
  }

  bool get proximoAVencer =>
      diasRestantes != null && diasRestantes! <= 7 && !vencido;
}

class HistorialPago {
  final String pasarela;
  final String planNombre;
  final double monto;
  final String moneda;
  final String estado;
  final int meses;
  final DateTime? fechaPago;

  const HistorialPago({
    required this.pasarela,
    required this.planNombre,
    required this.monto,
    required this.moneda,
    required this.estado,
    required this.meses,
    this.fechaPago,
  });

  factory HistorialPago.fromJson(Map<String, dynamic> j) => HistorialPago(
    pasarela:   j['pasarela'].toString(),
    planNombre: j['plan_nombre'].toString(),
    monto:      double.tryParse(j['monto'].toString()) ?? 0,
    moneda:     j['moneda'].toString(),
    estado:     j['estado'].toString(),
    meses:      j['meses'] as int? ?? 1,
    fechaPago:  j['fecha_pago'] != null
        ? DateTime.tryParse(j['fecha_pago'].toString()) : null,
  );
}

// ── SERVICE ───────────────────────────────────────────────────────────────────

class PaymentService {
  final SupabaseClient _client;
  final String _token;

  PaymentService(this._client, this._token);

  // ── Lista de planes disponibles (desde la BD) ─────────────────────────────
  Future<List<PlanDisponible>> getPlanes() async {
    final res = await _client
        .from('planes')
        .select('nombre, max_usuarios_normales, max_admins, precio_referencia, activo')
        .eq('activo', true)
        .order('precio_referencia');

    const labels = {
      'inicio':      'Inicio',
      'starter':     'Starter',
      'profesional': 'Profesional',
      'clinica':     'Clínica',
      'corporativo': 'Corporativo',
      'ilimitado':   'Ilimitado',
    };

    return (res as List).map((j) => PlanDisponible(
      nombre:      j['nombre'].toString(),
      label:       labels[j['nombre']] ?? j['nombre'].toString(),
      maxUsuarios: j['max_usuarios_normales'] as int? ?? 0,
      maxAdmins:   j['max_admins'] as int? ?? 0,
      precio:      double.tryParse(j['precio_referencia'].toString()) ?? 0,
      activo:      j['activo'] as bool? ?? true,
    )).where((p) => p.nombre != 'inicio').toList(); // inicio es gratis, no se paga
  }

  // ── Crear preferencia dinámica en MercadoPago ─────────────────────────────
  // Llama a la Edge Function crear-preferencia-mp que genera la preferencia
  // con el external_reference correcto (org_id:plan)
  Future<PreferenciaMp> crearPreferenciaMp(String planNombre) async {
    final res = await _client.functions.invoke(
      'crear-preferencia-mp',
      body: {'token': _token, 'plan': planNombre},
    );

    if (res.status != 200) {
      final data = res.data;
      final msg  = data is Map ? data['error'] ?? 'Error al crear pago' : 'Error al crear pago';
      throw Exception(msg);
    }

    final data = res.data is String ? jsonDecode(res.data) : res.data;
    return PreferenciaMp.fromJson(data as Map<String, dynamic>);
  }

  // ── Abrir URL de pago en navegador externo ────────────────────────────────
  // En producción usa init_point, en pruebas usa sandbox_init_point
  Future<bool> abrirPago(PreferenciaMp preferencia, {bool sandbox = false}) async {
    final url  = sandbox ? preferencia.sandboxInitPoint : preferencia.initPoint;
    final uri  = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // ── Info del plan actual ──────────────────────────────────────────────────
  Future<PlanInfo> getInfoPlan() async {
    final res = await _client.rpc('get_info_plan', params: {'p_token': _token});
    return PlanInfo.fromJson(res as Map<String, dynamic>);
  }

  // ── Historial de pagos ────────────────────────────────────────────────────
  Future<List<HistorialPago>> getHistorialPagos() async {
    final res = await _client.rpc('get_historial_pagos', params: {'p_token': _token});
    return (res as List)
        .map((j) => HistorialPago.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
