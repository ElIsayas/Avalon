import 'package:avalon/features/pagos/data/payment_service.dart';
import 'package:avalon/features/pagos/presentation/providers/payment_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPaymentService extends Mock implements PaymentService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(
      const PreferenciaMp(
        preferenceId: 'fallback',
        initPoint: 'https://fallback.test/init',
        sandboxInitPoint: 'https://fallback.test/sandbox',
      ),
    );
  });

  group('PaymentNotifier', () {
    late _MockPaymentService paymentService;
    late PaymentNotifier notifier;

    setUp(() {
      paymentService = _MockPaymentService();
      notifier = PaymentNotifier(paymentService);
    });

    test('cargarTodo llena plan, planes e historial', () async {
      when(() => paymentService.getPlanes()).thenAnswer(
        (_) async => const [
          PlanDisponible(
            nombre: 'starter',
            label: 'Starter',
            maxUsuarios: 5,
            maxAdmins: 1,
            precio: 100000,
            activo: true,
          ),
        ],
      );
      when(() => paymentService.getInfoPlan()).thenAnswer(
        (_) async => const PlanInfo(
          plan: 'starter',
          vencido: false,
          limiteUsuarios: 5,
          usuariosUsados: 2,
          usuariosDisponibles: 3,
          limiteAdmins: 1,
          adminsUsados: 1,
          esIlimitado: false,
        ),
      );
      when(() => paymentService.getHistorialPagos()).thenAnswer(
        (_) async => const [
          HistorialPago(
            pasarela: 'mercadopago',
            planNombre: 'starter',
            monto: 100000,
            moneda: 'COP',
            estado: 'completado',
            meses: 1,
          ),
        ],
      );

      await notifier.cargarTodo();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.planInfo?.plan, 'starter');
      expect(notifier.state.planes, hasLength(1));
      expect(notifier.state.historial, hasLength(1));
    });

    test('pagar crea preferencia y abre navegador', () async {
      when(() => paymentService.crearPreferenciaMp('starter')).thenAnswer(
        (_) async => const PreferenciaMp(
          preferenceId: 'pref-1',
          initPoint: 'https://mp.test/init',
          sandboxInitPoint: 'https://mp.test/sandbox',
        ),
      );
      when(
        () => paymentService.abrirPago(any(), sandbox: any(named: 'sandbox')),
      ).thenAnswer((_) async => true);

      await notifier.pagar('starter');

      expect(notifier.state.creandoPago, isFalse);
      expect(notifier.state.error, isNull);
      verify(() => paymentService.crearPreferenciaMp('starter')).called(1);
    });
  });
}
