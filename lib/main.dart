import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screenshot_mode.dart';
import 'services/device_manager.dart';
import 'ui/device_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 15 (API 35) enforces edge-to-edge. Opt in explicitly and make the
  // system bars transparent so the UI draws behind them — this clears the Play
  // Console "edge-to-edge may not display for all users" warning.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));
  runApp(const FppControlApp());
}

class FppControlApp extends StatefulWidget {
  const FppControlApp({super.key});

  @override
  State<FppControlApp> createState() => _FppControlAppState();
}

class _FppControlAppState extends State<FppControlApp> {
  late final DeviceManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = DeviceManager();
    // Store-screenshot/demo build: seed sample devices instead of scanning.
    if (kScreenshotMode) {
      _manager.loadDemoDevices();
    } else {
      _manager.init();
    }
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controller Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: DeviceListPage(manager: _manager),
    );
  }
}
