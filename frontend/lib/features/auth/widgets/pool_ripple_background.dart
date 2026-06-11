import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/constants/app_colors.dart';

/// Onda generada al tocar/arrastrar la pantalla.
class Ripple {
  Ripple({
    required this.center,
    required this.birth,
    this.maxRadius = 220,
    this.life = const Duration(milliseconds: 1800),
  });

  final Offset center;
  final Duration birth;
  final double maxRadius;
  final Duration life;

  /// Progreso 0..1 según el tiempo transcurrido.
  double progress(Duration now) {
    final elapsed = (now - birth).inMilliseconds;
    return (elapsed / life.inMilliseconds).clamp(0.0, 1.0);
  }

  bool isDead(Duration now) => progress(now) >= 1.0;
}

/// Burbuja que asciende de forma continua simulando el agua de la piscina.
class _Bubble {
  _Bubble({
    required this.x,
    required this.startY,
    required this.radius,
    required this.speed,
    required this.phase,
  });

  double x; // fracción 0..1 del ancho
  double startY; // fracción 0..1 del alto
  double radius;
  double speed; // fracción de alto por segundo
  double phase;
}

/// Fondo de piscina con animación continua de agua + ondas interactivas.
class PoolRippleBackground extends StatefulWidget {
  const PoolRippleBackground({
    super.key,
    this.imageAsset = 'assets/images/pool_background.png',
    this.onInteraction,
    this.mobileOptimized = false,
  });

  final String imageAsset;
  final VoidCallback? onInteraction;

  /// Aumenta contraste de ondas/burbujas y reduce el velo oscuro en pantallas pequeñas.
  final bool mobileOptimized;

  @override
  State<PoolRippleBackground> createState() => _PoolRippleBackgroundState();
}

class _PoolRippleBackgroundState extends State<PoolRippleBackground>
    with SingleTickerProviderStateMixin {
  static const int _maxRipples = 14;

  late final Ticker _ticker;
  final ValueNotifier<int> _frameTick = ValueNotifier(0);
  Duration _now = Duration.zero;
  Duration _lastAmbient = Duration.zero;

  final List<Ripple> _ripples = [];
  final List<_Bubble> _bubbles = [];
  final math.Random _random = math.Random();

  double get _intensity => widget.mobileOptimized ? 1.85 : 1.0;
  int get _ambientIntervalMs => widget.mobileOptimized ? 900 : 1600;

  @override
  void initState() {
    super.initState();
    _initBubbles();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedInitialRipples());
  }

  void _seedInitialRipples() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    final seeds = widget.mobileOptimized ? 4 : 2;
    for (var i = 0; i < seeds; i++) {
      _spawnRipple(
        Offset(
          size.width * (0.2 + _random.nextDouble() * 0.6),
          size.height * (0.25 + _random.nextDouble() * 0.5),
        ),
        maxRadius: widget.mobileOptimized ? 130 : 100,
      );
    }
  }

  void _initBubbles() {
    final count = widget.mobileOptimized ? 28 : 18;
    for (var i = 0; i < count; i++) {
      _bubbles.add(
        _Bubble(
          x: _random.nextDouble(),
          startY: _random.nextDouble(),
          radius: 1.5 + _random.nextDouble() * 3.5,
          speed: 0.015 + _random.nextDouble() * 0.04,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _onTick(Duration elapsed) {
    _now = elapsed;

    // Genera gotas ambientales automáticas para mantener vida visual.
    if ((_now - _lastAmbient).inMilliseconds > _ambientIntervalMs) {
      _lastAmbient = _now;
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final size = box.size;
        _spawnRipple(
          Offset(
            _random.nextDouble() * size.width,
            size.height * (0.2 + _random.nextDouble() * 0.6),
          ),
          maxRadius: 90 + _random.nextDouble() * 60,
        );
      }
    }

    _ripples.removeWhere((r) => r.isDead(_now));
    _frameTick.value++;
  }

  void _spawnRipple(Offset position, {double maxRadius = 220}) {
    if (_ripples.length >= _maxRipples) {
      _ripples.removeAt(0);
    }
    _ripples.add(Ripple(center: position, birth: _now, maxRadius: maxRadius));
    widget.onInteraction?.call();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frameTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (d) => _spawnRipple(d.localPosition),
      onPanUpdate: (d) => _spawnRipple(d.localPosition, maxRadius: 150),
      child: ValueListenableBuilder<int>(
        valueListenable: _frameTick,
        builder: (context, _, __) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                widget.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _WaterGradientFallback(),
              ),
              // Capa de animación continua de agua + ondas + burbujas.
              RepaintBoundary(
                child: CustomPaint(
                  painter: _WaterPainter(
                    ripples: List<Ripple>.from(_ripples),
                    bubbles: _bubbles,
                    now: _now,
                    intensity: _intensity,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              // Degradado para legibilidad del contenido encima.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.mobileOptimized
                        ? [
                            AppColors.background.withValues(alpha: 0.14),
                            AppColors.background.withValues(alpha: 0.34),
                            AppColors.background.withValues(alpha: 0.58),
                          ]
                        : [
                            AppColors.background.withValues(alpha: 0.30),
                            AppColors.background.withValues(alpha: 0.55),
                            AppColors.background.withValues(alpha: 0.78),
                          ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WaterGradientFallback extends StatelessWidget {
  const _WaterGradientFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.background,
          ],
        ),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter({
    required this.ripples,
    required this.bubbles,
    required this.now,
    this.intensity = 1.0,
  });

  final List<Ripple> ripples;
  final List<_Bubble> bubbles;
  final Duration now;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = now.inMilliseconds / 1000.0;

    _paintCaustics(canvas, size, t);
    _paintBubbles(canvas, size, t);
    _paintRipples(canvas, size);
  }

  /// Bandas de luz onduladas que se desplazan: efecto cáustico del agua.
  void _paintCaustics(Canvas canvas, Size size, double t) {
    const bands = 5;
    for (var i = 0; i < bands; i++) {
      final phase = t * 0.6 + i * 1.3;
      final yBase = size.height * (i + 0.5) / bands;
      final path = Path();
      path.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 24) {
        final y = yBase +
            math.sin((x / size.width * math.pi * 3) + phase) * 18 +
            math.cos((x / size.width * math.pi * 5) - phase * 0.7) * 10;
        path.lineTo(x, y);
      }

      final shimmer = (math.sin(phase) * 0.5 + 0.5);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * intensity.clamp(1.0, 2.0)
        ..color = AppColors.accent.withValues(
          alpha: (0.05 + shimmer * 0.07) * intensity,
        )
        ..blendMode = BlendMode.screen
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, paint);
    }
  }

  /// Burbujas que ascienden de forma continua.
  void _paintBubbles(Canvas canvas, Size size, double t) {
    for (final b in bubbles) {
      // Posición vertical: sube y se reinicia (módulo 1).
      final y = (b.startY - t * b.speed) % 1.0;
      final yy = y < 0 ? y + 1.0 : y;
      final wobble = math.sin(t * 1.5 + b.phase) * 0.012;
      final cx = ((b.x + wobble) % 1.0) * size.width;
      final cy = yy * size.height;

      final fade = (math.sin(yy * math.pi)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withValues(
          alpha: (0.10 + fade * 0.18) * intensity,
        )
        ..blendMode = BlendMode.screen;
      canvas.drawCircle(Offset(cx, cy), b.radius * intensity.clamp(1.0, 1.4), paint);

      // Brillo interno.
      final highlight = Paint()
        ..color = AppColors.primaryLight.withValues(alpha: 0.10 * fade * intensity)
        ..blendMode = BlendMode.screen;
      canvas.drawCircle(
        Offset(cx - b.radius * 0.3, cy - b.radius * 0.3),
        b.radius * 0.5,
        highlight,
      );
    }
  }

  /// Ondas concéntricas visibles al tocar/arrastrar.
  void _paintRipples(Canvas canvas, Size size) {
    for (final ripple in ripples) {
      final p = ripple.progress(now);
      if (p <= 0 || p >= 1) continue;

      final fade = (1 - p);
      // Tres anillos expandiéndose con desfase para sensación de profundidad.
      for (var ring = 0; ring < 3; ring++) {
        final ringProgress = (p - ring * 0.12).clamp(0.0, 1.0);
        if (ringProgress <= 0) continue;
        final radius = ripple.maxRadius * ringProgress;
        final alpha = fade * (1 - ring * 0.28) * 0.55 * intensity;
        if (alpha <= 0.01) continue;

        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (3.6 * fade * intensity.clamp(1.0, 1.5)).clamp(0.8, 4.2)
          ..color = AppColors.accent.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..blendMode = BlendMode.screen
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(ripple.center, radius, paint);
      }

      // Destello central que se desvanece.
      if (p < 0.4) {
        final glow = Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.primaryLight.withValues(
                alpha: 0.35 * (1 - p / 0.4) * intensity,
              ),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: ripple.center, radius: 40),
          )
          ..blendMode = BlendMode.screen;
        canvas.drawCircle(ripple.center, 40, glow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) => true;
}
