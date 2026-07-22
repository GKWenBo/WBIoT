// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'light_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 订阅某盏灯的状态流。deviceId 作为 family 参数（注解形式下就是函数加参数）。

@ProviderFor(lightState)
final lightStateProvider = LightStateFamily._();

/// 订阅某盏灯的状态流。deviceId 作为 family 参数（注解形式下就是函数加参数）。

final class LightStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<LightState>,
          LightState,
          Stream<LightState>
        >
    with $FutureModifier<LightState>, $StreamProvider<LightState> {
  /// 订阅某盏灯的状态流。deviceId 作为 family 参数（注解形式下就是函数加参数）。
  LightStateProvider._({
    required LightStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lightStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lightStateHash();

  @override
  String toString() {
    return r'lightStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<LightState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<LightState> create(Ref ref) {
    final argument = this.argument as String;
    return lightState(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LightStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lightStateHash() => r'5220da05d90ee141a6ab58c2b9606cf0b85932c0';

/// 订阅某盏灯的状态流。deviceId 作为 family 参数（注解形式下就是函数加参数）。

final class LightStateFamily extends $Family
    with $FunctionalFamilyOverride<Stream<LightState>, String> {
  LightStateFamily._()
    : super(
        retry: null,
        name: r'lightStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 订阅某盏灯的状态流。deviceId 作为 family 参数（注解形式下就是函数加参数）。

  LightStateProvider call(String deviceId) =>
      LightStateProvider._(argument: deviceId, from: this);

  @override
  String toString() => r'lightStateProvider';
}
