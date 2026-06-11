import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Sección de detalle (qué es / cómo se mide / qué indica) dentro de una tarjeta.
class _Detail {
  const _Detail(this.label, this.text);
  final String label;
  final String text;
}

/// Definición de una tarjeta del carrusel educativo.
class _FeatureSlide {
  const _FeatureSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.idealRange,
    this.intro,
    this.details = const [],
    this.bullets = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? idealRange;
  final String? intro;
  final List<_Detail> details;
  final List<String> bullets;
}

/// Carrusel horizontal con control manual (flechas + puntos)
/// y tarjetas cuyo contenido se desplaza para no cortarse.
class WelcomeFeatureCarousel extends StatefulWidget {
  const WelcomeFeatureCarousel({
    super.key,
    this.viewportFraction = 1.0,
    this.height = 320,
    this.onWaterBackground = false,
  });

  final double viewportFraction;
  final double height;

  /// Estilo translúcido para paneles sobre el fondo animado de la piscina.
  final bool onWaterBackground;

  @override
  State<WelcomeFeatureCarousel> createState() => _WelcomeFeatureCarouselState();
}

class _WelcomeFeatureCarouselState extends State<WelcomeFeatureCarousel> {
  static final List<_FeatureSlide> _slides = [
    _FeatureSlide(
      title: AppStrings.welcomeFunctionsTitle,
      subtitle: 'Monitorea, alerta y gestiona tu piscina',
      icon: Icons.dashboard_customize_outlined,
      accentColor: AppColors.primary,
      intro: AppStrings.welcomeAppIntro,
      bullets: AppStrings.welcomeFunctions,
    ),
    _FeatureSlide(
      title: AppStrings.welcomePhTitle,
      subtitle: 'Equilibrio ácido-base del agua',
      icon: Icons.science_outlined,
      accentColor: AppColors.accent,
      idealRange: '7,2 – 7,6',
      details: const [
        _Detail(AppStrings.welcomeCardWhat, AppStrings.welcomePhWhat),
        _Detail(AppStrings.welcomeCardMeasure, AppStrings.welcomePhMeasure),
        _Detail(AppStrings.welcomeCardIndicates, AppStrings.welcomePhIndicates),
      ],
    ),
    _FeatureSlide(
      title: AppStrings.welcomeChlorineTitle,
      subtitle: 'Desinfección y seguridad microbiológica',
      icon: Icons.bubble_chart_outlined,
      accentColor: AppColors.statusGood,
      idealRange: '1 – 3 ppm',
      details: const [
        _Detail(AppStrings.welcomeCardWhat, AppStrings.welcomeChlorineWhat),
        _Detail(AppStrings.welcomeCardMeasure, AppStrings.welcomeChlorineMeasure),
        _Detail(AppStrings.welcomeCardIndicates, AppStrings.welcomeChlorineIndicates),
      ],
    ),
    _FeatureSlide(
      title: AppStrings.welcomeOrpTitle,
      subtitle: 'Capacidad desinfectante del agua',
      icon: Icons.bolt_outlined,
      accentColor: AppColors.primaryLight,
      idealRange: '650 – 750 mV',
      details: const [
        _Detail(AppStrings.welcomeCardWhat, AppStrings.welcomeOrpWhat),
        _Detail(AppStrings.welcomeCardMeasure, AppStrings.welcomeOrpMeasure),
        _Detail(AppStrings.welcomeCardIndicates, AppStrings.welcomeOrpIndicates),
      ],
    ),
    _FeatureSlide(
      title: AppStrings.welcomeSolvesTitle,
      subtitle: 'Problemas que CleanPool resuelve',
      icon: Icons.verified_outlined,
      accentColor: AppColors.primaryLight,
      bullets: AppStrings.welcomeSolves,
    ),
  ];

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction);
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage && mounted) {
      setState(() => _currentPage = page);
    }
  }

  void _goTo(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() => _goTo((_currentPage + 1) % _slides.length);
  void _prev() => _goTo((_currentPage - 1 + _slides.length) % _slides.length);

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderControls(),
        const SizedBox(height: 12),
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  final page = _pageController.hasClients
                      ? (_pageController.page ?? _currentPage.toDouble())
                      : _currentPage.toDouble();
                  final delta = (page - index).abs().clamp(0.0, 1.0);
                  final scale = 1 - (delta * 0.05);
                  final opacity = (1 - (delta * 0.35)).clamp(0.65, 1.0);
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    right: widget.viewportFraction < 1 ? 12 : 0,
                  ),
                  child: _FeatureCard(
                    slide: _slides[index],
                    isActive: index == _currentPage,
                    onWaterBackground: widget.onWaterBackground,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildDots(),
      ],
    );
  }

  Widget _buildHeaderControls() {
    final muted = widget.onWaterBackground;
    return Row(
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          size: 16,
          color: AppColors.primaryLight.withValues(alpha: muted ? 0.75 : 0.9),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Cómo funciona CleanPool',
            style: GoogleFonts.interTight(
              fontSize: muted ? 12 : 14,
              fontWeight: FontWeight.w600,
              letterSpacing: muted ? 0.3 : 0,
              color: muted
                  ? AppColors.textPrimary.withValues(alpha: 0.72)
                  : AppColors.textPrimary,
            ),
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: _prev,
          onWaterBackground: widget.onWaterBackground,
        ),
        const SizedBox(width: 8),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: _next,
          onWaterBackground: widget.onWaterBackground,
        ),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final active = index == _currentPage;
        return GestureDetector(
          onTap: () => _goTo(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active
                  ? (widget.onWaterBackground
                      ? AppColors.primaryLight.withValues(alpha: 0.9)
                      : AppColors.primary)
                  : AppColors.textMuted.withValues(
                      alpha: widget.onWaterBackground ? 0.45 : 1,
                    ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

/// Botón circular para avanzar/retroceder (funciona con mouse en web).
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.onTap,
    this.onWaterBackground = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool onWaterBackground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onWaterBackground
          ? AppColors.background.withValues(alpha: 0.35)
          : AppColors.surfaceElevated.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: onWaterBackground
                  ? Colors.white.withValues(alpha: 0.16)
                  : AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            icon,
            color: onWaterBackground
                ? AppColors.textPrimary.withValues(alpha: 0.85)
                : AppColors.primaryLight,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.slide,
    required this.isActive,
    this.onWaterBackground = false,
  });

  final _FeatureSlide slide;
  final bool isActive;
  final bool onWaterBackground;

  @override
  Widget build(BuildContext context) {
    final overlay = onWaterBackground;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: overlay
            ? AppColors.background.withValues(alpha: isActive ? 0.58 : 0.44)
            : AppColors.surfaceElevated.withValues(alpha: isActive ? 0.96 : 0.78),
        borderRadius: BorderRadius.circular(overlay ? 16 : 20),
        border: Border.all(
          color: overlay
              ? Colors.white.withValues(alpha: isActive ? 0.18 : 0.10)
              : slide.accentColor.withValues(alpha: isActive ? 0.45 : 0.2),
          width: 1,
        ),
        boxShadow: overlay
            ? null
            : [
                if (isActive)
                  BoxShadow(
                    color: slide.accentColor.withValues(alpha: 0.15),
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
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: slide.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: slide.accentColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(slide.icon, color: slide.accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slide.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.interTight(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (slide.idealRange != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: slide.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: slide.accentColor.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    'Ideal: ${slide.idealRange}',
                    style: GoogleFonts.interTight(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: slide.accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Cuerpo desplazable: evita que el contenido se corte.
          Expanded(
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0.0, 0.92, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slide.intro != null)
          Text(
            slide.intro!,
            style: GoogleFonts.interTight(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        if (slide.intro != null && slide.bullets.isNotEmpty)
          const SizedBox(height: 12),
        for (final detail in slide.details) ...[
          _DetailBlock(detail: detail),
          const SizedBox(height: 10),
        ],
        if (slide.bullets.isNotEmpty)
          for (final bullet in slide.bullets)
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
                      decoration: BoxDecoration(
                        color: slide.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: GoogleFonts.interTight(
                        fontSize: 13,
                        height: 1.45,
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

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.detail});

  final _Detail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.label,
          style: GoogleFonts.interTight(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail.text,
          style: GoogleFonts.interTight(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
