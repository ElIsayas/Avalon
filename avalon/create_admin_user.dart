import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://xovztnvrchdgpxnyebpr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhvdnp0bnZyY2hkcHhueWVicHIiLCJpYXQiOjE3MzQxMDQxNzcsImV4cCI6MjA0OTY4MDE3N30.SQHzv9t5QkKJNJIhIq5lLXQ8Bt1JpX4sKqKqKqKqKqK',
  );

  final client = Supabase.instance.client;
  
  print('🔧 CREACIÓN DE USUARIO ADMIN');
  print('============================');
  
  try {
    // 1. Intentar login primero para ver si existe
    print('\n📧 Verificando si admin@example.com existe...');
    try {
      final loginResponse = await client.auth.signInWithPassword(
        email: 'admin@example.com',
        password: 'admin123',
      );
      print('✅ Usuario admin ya existe: ${loginResponse.user?.email}');
      print('🆔 User ID: ${loginResponse.user?.id}');
      
      // Logout
      await client.auth.signOut();
      print('🚪 Logout completado');
      
      // Verificar si existe en la tabla usuarios
      print('\n🔍 Verificando tabla usuarios...');
      final userData = await client
          .from('usuarios')
          .select()
          .eq('auth_user_id', loginResponse.user!.id)
          .maybeSingle();
          
      if (userData != null) {
        print('✅ Usuario encontrado en tabla usuarios:');
        print('   - Nombre: ${userData['nombre']}');
        print('   - Rol: ${userData['rol']}');
        print('   - Activo: ${userData['activo']}');
      } else {
        print('❌ Usuario NO encontrado en tabla usuarios');
        print('🔧 Creando registro en tabla usuarios...');
        
        await client.from('usuarios').insert({
          'auth_user_id': loginResponse.user!.id,
          'nombre': 'Administrador',
          'email': 'admin@example.com',
          'rol': 'admin',
          'activo': true,
          'clinica_id': 'default-clinic', // Ajustar según tu configuración
        });
        print('✅ Registro creado en tabla usuarios');
      }
      
    } catch (loginError) {
      print('❌ Usuario admin NO existe en Supabase Auth');
      print('🔧 Creando usuario admin...');
      
      // Crear usuario en Supabase Auth
      final signupResponse = await client.auth.signUp(
        email: 'admin@example.com',
        password: 'admin123',
      );
      
      if (signupResponse.user != null) {
        print('✅ Usuario admin creado en Supabase Auth');
        print('🆔 User ID: ${signupResponse.user!.id}');
        
        // Crear registro en tabla usuarios
        await client.from('usuarios').insert({
          'auth_user_id': signupResponse.user!.id,
          'nombre': 'Administrador',
          'email': 'admin@example.com',
          'rol': 'admin',
          'activo': true,
          'clinica_id': 'default-clinic', // Ajustar según tu configuración
        });
        print('✅ Registro creado en tabla usuarios');
        
        // Logout para que pueda hacer login normal
        await client.auth.signOut();
        print('🚪 Logout completado - usuario listo para usar');
      }
    }
    
    print('\n🎉 PROCESO COMPLETADO');
    print('📧 Ahora puedes hacer login con: admin@example.com / admin123');
    
  } catch (e) {
    print('❌ Error: $e');
    print('🔍 Detalles del error:');
    print('   - Tipo: ${e.runtimeType}');
    print('   - Mensaje: ${e.toString()}');
  }
}
