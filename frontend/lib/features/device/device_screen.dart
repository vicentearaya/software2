import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool _isDeviceLinked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceState();
  }

  Future<void> _loadDeviceState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDeviceLinked = prefs.getBool('isDeviceLinked') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _linkDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDeviceLinked', true);
    setState(() {
      _isDeviceLinked = true;
    });
  }

  Future<void> _unlinkDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDeviceLinked', false);
    setState(() {
      _isDeviceLinked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

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
              'Sigue estos pasos para recibir las lecturas del agua de tu piscina desde tu dispositivo.',
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
              description: 'Presiona el botón en tu dispositivo Arduino para que comience a emitir red Wi-Fi',
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

  Widget _buildUnlinkedState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link_off_rounded, size: 80, color: AppColors.textMuted),
          const SizedBox(height: 24),
          Text(
            'Vincular dispositivo',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Sigue estos pasos para conectar tu boya CleanPool:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildStep(
            1,
            'Presiona el botón de la boya CleanPool para activar la red WiFi.',
          ),
          const SizedBox(height: 16),
          _buildStep(
            2,
            'Ve a Configuración de tu celular y conéctate a la red "CleanPool-Device".',
          ),
          const SizedBox(height: 16),
          _buildStep(
            3,
            'Vuelve a la app, la conexión se detectará automáticamente.',
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _linkDevice,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Ya estoy conectado (Demo)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pool, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'CleanPool Boya #1',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.statusGood,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Conectado',
                style: TextStyle(
                  color: AppColors.statusGood,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildSensorRow('pH', '7.2', Icons.water_drop),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.border),
                ),
                _buildSensorRow('Temperatura', '26°C', Icons.thermostat),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.border),
                ),
                _buildSensorRow('Cloro', '1.5 ppm', Icons.science),
              ],
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: _unlinkDevice,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusDanger,
              side: const BorderSide(color: AppColors.statusDanger),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Desvincular',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryLight, size: 24),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
