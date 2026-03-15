// ── CAMBIOS EN superadmin_screen.dart ────────────────────────────────────────
//
// 1. Agrega el import al inicio del archivo:
import 'pasarelas_tab.dart';
//
// 2. Cambia el TabController de length: 4 a length: 5:
//    _tabs = TabController(length: 5, vsync: this);
//
// 3. Agrega el tab en el AppBar bottom:
//    Tab(icon: Icon(Icons.credit_card_outlined, size: 18), text: 'Pasarelas'),
//
// 4. Agrega el TabBarView en el body:
//    PasarelasTab(organizaciones: state.organizaciones),
//
// ── RESULTADO FINAL del AppBar bottom ────────────────────────────────────────
//
//   bottom: TabBar(
//     controller: _tabs,
//     tabs: const [
//       Tab(icon: Icon(Icons.dashboard_outlined, size: 18),  text: 'Métricas'),
//       Tab(icon: Icon(Icons.business_outlined, size: 18),   text: 'Orgs'),
//       Tab(icon: Icon(Icons.people_outline, size: 18),      text: 'Usuarios'),
//       Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Pagos'),
//       Tab(icon: Icon(Icons.credit_card_outlined, size: 18), text: 'Pasarelas'), // ← nuevo
//     ],
//   ),
//
// ── RESULTADO FINAL del body TabBarView ──────────────────────────────────────
//
//   body: TabBarView(
//     controller: _tabs,
//     children: [
//       _MetricasTab(metricas: state.metricas),
//       _OrgsTab(orgs: state.organizaciones),
//       _UsuariosTab(usuarios: state.usuarios, orgs: state.organizaciones),
//       _PagosTab(pagos: state.pagos),
//       PasarelasTab(organizaciones: state.organizaciones), // ← nuevo
//     ],
//   ),
