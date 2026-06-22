import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/inventory_service.dart';
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
    case 'gr':
    case 'g':
      return 'Ej: 500';
    case 'kg':
    case 'L':
      return 'Ej: 0.8';
    case 'ml':
      return 'Ej: 250';
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

/// Producto del catálogo global (colección `productos_catalogo`).
class CatalogProduct {
  final String slug;
  final String nombre;
  final String categoria;
  final String unidad;
  final String unidadEtiqueta;
  final String descripcion;
  final String seguridad;

  const CatalogProduct({
    required this.slug,
    required this.nombre,
    required this.categoria,
    required this.unidad,
    required this.unidadEtiqueta,
    required this.descripcion,
    required this.seguridad,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) => CatalogProduct(
        slug: json['slug'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        categoria: json['categoria'] as String? ?? '',
        unidad: json['unidad'] as String? ?? '',
        unidadEtiqueta: json['unidadEtiqueta'] as String? ??
            json['unidad'] as String? ??
            '',
        descripcion: json['descripcion'] as String? ?? '',
        seguridad: json['seguridad'] as String? ?? '',
      );
}

String _normalizeProductName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

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

// ── Pantalla principal ──────────────────────────
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const String _storageKey = 'user_inventory';
  final AuthService _authService = AuthService();
  final InventoryService _inventoryService = InventoryService();
  bool _loading = true;
  bool _actionInProgress = false;
  bool _isAuthenticated = false;
  List<InventoryProduct> _products = [];
  List<CatalogProduct>? _catalogProducts = const [];
  final Set<String> _collapsedCategories = {};

  Future<void> _runInventoryAction(Future<void> Function() action) async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Widget _withActionOverlay(Widget child) {
    return Stack(
      children: [
        child,
        if (_actionInProgress) ...[
          const ModalBarrier(dismissible: false, color: Colors.black26),
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ],
      ],
    );
  }

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
    if (mounted) setState(() => _loading = true);
    await _reloadFromApi();
    await _loadCatalogMetadata(token);
    await _migrateLocalIfNeeded(token);
    await _reloadFromApi();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCatalogMetadata(String token) async {
    final res = await _inventoryService.getCatalog(token);
    if (!mounted || res['success'] != true) return;
    final data = res['data'];
    final parsed = <CatalogProduct>[];
    if (data is Map<String, dynamic> && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map<String, dynamic>) {
          parsed.add(CatalogProduct.fromJson(e));
        }
      }
    }
    setState(() => _catalogProducts = parsed);
  }

  /// Carga la lista desde el backend. Muestra SnackBar en error (coherente con [ApiClient]).
  Future<void> _reloadFromApi() async {
    final token = await _authService.getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _products = [];
        });
      }
      return;
    }
    final res = await _inventoryService.getItems(token);
    if (!mounted) return;
    if (res['success'] != true) {
      AppUtils.showSnackBar(
        context,
        res['message']?.toString() ?? 'No se pudo cargar el inventario',
        isError: true,
      );
      setState(() => _products = []);
      return;
    }
    final data = res['data'];
    final parsed = <InventoryProduct>[];
    if (data is Map<String, dynamic> && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map<String, dynamic>) {
          parsed.add(InventoryProduct.fromJson(e));
        }
      }
    }
    setState(() => _products = parsed);
  }

  /// Si había datos solo en el dispositivo y el servidor está vacío, sube cada ítem una vez.
  Future<void> _migrateLocalIfNeeded(String token) async {
    if (_products.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }
    if (decoded.isEmpty) return;

    var failures = 0;
    for (final e in decoded) {
      if (e is! Map<String, dynamic>) continue;
      final p = InventoryProduct.fromJson(Map<String, dynamic>.from(e));
      final res = await _inventoryService.createItem(
        token: token,
        body: {
          'nombre': p.nombre,
          'categoria': p.categoria,
          'cantidad': p.cantidad,
          'unidad': p.unidad,
          'notas': p.notas,
        },
      );
      if (res['success'] != true) failures++;
    }
    if (!mounted) return;
    if (failures == 0) {
      await prefs.remove(_storageKey);
    } else {
      AppUtils.showSnackBar(
        context,
        'No se migraron todos los productos locales ($failures error(es)). Reintenta más tarde.',
        isError: true,
      );
    }
  }

  InventoryProduct? _findProductByNombre(String nombre) {
    final normalized = _normalizeProductName(nombre);
    for (final p in _products) {
      if (_normalizeProductName(p.nombre) == normalized) return p;
    }
    return null;
  }

  CatalogProduct? _findCatalogByNombre(String nombre) {
    final normalized = _normalizeProductName(nombre);
    for (final item in _catalogProducts ?? const <CatalogProduct>[]) {
      if (_normalizeProductName(item.nombre) == normalized) return item;
    }
    return null;
  }

  Future<bool> _saveCatalogQuantities(
    List<CatalogProduct> catalog,
    Map<String, double> quantitiesBySlug,
  ) async {
    if (quantitiesBySlug.isEmpty) return false;
    var ok = false;
    final messenger = ScaffoldMessenger.of(context);
    void showInventoryMessage(String message, {bool isError = false}) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.statusDanger : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    await _runInventoryAction(() async {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) {
          AppUtils.showSnackBar(context, 'Sesión expirada', isError: true);
        }
        return;
      }

      var failures = 0;
      var saved = 0;
      for (final item in catalog) {
        final qty = quantitiesBySlug[item.slug];
        if (qty == null) continue;

        final existing = _findProductByNombre(item.nombre);
        final Map<String, dynamic> res;
        if (existing != null) {
          res = await _inventoryService.addStock(
            itemId: existing.id,
            cantidad: qty,
            token: token,
          );
        } else {
          res = await _inventoryService.createItem(
            token: token,
            body: {
              'nombre': item.nombre,
              'categoria': item.categoria,
              'cantidad': qty,
              'unidad': item.unidad,
            },
          );
        }
        if (res['success'] == true) {
          saved++;
        } else {
          failures++;
        }
      }

      if (!mounted) return;
      await _reloadFromApi();
      if (!mounted) return;
      if (failures > 0 && saved == 0) {
        showInventoryMessage(
          'No se pudieron guardar los productos',
          isError: true,
        );
        return;
      }
      if (failures > 0) {
        showInventoryMessage(
          'Se guardaron $saved producto(s); $failures no se pudieron registrar',
          isError: true,
        );
      } else {
        showInventoryMessage(
          saved == 1 ? 'Producto agregado' : '$saved productos agregados',
        );
      }
      ok = saved > 0;
    });
    return ok;
  }

  Future<void> _removeProduct(String id) async {
    await _runInventoryAction(() async {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) {
          AppUtils.showSnackBar(context, 'Sesión expirada', isError: true);
        }
        return;
      }
      final res = await _inventoryService.deleteItem(itemId: id, token: token);
      if (!mounted) return;
      if (res['success'] != true) {
        AppUtils.showSnackBar(
          context,
          res['message']?.toString() ?? 'No se pudo eliminar',
          isError: true,
        );
        return;
      }
      await _reloadFromApi();
      if (mounted) {
        AppUtils.showSnackBar(context, 'Producto eliminado');
      }
    });
  }

  Future<void> _addStockRemote(String itemId, double add) async {
    await _runInventoryAction(() async {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) {
          AppUtils.showSnackBar(context, 'Sesión expirada', isError: true);
        }
        return;
      }
      final res = await _inventoryService.addStock(
        itemId: itemId,
        cantidad: add,
        token: token,
      );
      if (!mounted) return;
      if (res['success'] != true) {
        AppUtils.showSnackBar(
          context,
          res['message']?.toString() ?? 'No se pudo actualizar el stock',
          isError: true,
        );
        return;
      }
      await _reloadFromApi();
      if (mounted) {
        AppUtils.showSnackBar(context, 'Stock actualizado');
      }
    });
  }

  Future<void> _useStockRemote(String itemId, double used) async {
    await _runInventoryAction(() async {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) {
          AppUtils.showSnackBar(context, 'Sesión expirada', isError: true);
        }
        return;
      }
      final res = await _inventoryService.useStock(
        itemId: itemId,
        cantidad: used,
        token: token,
      );
      if (!mounted) return;
      if (res['success'] != true) {
        AppUtils.showSnackBar(
          context,
          res['message']?.toString() ?? 'No se pudo registrar el uso',
          isError: true,
        );
        return;
      }
      await _reloadFromApi();
      if (mounted) {
        AppUtils.showSnackBar(context, 'Stock actualizado');
      }
    });
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
                          await _addStockRemote(product.id, add);
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
                          await _useStockRemote(product.id, used);
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
    if (_actionInProgress) return;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          _BulkAddCatalogScreen(
        inventoryService: _inventoryService,
        authService: _authService,
        onSave: _saveCatalogQuantities,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
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
    return _withActionOverlay(Scaffold(
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
                  onPressed: _actionInProgress ? null : _openAddForm,
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
    ));
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

    return _withActionOverlay(Scaffold(
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
              final isCollapsed = _collapsedCategories.contains(cat);
              return [
                // Header de categoría
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          if (isCollapsed) {
                            _collapsedCategories.remove(cat);
                          } else {
                            _collapsedCategories.add(cat);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                            const SizedBox(width: 8),
                            Icon(
                              isCollapsed
                                  ? Icons.keyboard_arrow_right_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textMuted,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Tarjetas de productos
                if (!isCollapsed)
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
                            catalogInfo: _findCatalogByNombre(entry.value.nombre),
                            onAddMore: () => _openAddStockSheet(entry.key),
                            onRegisterUse: () => _openUseStockSheet(entry.key),
                            onDelete: () => _removeProduct(entry.value.id),
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
        onPressed: _actionInProgress ? null : _openAddForm,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Agregar', style: GoogleFonts.syne(fontWeight: FontWeight.w600)),
      ),
    ));
  }
}

class _InventorySafetyHint extends StatelessWidget {
  final String text;

  const _InventorySafetyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusWarning.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.statusWarning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.interTight(
              color: AppColors.textSecondary, fontSize: 11, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de producto ─────────────────────────
class _ProductCard extends StatefulWidget {
  final InventoryProduct product;
  final _CategoryInfo categoryInfo;
  final CatalogProduct? catalogInfo;
  final VoidCallback onAddMore;
  final VoidCallback onRegisterUse;
  final VoidCallback onDelete;
  const _ProductCard({
    required this.product,
    required this.categoryInfo,
    this.catalogInfo,
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
    final description = widget.catalogInfo?.descripcion ?? '';
    final safety = widget.catalogInfo?.seguridad ?? '';
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _hovered ? c.color.withValues(alpha: 0.16) : AppColors.border.withValues(alpha: 0.5)),
          boxShadow: _hovered
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))]
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
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(description, style: GoogleFonts.interTight(
                      color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
                  ],
                  if (safety.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InventorySafetyHint(text: safety),
                  ],
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

// ── Formulario alta masiva (catálogo de la calculadora) ──
class _BulkAddCatalogScreen extends StatefulWidget {
  final InventoryService inventoryService;
  final AuthService authService;
  final Future<bool> Function(
    List<CatalogProduct> catalog,
    Map<String, double> quantitiesBySlug,
  ) onSave;

  const _BulkAddCatalogScreen({
    required this.inventoryService,
    required this.authService,
    required this.onSave,
  });

  @override
  State<_BulkAddCatalogScreen> createState() => _BulkAddCatalogScreenState();
}

class _BulkAddCatalogScreenState extends State<_BulkAddCatalogScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  List<CatalogProduct> _catalog = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final token = await widget.authService.getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Sesión expirada';
        });
      }
      return;
    }
    final res = await widget.inventoryService.getCatalog(token);
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() {
        _loading = false;
        _loadError = res['message']?.toString() ?? 'No se pudo cargar el catálogo';
      });
      return;
    }
    final data = res['data'];
    final parsed = <CatalogProduct>[];
    if (data is Map<String, dynamic> && data['items'] is List) {
      for (final e in data['items'] as List) {
        if (e is Map<String, dynamic>) {
          parsed.add(CatalogProduct.fromJson(e));
        }
      }
    }
    for (final item in parsed) {
      _controllers[item.slug] = TextEditingController();
    }
    setState(() {
      _catalog = parsed;
      _loading = false;
      _loadError = parsed.isEmpty ? 'No hay productos en el catálogo' : null;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, double> _collectFilledQuantities() {
    final out = <String, double>{};
    for (final item in _catalog) {
      final ctrl = _controllers[item.slug];
      if (ctrl == null) continue;
      final raw = ctrl.text.trim();
      if (raw.isEmpty) continue;
      final n = double.tryParse(raw);
      if (n != null && n > 0) {
        out[item.slug] = n;
      }
    }
    return out;
  }

  String? _validateFilledFields() {
    for (final item in _catalog) {
      final ctrl = _controllers[item.slug];
      if (ctrl == null) continue;
      final raw = ctrl.text.trim();
      if (raw.isEmpty) continue;
      final n = double.tryParse(raw);
      if (n == null || n <= 0) {
        return 'Revisa la cantidad de "${item.nombre}"';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (_saving) return;
    final fieldError = _validateFilledFields();
    if (fieldError != null) {
      AppUtils.showSnackBar(context, fieldError, isError: true);
      return;
    }
    final quantities = _collectFilledQuantities();
    if (quantities.isEmpty) {
      AppUtils.showSnackBar(
        context,
        'Ingresa al menos una cantidad para agregar productos',
        isError: true,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await widget.onSave(_catalog, quantities);
      if (mounted && ok) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Agregar productos',
          style: GoogleFonts.syne(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _loadError != null
              ? _buildLoadError()
              : _buildForm(),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.statusDanger),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.interTight(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _loadError = null;
                });
                _loadCatalog();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Reintentar', style: GoogleFonts.interTight()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final grouped = <String, List<CatalogProduct>>{};
    for (final item in _catalog) {
      grouped.putIfAbsent(item.categoria, () => []);
      grouped[item.categoria]!.add(item);
    }
    final orderedCats = kCategorias.where((c) => grouped.containsKey(c)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Indica la cantidad de cada producto que tienes. '
            'Los campos vacíos no se agregarán. Unidades iguales a las recomendaciones del sistema.',
            style: GoogleFonts.interTight(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              for (final cat in orderedCats) ...[
                _buildCategoryHeader(cat),
                const SizedBox(height: 10),
                ...grouped[cat]!.map(_buildProductRow),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(
                _saving ? 'Guardando...' : 'Guardar productos',
                style: GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(String cat) {
    final info = _getCategory(cat);
    return Row(
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
        Text(
          cat.toUpperCase(),
          style: GoogleFonts.syne(
            color: info.color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(CatalogProduct item) {
    final ctrl = _controllers[item.slug]!;
    final catInfo = _getCategory(item.categoria);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: catInfo.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(catInfo.icon, color: catInfo.color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    style: GoogleFonts.interTight(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  if (item.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.descripcion, style: GoogleFonts.interTight(
                      color: AppColors.textSecondary, fontSize: 12, height: 1.3)),
                  ],
                  if (item.seguridad.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.statusWarning, size: 14),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(item.seguridad, style: GoogleFonts.interTight(
                            color: AppColors.textMuted, fontSize: 11, height: 1.25)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: TextField(
                controller: ctrl,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                textAlign: TextAlign.right,
                style: GoogleFonts.interTight(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: _inventoryQuantityPlaceholder(item.unidadEtiqueta),
                  hintStyle: GoogleFonts.interTight(color: AppColors.textMuted, fontSize: 13),
                  suffixText: item.unidadEtiqueta,
                  suffixStyle: GoogleFonts.interTight(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
