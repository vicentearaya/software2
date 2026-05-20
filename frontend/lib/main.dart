import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init();
  runApp(const CleanPoolApp());
}

class CleanPoolApp extends StatelessWidget {
  const CleanPoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.welcome,
      routes: {
        AppRoutes.welcome: (_) => const WelcomeScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
      },
    );
  }
}
