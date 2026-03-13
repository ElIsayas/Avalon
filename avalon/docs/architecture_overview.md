# Avalon - Architecture Overview

## Clean Architecture Implementation

Avalon follows Clean Architecture principles with clear separation of concerns across layers:

```
lib/
├── core/                          # Shared utilities and configurations
│   ├── constants/                 # App constants
│   ├── supabase/                  # Database configuration
│   ├── themes/                    # UI themes
│   └── utils/                     # Utility functions
├── features/                      # Feature modules
│   ├── auth/                      # Authentication module
│   ├── admin/                     # Admin console module
│   ├── pacientes/                 # Patient management module
│   ├── citas/                     # Appointments module
│   ├── evaluaciones/              # Psychological evaluations module
│   ├── notas/                     # Therapy notes module
│   └── dashboard/                 # Main dashboard
└── main.dart                      # App entry point
```

## Feature Module Structure

Each feature module follows this consistent structure:

```
features/[feature_name]/
├── domain/                        # Business logic layer
│   ├── entities/                  # Business entities
│   ├── repositories/              # Repository interfaces
│   └── use_cases/                 # Business use cases (if needed)
├── data/                          # Data layer
│   ├── models/                     # Data models (if different from entities)
│   ├── datasources/               # Data sources
│   └── repositories/              # Repository implementations
├── presentation/                  # UI layer
│   ├── providers/                 # State management (Riverpod)
│   ├── screens/                   # UI screens
│   └── widgets/                   # Reusable UI components
└── [feature_name]_module.dart     # Module barrel exports
```

## Module Dependencies

### Core Dependencies
- **Supabase** - Backend database and authentication
- **Riverpod** - State management
- **Flutter ScreenUtil** - Responsive design
- **Google Fonts** - Typography
- **Material 3** - UI design system

### Feature Dependencies
- **Auth Module** - Core authentication, used by all other modules
- **Admin Module** - Manages psicologo users and system settings
- **Pacientes Module** - Patient management and records
- **Citas Module** - Appointment scheduling and management
- **Evaluaciones Module** - Psychological assessments
- **Notas Module** - Therapy session notes
- **Dashboard Module** - Main navigation and overview

## Data Flow Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │     Domain      │    │      Data       │
│                 │    │                 │    │                 │
│ • Screens       │◄──►│ • Entities      │◄──►│ • Services      │
│ • Providers     │    │ • Repositories  │    │ • Models        │
│ • Widgets       │    │ • Use Cases     │    │ • Data Sources  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Role-Based Access Control

### User Roles
- **Admin** - Full system access, manages psicólogos
- **Psicólogo** - Manages own patients, appointments, evaluations, notes

### Permission Implementation
- **Service Layer** - Provides data access methods
- **Provider Layer** - Implements role-based filtering
- **UI Layer** - Respects permission boundaries

### Permission Flow
```
User Request → Provider (Role Check) → Service (Data Access) → Database
```

## Database Schema Alignment

### Core Tables
- **usuarios** - User authentication and profiles
- **pacientes** - Patient records and information
- **citas** - Appointments and scheduling
- **evaluaciones** - Psychological assessments
- **notas_terapia** - Therapy session notes

### Key Relationships
- **usuarios.psicologo_id** → Links to pacientes.creado_por
- **citas.paciente_id** → Links to pacientes
- **citas.psicologo_id** → Links to usuarios
- **evaluaciones.paciente_id** → Links to pacientes
- **evaluaciones.psicologo_id** → Links to usuarios
- **notas_terapia.paciente_id** → Links to pacientes
- **notas_terapia.psicologo_id** → Links to usuarios

## State Management Architecture

### Riverpod Providers
- **Service Providers** - Dependency injection for services
- **State Notifiers** - State management with business logic
- **Future Providers** - Async data handling
- **Stream Providers** - Real-time data (if needed)

### State Flow
```
UI Event → Provider → Service → Database → Provider → UI Update
```

## Error Handling Strategy

### Layer-Specific Error Handling
- **Service Layer** - Database and network errors
- **Provider Layer** - Business logic and validation errors
- **UI Layer** - User-friendly error messages

### Error Types
- **Authentication Errors** - Login, session issues
- **Validation Errors** - Form validation, data integrity
- **Network Errors** - Database connectivity
- **Permission Errors** - Access control violations

## Testing Architecture

### Test Organization
```
test/
├── features/
│   ├── auth/
│   ├── pacientes/
│   ├── citas/
│   ├── evaluaciones/
│   └── notas/
└── unit/                          # Shared utilities testing
```

### Test Types
- **Entity Tests** - Business entity validation
- **Service Tests** - Data layer functionality
- **Provider Tests** - State management logic
- **Integration Tests** - End-to-end workflows

## Performance Considerations

### Data Optimization
- **Lazy Loading** - Load data only when needed
- **Caching** - Provider-level state caching
- **Pagination** - Large dataset handling
- **Indexing** - Database query optimization

### UI Performance
- **Widget Reuse** - Shared components
- **State Management** - Efficient updates
- **Responsive Design** - ScreenUtil for scaling
- **Image Optimization** - Efficient asset loading

## Security Architecture

### Authentication
- **Supabase Auth** - Secure user authentication
- **JWT Tokens** - Session management
- **Role-Based Access** - Permission enforcement

### Data Security
- **Input Validation** - Form and API validation
- **SQL Injection Prevention** - Supabase RLS policies
- **Data Encryption** - Sensitive information protection

## Deployment Architecture

### Environment Configuration
- **Development** - Local development setup
- **Staging** - Testing environment
- **Production** - Live application

### Build Process
- **Flutter Build** - Application compilation
- **Asset Optimization** - Resource compression
- **Code Splitting** - Modular loading

## Future Scalability

### Modular Growth
- **New Features** - Add new feature modules
- **Service Expansion** - Extend existing services
- **UI Components** - Reusable widget library

### Technical Debt Management
- **Code Reviews** - Quality assurance
- **Refactoring** - Continuous improvement
- **Documentation** - Knowledge sharing

## Best Practices

### Code Organization
- **Single Responsibility** - Each class has one purpose
- **Dependency Injection** - Loose coupling
- **Interface Segregation** - Small, focused interfaces
- **Don't Repeat Yourself** - Code reuse

### Development Workflow
- **Feature Branches** - Isolated development
- **Code Reviews** - Peer validation
- **Automated Testing** - Continuous integration
- **Documentation** - Knowledge preservation

This architecture ensures maintainability, scalability, and testability while following clean architecture principles and Flutter best practices.
