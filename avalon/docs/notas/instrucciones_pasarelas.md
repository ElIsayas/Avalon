# Integracion de Pasarelas en SuperAdmin

Resumen de cambios esperados en `superadmin_screen.dart`:

1. Importar `pasarelas_tab.dart`.
2. Cambiar `TabController(length: 4)` a `TabController(length: 5)`.
3. Agregar tab `Pasarelas` en el `TabBar`.
4. Agregar `PasarelasTab(organizaciones: state.organizaciones)` en `TabBarView`.

TabBar final esperado:

- Metricas
- Orgs
- Usuarios
- Pagos
- Pasarelas
