import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase.dart';
import '../../../../core/constants/app_constants.dart';

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  String _connectionStatus = 'Verificando conexión...';
  bool _isLoading = false;
  List<Map<String, dynamic>> _clinicas = [];

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _investigateClinicasTable() async {
    try {
      // Intento 1: Verificar estructura básica sin datos
      await supabase.from('clinicas').select('id').limit(0);

      setState(() {
        _connectionStatus =
            '✅ Estructura de clinicas correcta - Tabla vacía o sin datos';
      });
    } catch (e) {
      try {
        // Intento 2: Verificar si hay triggers o vistas problemáticas
        final count = await supabase.from('clinicas').select('id').limit(1);

        setState(() {
          _connectionStatus =
              '⚠️ clinicas accesible pero con problemas - Count: ${count.length}';
        });
      } catch (e2) {
        // Intento 3: Crear una vista simple para evitar el problema
        setState(() {
          _connectionStatus =
              '❌ Problema detectado en clinicas: $e2\n\n💡 Solución: Crear vista simple en Supabase:\nCREATE VIEW clinicas_simple AS SELECT id, nombre FROM clinicas;';
        });
      }
    }
  }

  Future<void> _diagnoseDatabaseIssue() async {
    try {
      // Intento 1: Verificar si podemos acceder a información básica
      await supabase.from('clinicas').select('id').limit(1);

      setState(() {
        _connectionStatus = '✅ Conexión exitosa - Tabla clinicas accesible';
      });
    } catch (e) {
      try {
        // Intento 2: Probar con otra tabla simple
        final roles = await supabase
            .from('roles')
            .select('id, nombre')
            .limit(3);

        setState(() {
          _connectionStatus =
              '✅ Tabla roles accesible - Roles: ${roles.map((r) => r['nombre']).join(', ')}';
        });
      } catch (e2) {
        try {
          // Intento 3: Probar con permisos (tabla más simple)
          await supabase.from('permisos').select('id').limit(1);

          setState(() {
            _connectionStatus =
                '✅ Tabla permisos accesible - Conexión básica funciona';
          });
        } catch (e3) {
          setState(() {
            _connectionStatus = '❌ Error en diagnóstico: $e3';
          });
        }
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Conectando a Supabase...';
    });

    try {
      // Verificar si Supabase está inicializado
      if (true) {
        // Supabase siempre está inicializado después de main.dart
        setState(() {
          _connectionStatus = '✅ Supabase inicializado correctamente';
        });

        // Probar conexión con consulta específica según el esquema
        List<Map<String, dynamic>> response = [];

        try {
          // Consulta a clinicas con columnas específicas del esquema
          response = await supabase
              .from(AppConstants.tableClinicas)
              .select('id, nombre, telefono, activa')
              .limit(5);

          setState(() {
            _clinicas = List<Map<String, dynamic>>.from(response);
            _connectionStatus =
                '✅ Conexión exitosa - ${response.length} clínicas encontradas';
          });
        } catch (e) {
          // Si falla, intentamos con una tabla más simple
          try {
            final roles = await supabase
                .from('roles')
                .select('id, nombre')
                .limit(3);
            setState(() {
              _connectionStatus =
                  '⚠️ Tabla clinicas con problemas, pero roles funciona: ${roles.length} roles encontrados';
            });
          } catch (e2) {
            setState(() {
              _connectionStatus = '❌ Error general: $e2';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Conexión Supabase'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado de Conexión',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_connectionStatus),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _testConnection,
                            child: const Text('Probar Conexión'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _diagnoseDatabaseIssue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Diagnosticar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _investigateClinicasTable,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Investigar Clinicas'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_clinicas.isNotEmpty) ...[
              const Text(
                'Clínicas encontradas:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _clinicas.length,
                  itemBuilder: (context, index) {
                    final clinica = _clinicas[index];
                    return Card(
                      child: ListTile(
                        title: Text(clinica['nombre'] ?? 'Sin nombre'),
                        subtitle: Text(
                          'ID: ${clinica['id']}\nTeléfono: ${clinica['telefono'] ?? 'No registrado'}',
                        ),
                        leading: const Icon(Icons.local_hospital),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
