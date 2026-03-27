import 'package:avalon/core/navigation/nav_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavNotifier', () {
    test('inicia en dashboard', () {
      final notifier = NavNotifier();
      expect(notifier.state, AppTab.dashboard);
    });

    test('permite navegar entre tabs principales', () {
      final notifier = NavNotifier();

      notifier.goToPacientes();
      expect(notifier.state, AppTab.pacientes);

      notifier.goToCitas();
      expect(notifier.state, AppTab.citas);

      notifier.goToNotas();
      expect(notifier.state, AppTab.notas);

      notifier.goToConfiguracion();
      expect(notifier.state, AppTab.configuracion);

      notifier.goToDashboard();
      expect(notifier.state, AppTab.dashboard);
    });
  });
}
