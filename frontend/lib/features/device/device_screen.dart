import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.sensors,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Conecta tu Medidor CleanPool',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sigue estos pasos para recibir las lecturas del agua de tu piscina en tiempo real.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 32),
            _buildStepCard(
              context,
              stepNumber: '1',
              title: 'Activa el Modo Wi-Fi',
              description: 'Presiona el botón en tu dispositivo Arduino hasta que la luz indicadora comience a parpadear.',
              icon: Icons.power_settings_new,
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              context,
              stepNumber: '2',
              title: 'Conéctate a la Red',
              description: 'Ve a la configuración Wi-Fi de tu celular y conéctate a la red emitida por el dispositivo.',
              icon: Icons.wifi,
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              context,
              stepNumber: '3',
              title: 'Recibe los Datos',
              description: 'Vuelve a esta aplicación. Una vez conectados, verás las métricas del agua automáticamente.',
              icon: Icons.analytics_outlined,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                AppSettings.openAppSettings(type: AppSettingsType.wifi);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ir a Configuración Wi-Fi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              child: Text(
                stepNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: AppColors.textMuted.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
