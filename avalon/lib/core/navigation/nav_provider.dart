import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab { dashboard, pacientes, citas, notas, configuracion }

class NavNotifier extends StateNotifier<AppTab> {
  NavNotifier() : super(AppTab.dashboard);

  void goTo(AppTab tab) => state = tab;
  void goToDashboard()     => state = AppTab.dashboard;
  void goToPacientes()     => state = AppTab.pacientes;
  void goToCitas()         => state = AppTab.citas;
  void goToNotas()         => state = AppTab.notas;
  void goToConfiguracion() => state = AppTab.configuracion;
}

final navProvider = StateNotifierProvider<NavNotifier, AppTab>(
  (ref) => NavNotifier(),
);

// Provider de índice numérico para el BottomNavigationBar
final navIndexProvider = Provider<int>((ref) {
  return ref.watch(navProvider).index;
});
