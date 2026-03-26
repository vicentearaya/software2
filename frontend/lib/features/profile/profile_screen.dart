import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
<<<<<<< HEAD
=======
import '../../shared/services/auth_service.dart';
import '../auth/login_screen.dart';
>>>>>>> 8d6fa66eeb4773c14bbae33fd940f32bb7db3a6d

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
<<<<<<< HEAD
            Icon(Icons.person_outline, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Perfil', style: Theme.of(context).textTheme.titleLarge),
=======
            const Icon(Icons.person_outline, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Perfil', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
>>>>>>> 8d6fa66eeb4773c14bbae33fd940f32bb7db3a6d
          ],
        ),
      ),
    );
  }
}
