import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart' as rive;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';

/// Asset Rive (solo móvil/escritorio nativo): ejemplo [rive-flutter](https://github.com/rive-app/rive-flutter) (MIT), tema agua.
const String _kWelcomeRiveAsset = 'assets/rive/welcome.riv';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// En **web** Rive suele mostrar demos raros o placeholders; usamos olas en Canvas.
  /// En iOS/Android/desktop usamos Rive con asset acuático.
  rive.FileLoader? _riveLoader;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _riveLoader = rive.FileLoader.fromAsset(
        _kWelcomeRiveAsset,
        riveFactory: rive.Factory.flutter,
      );
    }
  }

  @override
  void dispose() {
    _riveLoader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final wide = w >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _WelcomeBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: w >= 600 ? 40 : 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1040 : 480),
                  child: wide ? _buildWideLayout(context) : _buildNarrowLayout(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroRiveCard(height: 200, fileLoader: _riveLoader),
        const SizedBox(height: 28),
        _CopyBlock(context),
        const SizedBox(height: 28),
        _CtaButtons(context),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 54,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CopyBlock(context),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _CtaButtons(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          flex: 46,
          child: Align(
            alignment: Alignment.topCenter,
            child: _HeroRiveCard(height: 360, fileLoader: _riveLoader),
          ),
        ),
      ],
    );
  }

  Widget _CopyBlock(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textMaxWidth = constraints.maxWidth > 620 ? 580.0 : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BrandPill(),
            const SizedBox(height: 18),
            Text(
              AppStrings.welcomeHeadline,
              style: GoogleFonts.syne(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.accent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                AppStrings.welcomeTitle,
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: textMaxWidth,
              child: _WelcomeBodyText(),
            ),
          ],
        );
      },
    );
  }

  Widget _CtaButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrimaryCta(
          label: AppStrings.login,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
        ),
        const SizedBox(height: 14),
        _SecondaryCta(
          label: AppStrings.welcomeRegister,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
        ),
      ],
    );
  }
}

/// Cuerpo de la bienvenida: varios párrafos con ritmo visual claro.
class _WelcomeBodyText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final paras = AppStrings.welcomeBodyParagraphs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paras.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Text(
            paras[i],
            style: GoogleFonts.interTight(
              fontSize: i == 0 ? 17 : 15.5,
              height: 1.62,
              fontWeight: i == 0 ? FontWeight.w500 : FontWeight.w400,
              color: i == 0 ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _WelcomeBackdrop extends StatelessWidget {
  const _WelcomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackdropPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF060A12),
          const Color(0xFF0A1424),
          const Color(0xFF0D1A2E),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    void orb(double cx, double cy, double r, Color c) {
      final p = Paint()
        ..shader = RadialGradient(
          colors: [c.withValues(alpha: 0.45), c.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, p);
    }

    orb(size.width * 0.85, size.height * 0.08, size.width * 0.35, AppColors.primary);
    orb(size.width * 0.1, size.height * 0.55, size.width * 0.42, AppColors.accent);
    orb(size.width * 0.7, size.height * 0.88, size.width * 0.28, const Color(0xFF1A6FA3));

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BrandPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceElevated.withValues(alpha: 0.65),
                AppColors.surface.withValues(alpha: 0.35),
              ],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.appName,
                style: GoogleFonts.syne(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'IoT',
                  style: GoogleFonts.interTight(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroRiveCard extends StatelessWidget {
  const _HeroRiveCard({
    required this.height,
    this.fileLoader,
  });

  final double height;
  final rive.FileLoader? fileLoader;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceElevated,
                    const Color(0xFF0F1729),
                    AppColors.surface.withValues(alpha: 0.95),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: const Color(0xFF080C14),
                    child: fileLoader == null
                        ? const _AnimatedWaterHero()
                        : _RiveStage(fileLoader: fileLoader!, height: height),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiveStage extends StatelessWidget {
  const _RiveStage({
    required this.fileLoader,
    required this.height,
  });

  final rive.FileLoader fileLoader;
  final double height;

  @override
  Widget build(BuildContext context) {
    return rive.RiveWidgetBuilder(
      fileLoader: fileLoader,
      builder: (context, state) {
        return switch (state) {
          rive.RiveLoading() => Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary.withValues(alpha: 0.85),
                ),
              ),
            ),
          rive.RiveFailed() => _DecorativeWaterFallback(height: height),
          rive.RiveLoaded(:final controller) => rive.RiveWidget(
              controller: controller,
              fit: rive.Fit.contain,
              alignment: Alignment.center,
            ),
        };
      },
    );
  }
}

/// Olas animadas en puro Flutter (reemplazo estable en web frente a glitches de Rive).
class _AnimatedWaterHero extends StatefulWidget {
  const _AnimatedWaterHero();

  @override
  State<_AnimatedWaterHero> createState() => _AnimatedWaterHeroState();
}

class _AnimatedWaterHeroState extends State<_AnimatedWaterHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _WavesPainter(phase: _controller.value * 2 * math.pi),
        );
      },
    );
  }
}

class _WavesPainter extends CustomPainter {
  _WavesPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final center = Offset(w * 0.5, h * 0.48);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.28),
          AppColors.accent.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.35));
    canvas.drawCircle(center, w * 0.35, glow);

    for (var i = 0; i < 4; i++) {
      final path = Path();
      final y0 = h * (0.38 + i * 0.09);
      final amp = 5.0 + i * 3.5;
      final freq = 0.014 + i * 0.003;
      final shift = phase * (1.0 + i * 0.15) + i * 0.8;
      path.moveTo(0, y0);
      for (double x = 0; x <= w; x += 4) {
        final y = y0 + math.sin(x * freq + shift) * amp;
        path.lineTo(x, y);
      }
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + i * 0.35
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primaryLight.withValues(alpha: 0.22 - i * 0.035);
      canvas.drawPath(path, stroke);
    }

    final drop = Path()
      ..addOval(
        Rect.fromCenter(
          center: center,
          width: w * 0.14,
          height: w * 0.2,
        ),
      );
    canvas.drawPath(
      drop,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      drop,
      Paint()
        ..color = AppColors.primaryLight.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) => oldDelegate.phase != phase;
}

class _DecorativeWaterFallback extends StatelessWidget {
  const _DecorativeWaterFallback({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: height * 0.42,
          height: height * 0.42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.35),
                AppColors.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Icon(
          Icons.waves_rounded,
          size: height * 0.22,
          color: AppColors.primaryLight.withValues(alpha: 0.9),
        ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E8BC3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryCta extends StatelessWidget {
  const _SecondaryCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
