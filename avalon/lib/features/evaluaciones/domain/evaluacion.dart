import 'package:flutter/material.dart';

// Escalas psicologicas estandarizadas disponibles en la app.
enum EscalaEvaluacion {
  phq9('phq9', 'PHQ-9', 'Depresion (Patient Health Questionnaire)', 27),
  gad7('gad7', 'GAD-7', 'Ansiedad Generalizada', 21),
  hama('hama', 'HAM-A', 'Ansiedad de Hamilton', 56),
  bdi2('bdi2', 'BDI-II', 'Inventario de Depresion de Beck', 63),
  psqi('psqi', 'PSQI', 'Calidad del Sueno de Pittsburgh', 21),
  personalizada('personalizada', 'Personalizada', 'Evaluacion libre', 999);

  const EscalaEvaluacion(
    this.value,
    this.nombre,
    this.descripcion,
    this.puntuacionMax,
  );

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

// Item de una escala (pregunta + opciones).
class ItemEscala {
  final int numero;
  final String pregunta;
  final List<String> opciones; // Las opciones son 0..n en orden.
  final int valor; // Valor seleccionado (>= 0 cuando ya fue respondida).

  const ItemEscala({
    required this.numero,
    required this.pregunta,
    required this.opciones,
    this.valor = -1,
  });

  ItemEscala conValor(int v) => ItemEscala(
      numero: numero, pregunta: pregunta, opciones: opciones, valor: v);

  bool get respondida => valor >= 0;
}

// Evaluacion guardada en BD.
class Evaluacion {
  final String id;
  final String pacienteId;
  final String psicologoId;
  final String? citaId;
  final String escala; // valor de EscalaEvaluacion.
  final int puntuacionTotal;
  final String? interpretacion;
  final String? observaciones;
  final Map<String, dynamic> respuestas; // item_num -> valor.
  final DateTime fechaCreacion;
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
        id: j['id'].toString(),
        pacienteId: j['paciente_id'].toString(),
        psicologoId: j['psicologo_id'].toString(),
        citaId: j['cita_id']?.toString(),
        escala: j['escala']?.toString() ?? 'personalizada',
        puntuacionTotal: (j['puntuacion_total'] as num?)?.toInt() ?? 0,
        interpretacion: j['interpretacion']?.toString(),
        observaciones: j['observaciones']?.toString(),
        respuestas: Map<String, dynamic>.from(j['respuestas'] as Map? ?? {}),
        fechaCreacion:
            DateTime.tryParse(j['fecha_creacion'].toString()) ?? DateTime.now(),
        pacienteNombre: j['paciente_nombre']?.toString(),
        psicologoNombre: j['psicologo_nombre']?.toString(),
      );

  EscalaEvaluacion get escalaEnum => EscalaEvaluacion.fromString(escala);

  // Nivel de severidad/interpretacion por escala.
  String get nivelSeveridad {
    switch (escala) {
      case 'phq9':
        if (puntuacionTotal <= 4) return 'Mínima';
        if (puntuacionTotal <= 9) return 'Leve';
        if (puntuacionTotal <= 14) return 'Moderada';
        if (puntuacionTotal <= 19) return 'Moderadamente severa';
        return 'Severa';
      case 'gad7':
        if (puntuacionTotal <= 4) return 'Mínima';
        if (puntuacionTotal <= 9) return 'Leve';
        if (puntuacionTotal <= 14) return 'Moderada';
        return 'Severa';
      case 'hama':
        if (puntuacionTotal <= 17) return 'Leve';
        if (puntuacionTotal <= 24) return 'Moderada';
        return 'Severa';
      case 'bdi2':
        if (puntuacionTotal <= 13) return 'Mínima';
        if (puntuacionTotal <= 19) return 'Leve';
        if (puntuacionTotal <= 28) return 'Moderada';
        return 'Severa';
      case 'psqi':
        if (puntuacionTotal <= 4) return 'Mínima';
        if (puntuacionTotal <= 10) return 'Leve';
        if (puntuacionTotal <= 15) return 'Moderada';
        return 'Severa';
      default:
        return interpretacion ?? '—';
    }
  }

  Color severidadColor(Color Function(String) resolver) =>
      resolver(nivelSeveridad);
}

const List<String> kOpcionesFrecuencia2Semanas = [
  'Para nada',
  'Varios dias',
  'Mas de la mitad de los dias',
  'Casi todos los dias',
];

const List<String> kOpcionesIntensidadHama = [
  '0 - Ausente',
  '1 - Leve',
  '2 - Moderado',
  '3 - Grave',
  '4 - Muy grave',
];

const List<String> kOpcionesBdi2 = [
  '0 - No me describe',
  '1 - Me describe levemente',
  '2 - Me describe moderadamente',
  '3 - Me describe severamente',
];

const List<String> kOpcionesPsqi = [
  '0 - Ninguna dificultad',
  '1 - Dificultad leve',
  '2 - Dificultad moderada',
  '3 - Dificultad severa',
];

const Map<String, String> kInstruccionesEscalas = {
  'phq9':
      'Durante las ultimas 2 semanas, indique con que frecuencia aparecio cada sintoma.',
  'gad7':
      'Durante las ultimas 2 semanas, indique con que frecuencia aparecio cada sintoma.',
  'hama':
      'Valore la intensidad de cada sintoma observado durante la ultima semana.',
  'bdi2':
      'Considere como se ha sentido durante las ultimas 2 semanas al responder cada item.',
  'psqi': 'Califique cada componente de calidad del sueno segun el ultimo mes.',
  'personalizada': 'Registre el puntaje global manual de la escala aplicada.',
};

const Map<String, List<ItemEscala>> kItemsEscalas = {
  'phq9': [
    ItemEscala(
      numero: 1,
      pregunta: 'Poco interes o placer en hacer cosas',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 2,
      pregunta: 'Se ha sentido decaido/a, deprimido/a o sin esperanza',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 3,
      pregunta: 'Problemas para dormir o dormir demasiado',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 4,
      pregunta: 'Se ha sentido cansado/a o con poca energia',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 5,
      pregunta: 'Falta de apetito o ha comido demasiado',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 6,
      pregunta: 'Se ha sentido mal consigo mismo/a',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 7,
      pregunta: 'Problemas para concentrarse',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 8,
      pregunta: 'Se ha movido o hablado muy lento, o lo contrario',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 9,
      pregunta: 'Pensamientos de que estaria mejor muerto/a',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
  ],
  'gad7': [
    ItemEscala(
      numero: 1,
      pregunta: 'Se ha sentido nervioso/a, ansioso/a o muy tenso/a',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 2,
      pregunta: 'No ha podido dejar de preocuparse',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 3,
      pregunta: 'Se ha preocupado demasiado por diferentes cosas',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 4,
      pregunta: 'Ha tenido dificultades para relajarse',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 5,
      pregunta:
          'Se ha sentido tan inquieto/a que no ha podido quedarse quieto/a',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 6,
      pregunta: 'Se ha irritado o enojado con facilidad',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
    ItemEscala(
      numero: 7,
      pregunta: 'Ha sentido miedo, como si algo terrible pudiera pasar',
      opciones: kOpcionesFrecuencia2Semanas,
    ),
  ],
  'hama': [
    ItemEscala(
        numero: 1,
        pregunta: 'Estado de animo ansioso',
        opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 2, pregunta: 'Tension', opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 3, pregunta: 'Miedos', opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 4, pregunta: 'Insomnio', opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 5,
        pregunta: 'Dificultad cognitiva y concentracion',
        opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 6,
        pregunta: 'Estado de animo deprimido',
        opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 7,
        pregunta: 'Sintomas somaticos musculares',
        opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 8,
        pregunta: 'Sintomas somaticos sensoriales',
        opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 9,
        pregunta: 'Sintomas cardiovasculares',
        opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 10,
        pregunta: 'Sintomas respiratorios',
        opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 11,
        pregunta: 'Sintomas gastrointestinales',
        opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 12,
        pregunta: 'Sintomas genitourinarios',
        opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 13,
        pregunta: 'Sintomas autonomicos',
        opciones: kOpcionesIntensidadHama),
    ItemEscala(
        numero: 14,
        pregunta: 'Conducta observada durante la entrevista',
        opciones: kOpcionesIntensidadHama),
  ],
  'bdi2': [
    ItemEscala(numero: 1, pregunta: 'Tristeza', opciones: kOpcionesBdi2),
    ItemEscala(numero: 2, pregunta: 'Pesimismo', opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 3, pregunta: 'Fracaso percibido', opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 4, pregunta: 'Perdida de placer', opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 5, pregunta: 'Sentimientos de culpa', opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 6,
        pregunta: 'Sentimientos de castigo',
        opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 7,
        pregunta: 'Disconformidad con uno mismo',
        opciones: kOpcionesBdi2),
    ItemEscala(numero: 8, pregunta: 'Autocritica', opciones: kOpcionesBdi2),
    ItemEscala(numero: 9, pregunta: 'Ideas suicidas', opciones: kOpcionesBdi2),
    ItemEscala(numero: 10, pregunta: 'Llanto', opciones: kOpcionesBdi2),
    ItemEscala(numero: 11, pregunta: 'Agitacion', opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 12, pregunta: 'Perdida de interes', opciones: kOpcionesBdi2),
    ItemEscala(numero: 13, pregunta: 'Indecision', opciones: kOpcionesBdi2),
    ItemEscala(numero: 14, pregunta: 'Inutilidad', opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 15, pregunta: 'Perdida de energia', opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 16, pregunta: 'Cambios en el sueno', opciones: kOpcionesBdi2),
    ItemEscala(numero: 17, pregunta: 'Irritabilidad', opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 18, pregunta: 'Cambios en el apetito', opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 19,
        pregunta: 'Dificultad de concentracion',
        opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 20, pregunta: 'Cansancio o fatiga', opciones: kOpcionesBdi2),
    ItemEscala(
        numero: 21,
        pregunta: 'Perdida de interes sexual',
        opciones: kOpcionesBdi2),
  ],
  'psqi': [
    ItemEscala(
        numero: 1,
        pregunta: 'Calidad subjetiva del sueno',
        opciones: kOpcionesPsqi),
    ItemEscala(
        numero: 2,
        pregunta: 'Latencia para conciliar el sueno',
        opciones: kOpcionesPsqi),
    ItemEscala(
        numero: 3, pregunta: 'Duracion del sueno', opciones: kOpcionesPsqi),
    ItemEscala(
        numero: 4,
        pregunta: 'Eficiencia habitual del sueno',
        opciones: kOpcionesPsqi),
    ItemEscala(
        numero: 5,
        pregunta: 'Perturbaciones del sueno',
        opciones: kOpcionesPsqi),
    ItemEscala(
        numero: 6,
        pregunta: 'Uso de medicacion para dormir',
        opciones: kOpcionesPsqi),
    ItemEscala(
        numero: 7, pregunta: 'Disfuncion diurna', opciones: kOpcionesPsqi),
    ItemEscala(
        numero: 8,
        pregunta: 'Somnolencia y energia diurna',
        opciones: kOpcionesPsqi),
    ItemEscala(
        numero: 9,
        pregunta: 'Impacto funcional global del sueno',
        opciones: kOpcionesPsqi),
  ],
};
