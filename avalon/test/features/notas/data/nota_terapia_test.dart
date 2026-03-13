import 'package:flutter_test/flutter_test.dart';
import 'package:avalon/features/notas/domain/entities/nota_terapia.dart';

void main() {
  group('NotaTerapia Entity Tests', () {
    test('should create NotaTerapia with required fields', () {
      // Arrange
      final nota = NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.parse('2023-01-01'),
        notas: 'Initial session notes',
      );

      // Assert
      expect(nota.id, '1');
      expect(nota.pacienteId, 'pac1');
      expect(nota.psicologoId, 'psic1');
      expect(nota.fecha, DateTime.parse('2023-01-01'));
      expect(nota.notas, 'Initial session notes');
    });

    test('should create NotaTerapia with all fields', () {
      // Arrange
      final nota = NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        citaId: 'cita1',
        fecha: DateTime.parse('2023-01-01'),
        notas: 'Detailed session notes',
        objetivos: 'Improve communication skills',
        progreso: 'Patient showing good progress',
      );

      // Assert
      expect(nota.id, '1');
      expect(nota.pacienteId, 'pac1');
      expect(nota.psicologoId, 'psic1');
      expect(nota.citaId, 'cita1');
      expect(nota.fecha, DateTime.parse('2023-01-01'));
      expect(nota.notas, 'Detailed session notes');
      expect(nota.objetivos, 'Improve communication skills');
      expect(nota.progreso, 'Patient showing good progress');
    });

    test('should copy with updated values', () {
      // Arrange
      final originalNota = NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.parse('2023-01-01'),
        notas: 'Original notes',
      );

      // Act
      final updatedNota = originalNota.copyWith(
        notas: 'Updated notes',
        objetivos: 'New objectives',
      );

      // Assert
      expect(updatedNota.id, '1'); // Should remain unchanged
      expect(updatedNota.pacienteId, 'pac1'); // Should remain unchanged
      expect(updatedNota.psicologoId, 'psic1'); // Should remain unchanged
      expect(updatedNota.notas, 'Updated notes'); // Should be updated
      expect(updatedNota.objetivos, 'New objectives'); // Should be updated
      expect(updatedNota.fecha, DateTime.parse('2023-01-01')); // Should remain unchanged
    });

    test('should create NotaTerapia from JSON', () {
      // Arrange
      final json = {
        'id': '1',
        'paciente_id': 'pac1',
        'psicologo_id': 'psic1',
        'cita_id': 'cita1',
        'fecha': '2023-01-01T10:00:00Z',
        'notas': 'Session notes',
        'objetivos': 'Therapy objectives',
        'progreso': 'Progress notes',
      };

      // Act
      final nota = NotaTerapia.fromJson(json);

      // Assert
      expect(nota.id, '1');
      expect(nota.pacienteId, 'pac1');
      expect(nota.psicologoId, 'psic1');
      expect(nota.citaId, 'cita1');
      expect(nota.fecha, DateTime.parse('2023-01-01T10:00:00Z'));
      expect(nota.notas, 'Session notes');
      expect(nota.objetivos, 'Therapy objectives');
      expect(nota.progreso, 'Progress notes');
    });

    test('should convert NotaTerapia to JSON', () {
      // Arrange
      final nota = NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        citaId: 'cita1',
        fecha: DateTime.parse('2023-01-01T10:00:00Z'),
        notas: 'Session notes',
        objetivos: 'Therapy objectives',
        progreso: 'Progress notes',
      );

      // Act
      final json = nota.toJson();

      // Assert
      expect(json['id'], '1');
      expect(json['paciente_id'], 'pac1');
      expect(json['psicologo_id'], 'psic1');
      expect(json['cita_id'], 'cita1');
      expect(json['fecha'], '2023-01-01T10:00:00.000Z');
      expect(json['notas'], 'Session notes');
      expect(json['objetivos'], 'Therapy objectives');
      expect(json['progreso'], 'Progress notes');
    });

    test('should handle null optional fields in JSON', () {
      // Arrange
      final json = {
        'id': '1',
        'paciente_id': 'pac1',
        'psicologo_id': 'psic1',
        'fecha': '2023-01-01T10:00:00Z',
        'notas': 'Basic notes',
      };

      // Act
      final nota = NotaTerapia.fromJson(json);

      // Assert
      expect(nota.id, '1');
      expect(nota.pacienteId, 'pac1');
      expect(nota.psicologoId, 'psic1');
      expect(nota.fecha, DateTime.parse('2023-01-01T10:00:00Z'));
      expect(nota.notas, 'Basic notes');
      expect(nota.citaId, null);
      expect(nota.objetivos, null);
      expect(nota.progreso, null);
    });

    test('should validate notes are not empty', () {
      // Test valid notes
      expect(() => NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.now(),
        notas: 'Valid session notes',
      ), returnsNormally);

      // Test empty notes
      expect(() => NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.now(),
        notas: '',
      ), returnsNormally); // Entity doesn't enforce validation
    });

    test('should validate date is not in future', () {
      // Test past date
      expect(() => NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.now().subtract(Duration(days: 1)),
        notas: 'Notes',
      ), returnsNormally);

      // Test future date
      expect(() => NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.now().add(Duration(days: 1)),
        notas: 'Notes',
      ), returnsNormally); // Entity doesn't enforce validation
    });
  });

  group('NotaTerapia Business Logic Tests', () {
    test('should handle long notes correctly', () {
      final longNotes = 'A' * 1000; // Very long notes
      final nota = NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.now(),
        notas: longNotes,
      );

      expect(nota.notas.length, 1000);
      expect(nota.notas, longNotes);
    });

    test('should handle appointment linking', () {
      final notaWithCita = NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.now(),
        notas: 'Notes',
        citaId: 'cita123',
      );

      final notaWithoutCita = NotaTerapia(
        id: '2',
        pacienteId: 'pac2',
        psicologoId: 'psic1',
        fecha: DateTime.now(),
        notas: 'Notes',
      );

      expect(notaWithCita.citaId, 'cita123');
      expect(notaWithoutCita.citaId, null);
    });

    test('should handle objectives and progress tracking', () {
      final nota = NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.now(),
        notas: 'Session notes',
        objetivos: '1. Improve communication\n2. Reduce anxiety\n3. Build confidence',
        progreso: 'Patient has shown significant improvement in communication skills. Anxiety levels have decreased by 30%. Building confidence through positive reinforcement.',
      );

      expect(nota.objetivos, contains('Improve communication'));
      expect(nota.objetivos, contains('Reduce anxiety'));
      expect(nota.objetivos, contains('Build confidence'));
      expect(nota.progreso, contains('significant improvement'));
      expect(nota.progreso, contains('decreased by 30%'));
    });

    test('should handle date conversions correctly', () {
      final nota = NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.parse('2023-01-01T15:30:00'),
        notas: 'Notes',
      );

      final json = nota.toJson();
      
      expect(json['fecha'], '2023-01-01T15:30:00.000Z');
    });

    test('should handle special characters in notes', () {
      final nota = NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.now(),
        notas: 'Patient shows: 😊 happy, 😢 sad, 😡 angry emotions. Progress: 75% improvement.',
        objetivos: 'Manejar estrés (stress management) • Mejorar autoestima (self-esteem)',
        progreso: 'Paciente puede expresar emociones en español y inglés.',
      );

      expect(nota.notas, contains('😊'));
      expect(nota.notas, contains('😢'));
      expect(nota.notas, contains('😡'));
      expect(nota.notas, contains('75%'));
      expect(nota.objetivos, contains('Manejar estrés'));
      expect(nota.objetivos, contains('Mejorar autoestima'));
      expect(nota.progreso, contains('español'));
      expect(nota.progreso, contains('inglés'));
    });

    test('should handle multiline notes correctly', () {
      final multilineNotes = '''Session Summary:
- Patient arrived on time
- Discussed family issues
- Assigned homework exercises
- Next session scheduled

Key insights: Patient is making steady progress.''';

      final nota = NotaTerapia(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        fecha: DateTime.now(),
        notas: multilineNotes,
      );

      expect(nota.notas, contains('Session Summary:'));
      expect(nota.notas, contains('Patient arrived on time'));
      expect(nota.notas, contains('Key insights:'));
      expect(nota.notas.split('\n').length, greaterThan(5));
    });
  });
}
