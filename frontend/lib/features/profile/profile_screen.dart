import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Perfil', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
