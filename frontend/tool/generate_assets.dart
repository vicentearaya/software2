// Script temporal para generar placeholders PNG.
import 'dart:io';
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/images');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  writePng(
    'assets/images/pool_background.png',
    800,
    600,
    (x, y, w, h) => [
      (10 + 30 * y / h).round().clamp(0, 255),
      (80 + 60 * y / h).round().clamp(0, 255),
      (120 + 80 * x / w).round().clamp(0, 255),
    ],
  );

  writePng(
    'assets/images/device_placeholder.png',
    400,
    500,
    (x, y, w, h) {
      final inside = x > 20 && x < w - 20 && y > 20 && y < h - 20;
      return inside ? [26, 34, 50] : [45, 55, 70];
    },
  );

  stdout.writeln('PNG assets created');
}

void writePng(
  String path,
  int width,
  int height,
  List<int> Function(int x, int y, int w, int h) pixel,
) {
  final rows = BytesBuilder();
  for (var y = 0; y < height; y++) {
    rows.addByte(0);
    for (var x = 0; x < width; x++) {
      final rgb = pixel(x, y, width, height);
      rows.add(rgb);
    }
  }
  final compressed = zlib.encode(rows.toBytes());
  final file = File(path);
  file.writeAsBytesSync(_buildPng(width, height, compressed));
}

Uint8List _buildPng(int width, int height, Uint8List idat) {
  final out = BytesBuilder();
  out.add(_pngSignature);
  out.add(_chunk('IHDR', _ihdr(width, height)));
  out.add(_chunk('IDAT', idat));
  out.add(_chunk('IEND', Uint8List(0)));
  return out.toBytes();
}

final _pngSignature = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
]);

Uint8List _ihdr(int width, int height) {
  final b = ByteData(13);
  b.setUint32(0, width);
  b.setUint32(4, height);
  b.setUint8(8, 8);
  b.setUint8(9, 2);
  b.setUint8(10, 0);
  b.setUint8(11, 0);
  b.setUint8(12, 0);
  return b.buffer.asUint8List();
}

Uint8List _chunk(String type, Uint8List data) {
  final typeBytes = Uint8List.fromList(type.codeUnits);
  final crcInput = BytesBuilder();
  crcInput.add(typeBytes);
  crcInput.add(data);
  final crc = _crc32(crcInput.toBytes());

  final out = BytesBuilder();
  out.add(_uint32Be(data.length));
  out.add(typeBytes);
  out.add(data);
  out.add(_uint32Be(crc));
  return out.toBytes();
}

Uint8List _uint32Be(int value) {
  final b = ByteData(4);
  b.setUint32(0, value);
  return b.buffer.asUint8List();
}

int _crc32(Uint8List data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
