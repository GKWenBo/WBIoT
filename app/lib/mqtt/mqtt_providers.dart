import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_config.dart';
import 'mqtt_service.dart';

part 'mqtt_providers.g.dart';

// service 单例。keepAlive: true —— 连接是长期存在的，不随最后一个监听者移除而 dispose
@Riverpod(keepAlive: true)
MqttService mqttService(Ref ref) {
  final service = MqttService();
  ref.onDispose(service.dispose);
  return service;
}

// 把 service 的状态 Stream 暴露给 UI；未发出前 AsyncValue 处于 loading
@Riverpod(keepAlive: true)
Stream<MqttConnectionState> connectionState(Ref ref) {
  return ref.watch(mqttServiceProvider).stateStream;
}

// 连接配置。注解形式下，一个类就是一个 provider，无需手写 NotifierProvider(...)
// 默认 host 按运行环境改：
// iOS 模拟器 127.0.0.1 / Android 模拟器 10.0.2.2 / 真机填 Mac 局域网 IP
@riverpod
class MqttConfigController extends _$MqttConfigController {
  @override
  MqttConfig build() =>
      const MqttConfig(host: '127.0.0.1', clientId: 'wbiot-app-001');

  void updateHost(String host) => state = state.copyWith(host: host);
}
