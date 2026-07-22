import 'dart:io';

import 'package:simulator/light_device.dart';

/// 用法：dart run bin/simulator.dart [deviceId] [host]
/// 例：  dart run bin/simulator.dart light-001 127.0.0.1
Future<void> main(List<String> args) async {
  final deviceId = args.isNotEmpty ? args[0] : 'light-001';
  final host = args.length > 1 ? args[1] : '127.0.0.1';

  final device = LightDevice(deviceId: deviceId, host: host);
  await device.start();

  // Ctrl+C 优雅停机
  ProcessSignal.sigint.watch().listen((_) {
    print('\n正在停止 $deviceId ...');
    device.stop();
    exit(0);
  });
}
