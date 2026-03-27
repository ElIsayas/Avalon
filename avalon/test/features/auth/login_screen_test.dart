import 'package:avalon/features/auth/data/auth_service.dart';
import 'package:avalon/features/auth/domain/app_user.dart';
import 'package:avalon/features/auth/presentation/providers/auth_provider.dart';
import 'package:avalon/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  group('LoginScreen', () {
    late _MockAuthService authService;

    setUp(() {
      authService = _MockAuthService();
      when(() => authService.getSessionUser()).thenAnswer((_) async => null);
      when(() => authService.signOut(any())).thenAnswer((_) async {});
      when(() => authService.sendPasswordReset(any())).thenAnswer((_) async {});
    });

    testWidgets('envia credenciales al presionar Iniciar sesion',
        (tester) async {
      when(() => authService.signIn('ana@test.com', 'secret')).thenAnswer(
        (_) async => const AppUser(
          id: 'u-1',
          nombre: 'Ana Perez',
          email: 'ana@test.com',
          rol: 'admin',
          activa: true,
          sessionToken: 'token-1',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'ana@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret');
      await tester.tap(find.text('Iniciar sesi\u00f3n'));
      await tester.pumpAndSettle();

      verify(() => authService.signIn('ana@test.com', 'secret')).called(1);
    });

    testWidgets('muestra dialogo de recuperacion al enviar email valido',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'ana@test.com');
      await tester.tap(find.text('Olvid\u00e9 mi contrase\u00f1a'));
      await tester.pumpAndSettle();

      verify(() => authService.sendPasswordReset('ana@test.com')).called(1);
      expect(find.text('Correo enviado'), findsOneWidget);
      expect(find.textContaining('Revisa tu bandeja de entrada'), findsOneWidget);
    });
  });
}
