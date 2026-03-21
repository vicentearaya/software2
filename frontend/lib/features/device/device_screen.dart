import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Dispositivo', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
