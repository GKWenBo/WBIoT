class LightState {
  final String deviceId;
  final bool on;
  final int brightness;
  final DateTime updatedAt;

  const LightState({
    required this.deviceId,
    required this.on,
    required this.brightness,
    required this.updatedAt,
  });

  factory LightState.fromJson(Map<String, dynamic> json) => LightState(
        deviceId: json['deviceId'] as String,
        on: json['on'] as bool,
        brightness: json['brightness'] as int,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      );
}
