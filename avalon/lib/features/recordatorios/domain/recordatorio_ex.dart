import 'package:flutter/material.dart';

// Extiende el modelo básico Recordatorio de cita.dart con campos adicionales
// que la tabla 'recordatorios' en Supabase ya soporta.

enum CategoriaRecordatorio {
  paciente('paciente', 'Paciente'),
  admin('admin', 'Administrativo'),
  tarea('tarea', 'Tarea'),
  cita('cita', 'Cita');

  const CategoriaRecordatorio(this.value, this.label);
  final String value;
  final String label;

  static CategoriaRecordatorio fromString(String v) =>
      CategoriaRecordatorio.values.firstWhere(
        (e) => e.value == v,
        orElse: () => CategoriaRecordatorio.tarea,
      );
}

enum PrioridadR { baja, normal, urgente }

class RecordatorioEx {
  final String id;
  final String organizacionId;
  final String creadoPor;
  final String? asignadoA;     // null = visible para todos
  final String titulo;
  final String? descripcion;
  final String prioridad;
  final CategoriaRecordatorio categoria;
  final bool resuelto;
  final DateTime? fechaVencimiento;
  final DateTime fechaRegistro;
  // Campos enriquecidos del JOIN
  final String? creadoPorNombre;
  final String? asignadoANombre;

  const RecordatorioEx({
    required this.id,
    required this.organizacionId,
    required this.creadoPor,
    this.asignadoA,
    required this.titulo,
    this.descripcion,
    required this.prioridad,
    required this.categoria,
    required this.resuelto,
    this.fechaVencimiento,
    required this.fechaRegistro,
    this.creadoPorNombre,
    this.asignadoANombre,
  });

  factory RecordatorioEx.fromJson(Map<String, dynamic> j) => RecordatorioEx(
        id:                j['id'].toString(),
        organizacionId:    j['organizacion_id'].toString(),
        creadoPor:         j['creado_por'].toString(),
        asignadoA:         j['asignado_a']?.toString(),
        titulo:            j['titulo'].toString(),
        descripcion:       j['descripcion']?.toString(),
        prioridad:         j['prioridad']?.toString() ?? 'normal',
        categoria:         CategoriaRecordatorio.fromString(
                              j['categoria']?.toString() ?? 'tarea'),
        resuelto:          j['resuelto'] as bool? ?? false,
        fechaVencimiento:  j['fecha_vencimiento'] != null
            ? DateTime.tryParse(j['fecha_vencimiento'].toString())
            : null,
        fechaRegistro:     DateTime.tryParse(
                              j['fecha_registro'].toString()) ??
                           DateTime.now(),
        creadoPorNombre:   j['creado_por_nombre']?.toString(),
        asignadoANombre:   j['asignado_a_nombre']?.toString(),
      );

  bool get estaVencido =>
      fechaVencimiento != null &&
      fechaVencimiento!.isBefore(DateTime.now()) &&
      !resuelto;

  bool get venceHoy {
    if (fechaVencimiento == null) return false;
    final ahora = DateTime.now();
    final v = fechaVencimiento!;
    return v.year == ahora.year &&
        v.month == ahora.month &&
        v.day == ahora.day;
  }

  Color get prioridadColor {
    switch (prioridad) {
      case 'urgente': return Color(0xFFE74C3C);
      case 'normal':  return Color(0xFF1E5AA8);
      default:        return Color(0xFF2ECC71);
    }
  }

  String get prioridadLabel {
    switch (prioridad) {
      case 'urgente': return 'Urgente';
      case 'normal':  return 'Normal';
      default:        return 'Baja';
    }
  }
}
