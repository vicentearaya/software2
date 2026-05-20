import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'frequent_problems_screen.dart';
import 'pool_filter_screen.dart';
import 'pool_cleaning_screen.dart';

// ── Persistencia ────────────────────────────────
const String _kLastGuide = 'guides_last_opened';

// ── Datos de guías ──────────────────────────────
class _GuideData {
  final String key;
  final String title;
  final String shortTitle;
  final String subtitle;
  final IconData icon;
  final String badge;
  final String readTime;
  final Color accentColor;

  const _GuideData({
    required this.key,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.readTime,
    required this.accentColor,
  });
}

const _guidesData = [
  _GuideData(
    key: 'frequent_problems',
    title: 'Problemas Frecuentes',
    shortTitle: 'Problemas',
    subtitle: 'Diagnóstico y solución paso a paso para los 6 problemas de agua más comunes.',
    icon: Icons.troubleshoot,
    badge: '6 problemas',
    readTime: '~8 min',
    accentColor: AppColors.statusWarning,
  ),
  _GuideData(
    key: 'pool_filter',
    title: 'Filtro de Piscina',
    shortTitle: 'Filtro',
    subtitle: 'Programación, modos de válvula y reglas de oro.',
    icon: Icons.cyclone,
    badge: '3 secciones',
    readTime: '~5 min',
    accentColor: AppColors.primary,
  ),
  _GuideData(
    key: 'pool_cleaning',
    title: 'Limpieza de Piscina',
    shortTitle: 'Limpieza',
    subtitle: 'Herramientas, frecuencia y técnicas profesionales.',
    icon: Icons.auto_fix_high,
    badge: '4 secciones',
    readTime: '~6 min',
    accentColor: AppColors.statusGood,
  ),
];

Widget _buildGuideContent(String key) {
  switch (key) {
    case 'frequent_problems':
      return const FrequentProblemsScreen(embedded: true);
    case 'pool_filter':
      return const PoolFilterScreen(embedded: true);
    case 'pool_cleaning':
      return const PoolCleaningScreen(embedded: true);
    default:
      return const SizedBox.shrink();
  }
}

// ── Pantalla principal ──────────────────────────
class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});
  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  String? _activeGuideKey; // null = mostrar hub
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadLastGuide();
  }

  Future<void> _loadLastGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_kLastGuide);
    if (mounted) setState(() { _activeGuideKey = last; _loaded = true; });
  }

  Future<void> _openGuide(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastGuide, key);
    setState(() => _activeGuideKey = key);
  }

  void _backToHub() {
    setState(() => _activeGuideKey = null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Si hay una guía activa, mostrar su contenido inline
    if (_activeGuideKey != null) {
      return _buildGuideView();
    }

    return _buildHub();
  }

  // ── Vista de guía (inline, bottom bar se mantiene) ──
  Widget _buildGuideView() {
    final guide = _guidesData.firstWhere((g) => g.key == _activeGuideKey,
        orElse: () => _guidesData[0]);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar con back + título + selector de guías
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Column(
                children: [
                  // Fila: back + título
                  Row(
                    children: [
                      IconButton(
                        onPressed: _backToHub,
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textPrimary, size: 22),
                        tooltip: 'Volver a guías',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          guide.title,
                          style: GoogleFonts.syne(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Selector horizontal de guías
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _guidesData.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final g = _guidesData[i];
                        final isActive = g.key == _activeGuideKey;
                        return _GuideChip(
                          label: g.shortTitle,
                          icon: g.icon,
                          color: g.accentColor,
                          isActive: isActive,
                          onTap: () => _openGuide(g.key),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                ],
              ),
            ),
            // Contenido de la guía
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_activeGuideKey),
                  child: _buildGuideContent(_activeGuideKey!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hub principal ──────────────────────────────
  Widget _buildHub() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('Guías', style: GoogleFonts.syne(
                color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Aprende a mantener tu piscina en óptimas condiciones.',
                style: GoogleFonts.interTight(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),

              const SizedBox(height: 24),

              // Hero card
              _HeroGuideCard(
                guide: _guidesData[0],
                onTap: () => _openGuide(_guidesData[0].key),
              ),
              const SizedBox(height: 14),

              // Cards secundarias
              isWide
                  ? Row(children: [
                      Expanded(child: _CompactGuideCard(
                        guide: _guidesData[1], onTap: () => _openGuide(_guidesData[1].key))),
                      const SizedBox(width: 14),
                      Expanded(child: _CompactGuideCard(
                        guide: _guidesData[2], onTap: () => _openGuide(_guidesData[2].key))),
                    ])
                  : Column(children: [
                      _CompactGuideCard(
                        guide: _guidesData[1], onTap: () => _openGuide(_guidesData[1].key)),
                      const SizedBox(height: 14),
                      _CompactGuideCard(
                        guide: _guidesData[2], onTap: () => _openGuide(_guidesData[2].key)),
                    ]),

              const SizedBox(height: 24),

              // Footer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Basadas en buenas prácticas de mantenimiento profesional.',
                    style: GoogleFonts.interTight(color: AppColors.textMuted, fontSize: 12, height: 1.3))),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Chip selector horizontal de guías
// ─────────────────────────────────────────────────
class _GuideChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  const _GuideChip({required this.label, required this.icon, required this.color,
      required this.isActive, required this.onTap});
  @override
  State<_GuideChip> createState() => _GuideChipState();
}

class _GuideChipState extends State<_GuideChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final active = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? c.withValues(alpha: 0.15)
                : _hovered
                    ? c.withValues(alpha: 0.06)
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? c.withValues(alpha: 0.4)
                  : _hovered
                      ? c.withValues(alpha: 0.2)
                      : AppColors.border.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15,
                  color: active ? c : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(widget.label, style: GoogleFonts.interTight(
                color: active ? c : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Hero Card
// ─────────────────────────────────────────────────
class _HeroGuideCard extends StatefulWidget {
  final _GuideData guide;
  final VoidCallback onTap;
  const _HeroGuideCard({required this.guide, required this.onTap});
  @override
  State<_HeroGuideCard> createState() => _HeroGuideCardState();
}

class _HeroGuideCardState extends State<_HeroGuideCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.guide.accentColor;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovered ? c.withValues(alpha: 0.5) : c.withValues(alpha: 0.2),
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: [BoxShadow(
                color: _hovered
                    ? c.withValues(alpha: 0.2)
                    : const Color(0xFF1A1A2E).withValues(alpha: 0.3),
                blurRadius: _hovered ? 24 : 20,
                offset: const Offset(0, 8),
              )],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            _chip(widget.guide.badge, c),
                            const SizedBox(width: 8),
                            _timeChip(widget.guide.readTime),
                          ]),
                          const SizedBox(height: 16),
                          Text('Problemas\nFrecuentes', style: GoogleFonts.syne(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
                          const SizedBox(height: 10),
                          Text(widget.guide.subtitle, style: GoogleFonts.interTight(
                            color: Colors.white.withValues(alpha: 0.65), fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: _hovered ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: c.withValues(alpha: 0.25)),
                      ),
                      child: Icon(widget.guide.icon, color: c, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.withValues(alpha: 0.25)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Ver guía completa', style: GoogleFonts.interTight(
                      color: c, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: c, size: 16),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
    child: Text(t, style: GoogleFonts.interTight(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _timeChip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.schedule_rounded, size: 11, color: Colors.white.withValues(alpha: 0.5)),
      const SizedBox(width: 4),
      Text(t, style: GoogleFonts.interTight(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
    ]),
  );
}

// ─────────────────────────────────────────────────
// Compact Card
// ─────────────────────────────────────────────────
class _CompactGuideCard extends StatefulWidget {
  final _GuideData guide;
  final VoidCallback onTap;
  const _CompactGuideCard({required this.guide, required this.onTap});
  @override
  State<_CompactGuideCard> createState() => _CompactGuideCardState();
}

class _CompactGuideCardState extends State<_CompactGuideCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.guide.accentColor;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _hovered ? c.withValues(alpha: 0.06) : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered ? c.withValues(alpha: 0.35) : AppColors.border.withValues(alpha: 0.4),
                width: _hovered ? 1.5 : 1),
              boxShadow: [BoxShadow(
                color: _hovered ? c.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
                blurRadius: _hovered ? 16 : 6, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: _hovered ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.withValues(alpha: 0.18)),
                      ),
                      child: Icon(widget.guide.icon, color: c, size: 22),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _hovered ? c.withValues(alpha: 0.12) : AppColors.surfaceElevated.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_forward_rounded,
                        size: 16, color: _hovered ? c : AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(widget.guide.title, style: GoogleFonts.syne(
                  color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700, height: 1.2)),
                const SizedBox(height: 6),
                Text(widget.guide.subtitle, style: GoogleFonts.interTight(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 14),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: c.withValues(alpha: 0.12))),
                    child: Text(widget.guide.badge, style: GoogleFonts.interTight(
                      color: c, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.schedule_rounded, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(widget.guide.readTime, style: GoogleFonts.interTight(
                    color: AppColors.textMuted, fontSize: 11)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
