import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

typedef RpcInvoker = Future<dynamic> Function(
  String fn, {
  Map<String, dynamic>? params,
});

typedef EdgeInvoke = Future<FunctionResponse> Function(
  String functionName, {
  Object? body,
});

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
  final String initPoint;
  final String sandboxInitPoint;

  const PreferenciaMp({
    required this.preferenceId,
    required this.initPoint,
    required this.sandboxInitPoint,
  });

  factory PreferenciaMp.fromJson(Map<String, dynamic> j) => PreferenciaMp(
        preferenceId: j['preference_id'].toString(),
        initPoint: j['init_point'].toString(),
        sandboxInitPoint:
            j['sandbox_init_point']?.toString() ?? j['init_point'].toString(),
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
        plan: j['plan'].toString(),
        vencido: j['vencido'] as bool? ?? false,
        limiteUsuarios: _toInt(j['limite_usuarios'], fallback: 2),
        usuariosUsados: _toInt(j['usuarios_usados']),
        usuariosDisponibles: _toInt(j['usuarios_disponibles']),
        limiteAdmins: _toInt(j['limite_admins']),
        adminsUsados: _toInt(j['admins_usados']),
        esIlimitado:
            j['es_ilimitado'] as bool? ?? j['es_platinum'] as bool? ?? false,
        maxCustom: j['max_custom'] as int?,
        diasRestantes: j['dias_restantes'] as int?,
        fechaVencimiento: j['fecha_vencimiento'] != null
            ? DateTime.tryParse(j['fecha_vencimiento'].toString())
            : null,
      );

  String get planLabel {
    switch (plan) {
      case 'inicio':
        return 'Inicio';
      case 'starter':
        return 'Starter';
      case 'profesional':
        return 'Profesional';
      case 'clinica':
        return 'Clinica';
      case 'corporativo':
        return 'Corporativo';
      case 'ilimitado':
        return 'Ilimitado';
      default:
        return plan;
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
        pasarela: j['pasarela'].toString(),
        planNombre: j['plan_nombre'].toString(),
        monto: double.tryParse(j['monto'].toString()) ?? 0,
        moneda: j['moneda'].toString(),
        estado: j['estado'].toString(),
        meses: _toInt(j['meses'], fallback: 1),
        fechaPago: j['fecha_pago'] != null
            ? DateTime.tryParse(j['fecha_pago'].toString())
            : null,
      );
}

class PaymentService {
  final SupabaseClient _client;
  final String _token;
  final RpcInvoker? _rpcInvoker;
  final EdgeInvoke? _edgeInvoke;

  PaymentService(
    this._client,
    this._token, {
    RpcInvoker? rpcInvoker,
    EdgeInvoke? edgeInvoke,
  })  : _rpcInvoker = rpcInvoker,
        _edgeInvoke = edgeInvoke;

  Future<dynamic> _rpc(String fn, {Map<String, dynamic>? params}) {
    final invoker = _rpcInvoker;
    if (invoker != null) return invoker(fn, params: params);
    return _client.rpc(fn, params: params);
  }

  Future<FunctionResponse> _invoke(String functionName, {Object? body}) {
    final invoker = _edgeInvoke;
    if (invoker != null) return invoker(functionName, body: body);
    return _client.functions.invoke(functionName, body: body);
  }

  Future<List<PlanDisponible>> getPlanes() async {
    final res = await _rpc('get_planes', params: {'p_token': _token});
    const labels = {
      'inicio': 'Inicio',
      'starter': 'Starter',
      'profesional': 'Profesional',
      'clinica': 'Clínica',
      'corporativo': 'Corporativo',
      'ilimitado': 'Ilimitado',
    };

    return (res as List)
        .map((j) => PlanDisponible(
              nombre: j['nombre'].toString(),
              label: labels[j['nombre']] ?? j['nombre'].toString(),
              maxUsuarios: _toInt(j['max_usuarios_normales']),
              maxAdmins: _toInt(j['max_admins']),
              precio: double.tryParse(j['precio_referencia'].toString()) ?? 0,
              activo: j['activo'] as bool? ?? true,
            ))
        .where((p) => p.activo && p.nombre != 'inicio')
        .toList();
  }

  Future<PreferenciaMp> crearPreferenciaMp(String planNombre) async {
    final res = await _invoke(
      'crear-preferencia-mp',
      body: {'token': _token, 'plan': planNombre},
    );

    if (res.status != 200) {
      final data = res.data;
      final msg = data is Map
          ? data['error'] ?? 'Error al crear pago'
          : 'Error al crear pago';
      throw Exception(msg);
    }

    final data = res.data is String ? jsonDecode(res.data) : res.data;
    return PreferenciaMp.fromJson(data as Map<String, dynamic>);
  }

  Future<bool> abrirPago(PreferenciaMp preferencia,
      {bool sandbox = false}) async {
    final url = sandbox ? preferencia.sandboxInitPoint : preferencia.initPoint;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  Future<PlanInfo> getInfoPlan() async {
    final res = await _rpc('get_info_plan', params: {'p_token': _token});
    final data =
        res is List ? Map<String, dynamic>.from(res.first as Map) : res as Map;
    return PlanInfo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<HistorialPago>> getHistorialPagos() async {
    final res = await _rpc('get_historial_pagos', params: {'p_token': _token});
    return (res as List)
        .map((j) => HistorialPago.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }
}

int _toInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
