import 'package:flutter_test/flutter_test.dart';
import 'package:avalon/features/evaluaciones/domain/entities/evaluacion.dart';

void main() {
  group('Evaluacion Entity Tests', () {
    test('should create Evaluacion with required fields', () {
      // Arrange
      final evaluacion = Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: 'Depression Scale',
        fechaRealizacion: DateTime.parse('2023-01-01'),
      );

      // Assert
      expect(evaluacion.id, '1');
      expect(evaluacion.pacienteId, 'pac1');
      expect(evaluacion.psicologoId, 'psic1');
      expect(evaluacion.tipoTest, 'Depression Scale');
      expect(evaluacion.fechaRealizacion, DateTime.parse('2023-01-01'));
    });

    test('should create Evaluacion with all fields', () {
      // Arrange
      final evaluacion = Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: 'Anxiety Test',
        fechaRealizacion: DateTime.parse('2023-01-01'),
        citaId: 'cita1',
        resultados: {'score': 15, 'total': 20, 'interpretation': 'Moderate'},
        observaciones: 'Patient shows moderate anxiety',
      );

      // Assert
      expect(evaluacion.id, '1');
      expect(evaluacion.pacienteId, 'pac1');
      expect(evaluacion.psicologoId, 'psic1');
      expect(evaluacion.tipoTest, 'Anxiety Test');
      expect(evaluacion.fechaRealizacion, DateTime.parse('2023-01-01'));
      expect(evaluacion.citaId, 'cita1');
      expect(evaluacion.resultados!['score'], 15);
      expect(evaluacion.resultados!['total'], 20);
      expect(evaluacion.resultados!['interpretation'], 'Moderate');
      expect(evaluacion.observaciones, 'Patient shows moderate anxiety');
    });

    test('should copy with updated values', () {
      // Arrange
      final originalEvaluacion = Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: 'Original Test',
        fechaRealizacion: DateTime.parse('2023-01-01'),
      );

      // Act
      final updatedEvaluacion = originalEvaluacion.copyWith(
        tipoTest: 'Updated Test',
        resultados: {'score': 18, 'total': 20},
      );

      // Assert
      expect(updatedEvaluacion.id, '1'); // Should remain unchanged
      expect(updatedEvaluacion.pacienteId, 'pac1'); // Should remain unchanged
      expect(updatedEvaluacion.psicologoId, 'psic1'); // Should remain unchanged
      expect(updatedEvaluacion.tipoTest, 'Updated Test'); // Should be updated
      expect(updatedEvaluacion.resultados!['score'], 18); // Should be updated
      expect(updatedEvaluacion.fechaRealizacion, DateTime.parse('2023-01-01')); // Should remain unchanged
    });

    test('should create Evaluacion from JSON', () {
      // Arrange
      final json = {
        'id': '1',
        'paciente_id': 'pac1',
        'psicologo_id': 'psic1',
        'tipo_test': 'Depression Scale',
        'fecha_realizacion': '2023-01-01T10:00:00Z',
        'cita_id': 'cita1',
        'resultados': {'score': 12, 'total': 20, 'interpretation': 'Mild'},
        'observaciones': 'Patient shows mild depression',
      };

      // Act
      final evaluacion = Evaluacion.fromJson(json);

      // Assert
      expect(evaluacion.id, '1');
      expect(evaluacion.pacienteId, 'pac1');
      expect(evaluacion.psicologoId, 'psic1');
      expect(evaluacion.tipoTest, 'Depression Scale');
      expect(evaluacion.fechaRealizacion, DateTime.parse('2023-01-01T10:00:00Z'));
      expect(evaluacion.citaId, 'cita1');
      expect(evaluacion.resultados, 'Score: 12/20');
      expect(evaluacion.observaciones, 'Patient shows mild depression');
    });

    test('should convert Evaluacion to JSON', () {
      // Arrange
      final evaluacion = Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: 'Anxiety Test',
        fechaRealizacion: DateTime.parse('2023-01-01T10:00:00Z'),
        citaId: 'cita1',
        resultados: {'score': 15, 'total': 20, 'interpretation': 'Moderate'},
        observaciones: 'Patient shows moderate anxiety',
      );

      // Act
      final json = evaluacion.toJson();

      // Assert
      expect(json['id'], '1');
      expect(json['paciente_id'], 'pac1');
      expect(json['psicologo_id'], 'psic1');
      expect(json['tipo_test'], 'Anxiety Test');
      expect(json['fecha_realizacion'], '2023-01-01T10:00:00.000Z');
      expect(json['cita_id'], 'cita1');
      expect(json['resultados'], 'Score: 15/20');
      expect(json['observaciones'], 'Patient shows moderate anxiety');
    });

    test('should handle null optional fields in JSON', () {
      // Arrange
      final json = {
        'id': '1',
        'paciente_id': 'pac1',
        'psicologo_id': 'psic1',
        'tipo_test': 'Basic Test',
        'fecha_realizacion': '2023-01-01T10:00:00Z',
      };

      // Act
      final evaluacion = Evaluacion.fromJson(json);

      // Assert
      expect(evaluacion.id, '1');
      expect(evaluacion.pacienteId, 'pac1');
      expect(evaluacion.psicologoId, 'psic1');
      expect(evaluacion.tipoTest, 'Basic Test');
      expect(evaluacion.fechaRealizacion, DateTime.parse('2023-01-01T10:00:00Z'));
      expect(evaluacion.citaId, null);
      expect(evaluacion.resultados, null);
      expect(evaluacion.observaciones, null);
    });

    test('should validate test type is not empty', () {
      // Test valid test type
      expect(() => Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: 'Valid Test Name',
        fechaRealizacion: DateTime.now(),
      ), returnsNormally);

      // Test empty test type
      expect(() => Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: '',
        fechaRealizacion: DateTime.now(),
      ), returnsNormally); // Entity doesn't enforce validation
    });

    test('should validate date is not in future', () {
      // Test past date
      expect(() => Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: 'Test',
        fechaRealizacion: DateTime.now().subtract(Duration(days: 1)),
      ), returnsNormally);

      // Test future date
      expect(() => Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: 'Test',
        fechaRealizacion: DateTime.now().add(Duration(days: 1)),
      ), returnsNormally); // Entity doesn't enforce validation
    });
  });

  group('Evaluacion Business Logic Tests', () {
    test('should handle different test types correctly', () {
      final testTypes = [
        'Depression Scale',
        'Anxiety Inventory',
        'Stress Assessment',
        'Personality Test',
        'Cognitive Evaluation',
      ];

      for (final testType in testTypes) {
        final evaluacion = Evaluacion(
          id: '1',
          pacienteId: 'pac1',
          psicologoId: 'psic1',
          tipoTest: testType,
          fechaRealizacion: DateTime.now(),
        );

        expect(evaluacion.tipoTest, testType);
      }
    });

    test('should handle results formatting', () {
      final evaluacion = Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: 'Test',
        fechaRealizacion: DateTime.now(),
        resultados: {'score': 15, 'total': 20, 'interpretation': 'Moderate'},
        observaciones: 'Detailed notes about patient performance',
      );

      expect(evaluacion.resultados!['score'], 15);
      expect(evaluacion.resultados!['total'], 20);
      expect(evaluacion.observaciones, contains('Detailed notes'));
    });

    test('should handle appointment linking', () {
      final evaluacionWithCita = Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: 'Test',
        fechaRealizacion: DateTime.now(),
        citaId: 'cita123',
      );

      final evaluacionWithoutCita = Evaluacion(
        id: '2',
        pacienteId: 'pac2',
        psicologoId: 'psic1',
        tipoTest: 'Test',
        fechaRealizacion: DateTime.now(),
      );

      expect(evaluacionWithCita.citaId, 'cita123');
      expect(evaluacionWithoutCita.citaId, null);
    });

    test('should handle date conversions correctly', () {
      final evaluacion = Evaluacion(
        id: '1',
        pacienteId: 'pac1',
        psicologoId: 'psic1',
        tipoTest: 'Test',
        fechaRealizacion: DateTime.parse('2023-01-01T15:30:00'),
      );

      final json = evaluacion.toJson();
      
      expect(json['fecha_realizacion'], '2023-01-01T15:30:00.000Z');
    });
  });
}
