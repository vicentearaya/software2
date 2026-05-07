import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/services/auth_service.dart';
import '../auth/login_screen.dart';

// ── Modelo de producto ──────────────────────────
class InventoryProduct {
  final String id;
  final String nombre;
  final String categoria;
  final double cantidad;
  final String unidad;
  final String? notas;
  final DateTime creadoEn;

  InventoryProduct({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.unidad,
    this.notas,
    DateTime? creadoEn,
  }) : creadoEn = creadoEn ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'categoria': categoria,
    'cantidad': cantidad, 'unidad': unidad, 'notas': notas,
    'creadoEn': creadoEn.toIso8601String(),
  };

  factory InventoryProduct.fromJson(Map<String, dynamic> json) =>
      InventoryProduct(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        categoria: json['categoria'] as String,
        cantidad: (json['cantidad'] as num).toDouble(),
        unidad: json['unidad'] as String,
        notas: json['notas'] as String?,
        creadoEn: DateTime.parse(json['creadoEn'] as String),
      );
}

// ── Helpers de categoría ────────────────────────
class _CategoryInfo {
  final IconData icon;
  final Color color;
  const _CategoryInfo(this.icon, this.color);
}

const Map<String, _CategoryInfo> _categoryMap = {
  'Desinfectante': _CategoryInfo(Icons.sanitizer, Color(0xFF2ECC71)),
  'Regulador pH': _CategoryInfo(Icons.biotech, Color(0xFF3498DB)),
  'Algicida': _CategoryInfo(Icons.pest_control, Color(0xFF9B59B6)),
  'Floculante': _CategoryInfo(Icons.blur_on, Color(0xFFE67E22)),
  'Otro': _CategoryInfo(Icons.category_rounded, Color(0xFF95A5A6)),
};

_CategoryInfo _getCategory(String cat) =>
    _categoryMap[cat] ?? const _CategoryInfo(Icons.category_rounded, Color(0xFF95A5A6));

// ── Categorías y unidades ───────────────────────
const List<String> kCategorias = ['Desinfectante', 'Regulador pH', 'Algicida', 'Floculante', 'Otro'];
const List<String> kUnidades = ['kg', 'g', 'L', 'ml', 'unidades'];

// ── Pantalla principal ──────────────────────────
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const String _storageKey = 'user_inventory';
  final AuthService _authService = AuthService();
  bool _loading = true;
  bool _isAuthenticated = false;
  List<InventoryProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _checkSessionAndLoad();
  }

  Future<void> _checkSessionAndLoad() async {
    final token = await _authService.getToken();
    if (token == null) {
      if (mounted) setState(() { _isAuthenticated = false; _loading = false; });
      return;
    }
    _isAuthenticated = true;
    await _loadInventory();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final List<dynamic> decoded = jsonDecode(raw);
      _products = decoded.map((e) => InventoryProduct.fromJson(e)).toList();
    }
  }

  Future<void> _saveInventory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_products.map((p) => p.toJson()).toList()));
  }

  void _addProduct(InventoryProduct p) { setState(() => _products.add(p)); _saveInventory(); }
  void _removeProduct(int i) { setState(() => _products.removeAt(i)); _saveInventory(); }

  void _openAddForm() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => _AddProductScreen(onSave: _addProduct),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (!_isAuthenticated) return _buildNoSession();
    if (_products.isEmpty) return _buildEmptyState();
    return _buildClassifiedList();
  }

  // ── Sin sesión ────────────────────────────────
  Widget _buildNoSession() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, size: 44, color: AppColors.statusWarning),
                ),
                const SizedBox(height: 24),
                Text('Sesión requerida', style: GoogleFonts.syne(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text('Inicia sesión para acceder\na tu inventario de productos.',
                    style: GoogleFonts.interTight(color: AppColors.textSecondary, fontSize: 14, height: 1.6), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: Text('Iniciar sesión', style: GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Estado vacío ──────────────────────────────
  Widget _buildEmptyState() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.primary),
                ),
                const SizedBox(height: 28),
                Text('Sin inventario', style: GoogleFonts.syne(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text('Aún no tienes productos registrados.\nAgrega tus químicos para llevar el control.',
                    style: GoogleFonts.interTight(color: AppColors.textSecondary, fontSize: 14, height: 1.6), textAlign: TextAlign.center),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _openAddForm,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text('Agregar productos a tu inventario',
                      style: GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Lista clasificada por categoría ───────────
  Widget _buildClassifiedList() {
    // Agrupar productos por categoría
    final Map<String, List<MapEntry<int, InventoryProduct>>> grouped = {};
    for (int i = 0; i < _products.length; i++) {
      final cat = _products[i].categoria;
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add(MapEntry(i, _products[i]));
    }

    // Ordenar categorías según el orden definido
    final orderedKeys = kCategorias.where((c) => grouped.containsKey(c)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Inventario', style: GoogleFonts.syne(
                            color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${_products.length} producto${_products.length != 1 ? 's' : ''} en ${orderedKeys.length} categoría${orderedKeys.length != 1 ? 's' : ''}',
                              style: GoogleFonts.interTight(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text('${_products.length}', style: GoogleFonts.syne(
                        color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Grupos por categoría
            ...orderedKeys.expand((cat) {
              final info = _getCategory(cat);
              final items = grouped[cat]!;
              return [
                // Header de categoría
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: info.color.withValues(alpha: 0.2)),
                          ),
                          child: Icon(info.icon, color: info.color, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Text(cat.toUpperCase(), style: GoogleFonts.syne(
                          color: info.color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${items.length}', style: GoogleFonts.interTight(
                            color: info.color, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Container(height: 1, color: AppColors.border.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                ),
                // Tarjetas de productos
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((_, idx) {
                      final entry = items[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProductCard(
                          product: entry.value,
                          categoryInfo: info,
                          onDelete: () => _removeProduct(entry.key),
                        ),
                      );
                    }, childCount: items.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ];
            }),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Agregar', style: GoogleFonts.syne(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Tarjeta de producto ─────────────────────────
class _ProductCard extends StatefulWidget {
  final InventoryProduct product;
  final _CategoryInfo categoryInfo;
  final VoidCallback onDelete;
  const _ProductCard({required this.product, required this.categoryInfo, required this.onDelete});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.categoryInfo;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? c.color.withValues(alpha: 0.04) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _hovered ? c.color.withValues(alpha: 0.25) : AppColors.border.withValues(alpha: 0.5)),
          boxShadow: _hovered
              ? [BoxShadow(color: c.color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.color.withValues(alpha: 0.18)),
              ),
              child: Icon(c.icon, color: c.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.nombre, style: GoogleFonts.interTight(
                    color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text('${widget.product.cantidad} ${widget.product.unidad}',
                      style: GoogleFonts.interTight(color: AppColors.textSecondary, fontSize: 12)),
                  if (widget.product.notas != null && widget.product.notas!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(widget.product.notas!, style: GoogleFonts.interTight(
                        color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text('Eliminar', style: GoogleFonts.syne(color: AppColors.textPrimary)),
                  content: Text('¿Eliminar "${widget.product.nombre}"?',
                      style: GoogleFonts.interTight(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancelar', style: GoogleFonts.interTight(color: AppColors.textMuted))),
                    TextButton(onPressed: () { Navigator.pop(ctx); widget.onDelete(); },
                        child: Text('Eliminar', style: GoogleFonts.interTight(color: AppColors.statusDanger))),
                  ],
                ),
              ),
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formulario agregar producto ─────────────────
class _AddProductScreen extends StatefulWidget {
  final void Function(InventoryProduct) onSave;
  const _AddProductScreen({required this.onSave});
  @override
  State<_AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<_AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  String _cat = 'Desinfectante';
  String _uni = 'kg';

  @override
  void dispose() { _nombreCtrl.dispose(); _cantidadCtrl.dispose(); _notasCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(InventoryProduct(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombreCtrl.text.trim(),
      categoria: _cat,
      cantidad: double.parse(_cantidadCtrl.text.trim()),
      unidad: _uni,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final catInfo = _getCategory(_cat);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Nuevo producto', style: GoogleFonts.syne(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview de categoría
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: catInfo.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: catInfo.color.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: catInfo.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(catInfo.icon, color: catInfo.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Categoría seleccionada', style: GoogleFonts.interTight(color: AppColors.textMuted, fontSize: 11)),
                        Text(_cat, style: GoogleFonts.syne(color: catInfo.color, fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _label('Nombre del producto'),
              const SizedBox(height: 8),
              _field(controller: _nombreCtrl, hint: 'Ej: Cloro granulado',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null),
              const SizedBox(height: 20),

              _label('Categoría'),
              const SizedBox(height: 8),
              _dropdown<String>(value: _cat, items: kCategorias, onChanged: (v) => setState(() => _cat = v!)),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Cantidad'), const SizedBox(height: 8),
                  _field(controller: _cantidadCtrl, hint: 'Ej: 5',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Valor inválido';
                        return null;
                      }),
                ])),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Unidad'), const SizedBox(height: 8),
                  _dropdown<String>(value: _uni, items: kUnidades, onChanged: (v) => setState(() => _uni = v!)),
                ])),
              ]),
              const SizedBox(height: 20),

              _label('Notas (opcional)'),
              const SizedBox(height: 8),
              _field(controller: _notasCtrl, hint: 'Instrucciones, marca, etc.', maxLines: 3),
              const SizedBox(height: 36),

              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text('Guardar producto', style: GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: GoogleFonts.interTight(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600));

  Widget _field({required TextEditingController controller, required String hint,
      String? Function(String?)? validator, TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters, int maxLines = 1}) {
    return TextFormField(
      controller: controller, validator: validator, keyboardType: keyboardType,
      inputFormatters: inputFormatters, maxLines: maxLines,
      style: GoogleFonts.interTight(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint, hintStyle: GoogleFonts.interTight(color: AppColors.textMuted, fontSize: 14),
        filled: true, fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.statusDanger)),
      ),
    );
  }

  Widget _dropdown<T>({required T value, required List<T> items, required void Function(T?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value, isExpanded: true, dropdownColor: AppColors.surface,
          style: GoogleFonts.interTight(color: AppColors.textPrimary, fontSize: 15),
          items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text('$e'))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
