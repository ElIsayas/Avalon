import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://xovztnvrchdgpxnyebpr.supabase.co',
    anonKey: 'sb_publishable_TnT_BhEuiijFaXjw8vhamg_1i-rWmKB',
  );

  final client = Supabase.instance.client;
  
  print('🔧 CREANDO USUARIO ADMIN EN TABLA USUARIOS');
  print('==========================================');
  
  try {
    // Verificar si ya existe
    print('\n📧 Verificando si admin@example.com existe...');
    final existingUser = await client
        .from('usuarios')
        .select()
        .eq('email', 'admin@example.com')
        .maybeSingle();
        
    if (existingUser != null) {
      print('✅ Usuario admin ya existe:');
      print('   - ID: ${existingUser['id']}');
      print('   - Nombre: ${existingUser['nombre']}');
      print('   - Rol: ${existingUser['rol']}');
      print('   - Activo: ${existingUser['activa']}');
      print('🎉 Usuario listo para usar!');
      return;
    }
    
    // Crear usuario admin
    print('\n🔧 Creando usuario admin...');
    final newUser = await client
        .from('usuarios')
        .insert({
          'nombre': 'Administrador',
          'email': 'admin@example.com',
          'password': 'admin123', // En producción, usar hash
          'rol': 'admin',
          'activa': true,
          'licencia_id': '1',
          'device_id': null,
          'especialidad': null,
          'disponibilidad': true,
          'fecha_registro': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    
    print('✅ Usuario admin creado exitosamente:');
    print('   - ID: ${newUser['id']}');
    print('   - Nombre: ${newUser['nombre']}');
    print('   - Email: ${newUser['email']}');
    print('   - Rol: ${newUser['rol']}');
    print('   - Activo: ${newUser['activa']}');
    
    print('\n🎉 USUARIO ADMIN CREADO EXITOSAMENTE');
    print('📧 Puedes hacer login con:');
    print('   - Email: admin@example.com');
    print('   - Password: admin123');
    
  } catch (e) {
    print('❌ Error creando usuario admin: $e');
    print('❌ Error type: ${e.runtimeType}');
  }
}
