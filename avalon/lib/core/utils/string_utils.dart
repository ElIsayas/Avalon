extension StringUtils on String {
  String get iniciales {
    final value = trim();
    if (value.isEmpty) return '?';

    final partes = value.split(RegExp(r'\s+'));
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }

    return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
  }
}
