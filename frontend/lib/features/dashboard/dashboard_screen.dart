import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
