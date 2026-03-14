class AppConstants {
  // Supabase
  static const String supabaseUrl     = 'https://xovztnvrchdgpxnyebpr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhvdnp0bnZyY2hkZ3B4bnllYnByIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5Mjc1OTYsImV4cCI6MjA4ODUwMzU5Nn0.vepP0wFgTt6fiOdhzaZtL4DnN9Te1PDN9nVjD0SJ4tM';

  // Tablas
  static const String tableUsuarios     = 'usuarios';
  static const String tablePacientes    = 'pacientes';
  static const String tableCitas        = 'citas';
  static const String tableNotas        = 'notas_terapia';
  static const String tableEvaluaciones = 'evaluaciones';

  // RPCs de autenticación propia
  static const String rpcLogin            = 'login';
  static const String rpcValidateSession  = 'validate_session';
  static const String rpcLogout           = 'logout';
  static const String rpcGetUserFromToken = 'get_user_id_from_token';

  // Roles
  static const String rolAdmin     = 'admin';
  static const String rolPsicologo = 'psicologo';

  // Rutas
  static const String routeLogin     = '/';
  static const String routeDashboard = '/dashboard';
  static const String routePacientes = '/pacientes';
  static const String routeCitas     = '/citas';

  // SharedPreferences keys
  static const String keySessionToken = 'avalon_session_token';
}
