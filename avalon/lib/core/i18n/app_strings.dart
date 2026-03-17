import 'package:flutter/material.dart';

/// Clase central de strings traducibles de Avalon.
/// Uso: context.t.dashboard  o  AppStrings.of(context).pacientes
class AppStrings {
  final String langCode;
  const AppStrings._(this.langCode);

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'en'
        ? const AppStrings._('en')
        : const AppStrings._('es');
  }

  bool get isEn => langCode == 'en';

  // ── Navegación ────────────────────────────────────────────────
  String get inicio         => isEn ? 'Home'             : 'Inicio';
  String get pacientes      => isEn ? 'Patients'         : 'Pacientes';
  String get citas          => isEn ? 'Appointments'     : 'Citas';
  String get notas          => isEn ? 'Notes'            : 'Notas';
  String get configuracion  => isEn ? 'Settings'         : 'Configuración';

  // ── Dashboard ─────────────────────────────────────────────────
  String get hola           => isEn ? 'Hello,'           : 'Hola,';
  String get citasHoy       => isEn ? 'Today'            : 'Hoy';
  String get citasSemana    => isEn ? 'Week'             : 'Semana';
  String get citasMes       => isEn ? 'Month'            : 'Este mes';
  String get totalPacientes => isEn ? 'Patients'         : 'Pacientes';
  String get activos        => isEn ? 'active'           : 'activos';
  String get inactivos      => isEn ? 'Inactive'         : 'Inactivos';
  String get notasSemana    => isEn ? 'Notes'            : 'Notas';
  String get estaSemana     => isEn ? 'this week'        : 'esta semana';
  String get citasEstaSemana => isEn ? 'Appointments this week' : 'Citas esta semana';
  String get pacientesRecientes => isEn ? 'Recent patients' : 'Pacientes recientes';
  String get proximaCita    => isEn ? 'Next appointment' : 'Próxima cita';
  String get modulos        => isEn ? 'Modules'          : 'Módulos';
  String get evaluaciones   => isEn ? 'Evaluations'      : 'Evaluaciones';
  String get consola        => isEn ? 'Console'          : 'Consola';

  // ── Pacientes ─────────────────────────────────────────────────
  String get nuevoPaciente  => isEn ? 'New patient'      : 'Nuevo paciente';
  String get buscarPaciente => isEn ? 'Search by name, email or document...' : 'Buscar por nombre, email o documento...';
  String get total          => isEn ? 'Total'            : 'Total';
  String get activo         => isEn ? 'Active'           : 'Activo';
  String get inactivo       => isEn ? 'Inactive'         : 'Inactivo';
  String get sinPacientes   => isEn ? 'No patients'      : 'Sin pacientes';

  // ── Citas ─────────────────────────────────────────────────────
  String get calendario     => isEn ? 'Calendar'         : 'Calendario';
  String get lista          => isEn ? 'List'             : 'Lista';
  String get psicologos     => isEn ? 'Psychologists'    : 'Psicólogos';
  String get nuevaCita      => isEn ? 'New appointment'  : 'Nueva cita';
  String get sinCitas       => isEn ? 'No appointments'  : 'Sin citas';
  String get hoy            => isEn ? 'Today'            : 'Hoy';
  String get confirmar      => isEn ? 'Confirm'          : 'Confirmar';
  String get cancelar       => isEn ? 'Cancel'           : 'Cancelar';
  String get completada     => isEn ? 'Completed'        : 'Completada';
  String get cancelada      => isEn ? 'Cancelled'        : 'Cancelada';
  String get agendada       => isEn ? 'Scheduled'        : 'Agendada';
  String get confirmada     => isEn ? 'Confirmed'        : 'Confirmada';
  String get enProgreso     => isEn ? 'In progress'      : 'En progreso';
  String get noAsistio      => isEn ? 'No-show'          : 'No asistió';

  // ── Notas ─────────────────────────────────────────────────────
  String get nuevaNota      => isEn ? 'New note'         : 'Nueva nota';
  String get sinNotas       => isEn ? 'No notes yet'     : 'No hay notas aún';
  String get crearNota      => isEn ? 'Create the first note with the + button' : 'Crea la primera nota con el botón +';
  String get sesion         => isEn ? 'Session'          : 'Sesión';
  String get seguimiento    => isEn ? 'Follow-up'        : 'Seguimiento';
  String get interconsulta  => isEn ? 'Referral'         : 'Interconsulta';
  String get administrativa => isEn ? 'Administrative'   : 'Administrativa';
  String get todas          => isEn ? 'All'              : 'Todas';
  String get firmar         => isEn ? 'Sign'             : 'Firmar';
  String get firmada        => isEn ? 'Signed'           : 'Firmada';
  String get editar         => isEn ? 'Edit'             : 'Editar';
  String get eliminar       => isEn ? 'Delete'           : 'Eliminar';

  // ── Configuración ─────────────────────────────────────────────
  String get miPerfil       => isEn ? 'My profile'       : 'Mi perfil';
  String get apariencia     => isEn ? 'Appearance'       : 'Apariencia';
  String get modoOscuro     => isEn ? 'Dark mode'        : 'Modo oscuro';
  String get activado       => isEn ? 'Enabled'          : 'Activado';
  String get desactivado    => isEn ? 'Disabled'         : 'Desactivado';
  String get tamanoTexto    => isEn ? 'Text size'        : 'Tamaño de texto';
  String get idioma         => isEn ? 'Language'         : 'Idioma';
  String get notificaciones => isEn ? 'Notifications'    : 'Notificaciones';
  String get herramientas   => isEn ? 'Tools'            : 'Herramientas';
  String get miEquipo       => isEn ? 'My team'          : 'Mi equipo';
  String get gestionarUsuarios => isEn ? 'Manage users'  : 'Gestionar usuarios';
  String get recordatorios  => isEn ? 'Reminders'        : 'Recordatorios';
  String get acercaDe       => isEn ? 'About'            : 'Acerca de';
  String get versionApp     => isEn ? 'App version'      : 'Versión de la app';
  String get cerrarSesion   => isEn ? 'Sign out'         : 'Cerrar sesión';
  String get cerrarSesionConf => isEn
      ? 'Are you sure? Your session will be closed on all devices.'
      : '¿Estás seguro? Tu sesión se cerrará en todos los dispositivos.';
  String get notifCitas     => isEn ? 'Appointment reminders'  : 'Recordatorios de citas';
  String get notifCitasSub  => isEn ? 'Before each scheduled appointment' : 'Antes de cada cita programada';
  String get notifRec       => isEn ? 'Reminders'              : 'Recordatorios';
  String get notifRecSub    => isEn ? 'Pending task alerts'     : 'Alertas de tareas pendientes';
  String get notifSistema   => isEn ? 'System notifications'   : 'Notificaciones del sistema';
  String get notifSistemaSub => isEn ? 'Updates and notices'   : 'Actualizaciones y avisos';

  // ── Usuarios ──────────────────────────────────────────────────
  String get equipoConsultorio => isEn ? 'Practice team' : 'Equipo del consultorio';
  String get nuevoUsuario   => isEn ? 'New user'         : 'Nuevo usuario';
  String get editarUsuario  => isEn ? 'Edit user'        : 'Editar usuario';
  String get nombreCompleto => isEn ? 'Full name'        : 'Nombre completo';
  String get contrasena     => isEn ? 'Password'         : 'Contraseña';
  String get rolLabel       => isEn ? 'Role'             : 'Rol';
  String get especialidad   => isEn ? 'Specialty'        : 'Especialidad';
  String get guardar        => isEn ? 'Save'             : 'Guardar';
  String get guardarCambios => isEn ? 'Save changes'     : 'Guardar cambios';
  String get crearUsuario   => isEn ? 'Create user'      : 'Crear usuario';

  // ── Recordatorios ─────────────────────────────────────────────
  String get nuevoRecordatorio => isEn ? 'New reminder'  : 'Nuevo recordatorio';
  String get sinRecordatorios  => isEn ? 'No pending reminders' : 'Sin recordatorios pendientes';
  String get urgente        => isEn ? 'Urgent'           : 'Urgente';
  String get normal         => isEn ? 'Normal'           : 'Normal';
  String get baja           => isEn ? 'Low'              : 'Baja';
  String get vencido        => isEn ? 'Overdue'          : 'Vencido';
  String get resuelto       => isEn ? 'Resolved'         : 'Resuelto';
  String get prioridad      => isEn ? 'Priority'         : 'Prioridad';
  String get categoria      => isEn ? 'Category'         : 'Categoría';
  String get fechaVencimiento => isEn ? 'Due date'       : 'Fecha de vencimiento';
  String get asignarA       => isEn ? 'Assign to'        : 'Asignar a';

  // ── Evaluaciones ──────────────────────────────────────────────
  String get nuevaEvaluacion => isEn ? 'New evaluation'  : 'Nueva evaluación';
  String get sinEvaluaciones => isEn ? 'No evaluations'  : 'Sin evaluaciones';
  String get puntuacion     => isEn ? 'Score'            : 'Puntaje';
  String get resultado      => isEn ? 'Result'           : 'Resultado';
  String get observaciones  => isEn ? 'Observations'     : 'Observaciones';

  // ── Generales ─────────────────────────────────────────────────
  String get buscar         => isEn ? 'Search'           : 'Buscar';
  String get aceptar        => isEn ? 'Accept'           : 'Aceptar';
  String get volver         => isEn ? 'Back'             : 'Volver';
  String get si             => isEn ? 'Yes'              : 'Sí';
  String get no             => isEn ? 'No'               : 'No';
  String get cargando       => isEn ? 'Loading...'       : 'Cargando...';
  String get reintentar     => isEn ? 'Retry'            : 'Reintentar';
  String get nombre         => isEn ? 'Name'             : 'Nombre';
  String get email          => isEn ? 'Email'            : 'Email';
  String get telefono       => isEn ? 'Phone'            : 'Teléfono';
  String get proximamente   => isEn ? 'Coming soon'      : 'Próximamente';

  // ── Días de la semana (calendario) ────────────────────────────
  List<String> get diasSemana => isEn
      ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      : ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  // ── Meses ─────────────────────────────────────────────────────
  List<String> get meses => isEn
      ? ['January','February','March','April','May','June',
         'July','August','September','October','November','December']
      : ['enero','febrero','marzo','abril','mayo','junio',
         'julio','agosto','septiembre','octubre','noviembre','diciembre'];

  // ── App shell ─────────────────────────────────────────────────
  String get config         => isEn ? 'Settings'         : 'Config';
}

/// Extension para acceso fácil: context.t.dashboard
extension AppStringsContext on BuildContext {
  AppStrings get t => AppStrings.of(this);
}
