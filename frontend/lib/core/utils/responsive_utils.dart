import 'package:flutter/material.dart';

/// Utilidades para layouts adaptativos en móvil, tablet y web.
class ResponsiveUtils {
  ResponsiveUtils._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  /// Padding horizontal según el ancho de pantalla.
  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 80);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 40);
    }
    return const EdgeInsets.symmetric(horizontal: 20);
  }
}
