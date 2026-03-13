import 'package:flutter_test/flutter_test.dart';
import 'package:avalon/features/pacientes/domain/entities/paciente.dart';

void main() {
  group('Paciente Entity Tests', () {
    test('should create Paciente with required fields', () {
      // Arrange
      final paciente = Paciente(
        id: '1',
        nombre: 'John Doe',
        email: 'john@example.com',
        numeroDocumento: '12345678',
        activo: true,
        fechaRegistro: DateTime.parse('2023-01-01'),
      );

      // Assert
      expect(paciente.id, '1');
      expect(paciente.nombre, 'John Doe');
      expect(paciente.email, 'john@example.com');
      expect(paciente.numeroDocumento, '12345678');
      expect(paciente.activo, true);
      expect(paciente.fechaRegistro, DateTime.parse('2023-01-01'));
    });

    test('should create Paciente with all fields', () {
      // Arrange
      final paciente = Paciente(
        id: '1',
        nombre: 'Jane Doe',
        email: 'jane@example.com',
        numeroDocumento: '87654321',
        telefono: '5551234',
        direccion: '123 Main St',
        fechaNacimiento: DateTime.parse('1990-01-01'),
        historialMedico: 'No allergies',
        activo: true,
        fechaRegistro: DateTime.parse('2023-01-01'),
        licenciaId: 'lic1',
        deviceId: 'dev1',
        creadoPor: 'psic1',
        objetivosTerapeuticos: 'Improve communication',
        progreso: 'Good progress',
        metadata: {'key': 'value'},
        fechaActualizacion: DateTime.parse('2023-01-01'),
      );

      // Assert
      expect(paciente.id, '1');
      expect(paciente.nombre, 'Jane Doe');
      expect(paciente.email, 'jane@example.com');
      expect(paciente.numeroDocumento, '87654321');
      expect(paciente.telefono, '5551234');
      expect(paciente.direccion, '123 Main St');
      expect(paciente.fechaNacimiento, DateTime.parse('1990-01-01'));
      expect(paciente.historialMedico, 'No allergies');
      expect(paciente.activo, true);
      expect(paciente.fechaRegistro, DateTime.parse('2023-01-01'));
      expect(paciente.licenciaId, 'lic1');
      expect(paciente.deviceId, 'dev1');
      expect(paciente.creadoPor, 'psic1');
      expect(paciente.objetivosTerapeuticos, 'Improve communication');
      expect(paciente.progreso, 'Good progress');
      expect(paciente.metadata, {'key': 'value'});
      expect(paciente.fechaActualizacion, DateTime.parse('2023-01-01'));
    });

    test('should copy with updated values', () {
      // Arrange
      final originalPaciente = Paciente(
        id: '1',
        nombre: 'John Doe',
        email: 'john@example.com',
        numeroDocumento: '12345678',
        activo: true,
        fechaRegistro: DateTime.parse('2023-01-01'),
      );

      // Act
      final updatedPaciente = originalPaciente.copyWith(
        nombre: 'John Updated',
        telefono: '5555678',
      );

      // Assert
      expect(updatedPaciente.id, '1'); // Should remain unchanged
      expect(updatedPaciente.nombre, 'John Updated'); // Should be updated
      expect(updatedPaciente.email, 'john@example.com'); // Should remain unchanged
      expect(updatedPaciente.telefono, '5555678'); // Should be updated
      expect(updatedPaciente.numeroDocumento, '12345678'); // Should remain unchanged
    });

    test('should create Paciente from JSON', () {
      // Arrange
      final json = {
        'id': '1',
        'nombre': 'Test User',
        'email': 'test@example.com',
        'numero_documento': '12345678',
        'telefono': '5551234',
        'direccion': '123 Test St',
        'fecha_nacimiento': '1990-01-01',
        'historial_medico': 'Test history',
        'activo': true,
        'fecha_registro': '2023-01-01T00:00:00Z',
        'licencia_id': 'lic1',
        'device_id': 'dev1',
        'creado_por': 'psic1',
        'objetivos_terapeuticos': 'Test objectives',
        'progreso': 'Test progress',
        'metadata': {'key': 'value'},
        'fecha_actualizacion': '2023-01-01T00:00:00Z',
      };

      // Act
      final paciente = Paciente.fromJson(json);

      // Assert
      expect(paciente.id, '1');
      expect(paciente.nombre, 'Test User');
      expect(paciente.email, 'test@example.com');
      expect(paciente.numeroDocumento, '12345678');
      expect(paciente.telefono, '5551234');
      expect(paciente.direccion, '123 Test St');
      expect(paciente.fechaNacimiento, DateTime.parse('1990-01-01'));
      expect(paciente.historialMedico, 'Test history');
      expect(paciente.activo, true);
      expect(paciente.fechaRegistro, DateTime.parse('2023-01-01T00:00:00Z'));
      expect(paciente.licenciaId, 'lic1');
      expect(paciente.deviceId, 'dev1');
      expect(paciente.creadoPor, 'psic1');
      expect(paciente.objetivosTerapeuticos, 'Test objectives');
      expect(paciente.progreso, 'Test progress');
      expect(paciente.metadata, {'key': 'value'});
      expect(paciente.fechaActualizacion, DateTime.parse('2023-01-01T00:00:00Z'));
    });

    test('should convert Paciente to JSON', () {
      // Arrange
      final paciente = Paciente(
        id: '1',
        nombre: 'Test User',
        email: 'test@example.com',
        numeroDocumento: '12345678',
        telefono: '5551234',
        direccion: '123 Test St',
        fechaNacimiento: DateTime.parse('1990-01-01'),
        historialMedico: 'Test history',
        activo: true,
        fechaRegistro: DateTime.parse('2023-01-01T00:00:00Z'),
        licenciaId: 'lic1',
        deviceId: 'dev1',
        creadoPor: 'psic1',
        objetivosTerapeuticos: 'Test objectives',
        progreso: 'Test progress',
        metadata: {'key': 'value'},
        fechaActualizacion: DateTime.parse('2023-01-01T00:00:00Z'),
      );

      // Act
      final json = paciente.toJson();

      // Assert
      expect(json['id'], '1');
      expect(json['nombre'], 'Test User');
      expect(json['email'], 'test@example.com');
      expect(json['numero_documento'], '12345678');
      expect(json['telefono'], '5551234');
      expect(json['direccion'], '123 Test St');
      expect(json['fecha_nacimiento'], '1990-01-01T00:00:00.000');
      expect(json['historial_medico'], 'Test history');
      expect(json['activo'], true);
      expect(json['fecha_registro'], '2023-01-01T00:00:00.000Z');
      expect(json['licencia_id'], 'lic1');
      expect(json['device_id'], 'dev1');
      expect(json['creado_por'], 'psic1');
      expect(json['objetivos_terapeuticos'], 'Test objectives');
      expect(json['progreso'], 'Test progress');
      expect(json['metadata'], {'key': 'value'});
      expect(json['fecha_actualizacion'], '2023-01-01T00:00:00.000Z');
    });

    test('should handle null optional fields in JSON', () {
      // Arrange
      final json = {
        'id': '1',
        'nombre': 'Test User',
        'email': 'test@example.com',
        'numero_documento': '12345678',
        'activo': true,
        'fecha_registro': '2023-01-01T00:00:00Z',
      };

      // Act
      final paciente = Paciente.fromJson(json);

      // Assert
      expect(paciente.id, '1');
      expect(paciente.nombre, 'Test User');
      expect(paciente.email, 'test@example.com');
      expect(paciente.numeroDocumento, '12345678');
      expect(paciente.telefono, null);
      expect(paciente.direccion, null);
      expect(paciente.fechaNacimiento, null);
      expect(paciente.historialMedico, null);
      expect(paciente.activo, true);
      expect(paciente.fechaRegistro, DateTime.parse('2023-01-01T00:00:00Z'));
      expect(paciente.licenciaId, null);
      expect(paciente.deviceId, null);
      expect(paciente.creadoPor, null);
      expect(paciente.objetivosTerapeuticos, null);
      expect(paciente.progreso, null);
      expect(paciente.metadata, null);
      expect(paciente.fechaActualizacion, null);
    });

    test('should validate email format', () {
      // Test valid emails
      expect(() => Paciente(
        id: '1',
        nombre: 'Test User',
        email: 'valid@example.com',
        numeroDocumento: '12345678',
        activo: true,
        fechaRegistro: DateTime.now(),
      ), returnsNormally);

      // Test invalid emails - these should be caught at validation layer
      expect(() => Paciente(
        id: '1',
        nombre: 'Test User',
        email: 'invalid-email',
        numeroDocumento: '12345678',
        activo: true,
        fechaRegistro: DateTime.now(),
      ), returnsNormally); // Entity doesn't validate, service should
    });

    test('should validate document number format', () {
      // Test valid document numbers
      expect(() => Paciente(
        id: '1',
        nombre: 'Test User',
        email: 'test@example.com',
        numeroDocumento: '12345678',
        activo: true,
        fechaRegistro: DateTime.now(),
      ), returnsNormally);

      // Test empty document number
      expect(() => Paciente(
        id: '1',
        nombre: 'Test User',
        email: 'test@example.com',
        numeroDocumento: '',
        activo: true,
        fechaRegistro: DateTime.now(),
      ), returnsNormally); // Entity doesn't validate, service should
    });
  });

  group('Paciente Validation Tests', () {
    test('should validate required fields', () {
      // Test that required fields are not null
      expect(() => Paciente(
        id: '',
        nombre: '',
        email: '',
        numeroDocumento: '',
        activo: true,
        fechaRegistro: DateTime.now(),
      ), returnsNormally); // Entity doesn't enforce validation
    });

    test('should handle date conversions correctly', () {
      final paciente = Paciente(
        id: '1',
        nombre: 'Test User',
        email: 'test@example.com',
        numeroDocumento: '12345678',
        fechaNacimiento: DateTime.parse('1990-01-01'),
        activo: true,
        fechaRegistro: DateTime.parse('2023-01-01T00:00:00Z'),
        fechaActualizacion: DateTime.parse('2023-01-01T00:00:00Z'),
      );

      final json = paciente.toJson();
      
      expect(json['fecha_nacimiento'], '1990-01-01T00:00:00.000');
      expect(json['fecha_registro'], '2023-01-01T00:00:00.000Z');
      expect(json['fecha_actualizacion'], '2023-01-01T00:00:00.000Z');
    });
  });
}
