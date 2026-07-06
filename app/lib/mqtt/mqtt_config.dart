class MqttConfig {
  final String host;
  final int port;
  final String clientId;
  final int keepAlivePeriod; // 秒

  const MqttConfig({
    required this.host,
    this.port = 1883,
    required this.clientId,
    this.keepAlivePeriod = 30,
  });

  MqttConfig copyWith({String? host, int? port, String? clientId}) =>
      MqttConfig(
        host: host ?? this.host,
        port: port ?? this.port,
        clientId: clientId ?? this.clientId,
        keepAlivePeriod: keepAlivePeriod,
      );
}
