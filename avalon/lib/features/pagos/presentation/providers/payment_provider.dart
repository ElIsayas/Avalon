import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final token = ref.watch(currentUserProvider)?.sessionToken ?? '';
  return PaymentService(Supabase.instance.client, token);
});

class PaymentState {
  final List<PlanDisponible> planes;
  final PlanInfo? planInfo;
  final List<HistorialPago> historial;
  final bool isLoading;
  final bool creandoPago;
  final bool pagoDetectado;
  final bool retornoSinConfirmacion;
  final String? error;

  const PaymentState({
    this.planes = const [],
    this.planInfo,
    this.historial = const [],
    this.isLoading = false,
    this.creandoPago = false,
    this.pagoDetectado = false,
    this.retornoSinConfirmacion = false,
    this.error,
  });

  PaymentState copyWith({
    List<PlanDisponible>? planes,
    PlanInfo? planInfo,
    List<HistorialPago>? historial,
    bool? isLoading,
    bool? creandoPago,
    bool? pagoDetectado,
    bool? retornoSinConfirmacion,
    String? error,
    bool clearError = false,
  }) {
    return PaymentState(
      planes: planes ?? this.planes,
      planInfo: planInfo ?? this.planInfo,
      historial: historial ?? this.historial,
      isLoading: isLoading ?? this.isLoading,
      creandoPago: creandoPago ?? this.creandoPago,
      pagoDetectado: pagoDetectado ?? this.pagoDetectado,
      retornoSinConfirmacion:
          retornoSinConfirmacion ?? this.retornoSinConfirmacion,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState>
    with WidgetsBindingObserver {
  final PaymentService _service;
  String? _planAntesDePago;

  PaymentNotifier(this._service) : super(const PaymentState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _planAntesDePago != null) {
      _verificarPago();
    }
  }

  Future<void> cargarTodo() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _service.getPlanes(),
        _service.getInfoPlan(),
        _service.getHistorialPagos(),
      ]);
      state = state.copyWith(
        planes: results[0] as List<PlanDisponible>,
        planInfo: results[1] as PlanInfo,
        historial: results[2] as List<HistorialPago>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<void> cargarHistorial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final historial = await _service.getHistorialPagos();
      state = state.copyWith(historial: historial, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<void> pagar(String planNombre, {bool sandbox = false}) async {
    state = state.copyWith(creandoPago: true, clearError: true);
    try {
      _planAntesDePago = state.planInfo?.plan;
      final preferencia = await _service.crearPreferenciaMp(planNombre);
      final ok = await _service.abrirPago(preferencia, sandbox: sandbox);
      if (!ok) {
        _planAntesDePago = null;
        state = state.copyWith(
          creandoPago: false,
          error: 'No se pudo abrir el navegador',
        );
        return;
      }
      state = state.copyWith(
        creandoPago: false,
        pagoDetectado: false,
        retornoSinConfirmacion: false,
      );
    } catch (e) {
      _planAntesDePago = null;
      state = state.copyWith(creandoPago: false, error: _msg(e));
    }
  }

  Future<void> verificarPagoManual() => _verificarPago();

  Future<void> _verificarPago() async {
    try {
      final infoNueva = await _service.getInfoPlan();
      final historialNuevo = await _service.getHistorialPagos();
      final pagoExitoso = infoNueva.plan != _planAntesDePago ||
          (state.planInfo?.vencido == true && !infoNueva.vencido);
      state = state.copyWith(
        planInfo: infoNueva,
        historial: historialNuevo,
        pagoDetectado: pagoExitoso,
        retornoSinConfirmacion: !pagoExitoso,
      );
    } catch (_) {
      // Silencioso para no interrumpir retorno del usuario.
    } finally {
      _planAntesDePago = null;
    }
  }

  void clearPagoMensajes() {
    state = state.copyWith(
      pagoDetectado: false,
      retornoSinConfirmacion: false,
    );
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref.read(paymentServiceProvider));
});
