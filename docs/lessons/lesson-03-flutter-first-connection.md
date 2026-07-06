# 第 3 课：Flutter 工程搭建 + 首次连接

> 预计课时：2-3 小时
> 前置条件：第 2 课已完成（理解连接/Client ID/Keep Alive/QoS）
> 本课产出：`app/` Flutter 工程，一个能"连接 / 断开 / 实时显示连接状态"的页面，真机或模拟器上能连上 Mac 的 EMQX
> 本课特点：**第一次写代码**。你 Flutter 熟练，所以工程脚手架、UI 一带而过；重点在 **mqtt_client 库的用法** 和 **把 MQTT 的回调事件桥接进 Riverpod** 这两件新事。

> 📌 **本课代码已实测**：`Flutter 3.44.4 / Dart 3.12.2 / mqtt_client 10.11.11`，连接本地 EMQX 5.8.8 通过。（注意：网上很多老教程用的是 mqtt_client 3.x/5.x，API 有差异，以本课为准。）

---

## 一、学习目标

完成本课后，你应该能够：

1. 用 `mqtt_client` 建立到 Broker 的连接，并读取连接状态
2. 说清 `MqttServerClient` 与 `MqttBrowserClient` 的区别，以及移动端为什么用前者
3. 把 mqtt_client 的**回调事件**（onConnected/onDisconnected）桥接成 **Stream**，再用 Riverpod 暴露给 UI
4. **避开移动端连本地 Broker 的头号大坑**：`127.0.0.1` / `10.0.2.2` / 局域网 IP 到底该填哪个
5. 设计一个不把 MQTT 逻辑散落在 Widget 里的分层结构

## 二、理论讲解

### 2.1 为什么要有"服务层"，而不是在 Widget 里直接调 mqtt_client

新手常把 `MqttServerClient` 直接 new 在页面里、回调里直接 `setState`。这在第一个页面能跑，但很快失控：连接是**全局单例**（一个 App 通常只连一条），却被绑在某个页面的生命周期上；换页、热重载、多个页面都要用连接时就乱套。

企业做法是分三层（本课先立骨架，第 11 课再精修）：

```
┌─────────────┐   watch / read    ┌──────────────────┐   wraps    ┌───────────────┐
│  UI (Widget) │ ◀───────────────▶ │ Riverpod Provider │ ◀────────▶ │  MqttService  │
│ connection_  │                   │ (状态桥接/依赖注入) │            │ (封装 mqtt_    │
│ page.dart    │                   │                   │            │  client 库)    │
└─────────────┘                   └──────────────────┘            └───────────────┘
     只管展示和触发                    只管状态流转和生命周期            只管和 Broker 打交道
```

- **MqttService**：唯一碰 `mqtt_client` 库的地方。对上只暴露"连接/断开 + 一个状态 Stream"，换库、改协议都只动这里
- **Provider**：用 Riverpod 管理 service 的生命周期、把状态 Stream 变成 UI 可 watch 的东西
- **UI**：只 `watch` 状态、点按钮 `read` service 调方法，不知道 mqtt_client 存在

### 2.2 mqtt_client 库速览

`mqtt_client` 是 Dart 生态最主流的 MQTT 库。它按运行平台分两个客户端类：

| 类 | 底层 | 用于 |
|---|---|---|
| `MqttServerClient` | `dart:io` 的 TCP Socket | Android / iOS / 桌面 / 纯 Dart（**我们用这个**） |
| `MqttBrowserClient` | 浏览器 WebSocket | Flutter Web |

因为课程目标是 Android/iOS，全程用 `MqttServerClient`（导入 `package:mqtt_client/mqtt_server_client.dart`）。

核心 API（本课已实测）：

```dart
final client = MqttServerClient.withPort('127.0.0.1', 'client-id', 1883);
client.keepAlivePeriod = 30;          // 第 2 课的 Keep Alive，单位秒
client.logging(on: false);            // 调试期可设 true 看底层报文
client.autoReconnect = false;         // 自动重连，第 8 课再打开
client.onConnected = () { ... };      // 连接成功回调
client.onDisconnected = () { ... };   // 断开回调
client.connectionMessage = MqttConnectMessage()
    .withClientIdentifier('client-id') // 第 2 课：Client ID 要全局唯一
    .startClean();                     // Clean Session（第 8 课细讲）
await client.connect();               // 失败会抛异常，要 try/catch
client.connectionStatus?.state;       // → MqttConnectionState.connected 等
client.disconnect();
```

### 2.3 回调 → Stream → Riverpod：本课最重要的模式

mqtt_client 用的是**回调**风格（`onConnected = () {}`），而 Flutter/Riverpod 世界更喜欢**流**（Stream）。我们在 MqttService 内部架一座桥：把每次回调都 `add` 进一个 `StreamController`，对外只暴露 `Stream<MqttConnectionState>`。UI 侧就能用 Riverpod 的 `StreamProvider` 优雅地 watch。

> 这个"回调桥接成 Stream"的套路，第 4 课订阅消息时会**再用一次**（把收到的消息 add 进 Stream）。现在先在"连接状态"这个简单场景上把它学透。

### 2.4 头号大坑：手机上 `127.0.0.1` 连的不是你的 Mac！

`127.0.0.1`（localhost）永远指"我自己这台机器"。在手机/模拟器上运行的 App，"我自己"是手机/模拟器，不是你的 Mac。所以 broker 地址要按运行环境填：

| App 跑在哪 | broker host 填什么 | 原因 |
|---|---|---|
| **iOS 模拟器** | `127.0.0.1` | iOS 模拟器和 Mac 共享网络栈，localhost 就是 Mac ✅ |
| **Android 模拟器** | `10.0.2.2` | AVD 用这个特殊地址回指宿主 Mac（`127.0.0.1` 是模拟器自己） |
| **真机（安卓/iPhone）** | Mac 的局域网 IP | 手机和 Mac 必须同一 WiFi |

查你 Mac 当前局域网 IP（**本机实测在 en1，不一定是网上常说的 en0**）：

```bash
# 先看默认路由走哪个网卡
route -n get default | grep interface
# 再查该网卡的 IP（把 en1 换成上面查到的）
ipconfig getifaddr en1
```

> 💼 **企业视角**：生产环境 broker 是域名（`mqtt.yourcompany.com`）不是 IP，所以 host 一定要做成**可配置**（配置中心/环境变量/登录后下发），绝不能硬编码。本课我们直接把它做成 UI 输入框——既方便你切换模拟器/真机地址，也顺带养成"连接参数外部化"的习惯。

## 三、动手实战

### 步骤 1：创建 Flutter 工程

在仓库根目录下创建 `app/`（`--org` 决定 bundle id 前缀，随意）：

```bash
cd /Users/wenbo/Desktop/WBIoT
flutter create --org com.wbiot --project-name wbiot_app app
cd app
flutter run   # 先确认空工程能在你的设备上跑起来（选 iOS 模拟器或安卓设备）
```

### 步骤 2：添加依赖

```bash
flutter pub add mqtt_client flutter_riverpod
```

确认 `pubspec.yaml` 的 `dependencies` 里出现了这两个包。

### 步骤 3：连接配置 `lib/mqtt/mqtt_config.dart`

一个不可变的配置类，字段就是第 2 课学的连接参数：

```dart
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

  MqttConfig copyWith({String? host, int? port, String? clientId}) => MqttConfig(
        host: host ?? this.host,
        port: port ?? this.port,
        clientId: clientId ?? this.clientId,
        keepAlivePeriod: keepAlivePeriod,
      );
}
```

### 步骤 4：核心——服务层 `lib/mqtt/mqtt_service.dart`

**这是本课的重点，逐行看懂**。它只做两件事：封装 mqtt_client、把连接状态用 Stream 播出去。

```dart
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
    final client = MqttServerClient.withPort(
      config.host,
      config.clientId,
      config.port,
    )
      ..keepAlivePeriod = config.keepAlivePeriod
      ..logging(on: false)
      ..autoReconnect = false // 第 8 课再打开自动重连
      ..onConnected = () => _stateController.add(MqttConnectionState.connected)
      ..onDisconnected = () =>
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
```

要点：
- 对外接口极简：`connect(config)` / `disconnect()` / `stateStream` / `currentState`。UI 完全不碰 mqtt_client
- `connect()` 失败会**抛异常**（比如地址错、Broker 没开），所以 `try/catch` 后 `rethrow`，让 UI 弹提示
- `MqttConnectionState` 直接复用库里的枚举（connected / connecting / disconnected / disconnecting / faulted），没必要自己再定义一个

### 步骤 5：Riverpod providers `lib/mqtt/mqtt_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_config.dart';
import 'mqtt_service.dart';

// service 单例，随 provider 释放而 dispose
final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();
  ref.onDispose(service.dispose);
  return service;
});

// 把 service 的状态 Stream 暴露给 UI；初始给个 disconnected
final connectionStateProvider = StreamProvider<MqttConnectionState>((ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.stateStream;
});

// 当前连接配置（UI 输入框改它）。默认 host 按你的运行环境改：
// iOS 模拟器 127.0.0.1 / Android 模拟器 10.0.2.2 / 真机填 Mac 局域网 IP
final mqttConfigProvider = StateProvider<MqttConfig>((ref) {
  return const MqttConfig(host: '127.0.0.1', clientId: 'wbiot-app-001');
});
```

### 步骤 6：UI `lib/features/connection/connection_page.dart`

一个最小页面：host 输入框 + 状态徽标 + 连接/断开按钮。这部分你很熟，重点看它怎么 `watch` 状态、`read` service。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../../mqtt/mqtt_providers.dart';

class ConnectionPage extends ConsumerWidget {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(mqttConfigProvider);
    final stateAsync = ref.watch(connectionStateProvider);
    final state = stateAsync.valueOrNull ?? MqttConnectionState.disconnected;
    final connected = state == MqttConnectionState.connected;

    return Scaffold(
      appBar: AppBar(title: const Text('WBIoT · 连接')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: config.host,
              decoration: const InputDecoration(
                labelText: 'Broker Host',
                helperText: 'iOS模拟器:127.0.0.1 / 安卓模拟器:10.0.2.2 / 真机:Mac局域网IP',
              ),
              onChanged: (v) => ref.read(mqttConfigProvider.notifier).state =
                  config.copyWith(host: v.trim()),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.circle,
                    size: 14,
                    color: connected ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text('状态：${state.name}',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('连接'),
              onPressed: connected
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(mqttServiceProvider)
                            .connect(ref.read(mqttConfigProvider));
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('连接失败：$e')),
                          );
                        }
                      }
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.link_off),
              label: const Text('断开'),
              onPressed:
                  connected ? () => ref.read(mqttServiceProvider).disconnect() : null,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 步骤 7：入口 `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/connection/connection_page.dart';

void main() {
  runApp(const ProviderScope(child: WbiotApp()));
}

class WbiotApp extends StatelessWidget {
  const WbiotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WBIoT',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ConnectionPage(),
    );
  }
}
```

`ProviderScope` 包住整个 App 是 Riverpod 的硬性要求，别忘了。

### 步骤 8：运行并验证

1. 确认 EMQX 在跑：`emqx ctl status`
2. 按你的运行环境把 host 填对（见 2.4 表格）
3. `flutter run`，点"连接"，状态徽标变绿、文字变 `connected` ✅
4. 打开 Dashboard <http://localhost:18083> → Monitoring → Clients，应看到 `wbiot-app-001` 这个客户端，Keep Alive = 30
5. 点"断开"，徽标变灰；Dashboard 里客户端消失

## 四、企业实践对照

| 本课 | 企业实践 |
|---|---|
| host 写死在 StateProvider 默认值 | 从配置中心/登录接口下发 broker 地址，支持灰度和多环境 |
| Client ID 固定 `wbiot-app-001` | 用"用户ID + 设备指纹"生成，避免多端登录互踢（第 2 课） |
| `startClean()` 每次全新会话 | 结合业务决定是否保留会话拿离线消息（第 8 课） |
| 连接逻辑在 MqttService | 同样分层，但会加连接池/重连/鉴权 token 刷新（第 8、10、11 课） |

## 五、课后练习

1. **三环境连通**：至少在两种环境下各连通一次（iOS 模拟器 + 安卓模拟器，或任一模拟器 + 真机），把每种环境 host 填了什么、结果记下来
2. **互踢复现（呼应第 2 课）**：App 用 `wbiot-app-001` 连着，同时用 `mqttx conn -i wbiot-app-001 -h 127.0.0.1 -p 1883` 抢同一个 Client ID，观察 App 的状态徽标发生什么变化，解释原因
3. **faulted 体验**：故意把 host 填成一个连不上的地址（如 `192.168.99.99`）点连接，观察 SnackBar 报错和状态流转（connecting → faulted）
4. **（选做）** 给页面加一个"连接事件日志"列表：`watch` 一个新的 provider，把每次状态变化追加显示（提示：可在 UI 用 `ref.listen(connectionStateProvider, ...)`）

## 六、验收标准

- [ ] `app/` 工程创建成功，`flutter run` 能起来
- [ ] 能连上 Mac 上的 EMQX，状态徽标变绿，Dashboard 能看到该客户端
- [ ] 能断开，且 Dashboard 中客户端消失
- [ ] 能讲清 MqttService / Provider / UI 三层各自的职责，以及"回调桥接成 Stream"是怎么实现的
- [ ] 能说出 iOS 模拟器 / 安卓模拟器 / 真机三种环境 host 分别填什么、为什么
- [ ] 完成课后练习 1-3（练习 2 有书面解释）

---
✅ 验收全部通过后，更新 `docs/PROGRESS.md`，解锁第 4 课：设备模拟器 + 第一个智能设备（写 Dart 模拟器发消息、App 订阅实时展示，"回调桥接 Stream"套路第二次登场）。
