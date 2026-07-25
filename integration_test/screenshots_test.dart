// Captures App Store / Play Store screenshots by driving the demo-seeded app.
//
// Requires the demo seed, so run with --dart-define=SCREENSHOT=true. The output
// sub-folder is chosen with --dart-define=SHOT_DIR=<iphone-6.9|ipad-13>.
//
//   flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/screenshots_test.dart \
//     -d <udid> --dart-define=SCREENSHOT=true --dart-define=SHOT_DIR=iphone-6.9
import 'dart:io';

import 'package:controller_viewer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _shotDir = String.fromEnvironment('SHOT_DIR', defaultValue: 'iphone-6.9');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Pump for a fixed wall-clock budget instead of pumpAndSettle: some detail
  // pages keep an in-flight network Future / progress spinner alive (no real
  // hardware is present), which would make pumpAndSettle time out.
  Future<void> waitFrames(WidgetTester tester,
      [Duration total = const Duration(milliseconds: 1200)]) async {
    const step = Duration(milliseconds: 100);
    for (var elapsed = Duration.zero; elapsed < total; elapsed += step) {
      await tester.pump(step);
    }
  }

  Future<void> shot(String name) async {
    await binding.takeScreenshot('$_shotDir/$name');
  }

  testWidgets('capture store screenshots', (tester) async {
    await tester.pumpWidget(const FppControlApp());
    await waitFrames(tester);
    if (Platform.isIOS) {
      await binding.convertFlutterSurfaceToImage();
      await waitFrames(tester);
    }

    // 1. Device list.
    await shot('01-device-list');

    // 2. FPP player controls — tap the playing FPP device.
    await tester.tap(find.text('Front-Yard-Pi'));
    await waitFrames(tester);
    await shot('02-fpp-control');
    await tester.tap(find.byTooltip('Back'));
    await waitFrames(tester);

    // 3. Pixel-controller monitor — tap the Falcon V4 device (canned outputs).
    await tester.tap(find.text('Roofline-F48'));
    await waitFrames(tester);
    await shot('03-pixel-controller');
    await tester.tap(find.byTooltip('Back'));
    await waitFrames(tester);

    // 4. Add Controller dialog.
    await tester.tap(find.byTooltip('Add device by IP'));
    await waitFrames(tester);
    await shot('04-add-controller');
  });
}
