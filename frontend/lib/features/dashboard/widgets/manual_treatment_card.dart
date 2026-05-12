import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/pool_service.dart';

class ManualTreatmentCard extends StatefulWidget {
  const ManualTreatmentCard({
    super.key,
    required this.poolId,
    this.onCalculated,
  });

  final String? poolId;
  final void Function(double ph, double cloro)? onCalculated;

  @override
  State<ManualTreatmentCard> createState() => _ManualTreatmentCardState();
}

class _ManualTreatmentCardState extends State<ManualTreatmentCard> {
  final _authService = AuthService();
  final _poolService = PoolService();
  final _phCtrl = TextEditingController();
  final _cloroCtrl = TextEditingController();

  bool _isLoading = false;
  List<dynamic>? _tratamiento;
  String? _errorMessage;

  @override
  void dispose() {
    _phCtrl.dispose();
    _cloroCtrl.dispose();
    super.dispose();
  }

  Future<void> _calcular() async {
    final phStr = _phCtrl.text.trim();
    final cloroStr = _cloroCtrl.text.trim();

    if (phStr.isEmpty || cloroStr.isEmpty) {
      setState(() => _errorMessage = 'Requerido ingresar datos');
      return;
    }

    final ph = double.tryParse(phStr.replaceAll(',', '.'));
    final cloro = double.tryParse(cloroStr.replaceAll(',', '.'));

    if (ph == null || cloro == null) {
      setState(() => _errorMessage = 'Valores inválidos');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _tratamiento = null;
    });

    final token = await _authService.getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error de sesión';
      });
      return;
    }

    if (widget.poolId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sin conexión con el servidor';
      });
      return;
    }
    final res = await _poolService.calcularYRegistrarTratamiento(
      widget.poolId!,
      ph,
      cloro,
      token,
    );

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _tratamiento = res['data']['tratamiento'] as List<dynamic>?;
        widget.onCalculated?.call(ph, cloro);
      } else {
        _errorMessage = res['message'] as String?;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Limpieza de tu piscina',
                      style: GoogleFonts.syne(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Obtén la receta para tu piscina al instante',
                      style: GoogleFonts.interTight(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInput('pH', 'ej. 7.4', _phCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildInput('Cloro (ppm)', 'ej. 1.5', _cloroCtrl)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _calcular,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Descubrir qué echarle',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.interTight(
                  color: AppColors.statusDanger,
                  fontSize: 13,
                ),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _tratamiento != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildTratamientoResult(_tratamiento!),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.interTight(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.interTight(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.interTight(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTratamientoResult(List<dynamic> tratamiento) {
    if (tratamiento.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.statusGood.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.statusGood),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¡El agua está en óptimas condiciones!',
                style: GoogleFonts.interTight(
                  color: AppColors.statusGood,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.border, height: 24),
        Text(
          'Receta de Tratamiento Guardada',
          style: GoogleFonts.syne(
            color: AppColors.accent,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...tratamiento.map((item) {
          final producto = item['producto'] ?? '';
          if (producto == 'Ninguno') {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['instrucciones'] ?? '',
                      style: GoogleFonts.interTight(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: AppColors.accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto,
                        style: GoogleFonts.syne(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item['cantidad']} ${item['unidad']}',
                        style: GoogleFonts.interTight(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['instrucciones'] ?? '',
                        style: GoogleFonts.interTight(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
