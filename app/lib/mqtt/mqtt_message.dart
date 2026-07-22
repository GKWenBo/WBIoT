/// 从 Broker 收到的一条消息（topic + 字符串 payload）。
/// 把 mqtt_client 啰嗦的 MqttReceivedMessage 解包成这个干净的模型。
class MqttInboundMessage {
  final String topic;
  final String payload;
  const MqttInboundMessage({required this.topic, required this.payload});
}
