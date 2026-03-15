import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/payment_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── SERVICE PROVIDER ──────────────────────────────────────────────────────────
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final token = ref.watch(currentUserProvider)?.sessionToken ?? '';
  return PaymentService(Supabase.instance.client, token);
});

// ── ESTADO ────────────────────────────────────────────────────────────────────
class PaymentState {
  final List<PlanDisponible> planes;
  final PlanInfo? planInfo;
  final List<HistorialPago> historial;
  final bool isLoading;
  final bool creandoPago;      // true mientras genera la preferencia en MP
  final bool pagoDetectado;    // true cuando se detecta pago exitoso al volver
  final String? error;

  const PaymentState({
    this.planes        = const [],
    this.planInfo,
    this.historial     = const [],
    this.isLoading     = false,
    this.creandoPago   = false,
    this.pagoDetectado = false,
    this.error,
  });

  PaymentState copyWith({
    List<PlanDisponible>? planes,
    PlanInfo? planInfo,
    List<HistorialPago>? historial,
    bool? isLoading,
    bool? creandoPago,
    bool? pagoDetectado,
    String? error,
    bool clearError = false,
  }) => PaymentState(
    planes:        planes        ?? this.planes,
    planInfo:      planInfo      ?? this.planInfo,
    historial:     historial     ?? this.historial,
    isLoading:     isLoading     ?? this.isLoading,
    creandoPago:   creandoPago   ?? this.creandoPago,
    pagoDetectado: pagoDetectado ?? this.pagoDetectado,
    error:         clearError    ? null : error ?? this.error,
  );
}

// ── NOTIFIER ──────────────────────────────────────────────────────────────────
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

  // Detecta cuando la app vuelve al foreground después de pagar
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed && _planAntesDePago != null) {
      _verificarPago();
    }
  }

  // ── Carga inicial ─────────────────────────────────────────────────────────
  Future<void> cargarTodo() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _service.getPlanes(),
        _service.getInfoPlan(),
      ]);
      state = state.copyWith(
        planes:    results[0] as List<PlanDisponible>,
        planInfo:  results[1] as PlanInfo,
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

  // ── Iniciar pago ──────────────────────────────────────────────────────────
  // 1. Crea la preferencia en MP via Edge Function
  // 2. Abre la URL en el navegador
  // 3. Cuando el usuario vuelve, verifica si el plan cambió
  Future<void> pagar(String planNombre, {bool sandbox = false}) async {
    state = state.copyWith(creandoPago: true, clearError: true);
    try {
      // Guardar plan actual para comparar al volver
      _planAntesDePago = state.planInfo?.plan;

      // Crear preferencia dinámica con org_id:plan como external_reference
      final preferencia = await _service.crearPreferenciaMp(planNombre);

      // Abrir en navegador externo
      final ok = await _service.abrirPago(preferencia, sandbox: sandbox);
      if (!ok) {
        state = state.copyWith(
          creandoPago: false,
          error: 'No se pudo abrir el navegador',
        );
        return;
      }
      state = state.copyWith(creandoPago: false);
    } catch (e) {
      state = state.copyWith(creandoPago: false, error: _msg(e));
    }
  }

  // Verificación manual del pago (útil para botón "Ya pagué")
  Future<void> verificarPagoManual() => _verificarPago();

  Future<void> _verificarPago() async {
    try {
      final infoNueva    = await _service.getInfoPlan();
      final pagoExitoso  = infoNueva.plan != _planAntesDePago ||
          (state.planInfo?.vencido == true && !infoNueva.vencido);
      state = state.copyWith(
        planInfo:      infoNueva,
        pagoDetectado: pagoExitoso,
      );
    } catch (_) {
      // Silencioso — no interrumpir el flujo
    } finally {
      _planAntesDePago = null;
    }
  }

  void clearPagoDetectado() => state = state.copyWith(pagoDetectado: false);
  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}

// ── PROVIDERS ─────────────────────────────────────────────────────────────────
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref.read(paymentServiceProvider));
});
