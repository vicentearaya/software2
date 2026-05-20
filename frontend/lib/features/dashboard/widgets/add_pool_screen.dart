import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../pool_data.dart';

class AddPoolScreen extends StatefulWidget {
  const AddPoolScreen({super.key, required this.onSave, this.initialData});

  final Future<void> Function(PoolData) onSave;
  final PoolData? initialData;

  @override
  State<AddPoolScreen> createState() => _AddPoolScreenState();
}

class _AddPoolScreenState extends State<AddPoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _largoCtrl = TextEditingController();
  final _anchoCtrl = TextEditingController();
  final _profundidadCtrl = TextEditingController();

  bool _esInterior = false;
  bool _tieneFiltro = true;
  bool _isSaving = false;

  double get _litros {
    final l = double.tryParse(_largoCtrl.text) ?? 0;
    final a = double.tryParse(_anchoCtrl.text) ?? 0;
    final p = double.tryParse(_profundidadCtrl.text) ?? 0;
    return l * a * p * 1000;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _nombreCtrl.text = d.nombre;
      _largoCtrl.text = d.largo.toString();
      _anchoCtrl.text = d.ancho.toString();
      _profundidadCtrl.text = d.profundidad.toString();
      _esInterior = d.esInterior;
      _tieneFiltro = d.tieneFiltro;
    }
    _largoCtrl.addListener(() => setState(() {}));
    _anchoCtrl.addListener(() => setState(() {}));
    _profundidadCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _largoCtrl.dispose();
    _anchoCtrl.dispose();
    _profundidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final pool = PoolData(
      nombre: _nombreCtrl.text.trim(),
      largo: double.parse(_largoCtrl.text.trim()),
      ancho: double.parse(_anchoCtrl.text.trim()),
      profundidad: double.parse(_profundidadCtrl.text.trim()),
      esInterior: _esInterior,
      tieneFiltro: _tieneFiltro,
    );
    await widget.onSave(pool);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Nueva piscina',
                    style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa los detalles de tu piscina para calcular su capacidad y configurar el monitoreo.',
                        style: GoogleFonts.interTight(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _SectionLabel(label: 'Nombre de la piscina'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nombreCtrl,
                        hint: 'Ej: Piscina principal, Casa de playa…',
                        icon: Icons.pool_rounded,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(label: 'Dimensiones (en metros)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _largoCtrl,
                              hint: 'Largo',
                              icon: Icons.straighten_rounded,
                              isNumber: true,
                              validator: _validatePositiveNumber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _anchoCtrl,
                              hint: 'Ancho',
                              icon: Icons.swap_horiz_rounded,
                              isNumber: true,
                              validator: _validatePositiveNumber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _profundidadCtrl,
                        hint: 'Profundidad',
                        icon: Icons.vertical_align_bottom_rounded,
                        isNumber: true,
                        validator: _validatePositiveNumber,
                      ),
                      if (_litros > 0) ...[
                        const SizedBox(height: 16),
                        _LitrosPreview(litros: _litros),
                      ],
                      const SizedBox(height: 24),
                      _SectionLabel(label: 'Tipo de instalación'),
                      const SizedBox(height: 10),
                      _TypeSelector(
                        selectedInterior: _esInterior,
                        onChanged: (v) => setState(() => _esInterior = v),
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(label: 'Sistema de filtración'),
                      const SizedBox(height: 10),
                      _FilterSelector(
                        hasFiltro: _tieneFiltro,
                        onChanged: (v) => setState(() => _tieneFiltro = v),
                      ),
                      const SizedBox(height: 36),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Agregar piscina',
                                style: GoogleFonts.syne(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePositiveNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo requerido';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Ingresa un número válido';
    if (n <= 0) return 'Debe ser mayor a 0';
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d\.]'))]
          : null,
      style: GoogleFonts.interTight(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.interTight(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.statusDanger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.syne(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LitrosPreview extends StatelessWidget {
  const _LitrosPreview({required this.litros});
  final double litros;

  @override
  Widget build(BuildContext context) {
    final texto = litros >= 10000
        ? '${(litros / 1000).toStringAsFixed(2)} m³ — ${litros.toStringAsFixed(0)} L'
        : '${litros.toStringAsFixed(0)} litros';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.water_drop_rounded,
            color: AppColors.accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            'Capacidad estimada: ',
            style: GoogleFonts.interTight(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            texto,
            style: GoogleFonts.syne(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selectedInterior,
    required this.onChanged,
  });
  final bool selectedInterior;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: 'Exterior',
          icon: Icons.wb_sunny_rounded,
          selected: !selectedInterior,
          color: AppColors.statusWarning,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: 12),
        _Chip(
          label: 'Interior',
          icon: Icons.home_rounded,
          selected: selectedInterior,
          color: AppColors.accent,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _FilterSelector extends StatelessWidget {
  const _FilterSelector({required this.hasFiltro, required this.onChanged});
  final bool hasFiltro;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: 'Con filtro',
          icon: Icons.check_circle_rounded,
          selected: hasFiltro,
          color: AppColors.statusGood,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 12),
        _Chip(
          label: 'Sin filtro',
          icon: Icons.cancel_rounded,
          selected: !hasFiltro,
          color: AppColors.statusDanger,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color.withOpacity(0.6) : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? color : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.syne(
                  color: selected ? color : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
