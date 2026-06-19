import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
  final baseDir = 'android/app/src/main/res';

  for (final entry in sizes.entries) {
    final size = entry.value;
    final dir = '$baseDir/mipmap-${entry.key}';
    if (!Directory(dir).existsSync()) Directory(dir).createSync(recursive: true);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
    final scale = size / 108.0;

    // 暖米白背景
    canvas.drawRRect(
      RRect.fromRectAndCorners(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
          topLeft: Radius.circular(24 * scale), topRight: Radius.circular(24 * scale),
          bottomLeft: Radius.circular(24 * scale), bottomRight: Radius.circular(24 * scale)),
      Paint()..shader = const ui.Gradient.linear(
        Offset(54, 0), Offset(54, 108),
        [Color(0xFFFFF8F0), Color(0xFFFFF0E5)],
      ),
    );

    // 屋顶
    final roof = Path()
      ..moveTo(54, 32)
      ..lineTo(26, 60)
      ..lineTo(82, 60)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF5B9BD5)..style = PaintingStyle.fill);

    // 房身
    final body = Path()
      ..moveTo(30, 60)
      ..lineTo(30, 82)
      ..lineTo(78, 82)
      ..lineTo(78, 60)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFF5B9BD5)..style = PaintingStyle.fill);

    // 门
    final door = RRect.fromRectAndCorners(
      Rect.fromLTWH(47 * scale, 70 * scale, 14 * scale, 18 * scale),
      topLeft: Radius.circular(6 * scale), topRight: Radius.circular(6 * scale),
    );
    canvas.drawRRect(door, Paint()..color = const Color(0xFFFFF8F0));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final file = File('$dir/ic_launcher.png');
    await file.writeAsBytes(pngBytes);
    print('Generated ${entry.key} ($size×$size) → ${file.path}');
  }
  print('Done! All icons generated.');
}
