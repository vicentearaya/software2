import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                  constraints: BoxConstraints(maxWidth: wide ? 1040 : 520),
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
        _CopyBlock(),
        const SizedBox(height: 24),
        const _ParameterCardsRow(),
        const SizedBox(height: 28),
        _buildCtaButtons(context),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CopyBlock(),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: _buildCtaButtons(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        const Expanded(
          flex: 48,
          child: _ParameterCardsRow(),
        ),
      ],
    );
  }

  Widget _buildCtaButtons(BuildContext context) {
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

class _CopyBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BrandPill(),
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
        const SizedBox(height: 20),
        Text(
          AppStrings.welcomeAppIntro,
          style: GoogleFonts.interTight(
            fontSize: 16,
            height: 1.55,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 22),
        _SectionTitle(AppStrings.welcomeFunctionsTitle),
        const SizedBox(height: 10),
        const _BulletList(items: AppStrings.welcomeFunctions),
        const SizedBox(height: 20),
        _SectionTitle(AppStrings.welcomeSolvesTitle),
        const SizedBox(height: 10),
        const _BulletList(items: AppStrings.welcomeSolves),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.syne(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryLight,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.interTight(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ParameterCardsRow extends StatelessWidget {
  const _ParameterCardsRow();

  @override
  Widget build(BuildContext context) {
    final phCard = _ParameterInfoCard(
      title: AppStrings.welcomePhTitle,
      icon: Icons.science_outlined,
      accentColor: AppColors.accent,
      idealRange: '7,2 – 7,6',
      what: AppStrings.welcomePhWhat,
      measure: AppStrings.welcomePhMeasure,
      indicates: AppStrings.welcomePhIndicates,
    );

    final chlorineCard = _ParameterInfoCard(
      title: AppStrings.welcomeChlorineTitle,
      icon: Icons.bubble_chart_outlined,
      accentColor: AppColors.statusGood,
      idealRange: '1 – 3 ppm',
      what: AppStrings.welcomeChlorineWhat,
      measure: AppStrings.welcomeChlorineMeasure,
      indicates: AppStrings.welcomeChlorineIndicates,
    );

    return Column(
      children: [
        phCard,
        const SizedBox(height: 14),
        chlorineCard,
      ],
    );
  }
}

class _ParameterInfoCard extends StatelessWidget {
  const _ParameterInfoCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.idealRange,
    required this.what,
    required this.measure,
    required this.indicates,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final String idealRange;
  final String what;
  final String measure;
  final String indicates;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
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
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.syne(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.22)),
                ),
                child: Text(
                  'Ideal: $idealRange',
                  style: GoogleFonts.interTight(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CardSection(
            label: AppStrings.welcomeCardWhat,
            text: what,
          ),
          const SizedBox(height: 12),
          _CardSection(
            label: AppStrings.welcomeCardMeasure,
            text: measure,
          ),
          const SizedBox(height: 12),
          _CardSection(
            label: AppStrings.welcomeCardIndicates,
            text: indicates,
          ),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.interTight(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: GoogleFonts.interTight(
            fontSize: 13.5,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
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
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF060A12),
          Color(0xFF0A1424),
          Color(0xFF0D1A2E),
        ],
        stops: [0.0, 0.45, 1.0],
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
  const _BrandPill();

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
              const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 20),
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
