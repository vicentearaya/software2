import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/pool_service.dart';

// ─────────────────────────────────────────────
// Modelo local de piscina
// ─────────────────────────────────────────────
class PoolData {
  final String nombre;
  final double largo;
  final double ancho;
  final double profundidad;
  final bool esInterior;
  final bool tieneFiltro;

  const PoolData({
    required this.nombre,
    required this.largo,
    required this.ancho,
    required this.profundidad,
    required this.esInterior,
    required this.tieneFiltro,
  });

  /// Volumen en litros: largo × ancho × profundidad × 1000
  double get volumenLitros => largo * ancho * profundidad * 1000;

  /// Volumen en m³
  double get volumenM3 => largo * ancho * profundidad;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'largo': largo,
        'ancho': ancho,
        'profundidad': profundidad,
        'esInterior': esInterior,
        'tieneFiltro': tieneFiltro,
      };

  factory PoolData.fromJson(Map<String, dynamic> json) => PoolData(
        nombre: json['nombre'] as String,
        largo: (json['largo'] as num).toDouble(),
        ancho: (json['ancho'] as num).toDouble(),
        profundidad: (json['profundidad'] as num).toDouble(),
        esInterior: json['esInterior'] as bool,
        tieneFiltro: json['tieneFiltro'] as bool,
      );
}

// ─────────────────────────────────────────────
// DashboardScreen principal
// ─────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _prefKey = 'pool_data';

  PoolData? _pool;
  bool _loading = true;
  String? _backendPoolId; // ID del documento en MongoDB
  final _authService = AuthService();
  final _poolService = PoolService();

  Map<String, dynamic>? _poolStatus;
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadPool();
  }

  Future<void> _loadPoolStatus() async {
    if (_backendPoolId == null) {
      if (mounted) setState(() => _loadingStatus = false);
      return;
    }
    if (mounted) setState(() => _loadingStatus = true);
    final token = await _authService.getToken();
    final result = await _poolService.getPoolStatus(_backendPoolId!, token: token);
    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _poolStatus = result['data'];
          _loadingStatus = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  /// Carga la piscina: primero intenta el backend, cae en caché local si falla.
  Future<void> _loadPool() async {
    setState(() => _loading = true);

    // Leer caché local primero (para poder combinar luego)
    final prefs = await SharedPreferences.getInstance();
    PoolData? localPool;
    final rawLocal = prefs.getString(_prefKey);
    if (rawLocal != null) {
      try { localPool = PoolData.fromJson(jsonDecode(rawLocal)); } catch (_) {}
    }

    // 1. Intentar cargar desde el backend
    final token = await _authService.getToken();
    if (token != null) {
      final result = await _poolService.getPools(token);
      if (result['success'] == true) {
        final List<dynamic> pools = result['data'] as List<dynamic>;
        if (pools.isNotEmpty) {
          final doc = pools.first as Map<String, dynamic>;

          // Dimensiones del backend (pueden ser 0 si es backend antiguo no desplegado)
          final backendLargo = (doc['largo'] as num?)?.toDouble() ?? 0;
          final backendAncho = (doc['ancho'] as num?)?.toDouble() ?? 0;
          final backendProf  = (doc['profundidad'] as num?)?.toDouble() ?? 0;

          // Si el backend devuelve 0 pero el caché local tiene datos válidos,
          // conservar las dimensiones locales (el backend aún no las retorna)
          final largo      = backendLargo > 0 ? backendLargo : (localPool?.largo ?? 0);
          final ancho      = backendAncho > 0 ? backendAncho : (localPool?.ancho ?? 0);
          final prof       = backendProf  > 0 ? backendProf  : (localPool?.profundidad ?? 0);
          final esInterior = (doc['tipo'] as String?) == 'interior';
          final filtro     = (doc['filtro'] as bool?) ?? (localPool?.tieneFiltro ?? true);

          final pool = PoolData(
            nombre: doc['nombre'] as String? ?? '',
            largo: largo,
            ancho: ancho,
            profundidad: prof,
            esInterior: esInterior,
            tieneFiltro: filtro,
          );
          _backendPoolId = doc['id'] as String?;

          // Actualizar caché local con la versión combinada
          await prefs.setString(_prefKey, jsonEncode(pool.toJson()));
          if (mounted) {
            setState(() {
              _pool = pool;
              _loading = false;
            });
          }
          _loadPoolStatus();
          return;
        }
      }
    }

    // 2. Fallback: caché local (sin conexión o sin piscina en backend)
    if (localPool != null) {
      if (mounted) {
        setState(() {
          _pool = localPool;
          _loading = false;
        });
      }
      _loadPoolStatus();
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Guarda la piscina en el backend Y en caché local.
  Future<void> _savePool(PoolData pool) async {
    // Guardar en caché local inmediatamente (UX responsiva)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(pool.toJson()));
    setState(() => _pool = pool);

    // Intentar guardar en el backend
    final token = await _authService.getToken();
    if (token == null) return;

    final payload = {
      'nombre': pool.nombre,
      'volumen': pool.volumenM3,
      'tipo': pool.esInterior ? 'interior' : 'exterior',
      'ubicacion': '',
      'largo': pool.largo,
      'ancho': pool.ancho,
      'profundidad': pool.profundidad,
      'filtro': pool.tieneFiltro,
    };

    Map<String, dynamic> result;

    if (_backendPoolId != null) {
      // Ya existe: actualizar (PUT)
      result = await _poolService.updatePool(_backendPoolId!, payload, token);
    } else {
      // Nueva piscina: crear (POST)
      result = await _poolService.createPool(payload, token);
      if (result['success'] == true) {
        _backendPoolId = (result['data'] as Map<String, dynamic>?)?['id'] as String?;
      }
    }
    // Si falla el backend, la piscina igual queda en caché local
  }

  /// Elimina la piscina del caché local (el backend no tiene DELETE en /piscinas aún).
  Future<void> _deletePool() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _backendPoolId = null;
    setState(() => _pool = null);
  }

  void _openAddPoolForm() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => AddPoolScreen(
          onSave: _savePool,
          initialData: _pool, // Pre-poblar con los datos actuales al editar
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return _pool == null ? _buildEmptyState() : _buildDashboard();
  }

  // ── Estado vacío ─────────────────────────────
  Widget _buildEmptyState() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono animado
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.pool_outlined,
                    size: 52,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Sin piscina registrada',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Agrega tu piscina para comenzar a\nmonitorear el estado del agua.',
                  style: GoogleFonts.interTight(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _openAddPoolForm,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Agregar piscina',
                    style: GoogleFonts.syne(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Dashboard con datos de piscina ────────────
  Widget _buildDashboard() {
    final pool = _pool!;
    final litros = pool.volumenLitros;
    final litrosStr = litros >= 1000
        ? '${(litros / 1000).toStringAsFixed(2)} m³ (${_formatNumber(litros)} L)'
        : '${_formatNumber(litros)} L';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: GoogleFonts.syne(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "Monitorea tu piscina",
                          style: GoogleFonts.interTight(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    // Botón eliminar piscina
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') _confirmDeletePool();
                        if (value == 'edit') _openAddPoolForm();
                      },
                      color: AppColors.surfaceElevated,
                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                              const SizedBox(width: 10),
                              Text('Editar piscina', style: GoogleFonts.interTight(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: AppColors.statusDanger, size: 18),
                              const SizedBox(width: 10),
                              Text('Eliminar piscina', style: GoogleFonts.interTight(color: AppColors.statusDanger)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Indicador de Aptitud ────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildStatusWidget(),
              ),
            ),

            // ── Tarjeta principal de la piscina ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _PoolCard(pool: pool, litrosStr: litrosStr),
              ),
            ),

            // ── Representación visual de la piscina ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _PoolVisualCard(pool: pool),
              ),
            ),

            // ── Dimensiones compactas ────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CompactDimension(label: 'Largo', value: '${pool.largo} m'),
                      _VerticalDivider(),
                      _CompactDimension(label: 'Ancho', value: '${pool.ancho} m'),
                      _VerticalDivider(),
                      _CompactDimension(label: 'Prof.', value: '${pool.profundidad} m'),
                      _VerticalDivider(),
                      _CompactDimension(label: 'Vol.', value: '${pool.volumenM3.toStringAsFixed(1)} m³'),
                    ],
                  ),
                ),
              ),
            ),

            // ── Características ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'Características',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _InfoRow(
                    icon: pool.esInterior ? Icons.home_rounded : Icons.wb_sunny_rounded,
                    label: 'Tipo de instalación',
                    value: pool.esInterior ? 'Interior' : 'Exterior',
                    color: pool.esInterior ? AppColors.accent : AppColors.statusWarning,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: pool.tieneFiltro ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    label: 'Sistema de filtración',
                    value: pool.tieneFiltro ? 'Con filtro' : 'Sin filtro',
                    color: pool.tieneFiltro ? AppColors.statusGood : AppColors.statusDanger,
                  ),
                ]),
              ),
            ),

            // ── Tarjeta de Limpieza Manual Express ──
            if (_pool != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _ManualTreatmentCard(poolId: _backendPoolId),
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    if (_loadingStatus) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Default: gris
    Color bgColor = const Color(0xFF374151); // Gris neutro
    Color iconColor = Colors.white70;
    IconData icon = Icons.help_outline;
    String text = "Sin datos disponibles";
    String subText = "No hay lecturas registradas";

    Map<String, dynamic>? parametros;

    if (_poolStatus != null && _poolStatus!['estado'] != null) {
      parametros = _poolStatus!['parametros'] as Map<String, dynamic>?;
      final estado = _poolStatus!['estado'];
      if (estado == 'APTA') {
        bgColor = const Color(0xFF1B5E20); // Verde oscuro brillante
        iconColor = Colors.white;
        icon = Icons.check_circle_outline;
        text = "¡Apta para baño! Disfruta tu piscina 🏊";
        subText = "Los niveles químicos son óptimos.";
      } else if (estado == 'NO APTA') {
        bool hasData = false;
        if (parametros != null) {
          final ph = parametros['ph']?['valor'];
          final cloro = parametros['cloro']?['valor'];
          if (ph != null || cloro != null) {
            hasData = true;
          }
        }
        if (hasData) {
          bgColor = const Color(0xFFB71C1C); // Rojo oscuro brillante
          iconColor = Colors.white;
          icon = Icons.warning_amber_rounded;
          text = "No apta para baño";
          subText = "Revisa los parámetros químicos.";
        } else {
          // No apta pero por falta de datos
          bgColor = const Color(0xFF424242); 
          iconColor = Colors.white70;
          icon = Icons.info_outline;
          text = "Sin datos disponibles";
          subText = "Agrega una lectura o revisa los sensores.";
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subText,
                      style: GoogleFonts.interTight(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (parametros != null && (parametros['ph']?['valor'] != null || parametros['cloro']?['valor'] != null)) ...[
            const SizedBox(height: 16),
            Container(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildParamIndicator('pH', parametros['ph']),
                _buildParamIndicator('Cloro', parametros['cloro']),
                _buildParamIndicator('Temp.', parametros['temperatura']),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParamIndicator(String name, Map<String, dynamic>? paramData) {
    if (paramData == null || paramData['valor'] == null) {
      return Column(
        children: [
          Text(name, style: GoogleFonts.interTight(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          const Text("-", style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      );
    }

    final double valor = (paramData['valor'] as num).toDouble();
    final String estado = paramData['estado'] as String? ?? 'SIN DATOS';
    
    // Check if it's normal
    final bool isNormal = estado == 'NORMAL';
    final IconData pIcon = isNormal ? Icons.check_circle : Icons.cancel;
    final Color pColor = isNormal ? const Color(0xFF81C784) : const Color(0xFFE57373); // Colores más claros para mejor contraste oscuro
    
    String valStr = valor.toString();
    if (name == 'Temp.') valStr += '°C';
    else if (name == 'Cloro') valStr += ' ppm';

    return Column(
      children: [
        Text(name, style: GoogleFonts.interTight(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valStr,
              style: GoogleFonts.syne(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(pIcon, color: pColor, size: 14),
          ],
        ),
      ],
    );
  }

  void _confirmDeletePool() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar piscina',
          style: GoogleFonts.syne(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Seguro que quieres eliminar esta piscina? Se perderán los datos locales.',
          style: GoogleFonts.interTight(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.interTight(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePool();
            },
            child: Text('Eliminar', style: GoogleFonts.interTight(color: AppColors.statusDanger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

// ─────────────────────────────────────────────
// Tarjeta principal de la piscina
// ─────────────────────────────────────────────
class _PoolCard extends StatelessWidget {
  final PoolData pool;
  final String litrosStr;

  const _PoolCard({required this.pool, required this.litrosStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
        ),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre + ícono
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pool_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pool.nombre,
                      style: GoogleFonts.syne(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      pool.esInterior ? 'Piscina Interior' : 'Piscina Exterior',
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

          const SizedBox(height: 24),

          // Volumen destacado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.water_drop_rounded, color: AppColors.accent, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capacidad total',
                      style: GoogleFonts.interTight(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      litrosStr,
                      style: GoogleFonts.syne(
                        color: AppColors.accent,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Representación visual isométrica de la piscina
// ─────────────────────────────────────────────
class _PoolVisualCard extends StatefulWidget {
  final PoolData pool;
  const _PoolVisualCard({required this.pool});

  @override
  State<_PoolVisualCard> createState() => _PoolVisualCardState();
}

class _PoolVisualCardState extends State<_PoolVisualCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_in_ar_rounded,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Vista de la piscina',
                style: GoogleFonts.syne(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRect(
            child: SizedBox(
              width: double.infinity,
              height: 160,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(
                  painter: _PoolPainter(animValue: _ctrl.value),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolPainter extends CustomPainter {
  final double animValue;
  const _PoolPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const border = 12.0;   // grosor del borde de azulejo
    const r = 14.0;        // radio esquinas externas
    const ri = 8.0;        // radio esquinas internas (agua)

    // ── 1. Fondo exterior (borde tipo azulejo) ─
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h), const Radius.circular(r));
    canvas.drawRRect(
      outerRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF112240)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Líneas de rejilla del borde (efecto azulejo)
    final tilePaint = Paint()
      ..color = const Color(0xFF2A4A70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    // horizontales
    for (double y = border; y < h - border; y += border) {
      canvas.drawLine(Offset(0, y), Offset(w, y), tilePaint);
    }
    // verticales
    for (double x = border; x < w - border; x += border) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), tilePaint);
    }

    // ── 2. Área de agua ────────────────────────
    final waterRect = Rect.fromLTWH(border, border,
        w - border * 2, h - border * 2);
    final waterRRect = RRect.fromRectAndRadius(
        waterRect, const Radius.circular(ri));

    // Gradiente de agua animado
    final shimmer = (math.sin(animValue * 2 * math.pi) + 1) / 2;
    final c1 = Color.lerp(
        const Color(0xFF1565C0), const Color(0xFF0288D1), shimmer)!;
    final c2 = Color.lerp(
        const Color(0xFF29B6F6), const Color(0xFF00ACC1), shimmer)!;

    canvas.drawRRect(
      waterRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ).createShader(waterRect),
    );

    // ── 3. Ondas animadas ──────────────────────
    canvas.save();
    canvas.clipRRect(waterRRect);

    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final waveCount = 4;
    for (int i = 0; i < waveCount; i++) {
      // Cada ola se desplaza con la animación
      final yFrac = ((animValue + i / waveCount) % 1.0);
      final yPos = waterRect.top + yFrac * waterRect.height;
      final path = Path();
      path.moveTo(waterRect.left, yPos);
      const segments = 4;
      final segW = waterRect.width / segments;
      for (int s = 0; s < segments; s++) {
        final x1 = waterRect.left + s * segW + segW * 0.25;
        final x2 = waterRect.left + s * segW + segW * 0.75;
        final x3 = waterRect.left + (s + 1) * segW;
        final crest = (s % 2 == 0) ? -5.0 : 5.0;
        path.cubicTo(x1, yPos + crest, x2, yPos - crest, x3, yPos);
      }
      canvas.drawPath(path, wavePaint);
    }

    // ── 4. Reflejo de luz diagonal ─────────────
    final reflectShift = animValue * waterRect.width * 0.3;
    final reflectPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.07),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(waterRect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        waterRect.left + reflectShift,
        waterRect.top,
        waterRect.width * 0.4,
        waterRect.height,
      ),
      reflectPaint,
    );

    canvas.restore();

    // ── 5. Escalerilla (esquina sup-derecha) ───
    final ladderX = waterRect.right - 14;
    final ladderPaint = Paint()
      ..color = const Color(0xFF90CAF9).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    // Dos rieles verticales
    canvas.drawLine(
        Offset(ladderX - 5, border - 4),
        Offset(ladderX - 5, waterRect.top + 22), ladderPaint);
    canvas.drawLine(
        Offset(ladderX + 5, border - 4),
        Offset(ladderX + 5, waterRect.top + 22), ladderPaint);
    // Peldaños horizontales
    for (int s = 0; s < 3; s++) {
      final sy = waterRect.top + 4 + s * 9.0;
      canvas.drawLine(
          Offset(ladderX - 5, sy), Offset(ladderX + 5, sy), ladderPaint);
    }

    // ── 6. Borde azulejo contorno ──────────────
    canvas.drawRRect(
      outerRect,
      Paint()
        ..color = const Color(0xFF4FC3F7).withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      waterRRect,
      Paint()
        ..color = const Color(0xFF80DEEA).withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_PoolPainter old) => old.animValue != animValue;
}

// ─────────────────────────────────────────────
// Fila de información
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.interTight(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: GoogleFonts.syne(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pantalla de formulario: Agregar piscina
// ─────────────────────────────────────────────
class AddPoolScreen extends StatefulWidget {
  final Future<void> Function(PoolData) onSave;
  final PoolData? initialData;

  const AddPoolScreen({super.key, required this.onSave, this.initialData});

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

  // Cálculo en vivo
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
    // Recalcular en tiempo real
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
            // ── AppBar manual ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
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

            // ── Formulario ────────────────────
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

                      // Nombre
                      _SectionLabel(label: 'Nombre de la piscina'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nombreCtrl,
                        hint: 'Ej: Piscina principal, Casa de playa…',
                        icon: Icons.pool_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                      ),

                      const SizedBox(height: 24),
                      _SectionLabel(label: 'Dimensiones (en metros)'),
                      const SizedBox(height: 8),

                      // Largo + Ancho en fila
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

                      // Profundidad
                      _buildTextField(
                        controller: _profundidadCtrl,
                        hint: 'Profundidad',
                        icon: Icons.vertical_align_bottom_rounded,
                        isNumber: true,
                        validator: _validatePositiveNumber,
                      ),

                      // Preview de litros en tiempo real
                      if (_litros > 0) ...[
                        const SizedBox(height: 16),
                        _LitrosPreview(litros: _litros),
                      ],

                      const SizedBox(height: 24),

                      // Interior / Exterior
                      _SectionLabel(label: 'Tipo de instalación'),
                      const SizedBox(height: 10),
                      _TypeSelector(
                        selectedInterior: _esInterior,
                        onChanged: (v) => setState(() => _esInterior = v),
                      ),

                      const SizedBox(height: 24),

                      // Filtro
                      _SectionLabel(label: 'Sistema de filtración'),
                      const SizedBox(height: 10),
                      _FilterSelector(
                        hasFiltro: _tieneFiltro,
                        onChanged: (v) => setState(() => _tieneFiltro = v),
                      ),

                      const SizedBox(height: 36),

                      // Botón guardar
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Agregar piscina',
                                style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 15),
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
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d\.]'))]
          : null,
      style: GoogleFonts.interTight(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.interTight(color: AppColors.textMuted, fontSize: 14),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets del formulario
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

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
  final double litros;
  const _LitrosPreview({required this.litros});

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
          const Icon(Icons.water_drop_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 10),
          Text(
            'Capacidad estimada: ',
            style: GoogleFonts.interTight(color: AppColors.textSecondary, fontSize: 13),
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

/// Selector Interior / Exterior
class _TypeSelector extends StatelessWidget {
  final bool selectedInterior;
  final ValueChanged<bool> onChanged;

  const _TypeSelector({required this.selectedInterior, required this.onChanged});

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

/// Selector Tiene filtro / No tiene
class _FilterSelector extends StatelessWidget {
  final bool hasFiltro;
  final ValueChanged<bool> onChanged;

  const _FilterSelector({required this.hasFiltro, required this.onChanged});

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
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

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
              Icon(icon, color: selected ? color : AppColors.textMuted, size: 22),
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

// ─────────────────────────────────────────────
// Dimensión compacta (para la fila horizontal)
// ─────────────────────────────────────────────
class _CompactDimension extends StatelessWidget {
  final String label;
  final String value;

  const _CompactDimension({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.syne(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.interTight(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
    );
  }
}

// ─────────────────────────────────────────────
// Tarjeta de Limpieza Manual Exprés
// ─────────────────────────────────────────────
class _ManualTreatmentCard extends StatefulWidget {
  final String? poolId;

  const _ManualTreatmentCard({required this.poolId});

  @override
  State<_ManualTreatmentCard> createState() => _ManualTreatmentCardState();
}

class _ManualTreatmentCardState extends State<_ManualTreatmentCard> {
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
        widget.poolId!, ph, cloro, token);

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _tratamiento = res['data']['tratamiento'] as List<dynamic>?;
      } else {
        _errorMessage = res['message'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // Glassmorphism effect background
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            Colors.transparent,
          ],
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
                child: const Icon(Icons.science_rounded,
                    color: AppColors.primary, size: 20),
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
          // Formulario horizontal
          Row(
            children: [
              Expanded(
                child: _buildInput('pH', 'ej. 7.4', _phCtrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInput('Cloro (ppm)', 'ej. 1.5', _cloroCtrl),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Botón Calcular
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
                          strokeWidth: 2.5, color: Colors.white),
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
          // Errores
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.interTight(
                    color: AppColors.statusDanger, fontSize: 13),
              ),
            ),

          // Resultado Animado
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
                color: AppColors.textMuted, fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
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
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.statusGood),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¡El agua está en óptimas condiciones!',
                style: GoogleFonts.interTight(
                    color: AppColors.statusGood, fontWeight: FontWeight.w600),
              ),
            )
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
                  const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['instrucciones'] ?? '',
                      style: GoogleFonts.interTight(color: AppColors.textSecondary, fontSize: 13),
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
                )
              ]
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
                  child: const Icon(Icons.water_drop, color: AppColors.accent, size: 16),
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
