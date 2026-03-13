import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/debug_logger.dart';

// Modelo para los logs de debug
class DebugLog {
  final String timestamp;
  final String level;
  final String service;
  final String message;
  final String? details;
  final Color color;

  DebugLog({
    required this.timestamp,
    required this.level,
    required this.service,
    required this.message,
    this.details,
    required this.color,
  });

  @override
  String toString() {
    return '[$timestamp] $level: $service - $message';
  }
}

// Provider para manejar los logs de debug
class DebugConsoleNotifier extends StateNotifier<List<DebugLog>> {
  DebugConsoleNotifier() : super([]);
  
  static const int maxLogs = 100; // Límite de logs para evitar consumo excesivo de memoria
  
  void addLog({
    required String level,
    required String service,
    required String message,
    String? details,
  }) {
    final timestamp = DateTime.now().toString().substring(11, 23); // HH:mm:ss.sss
    final color = _getLevelColor(level);
    
    final log = DebugLog(
      timestamp: timestamp,
      level: level,
      service: service,
      message: message,
      details: details,
      color: color,
    );
    
    state = [log, ...state].take(maxLogs).toList();
  }
  
  void clearLogs() {
    state = [];
  }
  
  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      case 'DEBUG':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

final debugConsoleProvider = StateNotifierProvider<DebugConsoleNotifier, List<DebugLog>>(
  (ref) => DebugConsoleNotifier(),
);

// Widget de la consola de debug
class DebugConsole extends ConsumerStatefulWidget {
  const DebugConsole({super.key});

  @override
  ConsumerState<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends ConsumerState<DebugConsole> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String _selectedLevel = 'ALL';
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(debugConsoleProvider);
    final filteredLogs = _filterLogs(logs);
    
    return Container(
      height: 500.h, // Aumentado de 400 a 500
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16.r), // Aumentado de 12 a 16
        border: Border.all(color: Colors.grey[700]!, width: 2.w), // Aumentado border width
      ),
      child: Column(
        children: [
          // Header con controles
          Container(
            padding: EdgeInsets.all(16.w), // Aumentado de 12 a 16
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r), // Aumentado de 12 a 16
                topRight: Radius.circular(16.r), // Aumentado de 12 a 16
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.bug_report, color: Colors.green, size: 24.w), // Aumentado de 20 a 24
                SizedBox(width: 12.w), // Aumentado de 8 a 12
                Text(
                  'Consola de Debug',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18.sp, // Aumentado de 14 a 18
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                
                // Filtro por nivel
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h), // Aumentado padding
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8.r), // Aumentado de 6 a 8
                  ),
                  child: DropdownButton<String>(
                    value: _selectedLevel,
                    dropdownColor: Colors.grey[800],
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14.sp, // Aumentado de 12 a 14
                      color: Colors.white,
                    ),
                    underline: Container(),
                    items: ['ALL', 'ERROR', 'WARNING', 'INFO', 'DEBUG'].map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLevel = value!;
                      });
                    },
                  ),
                ),
                
                SizedBox(width: 12.w), // Aumentado de 8 a 12
                
                // Auto-scroll toggle
                IconButton(
                  onPressed: () {
                    setState(() {
                      _autoScroll = !_autoScroll;
                    });
                  },
                  icon: Icon(
                    _autoScroll ? Icons.arrow_downward : Icons.arrow_downward_outlined,
                    color: _autoScroll ? Colors.green : Colors.grey,
                    size: 24.w, // Aumentado de 20 a 24
                  ),
                  tooltip: 'Auto-scroll',
                ),
                
                SizedBox(width: 8.w), // Aumentado de 4 a 8
                
                // Test database connection
                IconButton(
                  onPressed: () => _testDatabaseConnection(context),
                  icon: Icon(Icons.storage, color: Colors.blue, size: 24.w), // Aumentado de 20 a 24
                  tooltip: 'Testear conexión DB',
                ),
                
                SizedBox(width: 8.w), // Aumentado de 4 a 8
                
                // Clear logs
                IconButton(
                  onPressed: () {
                    ref.read(debugConsoleProvider.notifier).clearLogs();
                  },
                  icon: Icon(Icons.clear, color: Colors.red, size: 24.w), // Aumentado de 20 a 24
                  tooltip: 'Limpiar logs',
                ),
              ],
            ),
          ),
          
          // Contenido de los logs
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.w), // Aumentado de 12 a 16
              child: filteredLogs.isEmpty
                  ? Center(
                      child: Text(
                        'No hay logs para mostrar',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14.sp, // Aumentado de 12 a 14
                          color: Colors.grey[500],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return _buildLogEntry(log);
                      },
                    ),
            ),
          ),
          
          // Footer con estadísticas
          Container(
            padding: EdgeInsets.all(12.w), // Aumentado de 8 a 12
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.r), // Aumentado de 12 a 16
                bottomRight: Radius.circular(16.r), // Aumentado de 12 a 16
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Logs: ${filteredLogs.length}/${logs.length}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.sp, // Aumentado de 10 a 12
                    color: Colors.grey[400],
                  ),
                ),
                Spacer(),
                Text(
                  'Último: ${logs.isNotEmpty ? logs.first.timestamp : '--:--:--'}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.sp, // Aumentado de 10 a 12
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<DebugLog> _filterLogs(List<DebugLog> logs) {
    if (_selectedLevel == 'ALL') {
      return logs;
    }
    return logs.where((log) => log.level == _selectedLevel).toList();
  }
  
  Widget _buildLogEntry(DebugLog log) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h), // Aumentado de 4 a 8
      padding: EdgeInsets.all(12.w), // Aumentado de 8 a 12
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8.r), // Aumentado de 6 a 8
        border: Border(
          left: BorderSide(
            color: log.color,
            width: 3.w, // Aumentado de 2 a 3
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80.w, // Aumentado de 60 a 80
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), // Aumentado padding
                decoration: BoxDecoration(
                  color: log.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.r), // Aumentado de 4 a 6
                ),
                child: Text(
                  log.level,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.sp, // Aumentado de 10 a 12
                    fontWeight: FontWeight.bold,
                    color: log.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 12.w), // Aumentado de 8 a 12
              Text(
                log.timestamp,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.sp, // Aumentado de 10 a 12
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(width: 12.w), // Aumentado de 8 a 12
              Expanded(
                child: Text(
                  log.service,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.sp, // Aumentado de 10 a 12
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h), // Aumentado de 4 a 8
          Text(
            log.message,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13.sp, // Aumentado de 11 a 13
              color: Colors.white,
            ),
          ),
          if (log.details != null) ...[
            SizedBox(height: 8.h), // Aumentado de 4 a 8
            Container(
              padding: EdgeInsets.all(8.w), // Aumentado de 6 a 8
              decoration: BoxDecoration(
                color: Colors.grey[900]?.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6.r), // Aumentado de 4 a 6
              ),
              child: Text(
                log.details!,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.sp, // Aumentado de 9 a 11
                  color: Colors.grey[300],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  @override
  void didUpdateWidget(DebugConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_autoScroll && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _testDatabaseConnection(BuildContext context) async {
    final logger = DebugLogger();
    
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Iniciando test de conexión a la base de datos...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
      final results = await logger.testDatabaseConnection();
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test completado. Revisa la consola para detalles.'),
            backgroundColor: results['overall_status'] == 'success' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Diálogo modal para mostrar la consola de debug
class DebugConsoleDialog extends StatelessWidget {
  const DebugConsoleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: DebugConsole(),
      ),
    );
  }
}
