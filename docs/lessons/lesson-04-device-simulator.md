# 第 4 课：设备模拟器 + 第一个智能设备

> 预计课时：2-3 小时
> 前置条件：第 3 课已完成（app/ 能连上 EMQX）
> 本课产出：`simulator/` Dart CLI 模拟一盏灯，每 3 秒上报状态；App 订阅并**实时**展示灯的开关/亮度/更新时间
> 本课主线：第一次打通"**设备 → Broker → App**"全链路，把第 3 课埋的"回调桥接 Stream"套路**第二次**用在收消息上

> 📌 **本课代码 API 已实测**：`mqtt_client 10.11.11` 的订阅/发布/收消息往返（连本地 EMQX 5.8.8）验证通过。

---

## 一、学习目标

完成本课后，你应该能够：

1. 从**设备视角**理解 MQTT：一个设备就是"连上 Broker + 周期性发布自己状态"的普通客户端
2. 用 `mqtt_client` 完成**发布**（`publishMessage` + `MqttClientPayloadBuilder`）
3. 用 `client.updates` **订阅收消息**，并把它桥接成干净的 `Stream<MqttInboundMessage>`
4. 设计一份合理的 JSON 上报 payload，理解为什么要带 `deviceId` 和 `ts`
5. 用 Riverpod 的 `.family`（注解形式下就是函数加参数）按 deviceId 订阅设备状态

## 二、理论讲解

### 2.1 设备视角：设备也只是个 MQTT 客户端

第 3 课我们的 App 是客户端。现在换个身份：**灯**也是客户端，地位完全平等。一个真实智能灯的固件逻辑，抽象出来就三件事：

1. **连接**：上电联网后连上 Broker（和 App 的 connect 一模一样）
2. **上行**：周期性 / 状态变化时，把自己的状态 `publish` 到某个 topic（本课做的）
3. **下行**：`subscribe` 一个指令 topic，收到指令就执行（第 6 课做）

我们用 Dart CLI 模拟这个固件。**为什么用模拟器而不买硬件**（第 0 课已定）：零成本、可随意造异常场景（断网、异常数据、批量设备），这也是**企业联调的常规手段**——嵌入式固件没就绪时，App/后端团队先用模拟器联调。

### 2.2 长连接 vs 第 1 课的 shell 循环

还记得第 1 课练习 1 的 shell 脚本吗？它每次上报都 `mqttx pub` 走一遍"连接→发布→断开"，你在 Dashboard 看到连接数一跳一跳。**真实设备绝不这样**——它维持**一条长连接**，反复用它发消息：省电、省流量、低延迟，Broker 也能通过这条连接随时下发指令。本课的模拟器就是长连接，你可以在 Dashboard 看到它稳定在线。

### 2.3 JSON Payload 设计

MQTT 只负责搬运字节，不管内容格式。企业最常用 **JSON**（可读、跨语言；对带宽极敏感的场景才上二进制/Protobuf）。本课的灯状态 payload：

```json
{
  "deviceId": "light-001",
  "on": true,
  "brightness": 80,
  "ts": 1783348031563
}
```

- **`deviceId`**：谁发的。虽然 topic 里也有，但 payload 自带 id 便于日志、落库、跨系统流转时不依赖 topic 解析
- **`on` / `brightness`**：业务状态本身
- **`ts`**：设备侧的毫秒时间戳。**极其重要**——弱网下消息可能延迟/乱序到达，接收方要靠 `ts` 判断"这是不是过期数据"，而不能用"收到的时间"。第 8 课弱网重连时你会真切体会到它的价值

> ⚠️ 本课 topic 先用临时命名 `wbiot/light/{deviceId}/status`，**第 5 课会用企业物模型规范重构**（属性/服务/事件三类 topic）。先跑通链路，再谈规范。

### 2.4 收消息：`client.updates` → 干净的 Stream（套路第二次登场）

第 3 课我们把"连接状态回调"桥接成了 Stream。收消息是**同一个套路**：`mqtt_client` 把所有订阅到的消息统一从 `client.updates` 这个 Stream 吐出来，但它的元素类型很啰嗦（`List<MqttReceivedMessage<MqttMessage>>`，payload 还是字节）。我们在 MqttService 里把它**解包**成自定义的 `MqttInboundMessage{topic, payload}` 再广播出去，UI 侧就清爽了：

```
client.updates (啰嗦的字节流)  ──MqttService 解包──▶  Stream<MqttInboundMessage> (topic + 字符串)
```

## 三、动手实战

> 全程保持 EMQX 运行。分两大块：**A. 建模拟器**（纯 Dart），**B. 改 App 收消息**（Flutter）。

### Part A：设备模拟器 `simulator/`

#### A1：创建 Dart CLI 工程

```bash
cd /Users/wenbo/Desktop/WBIoT
dart create -t console simulator
cd simulator
dart pub add mqtt_client
```

#### A2：设备逻辑 `simulator/lib/light_device.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// 模拟一盏智能灯：连上 Broker，每 3 秒上报一次状态。
class LightDevice {
  final String deviceId;
  final String host;
  final int port;

  LightDevice({required this.deviceId, this.host = '127.0.0.1', this.port = 1883});

  late final MqttServerClient _client;
  Timer? _timer;
  bool _on = true;
  int _brightness = 80;

  String get _statusTopic => 'wbiot/light/$deviceId/status';

  Future<void> start() async {
    _client = MqttServerClient.withPort(host, deviceId, port)
      ..keepAlivePeriod = 30
      ..logging(on: false);
    _client.connectionMessage =
        MqttConnectMessage().withClientIdentifier(deviceId).startClean();

    await _client.connect(); // 失败会抛异常
    print('[${_hhmmss()}] $deviceId 已连接 $host:$port');

    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _report());
    _report(); // 立即先报一次
  }

  void _report() {
    // 模拟亮度轻微波动，让实时刷新看得见
    _brightness = (_brightness + Random().nextInt(5) - 2).clamp(0, 100);

    final payload = jsonEncode({
      'deviceId': deviceId,
      'on': _on,
      'brightness': _brightness,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });

    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(_statusTopic, MqttQos.atLeastOnce, builder.payload!);
    print('[${_hhmmss()}] 上报 → $_statusTopic  $payload');
  }

  void stop() {
    _timer?.cancel();
    _client.disconnect();
  }

  String _hhmmss() => DateTime.now().toIso8601String().substring(11, 19);
}
```

#### A3：入口 `simulator/bin/simulator.dart`

```dart
import 'dart:io';

import 'package:wbiot_simulator/light_device.dart';

/// 用法：dart run bin/simulator.dart [deviceId] [host]
/// 例：  dart run bin/simulator.dart light-001 127.0.0.1
Future<void> main(List<String> args) async {
  final deviceId = args.isNotEmpty ? args[0] : 'light-001';
  final host = args.length > 1 ? args[1] : '127.0.0.1';

  final device = LightDevice(deviceId: deviceId, host: host);
  await device.start();

  // Ctrl+C 优雅停机
  ProcessSignal.sigint.watch().listen((_) {
    print('\n正在停止 $deviceId ...');
    device.stop();
    exit(0);
  });
}
```

> `package:wbiot_simulator/...` 里的 `wbiot_simulator` 是 `dart create` 生成的包名（见 `simulator/pubspec.yaml` 的 `name:`）。若你的包名不同，改成你的。

#### A4：先单独验证模拟器

```bash
# 终端 1：跑模拟器
cd simulator && dart run bin/simulator.dart light-001 127.0.0.1
# 终端 2：用 CLI 订阅，确认能收到（复习第 1 课）
mqttx sub -t 'wbiot/light/+/status' -h 127.0.0.1 -p 1883 -v
```

终端 2 每 3 秒应看到一条 JSON。去 Dashboard → Clients 也能看到 `light-001` **稳定在线**（长连接）。✅ 模拟器就绪。

### Part B：App 订阅并实时展示

#### B1：收到的消息模型 `app/lib/mqtt/mqtt_message.dart`

```dart
class MqttInboundMessage {
  final String topic;
  final String payload;
  const MqttInboundMessage({required this.topic, required this.payload});
}
```

#### B2：给 `MqttService` 增加 订阅 / 发布 / 消息流

在 `app/lib/mqtt/mqtt_service.dart` 里补充（`import 'mqtt_message.dart';`）：

```dart
// 1) 新增消息流控制器（放在 _stateController 旁边）
final _messageController = StreamController<MqttInboundMessage>.broadcast();
Stream<MqttInboundMessage> get messageStream => _messageController.stream;
```

在 `connect()` 里，构建完 client、**连接之前**挂上 updates 监听（套路第二次登场）：

```dart
    // client 构建完成后、await connect() 之前加：
    client.updates?.listen((events) {
      for (final e in events) {
        final msg = e.payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(msg.payload.message);
        _messageController.add(
          MqttInboundMessage(topic: e.topic, payload: payload),
        );
      }
    });
```

新增两个方法：

```dart
  void subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    _client?.subscribe(topic, qos);
  }

  void publish(String topic, String payload,
      {MqttQos qos = MqttQos.atLeastOnce}) {
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client?.publishMessage(topic, qos, builder.payload!);
  }
```

别忘了 `dispose()` 里关掉新控制器：`_messageController.close();`

#### B3：灯状态模型 `app/lib/features/light/light_state.dart`

```dart
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
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      );
}
```

#### B4：按 deviceId 订阅的 provider `app/lib/features/light/light_providers.dart`

这里体现**注解形式下 `.family` 的优雅**——只是给函数加一个参数：

```dart
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../mqtt/mqtt_providers.dart';
import 'light_state.dart';

part 'light_providers.g.dart';

/// 订阅某盏灯的状态流。deviceId 作为 family 参数。
@riverpod
Stream<LightState> lightState(Ref ref, String deviceId) {
  final service = ref.watch(mqttServiceProvider);
  final topic = 'wbiot/light/$deviceId/status';

  service.subscribe(topic); // 订阅（需已连接；未连接时下一课的重连会补订阅）
  return service.messageStream
      .where((m) => m.topic == topic)
      .map((m) =>
          LightState.fromJson(jsonDecode(m.payload) as Map<String, dynamic>));
}
```

写完跑 `dart run build_runner build`（或已挂 `watch`）生成 `light_providers.g.dart`。

#### B5：灯页面 `app/lib/features/light/light_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'light_providers.dart';
import 'light_state.dart';

class LightPage extends ConsumerWidget {
  const LightPage({super.key, this.deviceId = 'light-001'});
  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lightStateProvider(deviceId));

    return Scaffold(
      appBar: AppBar(title: Text('灯 · $deviceId')),
      body: Center(
        child: async.when(
          loading: () => const Text('等待设备上报…'),
          error: (e, _) => Text('解析出错：$e'),
          data: (LightState s) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb,
                  size: 96,
                  color: s.on ? Colors.amber : Colors.grey),
              const SizedBox(height: 16),
              Text('开关：${s.on ? "开" : "关"}',
                  style: Theme.of(context).textTheme.titleLarge),
              Text('亮度：${s.brightness}%',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('更新时间：${s.updatedAt.toIso8601String().substring(11, 19)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### B6：从连接页跳到灯页面

在 `connection_page.dart` 的按钮区加一个入口（连接成功后可用）：

```dart
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('查看灯设备'),
              onPressed: connected
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LightPage()),
                      )
                  : null,
            ),
```

（记得 `import '../light/light_page.dart';`）

### Part C：跑通全链路

1. EMQX 运行中
2. 终端跑模拟器：`cd simulator && dart run bin/simulator.dart light-001 127.0.0.1`
3. `cd app && flutter run`，先在连接页**连接**（host 按环境填），再点"查看灯设备"
4. 灯页面应**每 3 秒刷新**一次亮度与更新时间 ✅
5. 在模拟器终端按 Ctrl+C 停机，观察 App（下一课我们会让"离线"看得出来——目前只是停止刷新）

## 四、企业实践对照

| 本课 | 企业实践 |
|---|---|
| Dart 模拟器发状态 | 嵌入式固件（C/RTOS）发状态；联调期常有官方/自研模拟器 |
| topic `wbiot/light/{id}/status` | 严格物模型 topic（第 5 课）+ ACL 限制（第 10 课） |
| payload 手写 JSON | 平台定义物模型，SDK 自动序列化；高带宽敏感场景用二进制 |
| `ts` 设备时间戳 | 必备字段；还会加 `msgId`、协议版本等（第 6 课加 msgId） |
| 一个模拟器一盏灯 | 压测用一个进程模拟上万设备（`mqttx bench` 也能做） |

## 五、课后练习

1. **多设备**：开两个终端各跑一个模拟器 `light-001`、`light-002`（Client ID 天然不同，不会互踢）。用 `mqttx sub -t 'wbiot/light/+/status' -v` 同时观察两盏灯
2. **加一个传感器**：仿照 `LightDevice` 写一个 `TempSensor`，上报 `wbiot/sensor/{id}/status`，payload 为 `{"deviceId":..., "celsius": 24.6, "ts":...}`，每 2 秒一次（复用本课的发布套路）
3. **思考并记录**：`light_providers.dart` 里如果 App **尚未连接**就打开灯页面，会怎样？（提示：`subscribe` 时 `_client` 是 null）把现象和你的改进思路写下来——第 8 课（重连 + 补订阅）会正式解决
4. **（选做）** 给灯页面加"最近 5 条上报"的滚动列表，直接 `watch` `messageStream` 或在 provider 里维护一个列表

## 六、验收标准

- [ ] `simulator/` 能独立运行，`mqttx sub` 能收到灯的状态，Dashboard 显示设备长连接在线
- [ ] App 连接后打开灯页面，能**实时**看到亮度/更新时间每 3 秒刷新
- [ ] 能讲清 `client.updates` 是怎么被桥接成 `messageStream` 的（第二次用这个套路）
- [ ] 能说出 payload 里 `deviceId` 和 `ts` 各自的意义
- [ ] 能解释注解形式的 `.family`（`lightStateProvider(deviceId)`）比手写省在哪
- [ ] 完成课后练习 1-3（练习 3 有书面记录）

---
✅ 验收全部通过后，更新 `docs/PROGRESS.md`，解锁第 5 课：企业级 Topic 架构与物模型（把本课临时的 topic/payload 重构成阿里云/腾讯云那样的规范物模型）。
