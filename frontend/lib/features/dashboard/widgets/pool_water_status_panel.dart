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
    Color iconColor = Colors.white.withValues(alpha: 0.9);
    IconData icon = Icons.info_outline_rounded;
    String text = '';
    String subText = '';

    final Map<String, dynamic>? parametros =
        statusData['parametros'] as Map<String, dynamic>?;
    final estado = statusData['estado'];
    final warnings = _buildWaterRiskWarnings(parametros);

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
            color: bgColor.withValues(alpha: 0.4),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
                        color: Colors.white.withValues(alpha: 0.9),
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ParamCell(
                    label: 'pH',
                    paramKey: 'ph',
                    data: parametros?['ph'],
                  ),
                ),
                Expanded(
                  child: _ParamCell(
                    label: 'Cloro',
                    paramKey: 'cloro',
                    data: parametros?['cloro'],
                  ),
                ),
                if (parametros?['temperatura'] != null)
                  Expanded(
                    child: _ParamCell(
                      label: 'Temp.',
                      paramKey: 'temperatura',
                      data: parametros?['temperatura'],
                    ),
                  ),
              ],
            ),
          ),
          if (estado != 'APTA' && warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            _RiskWarningList(warnings: warnings),
          ],
        ],
      ),
    );
  }
}

enum _RiskSeverity { warning, critical }

class _WaterRiskWarning {
  const _WaterRiskWarning({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final _RiskSeverity severity;
}

class _WaterParamRange {
  const _WaterParamRange({
    required this.optimalMin,
    required this.optimalMax,
    required this.warningMin,
    required this.warningMax,
  });

  final double optimalMin;
  final double optimalMax;
  final double warningMin;
  final double warningMax;
}

const Map<String, _WaterParamRange> _waterRiskRanges = {
  'ph': _WaterParamRange(
    optimalMin: 7.2,
    optimalMax: 7.8,
    warningMin: 6.8,
    warningMax: 8.2,
  ),
  'cloro': _WaterParamRange(
    optimalMin: 1.0,
    optimalMax: 3.0,
    warningMin: 0.5,
    warningMax: 5.0,
  ),
  'temperatura': _WaterParamRange(
    optimalMin: 24.0,
    optimalMax: 30.0,
    warningMin: 20.0,
    warningMax: 34.0,
  ),
};

List<_WaterRiskWarning> _buildWaterRiskWarnings(
  Map<String, dynamic>? parametros,
) {
  if (parametros == null) return const [];

  final warnings = <_WaterRiskWarning>[];
  for (final key in ['ph', 'cloro', 'temperatura']) {
    final rawData = parametros[key];
    if (rawData is! Map<String, dynamic>) continue;
    final rawValue = rawData['valor'];
    if (rawValue is! num) continue;

    final range = _waterRiskRanges[key];
    if (range == null) continue;
    final value = rawValue.toDouble();

    if (value >= range.optimalMin && value <= range.optimalMax) continue;

    final isLow = value < range.optimalMin;
    final isCritical = value < range.warningMin || value > range.warningMax;
    warnings.add(
      _riskWarningFor(paramKey: key, isLow: isLow, isCritical: isCritical),
    );
  }
  return warnings;
}

_WaterRiskWarning _riskWarningFor({
  required String paramKey,
  required bool isLow,
  required bool isCritical,
}) {
  final severity = isCritical ? _RiskSeverity.critical : _RiskSeverity.warning;
  switch (paramKey) {
    case 'ph':
      if (isLow) {
        return _WaterRiskWarning(
          title: isCritical ? 'pH críticamente bajo' : 'pH bajo',
          message: isCritical
              ? 'Evita el baño. El agua puede irritar piel y ojos; corrige el pH antes de usar la piscina.'
              : 'Puede causar irritación. Sube el pH gradualmente y vuelve a medir.',
          severity: severity,
        );
      }
      return _WaterRiskWarning(
        title: isCritical ? 'pH críticamente alto' : 'pH alto',
        message: isCritical
            ? 'Evita el baño. El cloro pierde eficacia y aumenta la irritación; ajusta el pH antes de usar.'
            : 'El cloro puede desinfectar peor. Baja el pH gradualmente y vuelve a medir.',
        severity: severity,
      );
    case 'cloro':
      if (isLow) {
        return _WaterRiskWarning(
          title: isCritical ? 'Cloro críticamente bajo' : 'Cloro bajo',
          message: isCritical
              ? 'No se recomienda el baño. Hay mayor riesgo de bacterias y agua verde.'
              : 'La desinfección puede ser insuficiente. Refuerza la dosis y vuelve a medir.',
          severity: severity,
        );
      }
      return _WaterRiskWarning(
        title: isCritical ? 'Cloro críticamente alto' : 'Cloro alto',
        message: isCritical
            ? 'Evita el baño. Puede irritar piel, ojos y vías respiratorias; espera a que baje.'
            : 'Puede causar irritación. Suspende nuevas dosis y deja circular el agua.',
        severity: severity,
      );
    case 'temperatura':
      if (isLow) {
        return _WaterRiskWarning(
          title: isCritical ? 'Temperatura muy baja' : 'Temperatura baja',
          message: isCritical
              ? 'Evita baños prolongados. El agua muy fría puede ser riesgosa para niños o personas sensibles.'
              : 'Puede resultar incómoda para el baño. Revisa calefacción o espera mejores condiciones.',
          severity: severity,
        );
      }
      return _WaterRiskWarning(
        title: isCritical ? 'Temperatura muy alta' : 'Temperatura alta',
        message: isCritical
            ? 'Evita el baño hasta corregir. El calor favorece algas y reduce la eficacia del cloro.'
            : 'Vigila el agua: el cloro se consume más rápido y pueden aparecer algas.',
        severity: severity,
      );
    default:
      return _WaterRiskWarning(
        title: 'Parámetro fuera de rango',
        message: 'Revisa el valor antes de usar la piscina.',
        severity: severity,
      );
  }
}

class _RiskWarningList extends StatelessWidget {
  const _RiskWarningList({required this.warnings});

  final List<_WaterRiskWarning> warnings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: warnings
          .map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RiskWarningTile(warning: warning),
            ),
          )
          .toList(),
    );
  }
}

class _RiskWarningTile extends StatelessWidget {
  const _RiskWarningTile({required this.warning});

  final _WaterRiskWarning warning;

  @override
  Widget build(BuildContext context) {
    final isCritical = warning.severity == _RiskSeverity.critical;
    final color = isCritical
        ? const Color(0xFFFFD1D1)
        : const Color(0xFFFFF3C4);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCritical
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning.title,
                  style: GoogleFonts.interTight(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  warning.message,
                  style: GoogleFonts.interTight(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.3,
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

class _ParamCell extends StatelessWidget {
  const _ParamCell({required this.label, required this.paramKey, this.data});

  final String label;
  final String paramKey;
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final bool hasData = data != null && data!['valor'] != null;
    final valor = hasData ? data!['valor'] : null;
    final estado = hasData ? data!['estado'] : 'SIN DATOS';
    final isNormal = estado == 'NORMAL' || estado == 'OPTIMO';

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
            color: Colors.white.withValues(alpha: 0.7),
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
