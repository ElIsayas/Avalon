# Avalon - Psychological Clinic Management System

A comprehensive Flutter application for managing psychological clinic operations, including patient management, appointments, evaluations, and therapy notes.

## 🏥 Features

### Core Modules
- **Authentication** - Secure user authentication with role-based access
- **Admin Console** - Psychologist user management and system administration
- **Patient Management** - Complete patient records and medical history
- **Appointment Scheduling** - Calendar-based appointment management
- **Psychological Evaluations** - Assessment tools and result tracking
- **Therapy Notes** - Session documentation and progress tracking
- **Dashboard** - Overview and quick access to key functions

### Key Capabilities
- 📱 Responsive design for mobile and tablet
- 🔐 Role-based access control (Admin/Psychologist)
- 📊 Real-time statistics and reporting
- 🗓️ Appointment scheduling with availability checking
- 📋 Comprehensive patient records
- 🧠 Psychological assessment tools
- 📝 Therapy session notes and progress tracking
- 🔍 Advanced search and filtering
- 💾 Secure data storage with Supabase

## 🏗️ Architecture

Avalon follows Clean Architecture principles with clear separation of concerns:

```
lib/
├── core/                          # Shared utilities
├── features/                      # Feature modules
│   ├── auth/                      # Authentication
│   ├── admin/                     # Admin console
│   ├── pacientes/                 # Patient management
│   ├── citas/                     # Appointments
│   ├── evaluaciones/              # Evaluations
│   ├── notas/                     # Therapy notes
│   └── dashboard/                 # Main dashboard
└── main.dart                      # App entry point
```

### Technology Stack
- **Flutter** - Cross-platform UI framework
- **Supabase** - Backend database and authentication
- **Riverpod** - State management
- **Material 3** - UI design system
- **Google Fonts** - Typography
- **Flutter ScreenUtil** - Responsive design

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Supabase account and project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/avalon.git
   cd avalon
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a new Supabase project
   - Set up the database schema (see `docs/database_schema.md`)
   - Configure authentication settings
   - Update `lib/core/supabase/supabase.dart` with your project URL and anon key

4. **Run the application**
   ```bash
   flutter run
   ```

## 📱 User Roles

### Admin
- Manage psychologist accounts
- View system-wide statistics
- Configure system settings
- Full access to all data

### Psychologist
- Manage assigned patients
- Schedule appointments
- Conduct evaluations
- Write therapy notes
- View own patient data only

## 🗄️ Database Schema

### Core Tables
- **usuarios** - User authentication and profiles
- **pacientes** - Patient records and information
- **citas** - Appointments and scheduling
- **evaluaciones** - Psychological assessments
- **notas_terapia** - Therapy session notes

### Key Relationships
- Users are linked to patients they create
- Appointments link patients and psychologists
- Evaluations and notes are tied to specific sessions

## 🧪 Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/pacientes/data/paciente_service_simple_test.dart

# Run with coverage
flutter test --coverage
```

### Test Structure
- **Entity Tests** - Business entity validation
- **Service Tests** - Data layer functionality
- **Provider Tests** - State management logic
- **Integration Tests** - End-to-end workflows

## 📱 Development

### Code Organization
- Follow Clean Architecture principles
- Use feature-based module structure
- Implement proper dependency injection
- Maintain separation of concerns

### State Management
- Riverpod for state management
- Immutable state updates
- Provider-level business logic
- Error handling and loading states

### UI Guidelines
- Material 3 design system
- Responsive design with ScreenUtil
- Consistent typography and colors
- Accessibility considerations

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Build Configuration
```bash
# Development build
flutter build apk --debug

# Production build
flutter build apk --release

# Web build
flutter build web
```

## 📚 Documentation

- [Architecture Overview](docs/architecture_overview.md)
- [Database Schema](docs/database_schema.md)
- [API Documentation](docs/api_documentation.md)
- [Deployment Guide](docs/deployment_guide.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow the existing code style
- Write tests for new features
- Update documentation
- Ensure all tests pass

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the [documentation](docs/)
- Review existing issues and discussions

## 🏆 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend services
- Material Design team for the design system
- The open-source community for inspiration and tools

---

**Built with ❤️ for the psychological community**
