import 'package:cleanpool_app/models/maintenance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('genera PDF con historial vacío sin errores', () async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Sin mantenciones registradas'),
        ],
      ),
    );
    final bytes = await pdf.save();
    expect(bytes.isNotEmpty, isTrue);
  });

  test('formatea campos de Maintenance para tabla PDF', () {
    final record = Maintenance(
      idPiscina: 'pool-1',
      productos: ['Cloro'],
      cantidades: ['500ml'],
      fecha: DateTime(2025, 6, 10, 14, 30),
      username: 'tester',
      ph: 7.4,
      cloro: 2.1,
      temperatura: 26.5,
    );

    final date = DateFormat('dd/MM/yyyy HH:mm').format(record.fecha);
    expect(date, '10/06/2025 14:30');
    expect(record.ph?.toStringAsFixed(1), '7.4');
    expect(
      record.temperatura != null
          ? 'Temp: ${record.temperatura!.toStringAsFixed(1)}°C'
          : '—',
      'Temp: 26.5°C',
    );
  });

  test('campos nulos muestran guión', () {
    final record = Maintenance(
      idPiscina: 'pool-1',
      productos: [],
      cantidades: [],
      fecha: DateTime.now(),
      username: 'tester',
    );

    expect(record.productos.isEmpty ? '—' : record.productos.join(', '), '—');
    expect(record.ph?.toStringAsFixed(1) ?? '—', '—');
    expect(
      record.temperatura != null
          ? 'Temp: ${record.temperatura!.toStringAsFixed(1)}°C'
          : '—',
      '—',
    );
  });
}
