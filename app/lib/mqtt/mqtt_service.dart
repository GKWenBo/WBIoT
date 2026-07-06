import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'mqtt_config.dart';

class MqttService {
  MqttServerClient? _client;

  // 回调 → Stream 的桥：broadcast 允许多个监听者（UI、日志等）
  final _stateController = StreamController<MqttConnectionState>.broadcast();
  Stream<MqttConnectionState> get stateStream => _stateController.stream;

  MqttConnectionState get currentState =>
      _client?.connectionStatus?.state ?? MqttConnectionState.disconnected;

  Future<void> connect(MqttConfig config) async {
    // 每次连接都用配置新建 client（host/clientId 可能已变）
    final client =
        MqttServerClient.withPort(config.host, config.clientId, config.port)
          ..keepAlivePeriod = config.keepAlivePeriod
          ..logging(on: false)
          ..autoReconnect =
              false // 第 8 课再打开自动重连
          ..onConnected = () =>
              _stateController.add(MqttConnectionState.connected);

    client.onDisconnected = () =>
        _stateController.add(MqttConnectionState.disconnected);

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(config.clientId)
        .startClean(); // Clean Session

    _client = client;
    _stateController.add(MqttConnectionState.connecting);

    try {
      await client.connect(); // 连接失败会抛异常
    } catch (e) {
      client.disconnect();
      _stateController.add(MqttConnectionState.faulted);
      rethrow; // 让上层能提示用户
    }
  }

  void disconnect() => _client?.disconnect();

  void dispose() {
    _client?.disconnect();
    _stateController.close();
  }
}
