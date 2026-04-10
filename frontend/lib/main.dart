import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'features/auth/login_screen.dart';
import 'shared/providers/pool_provider.dart';
=======
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'features/auth/login_screen.dart';
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9

void main() {
  runApp(const CleanPoolApp());
}

class CleanPoolApp extends StatelessWidget {
  const CleanPoolApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PoolProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
=======
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
    );
  }
}
