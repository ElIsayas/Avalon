import 'dart:developer' as developer;

class AppLogger {
  static const String _tag = 'AVALON';
  
  static void debug(String message, {String? tag}) {
    developer.log(
      '🔍 DEBUG: $message',
      name: tag ?? _tag,
      level: 500,
    );
  }
  
  static void info(String message, {String? tag}) {
    developer.log(
      'ℹ️ INFO: $message',
      name: tag ?? _tag,
      level: 800,
    );
  }
  
  static void warning(String message, {String? tag}) {
    developer.log(
      '⚠️ WARNING: $message',
      name: tag ?? _tag,
      level: 900,
    );
  }
  
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    developer.log(
      '❌ ERROR: $message',
      name: tag ?? _tag,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
  
  static void auth(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      '🔐 AUTH: $message',
      name: '$_tag-AUTH',
      error: error,
      stackTrace: stackTrace,
      level: 800,
    );
  }
  
  static void database(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      '💾 DATABASE: $message',
      name: '$_tag-DB',
      error: error,
      stackTrace: stackTrace,
      level: 800,
    );
  }
  
  static void api(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      '🌐 API: $message',
      name: '$_tag-API',
      error: error,
      stackTrace: stackTrace,
      level: 800,
    );
  }
  
  static void ui(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      '🖼️ UI: $message',
      name: '$_tag-UI',
      error: error,
      stackTrace: stackTrace,
      level: 800,
    );
  }
}
