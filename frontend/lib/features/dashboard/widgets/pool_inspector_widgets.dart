import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../pool_data.dart';

class PoolHeroCard extends StatelessWidget {
  const PoolHeroCard({
    super.key,
    required this.pool,
    required this.litrosStr,
    this.temperatureC,
  });

  final PoolData pool;
  final String litrosStr;
  final double? temperatureC;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
        ),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pool_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pool.nombre,
                      style: GoogleFonts.syne(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      pool.esInterior ? 'Piscina Interior' : 'Piscina Exterior',
                      style: GoogleFonts.interTight(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.accent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capacidad total',
                      style: GoogleFonts.interTight(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      litrosStr,
                      style: GoogleFonts.syne(
                        color: AppColors.accent,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.thermostat_rounded,
                color: AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                temperatureC != null ? '${temperatureC!.toStringAsFixed(1)}°C' : '-',
                style: GoogleFonts.syne(
                  color: AppColors.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PoolVisualSection extends StatefulWidget {
  const PoolVisualSection({super.key, required this.pool});
  final PoolData pool;

  @override
  State<PoolVisualSection> createState() => _PoolVisualSectionState();
}

class _PoolVisualSectionState extends State<PoolVisualSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.view_in_ar_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Vista de la piscina',
                style: GoogleFonts.syne(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRect(
            child: SizedBox(
              width: double.infinity,
              height: 160,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) =>
                    CustomPaint(painter: PoolWaterPainter(animValue: _ctrl.value)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PoolWaterPainter extends CustomPainter {
  PoolWaterPainter({required this.animValue});
  final double animValue;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const border = 12.0;
    const r = 14.0;
    const ri = 8.0;

    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(r),
    );
    canvas.drawRRect(
      outerRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF112240)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final tilePaint = Paint()
      ..color = const Color(0xFF2A4A70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (double y = border; y < h - border; y += border) {
      canvas.drawLine(Offset(0, y), Offset(w, y), tilePaint);
    }
    for (double x = border; x < w - border; x += border) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), tilePaint);
    }

    final waterRect = Rect.fromLTWH(
      border,
      border,
      w - border * 2,
      h - border * 2,
    );
    final waterRRect = RRect.fromRectAndRadius(
      waterRect,
      const Radius.circular(ri),
    );

    final shimmer = (math.sin(animValue * 2 * math.pi) + 1) / 2;
    final c1 = Color.lerp(
      const Color(0xFF1565C0),
      const Color(0xFF0288D1),
      shimmer,
    )!;
    final c2 = Color.lerp(
      const Color(0xFF29B6F6),
      const Color(0xFF00ACC1),
      shimmer,
    )!;

    canvas.drawRRect(
      waterRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ).createShader(waterRect),
    );

    canvas.save();
    canvas.clipRRect(waterRRect);

    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const waveCount = 4;
    for (int i = 0; i < waveCount; i++) {
      final yFrac = ((animValue + i / waveCount) % 1.0);
      final yPos = waterRect.top + yFrac * waterRect.height;
      final path = Path();
      path.moveTo(waterRect.left, yPos);
      const segments = 4;
      final segW = waterRect.width / segments;
      for (int s = 0; s < segments; s++) {
        final x1 = waterRect.left + s * segW + segW * 0.25;
        final x2 = waterRect.left + s * segW + segW * 0.75;
        final x3 = waterRect.left + (s + 1) * segW;
        final crest = (s % 2 == 0) ? -5.0 : 5.0;
        path.cubicTo(x1, yPos + crest, x2, yPos - crest, x3, yPos);
      }
      canvas.drawPath(path, wavePaint);
    }

    final reflectShift = animValue * waterRect.width * 0.3;
    final reflectPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.07),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(waterRect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        waterRect.left + reflectShift,
        waterRect.top,
        waterRect.width * 0.4,
        waterRect.height,
      ),
      reflectPaint,
    );

    canvas.restore();

    final ladderX = waterRect.right - 14;
    final ladderPaint = Paint()
      ..color = const Color(0xFF90CAF9).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(ladderX - 5, border - 4),
      Offset(ladderX - 5, waterRect.top + 22),
      ladderPaint,
    );
    canvas.drawLine(
      Offset(ladderX + 5, border - 4),
      Offset(ladderX + 5, waterRect.top + 22),
      ladderPaint,
    );
    for (int s = 0; s < 3; s++) {
      final sy = waterRect.top + 4 + s * 9.0;
      canvas.drawLine(
        Offset(ladderX - 5, sy),
        Offset(ladderX + 5, sy),
        ladderPaint,
      );
    }

    canvas.drawRRect(
      outerRect,
      Paint()
        ..color = const Color(0xFF4FC3F7).withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      waterRRect,
      Paint()
        ..color = const Color(0xFF80DEEA).withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(PoolWaterPainter old) => old.animValue != animValue;
}

class DashboardInfoRow extends StatelessWidget {
  const DashboardInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.interTight(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: GoogleFonts.syne(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PoolDimensionsStrip extends StatelessWidget {
  const PoolDimensionsStrip({super.key, required this.pool});

  final PoolData pool;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CompactDimension(label: 'Largo', value: '${pool.largo} m'),
          const _StripDivider(),
          _CompactDimension(label: 'Ancho', value: '${pool.ancho} m'),
          const _StripDivider(),
          _CompactDimension(label: 'Prof.', value: '${pool.profundidad} m'),
          const _StripDivider(),
          _CompactDimension(
            label: 'Vol.',
            value: '${pool.volumenM3.toStringAsFixed(1)} m³',
          ),
        ],
      ),
    );
  }
}

class _CompactDimension extends StatelessWidget {
  const _CompactDimension({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.syne(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.interTight(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _StripDivider extends StatelessWidget {
  const _StripDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppColors.border);
  }
}
