import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// 模拟一盏智能灯：连上 Broker，每 3 秒上报一次状态。
class LightDevice {
  final String deviceId;
  final String host;
  final int port;

  LightDevice({required this.deviceId, this.host = '127.0.0.1', this.port = 1883});

  late final MqttServerClient _client;
  Timer? _timer;
  final bool _on = true; // 第 6 课加指令下发后改为可变
  int _brightness = 80;

  String get _statusTopic => 'wbiot/light/$deviceId/status';

  Future<void> start() async {
    _client = MqttServerClient.withPort(host, deviceId, port)
      ..keepAlivePeriod = 30
      ..logging(on: false);
    _client.connectionMessage =
        MqttConnectMessage().withClientIdentifier(deviceId).startClean();

    await _client.connect(); // 失败会抛异常
    print('[${_hhmmss()}] $deviceId 已连接 $host:$port');

    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _report());
    _report(); // 立即先报一次
  }

  void _report() {
    // 模拟亮度轻微波动，让实时刷新看得见
    _brightness = (_brightness + Random().nextInt(5) - 2).clamp(0, 100);

    final payload = jsonEncode({
      'deviceId': deviceId,
      'on': _on,
      'brightness': _brightness,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });

    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(_statusTopic, MqttQos.atLeastOnce, builder.payload!);
    print('[${_hhmmss()}] 上报 → $_statusTopic  $payload');
  }

  void stop() {
    _timer?.cancel();
    _client.disconnect();
  }

  String _hhmmss() => DateTime.now().toIso8601String().substring(11, 19);
}
