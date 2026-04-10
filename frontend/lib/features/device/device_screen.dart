import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular Dispositivo'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 80,
                color: AppColors.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Próximamente',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'En construcción',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
