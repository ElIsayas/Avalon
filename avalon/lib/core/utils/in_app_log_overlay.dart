import 'package:flutter/material.dart';

import 'logger.dart';

const bool kShowInAppLogs = false;

class InAppLogOverlay extends StatelessWidget {
  final Widget child;

  const InAppLogOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kShowInAppLogs) return child;
    return Stack(
      children: [
        child,
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: SafeArea(
            child: IgnorePointer(
              ignoring: true,
              child: ValueListenableBuilder<List<InAppLogEntry>>(
                valueListenable: InAppLogController.instance.entries,
                builder: (context, entries, _) {
                  if (entries.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: entries
                        .map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _InAppLogCard(entry: entry),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InAppLogCard extends StatelessWidget {
  final InAppLogEntry entry;

  const _InAppLogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(entry.type);
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.title,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              entry.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (entry.location != null) ...[
              const SizedBox(height: 4),
              Text(
                entry.location!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.location,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogPalette {
  final Color background;
  final Color border;
  final Color title;
  final Color text;
  final Color location;

  const _LogPalette({
    required this.background,
    required this.border,
    required this.title,
    required this.text,
    required this.location,
  });
}

_LogPalette _paletteFor(InAppLogType type) {
  switch (type) {
    case InAppLogType.error:
      return const _LogPalette(
        background: Color(0xFFD32F2F),
        border: Color(0xFFB71C1C),
        title: Colors.white,
        text: Color(0xFFFFEBEE),
        location: Color(0xFFFFCDD2),
      );
    case InAppLogType.success:
      return const _LogPalette(
        background: Color(0xFF2E7D32),
        border: Color(0xFF1B5E20),
        title: Colors.white,
        text: Color(0xFFE8F5E9),
        location: Color(0xFFC8E6C9),
      );
    case InAppLogType.warning:
      return const _LogPalette(
        background: Color(0xFFEF6C00),
        border: Color(0xFFE65100),
        title: Colors.white,
        text: Color(0xFFFFF3E0),
        location: Color(0xFFFFE0B2),
      );
    case InAppLogType.info:
      return const _LogPalette(
        background: Color(0xFF1565C0),
        border: Color(0xFF0D47A1),
        title: Colors.white,
        text: Color(0xFFE3F2FD),
        location: Color(0xFFBBDEFB),
      );
  }
}
