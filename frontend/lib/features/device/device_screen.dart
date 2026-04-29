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

  // Estos campos se mantienen por compatibilidad del flujo actual
  // (carga/polling) aunque esta pantalla ya no renderiza el estado.
  // ignore: unused_field
  bool _loading = true;
  // ignore: unused_field
  Map<String, dynamic>? _deviceStatus;
  // ignore: unused_field
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
                    'En construcción',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                        Text(
                          'Esta sección mostrará información del dispositivo en una versión futura.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
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
