import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Recuadro flotante del hero: muestra una imagen de la piscina.
/// Si el asset no existe, dibuja un fallback estilizado.
class DevicePlaceholderWidget extends StatelessWidget {
  const DevicePlaceholderWidget({super.key});

  static const String assetPath = 'assets/images/pool_hero.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.surface),
          Image.asset(
            assetPath,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => const _HeroFallback(),
          ),
          // Borde sutil + degradado inferior para integrarlo con el tema.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.pool_rounded,
              color: AppColors.primaryLight,
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'CleanPool',
            style: GoogleFonts.syne(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
