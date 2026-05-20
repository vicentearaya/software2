import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Tarjeta de aptitud del agua (APTA / ADVERTENCIA / NO APTA) según datos del backend o lectura manual.
class PoolWaterStatusPanel extends StatelessWidget {
  const PoolWaterStatusPanel({
    super.key,
    required this.loading,
    this.manualOverride,
    this.poolStatus,
  });

  final bool loading;
  final Map<String, dynamic>? manualOverride;
  final Map<String, dynamic>? poolStatus;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final Map<String, dynamic>? statusData = manualOverride ?? poolStatus;
    if (statusData == null || statusData['estado'] == null) {
      return const SizedBox.shrink();
    }

    Color bgColor = const Color(0xFF4B5563);
    Color iconColor = Colors.white.withOpacity(0.9);
    IconData icon = Icons.info_outline_rounded;
    String text = '';
    String subText = '';

    final Map<String, dynamic>? parametros =
        statusData['parametros'] as Map<String, dynamic>?;
    final estado = statusData['estado'];

    if (estado == 'APTA') {
      bgColor = const Color(0xFF10B981);
      iconColor = Colors.white;
      icon = Icons.check_circle_rounded;
      text = '¡Apta para baño! Disfruta tu piscina 🏊';
      subText = 'Todos los parámetros están en rango óptimo.';
    } else if (estado == 'ADVERTENCIA') {
      bgColor = const Color(0xFFF59E0B);
      iconColor = Colors.white;
      icon = Icons.info_rounded;
      text = 'Precaución — Parámetros en advertencia ⚠️';
      subText =
          'Los valores están fuera del rango óptimo pero aún son aceptables.';
    } else if (estado == 'NO APTA') {
      bgColor = const Color(0xFFEF4444);
      iconColor = Colors.white;
      icon = Icons.warning_rounded;
      text = 'No apta para baño';
      subText = 'Se requiere ajuste de parámetros químicos.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subText,
                      style: GoogleFonts.interTight(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ParamCell(label: 'pH', paramKey: 'ph', data: parametros?['ph']),
                _ParamCell(
                  label: 'Cloro',
                  paramKey: 'cloro',
                  data: parametros?['cloro'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParamCell extends StatelessWidget {
  const _ParamCell({
    required this.label,
    required this.paramKey,
    this.data,
  });

  final String label;
  final String paramKey;
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final bool hasData = data != null && data!['valor'] != null;
    final valor = hasData ? data!['valor'] : null;
    final estado = hasData ? data!['estado'] : 'SIN DATOS';
    final isNormal = estado == 'NORMAL';

    String displayValue = '-';
    if (hasData) {
      if (paramKey == 'ph') {
        displayValue = valor.toStringAsFixed(1);
      } else if (paramKey == 'cloro') {
        displayValue = '${valor.toStringAsFixed(1)} ppm';
      } else if (paramKey == 'temperatura') {
        displayValue = '${valor.toStringAsFixed(1)}°C';
      }
    }

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.interTight(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayValue,
              style: GoogleFonts.syne(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasData) ...[
              const SizedBox(width: 4),
              Icon(
                isNormal ? Icons.check_rounded : Icons.close_rounded,
                color: isNormal
                    ? const Color(0xFF34D399)
                    : const Color(0xFFFCA5A5),
                size: 18,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
