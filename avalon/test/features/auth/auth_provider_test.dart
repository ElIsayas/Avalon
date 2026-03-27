import 'package:avalon/features/auth/data/auth_service.dart';
import 'package:avalon/features/auth/domain/app_user.dart';
import 'package:avalon/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  group('AuthNotifier', () {
    late _MockAuthService authService;
    late AuthNotifier notifier;

    const user = AppUser(
      id: 'u-1',
      nombre: 'Ana Perez',
      email: 'ana@test.com',
      rol: 'admin',
      activa: true,
      sessionToken: 'token-1',
    );

    setUp(() {
      authService = _MockAuthService();
      notifier = AuthNotifier(authService);
    });

    test('signIn exitoso actualiza usuario autenticado', () async {
      when(() => authService.signIn('ana@test.com', 'secret'))
          .thenAnswer((_) async => user);

      await notifier.signIn('ana@test.com', 'secret');

      expect(notifier.state.user, isNotNull);
      expect(notifier.state.user?.id, 'u-1');
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.error, isNull);
      expect(notifier.state.isLoading, isFalse);
    });

    test('signIn fallido guarda error', () async {
      when(() => authService.signIn(any(), any()))
          .thenThrow(Exception('Credenciales invalidas'));

      await notifier.signIn('ana@test.com', 'bad');

      expect(notifier.state.user, isNull);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.error, contains('Credenciales invalidas'));
      expect(notifier.state.isLoading, isFalse);
    });

    test('initialize con sesion expirada limpia usuario y reporta mensaje',
        () async {
      when(() => authService.getSessionUser())
          .thenThrow(const SessionExpiredException('Tu sesion ha vencido'));

      await notifier.initialize();

      expect(notifier.state.user, isNull);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.error, contains('sesion'));
      expect(notifier.state.isLoading, isFalse);
    });
  });
}
