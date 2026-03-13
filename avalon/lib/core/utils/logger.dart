import 'dart:developer' as developer;

class Logger {
  static void debug(String message, [String? tag]) {
    if (_isDebugMode) {
      final taggedMessage = tag != null ? '[$tag] DEBUG: $message' : 'DEBUG: $message';
      developer.log(taggedMessage, name: 'Avalon');
    }
  }

  static void info(String message, [String? tag]) {
    if (_isDebugMode) {
      final taggedMessage = tag != null ? '[$tag] INFO: $message' : 'INFO: $message';
      developer.log(taggedMessage, name: 'Avalon');
    }
  }

  static void warning(String message, [String? tag]) {
    if (_isDebugMode) {
      final taggedMessage = tag != null ? '[$tag] WARNING: $message' : 'WARNING: $message';
      developer.log(taggedMessage, name: 'Avalon', level: 900);
    }
  }

  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    if (_isDebugMode) {
      final taggedMessage = tag != null ? '[$tag] ERROR: $message' : 'ERROR: $message';
      developer.log(taggedMessage, name: 'Avalon', level: 1000, error: error, stackTrace: stackTrace);
    }
  }

  static bool get _isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
}
