// Screenshot driver: writes each screenshot captured by the integration test to
// disk. Run via:
//   flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/screenshots_test.dart \
//     -d <udid> --dart-define=SCREENSHOT=true --dart-define=SHOT_DIR=iphone-6.9
//
// The screenshot `name` passed by the test is used verbatim as a path under
// store/screenshots/ios/, e.g. "iphone-6.9/01-device-list".
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('store/screenshots/ios/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return true;
    },
  );
}
