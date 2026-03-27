import 'package:intl/intl.dart';

extension DateFormattingUtils on DateTime {
  String toShortDate() => DateFormat('dd/MM/yyyy').format(this);

  String toShortDateTime() => DateFormat('dd/MM/yyyy HH:mm').format(this);

  String toRelativeShort() {
    final diff = DateTime.now().difference(this);
    if (diff.inDays > 0) return 'Hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes}m';
    return 'Ahora';
  }
}
