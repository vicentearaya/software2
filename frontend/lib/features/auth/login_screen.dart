import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_utils.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/main_screen.dart';

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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                _buildHeader(),
                const SizedBox(height: 48),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 32),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
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
