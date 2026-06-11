import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/maintenance.dart';

/// Ejemplo de primera pagina:
/// - Cabecera editorial con CleanPool, usuario, fechas y piscina.
/// - Fila de 4 KPIs corporativos con acento lateral.
/// - Resumen visual contenido y sin elementos vectoriales invasivos.
///
/// Paginas siguientes:
/// - Tabla corporativa de mantenciones con fechas, piscina, productos,
///   cantidades, parametros de agua y badge APTA / NO APTA.
class PdfService {
  PdfService._();

  static const PdfColor _primary = PdfColors.cyan900;
  static const PdfColor _accent = PdfColors.cyan800;
  static const PdfColor _text = PdfColors.blueGrey900;
  static const PdfColor _muted = PdfColors.blueGrey500;
  static const PdfColor _border = PdfColors.grey300;
  static const PdfColor _soft = PdfColors.grey100;
  static const PdfColor _softAlt = PdfColors.grey50;

  static Future<void> exportMaintenanceHistory({
    required List<Maintenance> records,
    required String userName,
    String? poolName,
  }) async {
    final pdf = pw.Document();
    final sorted = List<Maintenance>.from(records)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final asc = List<Maintenance>.from(records)
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final reportPoolName = _cleanText(
      poolName ?? (sorted.isNotEmpty ? sorted.first.idPiscina : 'Piscina'),
    );
    final period = _periodLabel(asc);
    final exportDate = _formatDateTime(DateTime.now());
    final metrics = _ReportMetrics.fromRecords(sorted);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildExecutiveHeader(
              poolName: reportPoolName,
              period: period,
              userName: userName,
              exportDate: exportDate,
            ),
            pw.SizedBox(height: 22),
            _buildSummaryCards(metrics),
            pw.SizedBox(height: 24),
            _buildBehaviorOverview(asc),
            pw.SizedBox(height: 24),
            _buildGeneralStatusSection(sorted),
            pw.Spacer(),
            _buildFooter(context),
          ],
        ),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (_) => _buildDetailHeader(reportPoolName),
        footer: _buildFooter,
        build: (_) {
          if (sorted.isEmpty) return [_buildEmptyState()];
          return [
            pw.SizedBox(height: 14),
            _buildMaintenanceTable(sorted),
          ];
        },
      ),
    );

    final safePoolName = _fileSafe(reportPoolName);
    final safeDate = _fileDate(DateTime.now());
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'cleanpool_historial_${safePoolName}_$safeDate.pdf',
    );
  }

  static pw.Widget _buildExecutiveHeader({
    required String poolName,
    required String period,
    required String userName,
    required String exportDate,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CleanPool',
                    style: pw.TextStyle(
                      color: _primary,
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Historial de Mantenciones',
                    style: pw.TextStyle(
                      color: _text,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    poolName,
                    style: const pw.TextStyle(
                      color: _muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              width: 190,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _soft,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _border, width: 0.6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _metaLine('Usuario', userName),
                  _metaLine('Exportado', exportDate),
                  _metaLine('Periodo', period),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Container(height: 1, color: _accent),
      ],
    );
  }

  static pw.Widget _metaLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                color: _text,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryCards(_ReportMetrics metrics) {
    return pw.Row(
      children: [
        _summaryCard(
          title: metrics.total.toString(),
          description: 'Mantenciones realizadas',
          accent: PdfColors.blue700,
        ),
        pw.SizedBox(width: 8),
        _summaryCard(
          title: metrics.lastOptimalDate,
          description: 'Ultima agua optima',
          accent: PdfColors.green700,
        ),
        pw.SizedBox(width: 8),
        _summaryCard(
          title: metrics.frequentOutOfRangeTitle,
          description: metrics.frequentOutOfRangeDetail,
          accent: PdfColors.orange800,
        ),
        pw.SizedBox(width: 8),
        _summaryCard(
          title: metrics.mostUsedProduct,
          description: 'Producto mas usado',
          accent: PdfColors.purple700,
        ),
      ],
    );
  }

  static pw.Widget _summaryCard({
    required String title,
    required String description,
    required PdfColor accent,
  }) {
    return pw.Expanded(
      child: pw.Container(
        height: 82,
        decoration: pw.BoxDecoration(
          color: _soft,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _border, width: 0.5),
        ),
        child: pw.Row(
          children: [
            pw.Container(
              width: 3,
              height: double.infinity,
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  bottomLeft: pw.Radius.circular(8),
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      title,
                      maxLines: 2,
                      style: pw.TextStyle(
                        fontSize: title.length > 16 ? 10 : 16,
                        fontWeight: pw.FontWeight.bold,
                        color: _text,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      description,
                      maxLines: 2,
                      style: const pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildBehaviorOverview(List<Maintenance> asc) {
    final limited = asc.length > 20 ? asc.sublist(asc.length - 20) : asc;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Comportamiento reciente del agua',
            style: pw.TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Cada punto resume si la mantencion dejo el agua apta o si requirio correccion.',
            style: const pw.TextStyle(color: _muted, fontSize: 8.5),
          ),
          pw.SizedBox(height: 16),
          if (limited.length < 3)
            pw.Container(
              height: 54,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: _soft,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Aun hay pocos registros. Sigue registrando mantenciones para ver tu historial.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(color: _muted, fontSize: 9),
              ),
            )
          else
            _buildStatusDots(limited),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _legendBadge(PdfColors.green50, PdfColors.green900, 'Agua apta'),
              pw.SizedBox(width: 10),
              _legendBadge(PdfColors.red50, PdfColors.red900, 'Requirio correccion'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatusDots(List<Maintenance> records) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: records.map((item) {
        final apta = _isWaterFitForSwimming(item);
        return pw.Expanded(
          child: pw.Column(
            children: [
              pw.Container(
                height: 8,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
              pw.Transform.translate(
                offset: const PdfPoint(0, 4),
                child: pw.Container(
                  width: 13,
                  height: 13,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: apta ? PdfColors.green500 : PdfColors.red500,
                    border: pw.Border.all(color: PdfColors.white, width: 1.5),
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                item.ph?.toStringAsFixed(1) ?? '-',
                style: const pw.TextStyle(fontSize: 6.5, color: _text),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _shortDateName(item.fecha),
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 6, color: _muted),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _legendBadge(PdfColor bg, PdfColor fg, String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: fg,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildGeneralStatusSection(List<Maintenance> sorted) {
    final lastThirty = sorted.take(30).toList();
    final total = lastThirty.length;
    final fitCount = lastThirty.where(_isWaterFitForSwimming).length;
    final percentage = total == 0 ? 0 : (fitCount * 100 / total).round();

    late final PdfColor background;
    late final PdfColor foreground;
    late final String title;
    late final String subtitle;
    if (total == 0) {
      background = PdfColors.grey100;
      foreground = _text;
      title = 'Aun no hay registros suficientes';
      subtitle = 'Registra mantenciones para conocer el estado general de tu piscina.';
    } else if (percentage >= 80) {
      background = PdfColors.green50;
      foreground = PdfColors.green900;
      title = 'Tu piscina estuvo en buen estado la mayor parte del tiempo';
      subtitle = '$fitCount de $total mantenciones con agua apta para el baño.';
    } else if (percentage >= 50) {
      background = PdfColors.orange50;
      foreground = PdfColors.orange900;
      title = 'Tu piscina tuvo algunos problemas';
      subtitle = '${total - fitCount} de $total mantenciones requirieron correccion.';
    } else {
      background = PdfColors.red50;
      foreground = PdfColors.red900;
      title = 'Tu piscina necesito correcciones frecuentes';
      subtitle =
          'Considera revisar el equipo de filtracion o aumentar la frecuencia de mantencion.';
    }

    return pw.Container(
      width: double.infinity,
      height: 84,
      padding: const pw.EdgeInsets.symmetric(horizontal: 18),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'Estado general del ultimo mes',
            style: pw.TextStyle(
              color: foreground,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            title,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(color: foreground, fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEmptyState() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          'Sin mantenciones registradas',
          style: const pw.TextStyle(fontSize: 12, color: _muted),
        ),
      ),
    );
  }

  static pw.Widget _buildDetailHeader(String poolName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text(
              'CleanPool',
              style: pw.TextStyle(
                color: _primary,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              'Detalle de mantenciones | $poolName',
              style: const pw.TextStyle(color: _muted, fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1, color: _accent),
      ],
    );
  }

  static pw.Widget _buildMaintenanceTable(List<Maintenance> records) {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerDecoration: const pw.BoxDecoration(color: _primary),
      headerHeight: 28,
      cellHeight: 28,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8.5,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        color: _text,
        fontSize: 8,
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      headers: const [
        'Fecha',
        'Piscina',
        'Productos aplicados',
        'Cantidades',
        'pH',
        'Cloro',
        'Estado',
      ],
      data: records.map((item) {
        final apta = _isWaterFitForSwimming(item);
        return [
          _formatDateTime(item.fecha),
          _cleanText(item.idPiscina),
          _productsText(item),
          _quantitiesText(item),
          item.ph?.toStringAsFixed(1) ?? '—',
          item.cloro != null ? '${item.cloro!.toStringAsFixed(1)} ppm' : '—',
          apta ? 'APTA' : 'NO APTA',
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Column(
        children: [
          pw.Container(height: 0.8, color: PdfColors.grey300),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Generado por CleanPool · cleanpool.app',
                  style: const pw.TextStyle(fontSize: 7, color: _muted),
                ),
              ),
              pw.Text(
                'Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 7, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool _isWaterFitForSwimming(Maintenance item) {
    final ph = item.ph;
    final cloro = item.cloro;
    if (ph == null || cloro == null) return false;
    return ph >= 6.8 && ph <= 8.2 && cloro >= 0.5 && cloro <= 5.0;
  }

  static bool _isWaterOptimal(Maintenance item) {
    final ph = item.ph;
    final cloro = item.cloro;
    if (ph == null || cloro == null) return false;
    return ph >= 7.2 && ph <= 7.8 && cloro >= 1.0 && cloro <= 3.0;
  }

  static String _periodLabel(List<Maintenance> asc) {
    if (asc.isEmpty) return 'Sin periodo';
    return '${_shortDate(asc.first.fecha)} - ${_shortDate(asc.last.fecha)}';
  }

  static String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  static String _shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  static String _shortDateName(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  static String _productsText(Maintenance item) {
    if (item.productos.isEmpty) return '—';
    return item.productos.where((p) => p.trim().isNotEmpty).join(', ');
  }

  static String _quantitiesText(Maintenance item) {
    if (item.cantidades.isEmpty) return '—';
    return item.cantidades.where((c) => c.trim().isNotEmpty).join(', ');
  }

  static String _fileDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}$month$day';
  }

  static String _fileSafe(String value) {
    final normalized = value.trim().isEmpty ? 'piscina' : value.trim();
    return normalized.replaceAll(RegExp(r'[^\w\-]+'), '_').toLowerCase();
  }

  static String _cleanText(String value) {
    return value.trim().isEmpty ? 'Piscina' : value.trim();
  }
}

class _ReportMetrics {
  _ReportMetrics({
    required this.total,
    required this.lastOptimalDate,
    required this.frequentOutOfRangeTitle,
    required this.frequentOutOfRangeDetail,
    required this.mostUsedProduct,
  });

  final int total;
  final String lastOptimalDate;
  final String frequentOutOfRangeTitle;
  final String frequentOutOfRangeDetail;
  final String mostUsedProduct;

  factory _ReportMetrics.fromRecords(List<Maintenance> records) {
    final lastOptimal = records.where(PdfService._isWaterOptimal).toList();
    final phMeasurements = records.where((m) => m.ph != null).length;
    final chlorineMeasurements = records.where((m) => m.cloro != null).length;
    final phOut = records
        .where((m) => m.ph != null && (m.ph! < 7.2 || m.ph! > 7.8))
        .length;
    final chlorineOut = records
        .where((m) => m.cloro != null && (m.cloro! < 1.0 || m.cloro! > 3.0))
        .length;

    final phPct = phMeasurements == 0 ? 0 : (phOut * 100 / phMeasurements).round();
    final chlorinePct = chlorineMeasurements == 0
        ? 0
        : (chlorineOut * 100 / chlorineMeasurements).round();
    final usePh = phOut >= chlorineOut;

    return _ReportMetrics(
      total: records.length,
      lastOptimalDate: lastOptimal.isEmpty
          ? 'Sin registros optimos'
          : PdfService._shortDate(lastOptimal.first.fecha),
      frequentOutOfRangeTitle: phMeasurements == 0 && chlorineMeasurements == 0
          ? 'Sin mediciones'
          : (usePh ? 'pH' : 'Cloro'),
      frequentOutOfRangeDetail: phMeasurements == 0 && chlorineMeasurements == 0
          ? 'Sin datos para analizar'
          : (usePh
              ? 'fuera de rango en el $phPct%'
              : 'fuera de rango en el $chlorinePct%'),
      mostUsedProduct: _mostUsedProduct(records),
    );
  }

  static String _mostUsedProduct(List<Maintenance> records) {
    final counts = <String, int>{};
    for (final item in records) {
      for (final product in item.productos) {
        final normalized = product.trim();
        if (normalized.isEmpty) continue;
        if (normalized.toLowerCase() == 'sin productos necesarios') continue;
        counts[normalized] = (counts[normalized] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 'Agua estable';
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}

