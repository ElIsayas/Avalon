# Avalon
📘 Arquitectura del Proyecto – App de Psicología
Stack tecnológico

Frontend:

Flutter

Dart

Backend / BaaS:

Supabase

Base de datos:

PostgreSQL

Gestión de estado:

Riverpod

Diseño UI:

Figma

Control de versiones:

Git

GitHub

Testing API:

Postman

1. Objetivo del sistema

Desarrollar una plataforma de gestión psicológica para clínicas, que permita:

gestionar pacientes

registrar sesiones terapéuticas

almacenar historias clínicas

aplicar tests psicológicos

seguimiento de objetivos

manejo de citas

almacenamiento de archivos clínicos

recordatorios terapéuticos

El sistema está diseñado como multi-clínica (multi-tenant), donde cada clínica gestiona sus propios pacientes y psicólogos.

2. Arquitectura general

La aplicación utiliza una arquitectura Flutter + Supabase.

Flutter App
     │
     │ Supabase SDK
     ▼
Supabase Platform
  ├ Auth
  ├ REST API
  ├ Storage
  └ PostgreSQL Database

Supabase reemplaza:

backend tradicional

API REST

autenticación

almacenamiento de archivos

Esto reduce mucho el tiempo de desarrollo.

3. Manejo y edición de la UI

Flutter usa Material 3 con un sistema de temas centralizado.

Ventajas

consistencia visual

mantenimiento sencillo

escalabilidad

responsive design

Paquetes recomendados
flutter_screenutil
google_fonts
flutter_svg
Estructura UI
ui/
 ├ screens/
 │   ├ login_screen.dart
 │   ├ home_screen.dart
 │   ├ pacientes_screen.dart
 │   ├ sesiones_screen.dart
 │   ├ citas_screen.dart
 │   ├ tests_screen.dart
 │
 ├ widgets/
 │   ├ custom_button.dart
 │   ├ custom_textfield.dart
 │   ├ patient_card.dart
 │
 ├ theme/
 │   ├ colors.dart
 │   ├ text_styles.dart
 │   ├ app_theme.dart
4. Gestión de estado

Se utilizará Riverpod.

Ventajas:

escalable

fácil testing

control de dependencias

menos errores en runtime

Estructura
state/
 ├ auth_provider.dart
 ├ user_provider.dart
 ├ pacientes_provider.dart
 ├ sesiones_provider.dart
 ├ citas_provider.dart
5. Base de datos

La base de datos está construida en PostgreSQL usando Supabase.

Tablas principales:

clinicas
usuarios
psicologos
pacientes
citas
sesiones
historias_clinicas
tests_psicologicos
objetivos
progreso_objetivos
archivos
recordatorios
suscripciones
planes
roles
permisos
roles_permisos
usuarios_roles
6. Sistema de autenticación

Supabase utiliza su propia tabla interna:

auth.users

Ahí se guardan:

email

password (hash)

id

La app utiliza una tabla adicional:

usuarios

para almacenar información extendida.

7. Tabla de usuarios (login)

Tabla utilizada para mapear usuarios autenticados.

CREATE TABLE public.usuarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id uuid UNIQUE NOT NULL,
  clinica_id uuid,
  nombre text NOT NULL,
  email text UNIQUE NOT NULL,
  rol rol_usuario DEFAULT 'psicologo',
  numero_documento text UNIQUE,
  activo boolean DEFAULT true,
  fecha_registro timestamp DEFAULT now(),
  FOREIGN KEY (clinica_id) REFERENCES clinicas(id)
);
8. Flujo completo de autenticación
Registro

1️⃣ Usuario se registra en la app.

Flutter → Supabase Auth

Supabase crea el usuario en:

auth.users

2️⃣ Se crea el registro en la tabla usuarios.

INSERT INTO usuarios
Login

Flujo:

Flutter login
      │
      ▼
Supabase Auth
      │
      ▼
user.id
      │
      ▼
consulta tabla usuarios
Ejemplo Flutter login
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

Luego:

final user = supabase.auth.currentUser;

Consulta de datos:

final data = await supabase
    .from('usuarios')
    .select()
    .eq('auth_user_id', user!.id)
    .single();
9. Flujo completo del sistema
Flujo principal
Login
   │
Dashboard
   │
Pacientes
   │
Sesiones
   │
Historia clínica
   │
Objetivos
   │
Tests psicológicos
Flujo de pacientes
Crear paciente
     │
Ver perfil
     │
Historia clínica
     │
Sesiones
     │
Progreso terapéutico
Flujo de citas
Crear cita
   │
Asignar paciente
   │
Asignar psicólogo
   │
Confirmar
   │
Convertir en sesión
Flujo de sesión terapéutica
Inicio sesión
   │
Estado emocional
   │
Temas tratados
   │
Objetivos sesión
   │
Observaciones
   │
Tareas para paciente
   │
Registrar progreso
Flujo de tests psicológicos
Seleccionar test
   │
Responder preguntas
   │
Calcular puntaje
   │
Interpretación
   │
Guardar resultado
10. Estructura del proyecto Flutter

Arquitectura basada en Clean Architecture.

lib/

core/
 ├ constants
 ├ theme
 ├ utils
 ├ supabase
 │   └ supabase_client.dart

features/

 ├ auth/
 │   ├ data/
 │   │   ├ auth_service.dart
 │   │   ├ auth_repository.dart
 │   │
 │   ├ domain/
 │   │   ├ entities
 │   │   ├ usecases
 │   │
 │   ├ presentation/
 │       ├ screens
 │       │   ├ login_screen.dart
 │       │   └ register_screen.dart
 │       ├ providers

 ├ pacientes/
 ├ sesiones/
 ├ citas/
 ├ tests/
 ├ objetivos/
 ├ archivos/
11. Seguridad

Debido a que se trata de datos clínicos sensibles, se deben aplicar medidas de seguridad.

Medidas obligatorias:

Row Level Security (RLS)

HTTPS

autenticación Supabase

roles de usuario

control de acceso por clínica

encriptación de contraseñas (automática en Supabase)

12. Políticas de seguridad (RLS)

Ejemplo en pacientes:

ALTER TABLE pacientes ENABLE ROW LEVEL SECURITY;

Política ejemplo:

Solo usuarios de la misma clínica pueden ver pacientes.
13. Almacenamiento de archivos

Los archivos clínicos se almacenarán en Supabase Storage.

Ejemplos:

PDF de informes

imágenes

documentos clínicos

Tabla asociada:

archivos

Campos importantes:

url
tipo_archivo
descripcion
fecha_subida
14. Módulos de la aplicación

Módulos principales:

Autenticación
Dashboard
Pacientes
Citas
Sesiones
Historias clínicas
Tests psicológicos
Objetivos terapéuticos
Archivos clínicos
Recordatorios
Suscripciones
15. Estructura del proyecto completo
psychology_app/

frontend_flutter/
backend_supabase/
database/
docs/
16. Próximos pasos del desarrollo

Orden recomendado de desarrollo:

1️⃣ Configurar proyecto Flutter
2️⃣ Conectar Supabase
3️⃣ Crear sistema de login
4️⃣ Crear dashboard
5️⃣ CRUD pacientes
6️⃣ CRUD citas
7️⃣ Sistema de sesiones
8️⃣ Historia clínica
9️⃣ Tests psicológicos
10️⃣ Objetivos terapéuticos
