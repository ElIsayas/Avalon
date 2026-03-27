import 'package:avalon/features/pagos/data/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('PaymentService', () {
    test('getInfoPlan parsea la respuesta RPC', () async {
      final service = PaymentService(
        _MockSupabaseClient(),
        'token-test',
        rpcInvoker: (fn, {params}) async {
          expect(fn, 'get_info_plan');
          return {
            'plan': 'starter',
            'vencido': false,
            'limite_usuarios': 5,
            'usuarios_usados': 2,
            'usuarios_disponibles': 3,
            'limite_admins': 1,
            'admins_usados': 1,
            'es_ilimitado': false,
          };
        },
      );

      final plan = await service.getInfoPlan();
      expect(plan.plan, 'starter');
      expect(plan.vencido, isFalse);
      expect(plan.limiteUsuarios, 5);
      expect(plan.usuariosDisponibles, 3);
    });

    test('crearPreferenciaMp devuelve preferencia cuando Function responde 200', () async {
      final service = PaymentService(
        _MockSupabaseClient(),
        'token-test',
        edgeInvoke: (name, {body}) async {
          expect(name, 'crear-preferencia-mp');
          return FunctionResponse(
            status: 200,
            data: {
              'preference_id': 'pref-1',
              'init_point': 'https://mp.test/init',
              'sandbox_init_point': 'https://mp.test/sandbox',
            },
          );
        },
      );

      final pref = await service.crearPreferenciaMp('starter');
      expect(pref.preferenceId, 'pref-1');
      expect(pref.initPoint, 'https://mp.test/init');
      expect(pref.sandboxInitPoint, 'https://mp.test/sandbox');
    });
  });
}
