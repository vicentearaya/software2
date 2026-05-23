import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/device_config.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/pool_service.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _authService = AuthService();
  final _poolService = PoolService();
  Timer? _pollTimer;

  bool _loading = true;
  Map<String, dynamic>? _deviceStatus;
  String? _error;
  bool _notBound = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _loadDeviceStatus(showLoader: false);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceStatus({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
        _notBound = false;
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
      deviceId: DeviceConfig.deviceId,
      token: token,
    );

    if (!mounted) return;
    setState(() {
      if (showLoader) _loading = false;
      if (result['success'] == true) {
        _deviceStatus = result['data'] as Map<String, dynamic>;
        _error = null;
        _notBound = false;
      } else {
        final msg = result['message'] as String? ?? '';
        if (msg.toLowerCase().contains('vínculo') ||
            msg.toLowerCase().contains('vinculo')) {
          _notBound = true;
          _deviceStatus = null;
          _error = null;
        } else if (showLoader) {
          _deviceStatus = null;
          _error = msg.isNotEmpty ? msg : 'No se pudo cargar el estado.';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _deviceStatus?['is_online'] == true;
    final lastSeenRaw = _deviceStatus?['last_seen_at'];
    final lastTemp = _deviceStatus?['last_temperature'] as num?;

    return Scaffold(
      appBar: AppBar(title: const Text('Dispositivo'), centerTitle: true),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadDeviceStatus(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.statusDanger),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_notBound)
              _InfoCard(
                title: 'Sin vincular',
                child: Text(
                  'Vincula el dispositivo ${DeviceConfig.deviceId} a una piscina '
                  'desde el Dashboard para ver su estado aquí.',
                  style: _bodyStyle,
                ),
              )
            else if (_deviceStatus != null) ...[
              _ConnectionBanner(isOnline: isOnline),
              const SizedBox(height: 14),
              _InfoCard(
                title: 'Estado',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      label: 'ID',
                      value: _deviceStatus!['device_id']?.toString() ??
                          DeviceConfig.deviceId,
                    ),
                    _DetailRow(
                      label: 'Conexión',
                      value: isOnline
                          ? 'Dispositivo conectado'
                          : 'Dispositivo desconectado',
                      valueColor: isOnline
                          ? AppColors.statusGood
                          : AppColors.statusDanger,
                    ),
                    _DetailRow(
                      label: 'Última conexión',
                      value: _formatLastSeen(lastSeenRaw),
                    ),
                    if (isOnline && lastTemp != null)
                      _DetailRow(
                        label: 'Temperatura actual',
                        value: '${lastTemp.toStringAsFixed(1)} °C',
                      ),
                    if (_deviceStatus!['mqtt_topic_slug'] != null)
                      _DetailRow(
                        label: 'Topic MQTT',
                        value:
                            'cleanpool/${_deviceStatus!['mqtt_topic_slug']}/temperatura',
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const TextStyle _bodyStyle = TextStyle(
    color: AppColors.textSecondary,
    height: 1.5,
  );

  String _formatLastSeen(dynamic raw) {
    if (raw == null) return 'Nunca';
    final text = raw.toString();
    final dt = DateTime.tryParse(text);
    if (dt == null) return text;
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final y = local.year;
    return '$d/$mo/$y $h:$m';
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color =
        isOnline ? AppColors.statusGood : AppColors.statusDanger;
    final label = isOnline ? 'En línea' : 'Fuera de línea';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.syne(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isOnline
                      ? 'Recibiendo datos del sensor'
                      : 'Sin señal reciente del ESP8266',
                  style: GoogleFonts.interTight(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.interTight(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.interTight(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
