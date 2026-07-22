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

  factory LightState.fromJson(Map<String, dynamic> json) {
    final params = json['params'] as Map<String, dynamic>;
    return LightState(
      deviceId: json['deviceId'] as String,
      on: params['on'] as bool,
      brightness: params['brightness'] as int,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
    );
  }
}
