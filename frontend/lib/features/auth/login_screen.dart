import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/main_screen.dart';
import 'widgets/pool_ripple_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final rememberMe = await _authService.getRememberMe();
    final savedEmail = await _authService.getSavedEmail();
    if (!mounted) return;
    setState(() {
      _rememberMe = rememberMe;
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
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

  /// Móvil: solo formulario desplazable para evitar overflow con teclado.
  Widget _buildMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildBackButton(),
            const SizedBox(height: 16),
            _buildMobileBrandCard(),
            const SizedBox(height: 24),
            _buildHeader(),
            const SizedBox(height: 36),
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 12),
            _buildRememberMeRow(),
            const SizedBox(height: 24),
            _buildLoginButton(),
            const SizedBox(height: 20),
            _buildRegisterLink(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Banner animado compacto para móvil: ondas visibles sin split lateral.
  Widget _buildMobileBrandCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const PoolRippleBackground(
              imageAsset: 'assets/images/pool_background.png',
              mobileOptimized: true,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.08),
                    AppColors.background.withValues(alpha: 0.52),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.primaryLight.withValues(alpha: 0.92),
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.appName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitoreo inteligente para piscinas',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.interTight(
                      color: AppColors.textPrimary.withValues(alpha: 0.82),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Web/escritorio: formulario a la izquierda y branding minimalista a la derecha.
  Widget _buildWide() {
    return Row(
      children: [
        // Panel izquierdo: volver, bienvenida y formulario.
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(),
                      const SizedBox(height: 24),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      const SizedBox(height: 12),
                      _buildRememberMeRow(),
                      const SizedBox(height: 24),
                      _buildLoginButton(),
                      const SizedBox(height: 24),
                      _buildRegisterLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Panel derecho: fondo animado y branding limpio para usuarios recurrentes.
        Expanded(
          flex: 5,
          child: _buildMinimalBrandPanel(),
        ),
      ],
    );
  }

  Widget _buildMinimalBrandPanel() {
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
                AppColors.background.withValues(alpha: 0.12),
                AppColors.background.withValues(alpha: 0.62),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.primaryLight.withValues(alpha: 0.82),
                  size: 88,
                ),
                const SizedBox(height: 18),
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitoreo inteligente para piscinas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.interTight(
                    color: AppColors.textPrimary.withValues(alpha: 0.76),
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () => Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcome,
        (route) => false,
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
      label: Text(
        'Volver al inicio',
        style: GoogleFonts.syne(fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.water_drop, color: AppColors.primary, size: 32),
            const SizedBox(width: 10),
            Text(
              AppStrings.appName,
              style: GoogleFonts.syne(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text('Bienvenido', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión para monitorear\ntu piscina',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.name,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: 'Usuario o correo electrónico',
        prefixIcon: Icon(
          Icons.person_outline,
          color: AppColors.textMuted,
          size: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingresa tu usuario o correo electrónico';
        return null;
      },
    );
  }

  Widget _buildRememberMeRow() {
    return InkWell(
      onTap: () => setState(() => _rememberMe = !_rememberMe),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                activeColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
                onChanged: (value) {
                  setState(() => _rememberMe = value ?? true);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.rememberMe,
                style: GoogleFonts.interTight(
                  color: AppColors.textPrimary.withValues(alpha: 0.88),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
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
        if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
        if (value.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(AppStrings.login),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.noAccount,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          child: Text(
            AppStrings.register,
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
