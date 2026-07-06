// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mqtt_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mqttService)
final mqttServiceProvider = MqttServiceProvider._();

final class MqttServiceProvider
    extends $FunctionalProvider<MqttService, MqttService, MqttService>
    with $Provider<MqttService> {
  MqttServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mqttServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mqttServiceHash();

  @$internal
  @override
  $ProviderElement<MqttService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MqttService create(Ref ref) {
    return mqttService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MqttService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MqttService>(value),
    );
  }
}

String _$mqttServiceHash() => r'f876b6ee3d0519cb258ad0c17c4f72b41e758712';

@ProviderFor(connectionState)
final connectionStateProvider = ConnectionStateProvider._();

final class ConnectionStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<MqttConnectionState>,
          MqttConnectionState,
          Stream<MqttConnectionState>
        >
    with
        $FutureModifier<MqttConnectionState>,
        $StreamProvider<MqttConnectionState> {
  ConnectionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionStateHash();

  @$internal
  @override
  $StreamProviderElement<MqttConnectionState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MqttConnectionState> create(Ref ref) {
    return connectionState(ref);
  }
}

String _$connectionStateHash() => r'ea8f4a1f9f1233b446ef3b02af508c75d5603320';

@ProviderFor(MqttConfigController)
final mqttConfigControllerProvider = MqttConfigControllerProvider._();

final class MqttConfigControllerProvider
    extends $NotifierProvider<MqttConfigController, MqttConfig> {
  MqttConfigControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mqttConfigControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mqttConfigControllerHash();

  @$internal
  @override
  MqttConfigController create() => MqttConfigController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MqttConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MqttConfig>(value),
    );
  }
}

String _$mqttConfigControllerHash() =>
    r'f0b217b9aaf73cc96c068245bdabb0ce9b858ccd';

abstract class _$MqttConfigController extends $Notifier<MqttConfig> {
  MqttConfig build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MqttConfig, MqttConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MqttConfig, MqttConfig>,
              MqttConfig,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
