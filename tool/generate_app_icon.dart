// Regenerates the iOS app icon set from `AppIconPainter`.
//
//   flutter test tool/generate_app_icon.dart
//
// Every size is rendered from the vector painter rather than downscaled from
// one bitmap, and written as an opaque 24-bit PNG: App Store Connect rejects a
// marketing icon that carries an alpha channel.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'app_icon_painter.dart';

const _iconSetDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

/// Every image the icon set references, keyed by output file name.
const Map<String, int> _outputs = {
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate iOS app icons', () async {
    final dir = Directory(_iconSetDir);
    expect(dir.existsSync(), isTrue, reason: 'run from the repo root');

    for (final entry in _outputs.entries) {
      final bytes = await _renderIcon(entry.value);
      File('$_iconSetDir/${entry.key}').writeAsBytesSync(bytes);
    }

    File('$_iconSetDir/Contents.json').writeAsStringSync(_contentsJson());

    // Anything left over is from an older generator and would only confuse the
    // asset catalogue.
    for (final file in dir.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (name != 'Contents.json' && !_outputs.containsKey(name)) {
        file.deleteSync();
      }
    }
  });
}

Future<Uint8List> _renderIcon(int size) async {
  final recorder = ui.PictureRecorder();
  AppIconPainter.paint(ui.Canvas(recorder), size.toDouble());
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  picture.dispose();
  image.dispose();
  return _encodeOpaquePng(data!.buffer.asUint8List(), size, size);
}

/// Minimal PNG writer: 8-bit truecolour (colour type 2), so the alpha channel
/// never reaches the file. The canvas is painted edge to edge, so dropping
/// alpha is lossless here.
Uint8List _encodeOpaquePng(Uint8List rgba, int width, int height) {
  final raw = Uint8List(height * (1 + width * 3));
  var o = 0;
  for (var y = 0; y < height; y++) {
    raw[o++] = 0; // filter: none
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw[o++] = rgba[i];
      raw[o++] = rgba[i + 1];
      raw[o++] = rgba[i + 2];
    }
  }

  final out = BytesBuilder();
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  final ihdr = BytesBuilder()
    ..add(_uint32(width))
    ..add(_uint32(height))
    ..add(const [8, 2, 0, 0, 0]);
  out.add(_chunk('IHDR', ihdr.toBytes()));
  out.add(_chunk(
      'IDAT', Uint8List.fromList(ZLibCodec(level: 9).encode(raw))));
  out.add(_chunk('IEND', Uint8List(0)));
  return out.toBytes();
}

Uint8List _uint32(int value) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, value);

Uint8List _chunk(String type, Uint8List data) {
  final typeBytes = ascii.encode(type);
  final body = Uint8List(typeBytes.length + data.length)
    ..setRange(0, typeBytes.length, typeBytes)
    ..setRange(typeBytes.length, typeBytes.length + data.length, data);
  return Uint8List.fromList([
    ..._uint32(data.length),
    ...body,
    ..._uint32(_crc32(body)),
  ]);
}

final List<int> _crcTable = List.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(Uint8List bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

String _contentsJson() {
  const images = [
    ('Icon-App-20x20@2x.png', 'iphone', '20x20', '2x'),
    ('Icon-App-20x20@3x.png', 'iphone', '20x20', '3x'),
    ('Icon-App-29x29@1x.png', 'iphone', '29x29', '1x'),
    ('Icon-App-29x29@2x.png', 'iphone', '29x29', '2x'),
    ('Icon-App-29x29@3x.png', 'iphone', '29x29', '3x'),
    ('Icon-App-40x40@2x.png', 'iphone', '40x40', '2x'),
    ('Icon-App-40x40@3x.png', 'iphone', '40x40', '3x'),
    ('Icon-App-60x60@2x.png', 'iphone', '60x60', '2x'),
    ('Icon-App-60x60@3x.png', 'iphone', '60x60', '3x'),
    ('Icon-App-20x20@1x.png', 'ipad', '20x20', '1x'),
    ('Icon-App-20x20@2x.png', 'ipad', '20x20', '2x'),
    ('Icon-App-29x29@1x.png', 'ipad', '29x29', '1x'),
    ('Icon-App-29x29@2x.png', 'ipad', '29x29', '2x'),
    ('Icon-App-40x40@1x.png', 'ipad', '40x40', '1x'),
    ('Icon-App-40x40@2x.png', 'ipad', '40x40', '2x'),
    ('Icon-App-76x76@1x.png', 'ipad', '76x76', '1x'),
    ('Icon-App-76x76@2x.png', 'ipad', '76x76', '2x'),
    ('Icon-App-83.5x83.5@2x.png', 'ipad', '83.5x83.5', '2x'),
    ('Icon-App-1024x1024@1x.png', 'ios-marketing', '1024x1024', '1x'),
  ];
  final body = [
    for (final (filename, idiom, size, scale) in images)
      {'size': size, 'idiom': idiom, 'filename': filename, 'scale': scale},
  ];
  const encoder = JsonEncoder.withIndent('  ');
  return '${encoder.convert({
        'images': body,
        'info': {'version': 1, 'author': 'xcode'},
      })}\n';
}
