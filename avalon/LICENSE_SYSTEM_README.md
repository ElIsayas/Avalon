# Sistema de Autenticación por Licencias con HWID

## 📋 Overview

Sistema completo de autenticación basado en licencias que utiliza Hardware ID (HWID) para identificar y autorizar dispositivos específicos. El sistema garantiza que cada licencia solo pueda usarse en un dispositivo autorizado.

## 🏗️ Arquitectura

### Base de Datos
- **PostgreSQL** con tablas optimizadas
- **Funciones SQL** para validación de licencias
- **Índices** para consultas rápidas
- **Triggers** para timestamps automáticos

### Backend (API)
- **Node.js/Express** o **Python/FastAPI**
- **Endpoints REST** para validación
- **bcrypt** para hash de contraseñas
- **Validación JWT** opcional

### Frontend (Flutter)
- **Riverpod** para gestión de estado
- **HWID Generator** para identificación de hardware
- **UI Material Design** responsiva
- **Manejo de errores** específico

## 🗄️ Estructura de la Base de Datos

### Tabla `licencias`
```sql
CREATE TABLE licencias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT UNIQUE NOT NULL,           -- Formato: XXXX-XXXX-XXXX-XXXX
    hwid TEXT,                                   -- HWID del dispositivo autorizado
    activa BOOLEAN DEFAULT true,                -- Estado de la licencia
    fecha_creacion TIMESTAMP DEFAULT NOW(),      -- Cuándo se creó la licencia
    fecha_activacion TIMESTAMP,                  -- Cuándo se activó por primera vez
    fecha_expiracion TIMESTAMP,                  -- Cuándo expira (1 año después de activación)
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Tabla `usuarios`
```sql
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,                        -- Nombre del usuario
    email TEXT UNIQUE NOT NULL,                 -- Email único
    password_hash TEXT NOT NULL,                -- Hash bcrypt de la contraseña
    licencia_id UUID NOT NULL REFERENCES licencias(id),
    hwid TEXT NOT NULL,                         -- HWID del dispositivo
    fecha_registro TIMESTAMP DEFAULT NOW(),     -- Fecha de registro
    activo BOOLEAN DEFAULT true,                -- Estado del usuario
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

## 🔐 Funciones SQL Principales

### `validar_licencia(license_key, hwid)`
Valida una licencia y la activa si es la primera vez:
- ✅ Verifica que la licencia exista y esté activa
- ✅ Si es primera activación: asigna HWID y fecha de expiración (1 año)
- ✅ Si ya está activada: verifica que el HWID coincida
- ❌ Error si HWID no coincide o licencia expirada

### `validar_login(email, password, hwid)`
Valida credenciales y licencia del usuario:
- ✅ Verifica email y contraseña (bcrypt)
- ✅ Verifica que la licencia esté activa
- ✅ Verifica que la licencia no haya expirado
- ✅ Verifica que el HWID coincida con el de la licencia
- ❌ Error en cualquier validación

### `crear_usuario(nombre, email, password, licencia_id, hwid)`
Crea un nuevo usuario asociado a una licencia:
- ✅ Verifica que el email no exista
- ✅ Hashea contraseña con bcrypt
- ✅ Asocia usuario a licencia validada

## 📱 Generación de HWID en Flutter

### Algoritmo
```dart
// 1. Obtener información del hardware
String macAddress = await _getMacAddress();     // MAC address del dispositivo
String hostname = Platform.localHostname;        // Nombre del host
String osInfo = _getOSInfo();                   // Info del SO
String deviceModel = _getDeviceModel();         // Modelo del dispositivo

// 2. Concatenar información
String base = '$macAddress|$hostname|$osInfo|$deviceModel';

// 3. Generar SHA256
String hwid = sha256.convert(utf8.encode(base)).toString();
```

### Características
- **Cross-platform**: Windows, Linux, macOS, Android, iOS
- **Fallback**: Si no se puede obtener HWID, usa timestamp
- **Seguro**: SHA256 irreversible
- **Único**: Cada dispositivo genera un HWID diferente

## 🎫 Formato de Licencias

### Generación
```dart
static String generateLicenseKey() {
  final parts = <String>[];
  for (int i = 0; i < 4; i++) {
    final part = sha256
        .convert(utf8.encode('random$i'))
        .toString()
        .substring(0, 4)
        .toUpperCase();
    parts.add(part);
  }
  return parts.join('-'); // Formato: XXXX-XXXX-XXXX-XXXX
}
```

### Ejemplos
- `A1B2-C3D4-E5F6-G7H8`
- `9Z8Y-7X6W-5V4U-3T2S`
- `M1N2-O3P4-Q5R6-S7T8`

## 🔄 Flujo Completo

### 1. Activación de Licencia
```
Usuario ingresa licencia → App genera HWID → API valida licencia
├─ Si es primera vez: Asigna HWID, activa por 1 año
├─ Si ya existe: Verifica HWID coincida
└─ Si todo OK: Muestra formulario de registro
```

### 2. Registro de Usuario
```
Usuario completa formulario → App envía datos + HWID → API crea usuario
├─ Verifica email único
├─ Hashea contraseña con bcrypt
├─ Asocia a licencia validada
└─ Usuario listo para login
```

### 3. Login
```
Usuario ingresa email/password → App genera HWID → API valida todo
├─ Verifica credenciales (bcrypt)
├─ Verifica licencia activa
├─ Verifica licencia no expirada
├─ Verifica HWID coincida
└─ Si todo OK: Login exitoso
```

## 🛡️ Medidas de Seguridad

### Contraseñas
- **bcrypt** con salt automático
- **Mínimo 6 caracteres**
- **Nunca se almacenan en texto plano**

### HWID
- **SHA256** irreversible
- **Basado en hardware real**
- **No se puede falsificar fácilmente**

### Licencias
- **Formato aleatorio seguro**
- **Validación en cada login**
- **Expiración automática (1 año)**

### API
- **HTTPS obligatorio**
- **Rate limiting**
- **Validación de inputs**
- **Logs de accesos**

## 📊 Estados y Errores

### Códigos de Error
| Código | Descripción | Solución |
|--------|-------------|----------|
| `LICENCIA_INVALIDA` | No existe o está inactiva | Verificar licencia |
| `LICENCIA_EXPIRADA` | Pasó la fecha de expiración | Renovar licencia |
| `DISPOSITIVO_NO_AUTORIZADO` | HWID no coincide | Contactar soporte |
| `USUARIO_NO_ENCONTRADO` | Email no existe | Verificar credenciales |
| `CREDENCIALES_INVALIDAS` | Contraseña incorrecta | Reintentar |
| `EMAIL_EXISTE` | Email ya registrado | Usar otro email |

### Estados de Licencia
- **Pendiente**: Creada pero no activada
- **Activa**: En uso, válida
- **Expirada**: Pasó la fecha límite
- **Inactiva**: Desactivada manualmente

## 🚀 Implementación

### 1. Base de Datos
```bash
# Ejecutar el schema SQL
psql -d tu_database -f database/schema.sql
```

### 2. Backend
```bash
# Crear API endpoints
# /api/license/validate
# /api/user/create  
# /api/auth/login
# /api/license/generate
```

### 3. Flutter
```bash
# Agregar dependencias
flutter pub add crypto http flutter_riverpod

# Configurar providers
# LicenseService
# LicenseAuthProvider
# HWIDGenerator
```

### 4. Configuración
```dart
// Configurar URL y API key
final licenseService = LicenseService(
  baseUrl: 'https://tu-api.com',
  apiKey: 'tu-api-key-secreta',
);
```

## 📱 UI Screens

### LicenseActivationScreen
- Campo para ingresar licencia
- Validación de formato
- Formulario de registro (post-validación)
- Indicadores visuales de estado

### LoginScreen  
- Campos de email y contraseña
- Recordar HWID automáticamente
- Enlaces a recuperación y activación

### Dashboard (opcional)
- Información de licencia
- Días restantes
- Estado del dispositivo

## 🔧 Mantenimiento

### Tareas Automáticas
- **Limpieza de licencias expiradas** (cron job)
- **Logs de accesos** (monitoreo)
- **Backups diarios** (base de datos)

### Tareas Manuales
- **Generación de nuevas licencias**
- **Soporte a usuarios**
- **Renovación de licencias**

## 📈 Escalabilidad

### Base de Datos
- **Partitioning** por fecha de creación
- **Read replicas** para consultas
- **Connection pooling**

### API
- **Load balancing**
- **Caching** (Redis)
- **CDN** para assets estáticos

### Flutter
- **State persistence** (Hive/SQLite)
- **Offline mode** básico
- **Background sync**

## 🧪 Testing

### Unit Tests
- HWID generation
- License validation
- Password hashing

### Integration Tests
- Complete auth flow
- API endpoints
- Database operations

### Security Tests
- SQL injection
- XSS prevention
- Rate limiting

## 📞 Soporte

### Problemas Comunes
1. **HWID cambia después de actualización**
   - Solución: Implementar HWID estable basado en hardware permanente

2. **Usuario no recuerda licencia**
   - Solución: Sistema de recuperación por email

3. **Licencia expirada**
   - Solución: Portal de renovación automática

### Contacto
- **Email**: soporte@tuapp.com
- **Portal**: https://portal.tuapp.com
- **FAQ**: https://faq.tuapp.com

---

## 📝 Resumen

Este sistema proporciona una solución robusta y segura para controlar el acceso a software basado en licencias por dispositivo. La combinación de HWID, licencias con expiración y validación en cada login garantiza que solo usuarios autorizados puedan acceder al software en dispositivos específicos.

**Características principales:**
- ✅ Licencia por dispositivo (HWID)
- ✅ Expiración automática (1 año)
- ✅ Contraseñas seguras (bcrypt)
- ✅ Validación en cada login
- ✅ UI Flutter moderna
- ✅ API REST escalable
- ✅ Base de datos optimizada
