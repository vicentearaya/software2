import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
<<<<<<< Updated upstream

/// Pantalla de Inventario — placeholder para Sprint 4.
/// Aquí se gestionarán los productos químicos disponibles
/// (cloro, reguladores de pH, etc.) con stock y alertas de reposición.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
=======
import '../../core/utils/app_utils.dart';
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

  InventoryProduct copyWith({
    String? id,
    String? nombre,
    String? categoria,
    double? cantidad,
    String? unidad,
    String? notas,
    DateTime? creadoEn,
  }) {
    return InventoryProduct(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      cantidad: cantidad ?? this.cantidad,
      unidad: unidad ?? this.unidad,
      notas: notas ?? this.notas,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}

/// Cantidad legible para la UI (evita `5.0` cuando es entero).
String _formatInventoryAmount(double n) {
  if (n.isNaN || n.isInfinite) return '0';
  final rounded = n.round();
  if ((n - rounded).abs() < 1e-6) return rounded.toString();
  var s = n.toStringAsFixed(4);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return s;
}

/// Placeholder numérico coherente con la unidad del producto (misma que el stock).
String _inventoryQuantityPlaceholder(String unidad) {
  switch (unidad) {
    case 'kg':
    case 'L':
      return 'Ej: 0.8';
    case 'g':
    case 'ml':
      return 'Ej: 500';
    case 'unidades':
      return 'Ej: 2';
    default:
      return 'Ej: 1';
  }
}

/// Una línea de ayuda: el valor se interpreta en la misma unidad que el stock.
String _inventoryQuantityFieldHelper(String unidad) {
  switch (unidad) {
    case 'kg':
      return 'En kg, igual que el stock. Ej.: 800 g → ingresa 0.8';
    case 'L':
      return 'En litros, igual que el stock. Ej.: 250 ml → ingresa 0.25';
    case 'g':
    case 'ml':
      return 'En $unidad, igual que el stock actual.';
    case 'unidades':
      return 'En unidades, igual que el stock actual.';
    default:
      return 'Ingresa el valor en $unidad, la misma unidad que el stock.';
  }
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

  Future<bool> _persistInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_products.map((p) => p.toJson()).toList()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _addProduct(InventoryProduct p) async {
    setState(() => _products.add(p));
    if (!await _persistInventory()) {
      setState(() => _products.removeLast());
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          'No se pudo guardar el inventario',
          isError: true,
        );
      }
      return;
    }
    if (mounted) {
      AppUtils.showSnackBar(context, 'Producto agregado');
    }
  }

  Future<void> _removeProduct(int i) async {
    final removed = _products[i];
    setState(() => _products.removeAt(i));
    if (!await _persistInventory()) {
      setState(() => _products.insert(i, removed));
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          'No se pudo guardar el inventario',
          isError: true,
        );
      }
      return;
    }
    if (mounted) {
      AppUtils.showSnackBar(context, 'Producto eliminado');
    }
  }

  Future<void> _replaceProductAt(int index, InventoryProduct next) async {
    final previous = _products[index];
    setState(() => _products[index] = next);
    if (!await _persistInventory()) {
      setState(() => _products[index] = previous);
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          'No se pudo guardar el inventario',
          isError: true,
        );
      }
      return;
    }
    if (mounted) {
      AppUtils.showSnackBar(context, 'Stock actualizado');
    }
  }

  void _openAddStockSheet(int index) {
    final product = _products[index];
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Agregar más',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.nombre,
                  style: GoogleFonts.interTight(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock actual: ${_formatInventoryAmount(product.cantidad)} ${product.unidad}',
                  style: GoogleFonts.interTight(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: GoogleFonts.interTight(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cantidad a agregar',
                    hintText: _inventoryQuantityPlaceholder(product.unidad),
                    helperText: _inventoryQuantityFieldHelper(product.unidad),
                    helperMaxLines: 2,
                    suffixText: product.unidad,
                    suffixStyle: GoogleFonts.interTight(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    labelStyle: GoogleFonts.interTight(color: AppColors.textSecondary),
                    helperStyle: GoogleFonts.interTight(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa una cantidad en ${product.unidad}';
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Debe ser mayor que cero';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.interTight(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final add = double.parse(ctrl.text.trim());
                          Navigator.pop(sheetCtx);
                          await _replaceProductAt(
                            index,
                            product.copyWith(cantidad: product.cantidad + add),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Agregar',
                          style: GoogleFonts.syne(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      // Evita usar el controller tras dispose (cierre del sheet + animación).
      Future.delayed(const Duration(milliseconds: 400), () {
        ctrl.dispose();
      });
    });
  }

  void _openUseStockSheet(int index) {
    final product = _products[index];
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    const eps = 1e-9;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar uso',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.nombre,
                  style: GoogleFonts.interTight(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock actual: ${_formatInventoryAmount(product.cantidad)} ${product.unidad}',
                  style: GoogleFonts.interTight(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: GoogleFonts.interTight(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cantidad usada',
                    hintText: _inventoryQuantityPlaceholder(product.unidad),
                    helperText: _inventoryQuantityFieldHelper(product.unidad),
                    helperMaxLines: 2,
                    suffixText: product.unidad,
                    suffixStyle: GoogleFonts.interTight(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    labelStyle: GoogleFonts.interTight(color: AppColors.textSecondary),
                    helperStyle: GoogleFonts.interTight(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa una cantidad en ${product.unidad}';
                    }
                    final used = double.tryParse(v.trim());
                    if (used == null || used <= 0) return 'Debe ser mayor que cero';
                    if (used - product.cantidad > eps) {
                      return 'No puedes usar más del stock disponible (${_formatInventoryAmount(product.cantidad)} ${product.unidad})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.interTight(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final used = double.parse(ctrl.text.trim());
                          Navigator.pop(sheetCtx);
                          await _replaceProductAt(
                            index,
                            product.copyWith(cantidad: product.cantidad - used),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Descontar',
                          style: GoogleFonts.syne(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      Future.delayed(const Duration(milliseconds: 400), () {
        ctrl.dispose();
      });
    });
  }

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
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 52,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Inventario',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Gestiona tus productos químicos,\ncontrola el stock y recibe alertas\nde reposición.',
                  style: GoogleFonts.interTight(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.construction_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Próximamente',
                        style: GoogleFonts.interTight(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< Updated upstream
=======

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
                          onAddMore: () => _openAddStockSheet(entry.key),
                          onRegisterUse: () => _openUseStockSheet(entry.key),
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
  final VoidCallback onAddMore;
  final VoidCallback onRegisterUse;
  final VoidCallback onDelete;
  const _ProductCard({
    required this.product,
    required this.categoryInfo,
    required this.onAddMore,
    required this.onRegisterUse,
    required this.onDelete,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.categoryInfo;
    final stockLabel =
        '${_formatInventoryAmount(widget.product.cantidad)} ${widget.product.unidad}';
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 6),
                  Text(
                    'Stock actual',
                    style: GoogleFonts.interTight(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stockLabel,
                    style: GoogleFonts.interTight(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.product.notas != null && widget.product.notas!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(widget.product.notas!, style: GoogleFonts.interTight(
                        color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      TextButton.icon(
                        onPressed: widget.onAddMore,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
                        label: Text(
                          'Agregar más',
                          style: GoogleFonts.interTight(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onRegisterUse,
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.textSecondary),
                        label: Text(
                          'Registrar uso',
                          style: GoogleFonts.interTight(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
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
  final Future<void> Function(InventoryProduct) onSave;
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSave(InventoryProduct(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombreCtrl.text.trim(),
      categoria: _cat,
      cantidad: double.parse(_cantidadCtrl.text.trim()),
      unidad: _uni,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    ));
    if (mounted) Navigator.of(context).pop();
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
>>>>>>> Stashed changes
}
