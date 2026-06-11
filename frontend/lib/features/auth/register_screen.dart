import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../shared/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/widgets/main_screen.dart';
import 'widgets/pool_ripple_background.dart';
import 'widgets/welcome_feature_carousel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.register(
      _nameController.text.trim(),
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pool_data');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      AppUtils.showSnackBar(context, result['message'], isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    return Scaffold(
      body: SafeArea(
        child: isMobile ? _buildMobile() : _buildWide(),
      ),
    );
  }

  /// Móvil: formulario apilado y, debajo, el carrusel educativo (sin split).
  Widget _buildMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _formKey,
            child: _buildFormContent(topSpacing: 20, headerGap: 40),
          ),
          const SizedBox(height: 16),
          _buildOnboardingCard(
            carouselHeight: 300,
            compact: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Escritorio: formulario a la izquierda y onboarding educativo a la derecha.
  Widget _buildWide() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: _buildFormContent(topSpacing: 0, headerGap: 34),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: _buildOnboardingPanel(),
        ),
      ],
    );
  }

  Widget _buildFormContent({
    required double topSpacing,
    required double headerGap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topSpacing),
        _buildBackButton(),
        const SizedBox(height: 24),
        _buildHeader(),
        SizedBox(height: headerGap),
        _buildNameField(),
        const SizedBox(height: 16),
        _buildUsernameField(),
        const SizedBox(height: 16),
        _buildEmailField(),
        const SizedBox(height: 16),
        _buildPasswordField(),
        const SizedBox(height: 16),
        _buildConfirmPasswordField(),
        const SizedBox(height: 32),
        _buildRegisterButton(),
        const SizedBox(height: 24),
        _buildLoginLink(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOnboardingPanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const PoolRippleBackground(imageAsset: 'assets/images/pool_background.png'),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.10),
                AppColors.background.withValues(alpha: 0.55),
                AppColors.background.withValues(alpha: 0.72),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
            child: _buildOnboardingCard(
              carouselHeight: ResponsiveUtils.isDesktop(context) ? 340 : 300,
            ),
          ),
        ),
      ],
    );
  }

  /// Tarjeta unificada: encabezado + carrusel en un solo bloque coherente.
  Widget _buildOnboardingCard({
    required double carouselHeight,
    bool compact = false,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? double.infinity : 500),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          compact ? 18 : 28,
          compact ? 20 : 28,
          compact ? 18 : 28,
          compact ? 18 : 24,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(compact ? 20 : 28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: compact ? 18 : 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOnboardingHeader(compact: compact),
            SizedBox(height: compact ? 16 : 22),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            SizedBox(height: compact ? 14 : 18),
            WelcomeFeatureCarousel(
              viewportFraction: 1.0,
              height: carouselHeight,
              onWaterBackground: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingHeader({required bool compact}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
          ),
          child: Icon(
            Icons.water_drop_rounded,
            color: AppColors.primaryLight.withValues(alpha: 0.9),
            size: compact ? 22 : 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONOCE CLEANPOOL',
                style: GoogleFonts.interTight(
                  color: AppColors.primaryLight.withValues(alpha: 0.88),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                compact
                    ? 'Monitorea tu piscina desde el primer día'
                    : 'Monitorea tu piscina con confianza',
                style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Un recorrido breve por las métricas que usará tu piscina.',
                style: GoogleFonts.interTight(
                  color: AppColors.textSecondary,
                  fontSize: compact ? 13 : 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(
        Icons.arrow_back_ios,
        color: AppColors.textPrimary,
        size: 20,
      ),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crear cuenta', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Regístrate para comenzar a\nmonitorear tu piscina',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: 'Nombre completo',
        prefixIcon: Icon(
          Icons.person_outline,
          color: AppColors.textMuted,
          size: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingresa tu nombre';
        if (value.length < 2) return 'Nombre muy corto';
        return null;
      },
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: AppStrings.username,
        prefixIcon: Icon(
          Icons.badge_outlined,
          color: AppColors.textMuted,
          size: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre de usuario';
        if (value.length < 3) return 'Usuario muy corto';
        if (value.contains(' ')) return 'No debe contener espacios';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: 'Correo electrónico',
        prefixIcon: Icon(
          Icons.mail_outline,
          color: AppColors.textMuted,
          size: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingresa tu correo';
        if (!value.contains('@')) return 'Correo inválido';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Contraseña',
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AppColors.textMuted,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textMuted,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingresa una contraseña';
        if (value.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirm,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Confirmar contraseña',
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AppColors.textMuted,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textMuted,
            size: 20,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Confirma tu contraseña';
        if (value != _passwordController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleRegister,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(AppStrings.register),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.hasAccount,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            AppStrings.login,
            style: GoogleFonts.interTight(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
