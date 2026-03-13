import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/core/utils/logger.dart';

void main() async {
  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://xovztnvrchdgpxnyebpr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhvdnp0bnZyY2hkcHhueWVicHIiLCJpYXQiOjE3MzQxMDQxNzcsImV4cCI6MjA0OTY4MDE3N30.SQHzv9t5QkKJNJIhIq5lLXQ8Bt1JpX4sKqKqKqKqKqK',
  );

  final client = Supabase.instance.client;
  
  print('🧪 TEST DE CREDENCIALES');
  print('========================');
  
  // Test 1: Admin
  print('\n📧 Test 1: admin@example.com');
  try {
    final response = await client.auth.signInWithPassword(
      email: 'admin@example.com',
      password: 'admin123',
    );
    print('✅ Admin login exitoso: ${response.user?.email}');
    print('🆔 User ID: ${response.user?.id}');
    
    // Logout
    await client.auth.signOut();
    print('🚪 Admin logout completado');
  } catch (e) {
    print('❌ Admin login falló: $e');
  }
  
  // Test 2: Otro usuario si existe
  print('\n📧 Test 2: psicologo@example.com');
  try {
    final response = await client.auth.signInWithPassword(
      email: 'psicologo@example.com',
      password: 'psicologo123',
    );
    print('✅ Psicologo login exitoso: ${response.user?.email}');
    print('🆔 User ID: ${response.user?.id}');
    
    // Logout
    await client.auth.signOut();
    print('🚪 Psicologo logout completado');
  } catch (e) {
    print('❌ Psicologo login falló: $e');
  }
  
  print('\n🏁 TEST COMPLETADO');
}
