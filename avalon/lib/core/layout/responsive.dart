import 'package:flutter/material.dart';

/// Breakpoint a partir del cual se considera "desktop"
const double kDesktopBreakpoint = 720;

/// Ancho máximo del panel de contenido en escritorio
const double kDesktopContentMaxWidth = 900;

/// Ancho del sidebar de navegación en escritorio
const double kSidebarWidth = 220;

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= kDesktopBreakpoint;

bool isMobile(BuildContext context) => !isDesktop(context);

extension ResponsiveContext on BuildContext {
  bool get isDesktop => MediaQuery.of(this).size.width >= kDesktopBreakpoint;
  bool get isMobile  => !this.isDesktop;
  double get screenWidth  => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  const Responsive({super.key, required this.mobile, required this.desktop});
  @override
  Widget build(BuildContext context) =>
      context.isDesktop ? desktop : mobile;
}

class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = kDesktopContentMaxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: child,
        ),
      ),
    );
  }
}
