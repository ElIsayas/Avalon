import 'package:flutter/material.dart';

import '../../features/citas/domain/cita.dart';
import '../theme/app_theme.dart';

extension EstadoCitaUi on EstadoCita {
  String get label {
    switch (this) {
      case EstadoCita.agendada:
        return 'Agendada';
      case EstadoCita.confirmada:
        return 'Confirmada';
      case EstadoCita.enProgreso:
        return 'En Progreso';
      case EstadoCita.completada:
        return 'Completada';
      case EstadoCita.cancelada:
        return 'Cancelada';
      case EstadoCita.noAsistio:
        return 'No Asistio';
      case EstadoCita.reprogramada:
        return 'Reprogramada';
    }
  }

  Color get color {
    switch (this) {
      case EstadoCita.agendada:
        return AppTheme.warning;
      case EstadoCita.confirmada:
      case EstadoCita.enProgreso:
        return AppTheme.accent;
      case EstadoCita.completada:
        return AppTheme.primary;
      case EstadoCita.cancelada:
      case EstadoCita.noAsistio:
        return AppTheme.error;
      case EstadoCita.reprogramada:
        return AppTheme.secondary;
    }
  }

  String get actionLabel {
    switch (this) {
      case EstadoCita.confirmada:
        return 'Confirmar';
      case EstadoCita.enProgreso:
        return 'Iniciar sesion';
      case EstadoCita.completada:
        return 'Completar';
      case EstadoCita.cancelada:
        return 'Cancelar';
      case EstadoCita.noAsistio:
        return 'No asistio';
      case EstadoCita.reprogramada:
        return 'Reprogramar';
      case EstadoCita.agendada:
        return label;
    }
  }
}
