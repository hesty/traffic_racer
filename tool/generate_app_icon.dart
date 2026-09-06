// Regenerates the iOS and Android launcher icons from `AppIconPainter`.
//
//   flutter test tool/generate_app_icon.dart
//
// Every size is rendered from the vector painter rather than downscaled from
// one bitmap. Opaque images are written as 24-bit PNGs: App Store Connect
// rejects a marketing icon that carries an alpha channel.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'app_icon_painter.dart';

typedef IconPainter = void Function(ui.Canvas canvas, double size);

const _iconSetDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _androidResDir = 'android/app/src/main/res';

/// Every image the iOS icon set references, keyed by output file name.
const Map<String, int> _iosOutputs = {
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

/// Android density buckets and their scale against mdpi.
const Map<String, double> _densities = {
  'mdpi': 1,
  'hdpi': 1.5,
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate iOS app icons', () async {
    final dir = Directory(_iconSetDir);
    expect(dir.existsSync(), isTrue, reason: 'run from the repo root');

    for (final entry in _iosOutputs.entries) {
      final bytes = await _renderPng(entry.value, AppIconPainter.paintSquare,
          opaque: true);
      File('$_iconSetDir/${entry.key}').writeAsBytesSync(bytes);
    }

    File('$_iconSetDir/Contents.json').writeAsStringSync(_contentsJson());

    // Anything left over is from an older generator and would only confuse the
    // asset catalogue.
    for (final file in dir.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (name != 'Contents.json' && !_iosOutputs.containsKey(name)) {
        file.deleteSync();
      }
    }
  });

  test('generate Android launcher icons', () async {
    expect(Directory(_androidResDir).existsSync(), isTrue,
        reason: 'run from the repo root');

    for (final density in _densities.entries) {
      final dir = Directory('$_androidResDir/mipmap-${density.key}');
      expect(dir.existsSync(), isTrue, reason: '${dir.path} is missing');

      // The legacy square bitmap is 48 dp; the adaptive layers are 108 dp, of
      // which only the middle 72 dp survives the launcher mask.
      final legacy = (48 * density.value).round();
      final layer = (108 * density.value).round();

      Future<void> write(String name, int size, IconPainter painter,
          {required bool opaque}) async {
        final bytes = await _renderPng(size, painter, opaque: opaque);
        File('${dir.path}/$name').writeAsBytesSync(bytes);
      }

      await write('ic_launcher.png', legacy, AppIconPainter.paintSquare,
          opaque: true);
      await write('ic_launcher_background.png', layer,
          AppIconPainter.paintAdaptiveBackground,
          opaque: true);
      await write('ic_launcher_foreground.png', layer,
          AppIconPainter.paintAdaptiveForeground,
          opaque: false);
      await write('ic_launcher_monochrome.png', layer,
          AppIconPainter.paintAdaptiveMonochrome,
          opaque: false);
    }
  });
}

Future<Uint8List> _renderPng(int size, IconPainter painter,
    {required bool opaque}) async {
  final recorder = ui.PictureRecorder();
  painter(ui.Canvas(recorder), size.toDouble());
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  // Straight (unpremultiplied) RGBA is what PNG stores.
  final data = await image.toByteData(
    format: opaque
        ? ui.ImageByteFormat.rawRgba
        : ui.ImageByteFormat.rawStraightRgba,
  );
  picture.dispose();
  image.dispose();
  return _encodePng(data!.buffer.asUint8List(), size, size, opaque: opaque);
}

/// Minimal PNG writer: 8-bit truecolour, with (colour type 6) or without
/// (colour type 2) an alpha channel. An opaque icon is painted edge to edge,
/// so dropping its alpha is lossless.
Uint8List _encodePng(Uint8List rgba, int width, int height,
    {required bool opaque}) {
  final channels = opaque ? 3 : 4;
  final raw = Uint8List(height * (1 + width * channels));
  var o = 0;
  for (var y = 0; y < height; y++) {
    raw[o++] = 0; // filter: none
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw[o++] = rgba[i];
      raw[o++] = rgba[i + 1];
      raw[o++] = rgba[i + 2];
      if (!opaque) raw[o++] = rgba[i + 3];
    }
  }

  final out = BytesBuilder();
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  final ihdr = BytesBuilder()
    ..add(_uint32(width))
    ..add(_uint32(height))
    ..add([8, opaque ? 2 : 6, 0, 0, 0]);
  out.add(_chunk('IHDR', ihdr.toBytes()));
  out.add(
      _chunk('IDAT', Uint8List.fromList(ZLibCodec(level: 9).encode(raw))));
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
