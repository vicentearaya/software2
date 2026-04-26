import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/pool_service.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  static const String _deviceId = 'cleanpool-001';
  final _authService = AuthService();
  final _poolService = PoolService();

  bool _loading = true;
  Map<String, dynamic>? _deviceStatus;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadDeviceStatus();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadDeviceStatus(showLoader: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceStatus({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final token = await _authService.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        if (showLoader) _loading = false;
        _deviceStatus = null;
        _error = 'Inicia sesión para consultar el estado del dispositivo.';
      });
      return;
    }

    final result = await _poolService.getDeviceStatus(
      deviceId: _deviceId,
      token: token,
    );

    if (!mounted) return;
    setState(() {
      if (showLoader) _loading = false;
      if (result['success'] == true) {
        _deviceStatus = result['data'] as Map<String, dynamic>;
        _error = null;
      } else {
        if (showLoader) {
          _deviceStatus = null;
          _error = result['message'] as String?;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnected = _deviceStatus?['is_online'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Dispositivo'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _loadDeviceStatus,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instrucciones de uso',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '1) Coloca el dispositivo en la piscina que quieras medir.\n'
                    '2) En el Dashboard, selecciona esa piscina.\n'
                    '3) Pulsa "Vincular dispositivo a esta piscina".\n'
                    '4) Si el dispositivo envía lecturas, aquí aparecerá como conectado.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isConnected
                    ? AppColors.statusGood.withOpacity(0.12)
                    : AppColors.statusDanger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isConnected
                      ? AppColors.statusGood.withOpacity(0.45)
                      : AppColors.statusDanger.withOpacity(0.45),
                ),
              ),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isConnected
                                  ? Icons.wifi_tethering_rounded
                                  : Icons.wifi_off_rounded,
                              color: isConnected
                                  ? AppColors.statusGood
                                  : AppColors.statusDanger,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isConnected ? 'Conectado' : 'Desconectado',
                              style: TextStyle(
                                color: isConnected
                                    ? AppColors.statusGood
                                    : AppColors.statusDanger,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isConnected
                              ? 'Vinculado a la piscina: ${_deviceStatus!['pool_id']}\nÚltima señal: ${_deviceStatus!['last_seen_at'] ?? '-'}'
                              : (_error ??
                                    'No existe vínculo activo para este dispositivo.'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loadDeviceStatus,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Actualizar estado'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
