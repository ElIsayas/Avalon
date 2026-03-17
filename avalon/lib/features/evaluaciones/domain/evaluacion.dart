import 'package:flutter/material.dart';
// Escalas psicológicas estandarizadas disponibles en la app
enum EscalaEvaluacion {
  phq9('phq9', 'PHQ-9', 'Depresión (Patient Health Questionnaire)', 27),
  gad7('gad7', 'GAD-7', 'Ansiedad Generalizada', 21),
  hama('hama', 'HAM-A', 'Ansiedad de Hamilton', 56),
  bdi2('bdi2', 'BDI-II', 'Inventario de Depresión de Beck', 63),
  psqi('psqi', 'PSQI', 'Calidad del Sueño de Pittsburgh', 21),
  personalizada('personalizada', 'Personalizada', 'Evaluación libre', 999);

  const EscalaEvaluacion(
      this.value, this.nombre, this.descripcion, this.puntuacionMax);
  final String value;
  final String nombre;
  final String descripcion;
  final int puntuacionMax;

  static EscalaEvaluacion fromString(String v) =>
      EscalaEvaluacion.values.firstWhere(
        (e) => e.value == v,
        orElse: () => EscalaEvaluacion.personalizada,
      );
}

// Ítem de una escala (pregunta + opciones)
class ItemEscala {
  final int numero;
  final String pregunta;
  final List<String> opciones; // Las opciones son 0..n en orden
  final int valor;             // Valor seleccionado (0 = no respondido aún)

  const ItemEscala({
    required this.numero,
    required this.pregunta,
    required this.opciones,
    this.valor = -1,
  });

  ItemEscala conValor(int v) =>
      ItemEscala(numero: numero, pregunta: pregunta, opciones: opciones, valor: v);

  bool get respondida => valor >= 0;
}

// Evaluación guardada en BD
class Evaluacion {
  final String id;
  final String pacienteId;
  final String psicologoId;
  final String? citaId;
  final String escala;          // valor de EscalaEvaluacion
  final int puntuacionTotal;
  final String? interpretacion;
  final String? observaciones;
  final Map<String, dynamic> respuestas; // ítem_num → valor
  final DateTime fechaCreacion;
  // Enriquecidos
  final String? pacienteNombre;
  final String? psicologoNombre;

  const Evaluacion({
    required this.id,
    required this.pacienteId,
    required this.psicologoId,
    this.citaId,
    required this.escala,
    required this.puntuacionTotal,
    this.interpretacion,
    this.observaciones,
    required this.respuestas,
    required this.fechaCreacion,
    this.pacienteNombre,
    this.psicologoNombre,
  });

  factory Evaluacion.fromJson(Map<String, dynamic> j) => Evaluacion(
        id:               j['id'].toString(),
        pacienteId:       j['paciente_id'].toString(),
        psicologoId:      j['psicologo_id'].toString(),
        citaId:           j['cita_id']?.toString(),
        escala:           j['escala']?.toString() ?? 'personalizada',
        puntuacionTotal:  (j['puntuacion_total'] as num?)?.toInt() ?? 0,
        interpretacion:   j['interpretacion']?.toString(),
        observaciones:    j['observaciones']?.toString(),
        respuestas:       Map<String, dynamic>.from(
                              j['respuestas'] as Map? ?? {}),
        fechaCreacion:    DateTime.tryParse(j['fecha_creacion'].toString()) ??
                          DateTime.now(),
        pacienteNombre:   j['paciente_nombre']?.toString(),
        psicologoNombre:  j['psicologo_nombre']?.toString(),
      );

  EscalaEvaluacion get escalaEnum => EscalaEvaluacion.fromString(escala);

  // Nivel de severidad para PHQ-9 y GAD-7
  String get nivelSeveridad {
    switch (escala) {
      case 'phq9':
        if (puntuacionTotal <= 4)  return 'Mínima';
        if (puntuacionTotal <= 9)  return 'Leve';
        if (puntuacionTotal <= 14) return 'Moderada';
        if (puntuacionTotal <= 19) return 'Moderadamente severa';
        return 'Severa';
      case 'gad7':
        if (puntuacionTotal <= 4)  return 'Mínima';
        if (puntuacionTotal <= 9)  return 'Leve';
        if (puntuacionTotal <= 14) return 'Moderada';
        return 'Severa';
      case 'hama':
        if (puntuacionTotal <= 17)  return 'Leve';
        if (puntuacionTotal <= 24)  return 'Moderada';
        if (puntuacionTotal <= 30)  return 'Moderada-Severa';
        return 'Severa';
      default:
        return interpretacion ?? '—';
    }
  }

  Color severidadColor(Color Function(String) resolver) =>
      resolver(nivelSeveridad);
}

// ── Definiciones de escalas ───────────────────────────────────────────────────

const Map<String, List<ItemEscala>> kItemsEscalas = {
  'phq9': [
    ItemEscala(numero: 1, pregunta: 'Poco interés o placer en hacer cosas',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 2, pregunta: 'Se ha sentido decaído/a, deprimido/a o sin esperanza',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 3, pregunta: 'Problemas para dormir o dormir demasiado',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 4, pregunta: 'Se ha sentido cansado/a o con poca energía',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 5, pregunta: 'Falta de apetito o ha comido demasiado',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 6, pregunta: 'Se ha sentido mal consigo mismo/a',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 7, pregunta: 'Problemas para concentrarse',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 8, pregunta: 'Se ha movido o hablado muy lento, o lo contrario',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 9, pregunta: 'Pensamientos de que estaría mejor muerto/a',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
  ],
  'gad7': [
    ItemEscala(numero: 1, pregunta: 'Se ha sentido nervioso/a, ansioso/a o muy tenso/a',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 2, pregunta: 'No ha podido dejar de preocuparse',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 3, pregunta: 'Se ha preocupado demasiado por diferentes cosas',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 4, pregunta: 'Ha tenido dificultades para relajarse',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 5, pregunta: 'Se ha sentido tan inquieto/a que no ha podido quedarse quieto/a',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 6, pregunta: 'Se ha irritado o enojado con facilidad',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
    ItemEscala(numero: 7, pregunta: 'Ha sentido miedo, como si algo terrible pudiera pasar',
        opciones: ['Para nada', 'Varios días', 'Más de la mitad de los días', 'Casi todos los días']),
  ],
};
