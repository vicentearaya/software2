import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/main_screen.dart';
import 'welcome_screen.dart';

/// Pantalla inicial que restaura la sesión si el usuario activó "Recordarme".
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  bool _checking = true;
  bool _autoLogin = false;

  @override
  void initState() {
    super.initState();
    _resolveInitialRoute();
  }

  Future<void> _resolveInitialRoute() async {
    var shouldAutoLogin = false;
    try {
      shouldAutoLogin = await _authService
          .shouldAutoLogin()
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
    } catch (_) {
      shouldAutoLogin = false;
    }

    if (!mounted) return;
    setState(() {
      _checking = false;
      _autoLogin = shouldAutoLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando CleanPool...',
                style: GoogleFonts.interTight(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _autoLogin ? const MainScreen() : const WelcomeScreen();
  }
}
