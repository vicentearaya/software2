import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class PoolFilterScreen extends StatelessWidget {
  const PoolFilterScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return _buildContent();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Filtro de Piscina',
          style: GoogleFonts.syne(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        const _FilterDiagramWidget(),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: '1. Programación Diaria',
          subtitle: 'Modo FILTRACIÓN — Mantiene el agua libre de partículas.',
          icon: Icons.timer_outlined,
          iconColor: AppColors.primary,
          children: [
            _buildSubsection(
              title: 'Temporada de Verano',
              description: 'Uso intenso y calor.',
              items: [
                {'label': 'Tiempo', 'value': 'Entre 8 y 12 horas diarias.'},
                {
                  'label': 'Consejo',
                  'value':
                      'Evita 12 horas seguidas. Mejor dividir en bloques (ej. 6h mañana y 6h tarde) para evitar estancamiento.'
                },
              ],
              icon: Icons.wb_sunny_outlined,
              color: AppColors.statusWarning,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.border.withOpacity(0.1),
                      AppColors.border,
                      AppColors.border.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            _buildSubsection(
              title: 'Temporada de Invierno',
              description: 'Mantenimiento preventivo.',
              items: [
                {'label': 'Tiempo', 'value': 'Entre 2 y 4 horas diarias.'},
                {
                  'label': 'Objetivo',
                  'value':
                      'Evitar proliferación de algas o larvas, aunque la piscina no se use.'
                },
              ],
              icon: Icons.ac_unit_rounded,
              color: AppColors.primaryLight,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          title: '2. Modos de la Válvula',
          subtitle: 'Cuándo usar las funciones adicionales al filtro.',
          icon: Icons.tune_rounded,
          iconColor: AppColors.accent,
          children: [
            _buildModeItem(
              title: 'Modo RECIRCULACIÓN',
              subtitle: 'Sin pasar por el filtro.',
              whenToUse:
                  'Al añadir químicos potentes (cloro choque, algicida).',
              why:
                  'Mezcla el producto rápidamente (30-60 min) sin saturar la arena.',
              icon: Icons.recycling_rounded,
            ),
            const SizedBox(height: 10),
            _buildModeItem(
              title: 'Modo DESAGÜE / VACIADO',
              subtitle: 'Waste / Drenaje directo a la calle.',
              whenToUse:
                  'Para aspirar fondo muy sucio (tierra o algas muertas).',
              why:
                  'Evita saturar el filtro en 5 minutos en modo filtración.',
              icon: Icons.shower_outlined,
            ),
            const SizedBox(height: 10),
            _buildModeItem(
              title: 'Modo LAVADO y ENJUAGUE',
              subtitle: 'Backwash / Rinse',
              whenToUse: 'Una vez a la semana en verano.',
              why:
                  'Si los chorros de retorno pierden fuerza, es señal de filtro saturado. Ayuda a limpiar la arena para recuperar presión.',
              icon: Icons.build_circle_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildGoldenRulesCard(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.syne(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.interTight(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubsection({
    required String title,
    required String description,
    required List<Map<String, String>> items,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.syne(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: GoogleFonts.interTight(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 10, top: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    item['label']!.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.interTight(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item['value']!,
                    style: GoogleFonts.interTight(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildModeItem({
    required String title,
    required String subtitle,
    required String whenToUse,
    required String why,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.syne(
                        color: AppColors.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.interTight(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoint('Cuándo:', whenToUse),
          const SizedBox(height: 6),
          _buildBulletPoint('Por qué:', why),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6.0, right: 8.0),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.interTight(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.45,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: text,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoldenRulesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.statusDanger.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusDanger.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.statusDanger.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusDanger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.statusDanger, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                '3. Reglas de Oro',
                style: GoogleFonts.syne(
                  color: AppColors.statusDanger,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRuleRow(
            icon: Icons.do_not_touch,
            text:
                'NUNCA muevas la palanca de la válvula con la bomba encendida. Podrías romper las juntas y generar filtraciones.',
          ),
          const SizedBox(height: 12),
          _buildRuleRow(
            icon: Icons.water_drop,
            text:
                'El agua siempre a la mitad de la boca del skimmer. Si está más baja, la bomba succionará aire y podría quemarse.',
          ),
          const SizedBox(height: 12),
          _buildRuleRow(
            icon: Icons.delete_outline,
            text:
                'Pre-filtro: Una vez por semana, apaga todo y limpia la canastilla de la bomba. Sin ella limpia, el filtro no tiene fuerza.',
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.statusDanger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: AppColors.statusDanger.withOpacity(0.8), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.interTight(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterDiagramWidget extends StatefulWidget {
  const _FilterDiagramWidget();

  @override
  State<_FilterDiagramWidget> createState() => _FilterDiagramWidgetState();
}

class _FilterDiagramWidgetState extends State<_FilterDiagramWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  String _selectedMode = 'filtracion';

  final List<Map<String, dynamic>> _modes = [
    {
      'id': 'filtracion',
      'label': 'Filtración',
      'icon': Icons.filter_alt_rounded,
      'color': AppColors.primary,
      'title': 'Modo FILTRACIÓN',
      'description':
          'El agua pasa por la arena de arriba a abajo, reteniendo partículas de suciedad, y vuelve limpia a la piscina. Úsalo diariamente.',
      'time': '8 a 12 horas (verano) / 2 a 4 horas (invierno).',
    },
    {
      'id': 'recirculacion',
      'label': 'Recirculación',
      'icon': Icons.recycling_rounded,
      'color': AppColors.accent,
      'title': 'Modo RECIRCULACIÓN',
      'description':
          'El agua vuelve directamente a la piscina sin pasar por la arena. Ideal para mezclar químicos potentes (cloro choque, algicida) rápidamente.',
      'time': '30 a 60 minutos.',
    },
    {
      'id': 'desague',
      'label': 'Desagüe / Vaciado',
      'icon': Icons.shower_outlined,
      'color': AppColors.statusDanger,
      'title': 'Modo DESAGÜE',
      'description':
          'El agua se succiona y se envía directamente al desagüe de la calle. Se usa para aspirar tierra muy densa o algas muertas sin saturar el filtro.',
      'time': 'Durante la limpieza del fondo.',
    },
    {
      'id': 'lavado',
      'label': 'Lavado (Backwash)',
      'icon': Icons.water_drop_outlined,
      'color': AppColors.statusWarning,
      'title': 'Modo LAVADO',
      'description':
          'El flujo del agua se invierte (de abajo a arriba) para sacudir la arena del filtro y expulsar la suciedad retenida hacia la calle.',
      'time': '2 a 3 minutos (hasta que la mirilla se vea limpia).',
    },
    {
      'id': 'enjuague',
      'label': 'Enjuague (Rinse)',
      'icon': Icons.thumb_up_alt_outlined,
      'color': AppColors.primaryLight,
      'title': 'Modo ENJUAGUE',
      'description':
          'El agua fluye de arriba a abajo pero se bota a la calle. Úsalo tras el lavado para compactar la arena y evitar que vuelva suciedad a la piscina.',
      'time': '30 a 60 segundos.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeMode = _modes.firstWhere((m) => m['id'] == _selectedMode);
    final Color activeColor = activeMode['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Flujo del Agua Interactivo',
                style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona un modo de la válvula selectora para ver por dónde fluye el agua en los tubos.',
            style: GoogleFonts.interTight(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Mode Selector Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _modes.map((m) {
              final isSelected = _selectedMode == m['id'];
              final color = m['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedMode = m['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color.withOpacity(0.6) : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        m['icon'] as IconData,
                        color: isSelected ? color : AppColors.textMuted,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m['label'] as String,
                        style: GoogleFonts.syne(
                          color: isSelected ? color : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Animated Schematic Canvas
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FilterFlowPainter(
                    mode: _selectedMode,
                    animValue: _animCtrl.value,
                    activeColor: activeColor,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Guidelines Box
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: activeColor.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeMode['title'] as String,
                  style: GoogleFonts.syne(
                    color: activeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activeMode['description'] as String,
                  style: GoogleFonts.interTight(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: activeColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tiempo: ${activeMode['time']}',
                        style: GoogleFonts.interTight(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
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

class _FilterFlowPainter extends CustomPainter {
  final String mode;
  final double animValue;
  final Color activeColor;

  _FilterFlowPainter({
    required this.mode,
    required this.animValue,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Reference Coordinates
    final poolSource = Offset(30, h * 0.7);
    final poolReturn = Offset(30, h * 0.42);
    final bomba = Offset(w * 0.32, h * 0.76);
    final valve = Offset(w * 0.54, h * 0.32);
    final filterTop = Offset(w * 0.78, h * 0.55);
    final filterBottom = Offset(w * 0.78, h * 0.85);
    final waste = Offset(w * 0.9, h * 0.16);

    // Paths for flow depending on mode
    final List<List<Offset>> pipes = [];

    // 1. Suction pipe (Common: PoolSource -> Pump -> Valve)
    final commonSuction = [
      poolSource,
      Offset(bomba.dx, poolSource.dy),
      bomba,
      Offset(bomba.dx, h * 0.56),
      Offset(valve.dx, h * 0.56),
      valve
    ];
    pipes.add(commonSuction);

    if (mode == 'filtracion') {
      // Valve -> Filter Top
      pipes.add([valve, Offset(filterTop.dx, valve.dy), filterTop]);
      // Filter Top -> Filter Bottom
      pipes.add([filterTop, filterBottom]);
      // Filter Bottom -> Valve
      pipes.add([
        filterBottom,
        Offset(filterBottom.dx - 22, filterBottom.dy),
        Offset(filterBottom.dx - 22, h * 0.48),
        Offset(valve.dx, h * 0.48),
        valve
      ]);
      // Valve -> Return
      pipes.add([
        valve,
        Offset(valve.dx - 36, valve.dy),
        Offset(valve.dx - 36, poolReturn.dy),
        poolReturn
      ]);
    } else if (mode == 'recirculacion') {
      // Valve -> Return Directly
      pipes.add([
        valve,
        Offset(valve.dx - 36, valve.dy),
        Offset(valve.dx - 36, poolReturn.dy),
        poolReturn
      ]);
    } else if (mode == 'desague') {
      // Valve -> Waste
      pipes.add([valve, Offset(waste.dx, valve.dy), waste]);
    } else if (mode == 'lavado') {
      // Valve -> Filter Bottom (Reversed)
      pipes.add([
        valve,
        Offset(filterBottom.dx - 22, h * 0.48),
        Offset(filterBottom.dx - 22, filterBottom.dy),
        filterBottom
      ]);
      // Filter Bottom -> Filter Top (Upward cleaning)
      pipes.add([filterBottom, filterTop]);
      // Filter Top -> Valve
      pipes.add([filterTop, Offset(filterTop.dx, valve.dy), valve]);
      // Valve -> Waste
      pipes.add([valve, Offset(waste.dx, valve.dy), waste]);
    } else if (mode == 'enjuague') {
      // Valve -> Filter Top
      pipes.add([valve, Offset(filterTop.dx, valve.dy), filterTop]);
      // Filter Top -> Filter Bottom
      pipes.add([filterTop, filterBottom]);
      // Filter Bottom -> Valve
      pipes.add([
        filterBottom,
        Offset(filterBottom.dx - 22, filterBottom.dy),
        Offset(filterBottom.dx - 22, h * 0.48),
        Offset(valve.dx, h * 0.48),
        valve
      ]);
      // Valve -> Waste
      pipes.add([valve, Offset(waste.dx, valve.dy), waste]);
    }

    // Paint static pipes in background (light grey)
    final bgPipePaint = Paint()
      ..color = AppColors.border.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw all possible background pipes
    final allBackgroundPipes = [
      commonSuction,
      [valve, Offset(valve.dx - 36, valve.dy), Offset(valve.dx - 36, poolReturn.dy), poolReturn],
      [valve, Offset(waste.dx, valve.dy), waste],
      [valve, Offset(filterTop.dx, valve.dy), filterTop],
      [filterTop, filterBottom],
      [
        filterBottom,
        Offset(filterBottom.dx - 22, filterBottom.dy),
        Offset(filterBottom.dx - 22, h * 0.48),
        Offset(valve.dx, h * 0.48),
        valve
      ],
    ];

    for (final p in allBackgroundPipes) {
      final path = Path();
      path.moveTo(p.first.dx, p.first.dy);
      for (int i = 1; i < p.length; i++) {
        path.lineTo(p[i].dx, p[i].dy);
      }
      canvas.drawPath(path, bgPipePaint);
    }

    // Draw active pipes highlighted
    final activePipePaint = Paint()
      ..color = activeColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final p in pipes) {
      final path = Path();
      path.moveTo(p.first.dx, p.first.dy);
      for (int i = 1; i < p.length; i++) {
        path.lineTo(p[i].dx, p[i].dy);
      }
      canvas.drawPath(path, activePipePaint);
    }

    // Draw bubbles/particles inside active pipes
    for (final p in pipes) {
      _drawBubbles(canvas, p, animValue, activeColor);
    }

    // --- DRAW HUBS ---
    final textPaint = TextPainter(textDirection: TextDirection.ltr);

    // 1. Piscina (Draw pool visual bucket)
    final poolCenter = Offset(35, h * 0.55);
    final poolRect = Rect.fromCenter(center: poolCenter, width: 44, height: 75);
    canvas.drawRRect(
      RRect.fromRectAndRadius(poolRect, const Radius.circular(8)),
      Paint()..color = AppColors.surfaceElevated..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(poolRect, const Radius.circular(8)),
      Paint()..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );
    // Fill pool with water
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(poolRect, const Radius.circular(8)));
    canvas.drawRect(
      Rect.fromLTWH(poolRect.left, poolRect.bottom - 48, poolRect.width, 48),
      Paint()..color = AppColors.primary.withOpacity(0.25)..style = PaintingStyle.fill,
    );
    canvas.restore();
    // Draw label
    textPaint.text = TextSpan(
      text: 'PISCINA',
      style: GoogleFonts.syne(
        color: AppColors.textPrimary,
        fontSize: 8.0,
        fontWeight: FontWeight.bold,
      ),
    );
    textPaint.layout();
    textPaint.paint(canvas, poolCenter - Offset(textPaint.width / 2, textPaint.height / 2));

    // 2. Bomba
    canvas.drawCircle(
      bomba,
      14,
      Paint()..color = AppColors.surfaceElevated..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      bomba,
      14,
      Paint()..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );
    textPaint.text = TextSpan(
      text: 'BOMBA',
      style: GoogleFonts.syne(
        color: AppColors.textPrimary,
        fontSize: 7.0,
        fontWeight: FontWeight.bold,
      ),
    );
    textPaint.layout();
    textPaint.paint(canvas, bomba - Offset(textPaint.width / 2, textPaint.height / 2));

    // 3. Válvula
    canvas.drawCircle(
      valve,
      19,
      Paint()..color = AppColors.surfaceElevated..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      valve,
      19,
      Paint()..color = activeColor.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
    textPaint.text = TextSpan(
      text: 'VÁLVULA',
      style: GoogleFonts.syne(
        color: activeColor,
        fontSize: 7.5,
        fontWeight: FontWeight.bold,
      ),
    );
    textPaint.layout();
    textPaint.paint(canvas, valve - Offset(textPaint.width / 2, textPaint.height / 2));

    // 4. Filtro Arena cylinder
    final filterCenter = Offset(w * 0.78, h * 0.7);
    final filterRect = Rect.fromCenter(center: filterCenter, width: 50, height: 60);
    canvas.drawRRect(
      RRect.fromRectAndRadius(filterRect, const Radius.circular(8)),
      Paint()..color = AppColors.surfaceElevated..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(filterRect, const Radius.circular(8)),
      Paint()..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );
    // Fill sand
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(filterRect, const Radius.circular(8)));
    canvas.drawRect(
      Rect.fromLTWH(filterRect.left, filterRect.bottom - 38, filterRect.width, 38),
      Paint()..color = const Color(0xFFD2B48C).withOpacity(0.4)..style = PaintingStyle.fill, // sand color
    );
    canvas.restore();
    // Label
    textPaint.text = TextSpan(
      text: 'FILTRO\nARENA',
      style: GoogleFonts.syne(
        color: AppColors.textPrimary,
        fontSize: 7.5,
        fontWeight: FontWeight.bold,
      ),
    );
    textPaint.textAlign = TextAlign.center;
    textPaint.layout();
    textPaint.paint(canvas, filterCenter - Offset(textPaint.width / 2, textPaint.height / 2));

    // 5. Desagüe
    final wasteRect = Rect.fromCenter(center: waste, width: 46, height: 22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(wasteRect, const Radius.circular(6)),
      Paint()..color = AppColors.surfaceElevated..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(wasteRect, const Radius.circular(6)),
      Paint()..color = AppColors.statusDanger.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );
    textPaint.text = TextSpan(
      text: 'DESAGÜE',
      style: GoogleFonts.syne(
        color: AppColors.statusDanger,
        fontSize: 7.0,
        fontWeight: FontWeight.bold,
      ),
    );
    textPaint.layout();
    textPaint.paint(canvas, waste - Offset(textPaint.width / 2, textPaint.height / 2));
  }

  void _drawBubbles(Canvas canvas, List<Offset> points, double animValue, Color color) {
    if (points.length < 2) return;
    final bubblePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double totalLength = 0;
    final lengths = <double>[];
    for (int i = 0; i < points.length - 1; i++) {
      final len = (points[i + 1] - points[i]).distance;
      lengths.add(len);
      totalLength += len;
    }

    const double spacing = 28.0;
    double offset = (animValue * spacing) % spacing;

    while (offset < totalLength) {
      double current = 0;
      for (int i = 0; i < points.length - 1; i++) {
        final segLen = lengths[i];
        if (offset >= current && offset <= current + segLen) {
          final t = (offset - current) / segLen;
          final bubblePos = Offset.lerp(points[i], points[i + 1], t)!;
          canvas.drawCircle(bubblePos, 2.5, bubblePaint);
          break;
        }
        current += segLen;
      }
      offset += spacing;
    }
  }

  @override
  bool shouldRepaint(_FilterFlowPainter old) =>
      old.mode != mode || old.animValue != animValue || old.activeColor != activeColor;
}
