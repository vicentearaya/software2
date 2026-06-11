import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/responsive_utils.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/main_screen.dart';
import 'widgets/device_placeholder_widget.dart';
import 'widgets/pool_ripple_background.dart';
import 'widgets/welcome_cta_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Animación de entrada: aparece desvaneciéndose y subiendo al cargar.
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoLogin());
  }

  Future<void> _tryAutoLogin() async {
    final authService = AuthService();
    var shouldAutoLogin = false;
    try {
      shouldAutoLogin = await authService
          .shouldAutoLogin()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (_) {
      shouldAutoLogin = false;
    }

    if (!mounted || !shouldAutoLogin) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: PoolRippleBackground(mobileOptimized: isMobile),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = ResponsiveUtils.isMobile(context);
                return Padding(
                  padding: ResponsiveUtils.pagePadding(context),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 900,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: FadeTransition(
                        opacity: _entranceFade,
                        child: SlideTransition(
                          position: _entranceSlide,
                          child: SizedBox(
                            height: constraints.maxHeight,
                            width: double.infinity,
                            child: isMobile
                                ? _buildMobileLayout(context)
                                : _buildWebLayout(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceImage(
    BuildContext context, {
    required double heightFactor,
    double maxHeightFactor = 0.4,
  }) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final imageHeight = (screenHeight * heightFactor).clamp(
      120.0,
      screenHeight * maxHeightFactor,
    );

    return Hero(
      tag: 'cleanpool-device',
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: child,
          );
        },
        child: SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: const DevicePlaceholderWidget(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 1),
        const Center(child: WelcomeBrandPill()),
        const SizedBox(height: 18),
        _buildDeviceImage(
          context,
          heightFactor: 0.30,
          maxHeightFactor: 0.36,
        ),
        const SizedBox(height: 24),
        _buildTagline(centered: true),
        const SizedBox(height: 30),
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: _buildAuthButtons(context),
          ),
        ),
        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const WelcomeBrandPill(),
              const SizedBox(height: 20),
              _buildTagline(),
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: _buildAuthButtons(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 48,
          child: Center(
            child: _buildDeviceImage(
              context,
              heightFactor: 0.45,
              maxHeightFactor: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagline({bool centered = false}) {
    final alignment =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          AppStrings.welcomeHeadline,
          textAlign: textAlign,
          style: GoogleFonts.syne(
            fontSize: centered ? 32 : 38,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.accent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            AppStrings.welcomeTitle,
            textAlign: textAlign,
            style: GoogleFonts.syne(
              fontSize: centered ? 17 : 20,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WelcomePrimaryCta(
          label: AppStrings.login,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
        ),
        const SizedBox(height: 14),
        WelcomeSecondaryCta(
          label: AppStrings.welcomeRegister,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
        ),
      ],
    );
  }
}
