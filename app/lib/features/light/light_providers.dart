import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../mqtt/mqtt_providers.dart';
import '../../mqtt/topics.dart';
import 'light_state.dart';

part 'light_providers.g.dart';

/// 订阅某盏灯的状态流。deviceId 作为 family 参数（注解形式下就是函数加参数）。
@riverpod
Stream<LightState> lightState(Ref ref, String deviceId) {
  final service = ref.watch(mqttServiceProvider);
  final topic = Topics.propertyPost('light', deviceId);

  service.subscribe(topic); // 需已连接；未连接时第 8 课的重连会补订阅
  return service.messageStream
      .where((m) => m.topic == topic)
      .map((m) =>
          LightState.fromJson(jsonDecode(m.payload) as Map<String, dynamic>));
}
