import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_config.dart';
import 'mqtt_service.dart';

// service 单例，随 provider 释放而 dispose
final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();
  ref.onDispose(service.dispose);
  return service;
});

// 把 service 的状态 Stream 暴露给 UI；未发出前 AsyncValue 处于 loading
final connectionStateProvider = StreamProvider<MqttConnectionState>((ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.stateStream;
});

// 连接配置（Riverpod 3.x 用 Notifier，StateProvider 已降级为 legacy）
// 默认 host 按运行环境改：
// iOS 模拟器 127.0.0.1 / Android 模拟器 10.0.2.2 / 真机填 Mac 局域网 IP
class MqttConfigNotifier extends Notifier<MqttConfig> {
  @override
  MqttConfig build() =>
      const MqttConfig(host: '127.0.0.1', clientId: 'wbiot-app-001');

  void updateHost(String host) => state = state.copyWith(host: host);
}

final mqttConfigProvider = NotifierProvider<MqttConfigNotifier, MqttConfig>(
  MqttConfigNotifier.new,
);
