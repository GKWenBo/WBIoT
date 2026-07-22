# 第 5 课：企业级 Topic 架构与物模型

> 预计课时：2-3 小时（理论偏重）
> 前置条件：第 4 课已完成（灯设备实时上报跑通）
> 本课产出：把临时 topic/payload 重构成**企业级 Topic 规范 + 物模型（Thing Model）**；模拟器与 App 两端同步改造，功能不变但结构专业化
> 本课性质：**承上启下的架构课**。第 6 课起的指令下发、第 7 课的事件、第 9 课的多设备，全部依赖本课定下的 topic 规范

> 📌 **本课重构已实测**：模拟器按新规范上报、App 按新规范订阅解析，端到端连 EMQX 5.8.8 通过。

---

## 一、学习目标

1. 理解为什么"随手起的 topic"在企业规模下会出问题
2. 掌握企业级 topic 设计原则：分层、产品/设备分离、可做权限边界、善用通配符
3. 理解**物模型（Thing Model / TSL）**：把设备能力抽象成**属性 / 服务 / 事件**三类
4. 落地一套 WBIoT topic 规范，并用它重构第 4 课的代码
5. 理解 payload 的 **envelope（信封）** 设计：元数据与业务数据分离（`params` 包裹）

## 二、理论讲解

### 2.1 第 4 课的 topic 有什么问题？

第 4 课我们用了 `wbiot/light/light-001/status`。单个设备没问题，但放到企业规模：

- **无法区分"产品"和"设备"**：一款灯产品有 10 万台设备，topic 里应能区分"哪款产品"和"哪一台"
- **上/下行、属性/事件全挤在一个 `status` 里**：指令下发、事件告警该发去哪？没规划
- **没法做权限**：第 10 课要用 ACL 限制"设备只能发自己的 topic"，topic 结构必须能表达设备身份边界
- **不利于订阅聚合**：后端想订阅"所有灯的属性上报"，需要 topic 层级清晰配合通配符

企业里 topic 是**基础设施级的约定**，一旦上线几乎不可改（设备固件烧死了），所以必须一开始就设计好。

### 2.2 企业级 Topic 设计原则

1. **从通用到具体分层**：`{系统}/{产品}/{设备}/{类别}/{动作}`
2. **产品 Key + 设备名** 两级标识（阿里云 productKey+deviceName、腾讯云 ProductID+DeviceName 都是这个套路）
3. **方向与类别显式化**：属性上报、属性设置、服务调用、事件上报各有独立 topic 段
4. **通配符友好**：`+`（单层）聚合同类，`#`（多层）聚合子树
5. **能承载权限边界**：topic 里含 deviceName，Broker 就能用 ACL 规则限制"设备 X 只能读写自己命名空间下的 topic"

### 2.3 WBIoT Topic 规范（本课确立，后续沿用）

```
wbiot/{productKey}/{deviceName}/property/post          设备→云  上报属性     （本课）
wbiot/{productKey}/{deviceName}/property/set           云→设备  设置属性     （第 6 课）
wbiot/{productKey}/{deviceName}/service/{name}         云→设备  调用服务     （第 6 课）
wbiot/{productKey}/{deviceName}/service/{name}/reply   设备→云  服务响应     （第 6 课）
wbiot/{productKey}/{deviceName}/event/{name}           设备→云  事件上报     （第 7 课起）
```

- `productKey`：产品/品类标识，本课用可读的 `light`（真实云平台是随机串，如 `a1b2C3d4`）
- `deviceName`：设备实例名，如 `light-001`
- 例：`wbiot/light/light-001/property/post`

> 通配符例子（后端/App 聚合订阅）：
> - `wbiot/light/+/property/post` —— 所有灯的属性上报
> - `wbiot/light/light-001/#` —— 某台灯的全部消息

### 2.4 物模型（Thing Model / TSL）

**物模型 = 把一个设备"能干什么"抽象成标准化描述**，让云端/App 不用关心固件细节就能理解设备。三要素：

| 要素 | 英文 | 方向 | 含义 | 灯的例子 |
|---|---|---|---|---|
| **属性** | Property | 双向 | 设备的状态，可读（上报）可写（设置） | `on`(开关)、`brightness`(亮度) |
| **服务** | Service | 云→设备 | 可被调用的方法，可带返回 | `reset`(恢复出厂)（第 6 课） |
| **事件** | Event | 设备→云 | 设备主动上报的通知/告警 | `fault`(故障告警)（第 7 课） |

这就是阿里云/腾讯云物联网平台的核心概念（阿里云叫 TSL —— Thing Specification Language）。本课先定义灯的**属性**，服务和事件在后续课补齐。

#### 灯（productKey=light）物模型

| 类型 | 标识符 | 数据类型 | 取值 | 说明 |
|---|---|---|---|---|
| 属性 | `on` | bool | true/false | 开关 |
| 属性 | `brightness` | int | 0–100 | 亮度百分比 |

（本课把这份物模型也落成机器可读的 `simulator/thing-models/light.json`，模拟真实平台的 TSL 文件。）

### 2.5 Payload Envelope：元数据与业务分离

第 4 课 payload 把业务字段和元数据平铺在一起。企业做法是**信封结构**——外层放元数据，`params` 里放物模型属性：

```json
{
  "deviceId": "light-001",
  "ts": 1783348031563,
  "params": { "on": true, "brightness": 80 }
}
```

好处：解析方一眼分清"哪些是协议/元数据、哪些是设备业务属性"；未来加 `msgId`(第 6 课)、`version` 等元数据不污染业务字段。

> 真实阿里云 alink 上报长这样：`{"id":"123","version":"1.0","method":"thing.event.property.post","params":{"on":{"value":1}}}`。我们简化掉 `id/version/method`，保留最能体现"信封"思想的 `params`。

## 三、动手实战（重构，功能不变）

### Part A：落地物模型文件 `simulator/thing-models/light.json`

```json
{
  "productKey": "light",
  "properties": [
    { "identifier": "on", "dataType": "bool", "desc": "开关" },
    { "identifier": "brightness", "dataType": "int", "min": 0, "max": 100, "desc": "亮度百分比" }
  ],
  "services": [],
  "events": []
}
```

### Part B：模拟器改造 `simulator/lib/light_device.dart`

新增 `productKey`，改 topic 与 payload 信封：

```dart
class LightDevice {
  final String productKey;   // 新增：产品品类
  final String deviceId;     // 即 deviceName
  final String host;
  final int port;

  LightDevice({
    required this.deviceId,
    this.productKey = 'light',
    this.host = '127.0.0.1',
    this.port = 1883,
  });

  // 旧：'wbiot/light/$deviceId/status'
  String get _propertyPostTopic =>
      'wbiot/$productKey/$deviceId/property/post';

  // _report() 里改成信封结构：
  void _report() {
    _brightness = (_brightness + Random().nextInt(5) - 2).clamp(0, 100);
    final payload = jsonEncode({
      'deviceId': deviceId,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'params': {'on': _on, 'brightness': _brightness},
    });
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(
        _propertyPostTopic, MqttQos.atLeastOnce, builder.payload!);
    print('[${_hhmmss()}] 上报 → $_propertyPostTopic  $payload');
  }
}
```

### Part C：App 端 topic 规范集中管理 `app/lib/mqtt/topics.dart`

把 topic 拼装收敛到一处，杜绝散落的字符串魔法值：

```dart
/// WBIoT Topic 规范（第 5 课）。集中管理，避免魔法字符串散落各处。
class Topics {
  static String propertyPost(String productKey, String deviceName) =>
      'wbiot/$productKey/$deviceName/property/post';
  static String propertySet(String productKey, String deviceName) =>
      'wbiot/$productKey/$deviceName/property/set';
  static String service(String productKey, String deviceName, String name) =>
      'wbiot/$productKey/$deviceName/service/$name';
  static String serviceReply(
          String productKey, String deviceName, String name) =>
      'wbiot/$productKey/$deviceName/service/$name/reply';
  static String event(String productKey, String deviceName, String name) =>
      'wbiot/$productKey/$deviceName/event/$name';
}
```

### Part D：App 端解析改造

`app/lib/features/light/light_state.dart` —— 从 `params` 里取业务属性：

```dart
  factory LightState.fromJson(Map<String, dynamic> json) {
    final params = json['params'] as Map<String, dynamic>;
    return LightState(
      deviceId: json['deviceId'] as String,
      on: params['on'] as bool,
      brightness: params['brightness'] as int,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
    );
  }
```

`app/lib/features/light/light_providers.dart` —— 用 `Topics` 拼 topic：

```dart
@riverpod
Stream<LightState> lightState(Ref ref, String deviceId) {
  final service = ref.watch(mqttServiceProvider);
  final topic = Topics.propertyPost('light', deviceId); // 新
  service.subscribe(topic);
  return service.messageStream
      .where((m) => m.topic == topic)
      .map((m) =>
          LightState.fromJson(jsonDecode(m.payload) as Map<String, dynamic>));
}
```

（记得 `import '../../mqtt/topics.dart';`；改完 provider 跑一次 `dart run build_runner build`。）

### Part E：跑通验证

1. 模拟器：`cd simulator && dart run bin/simulator.dart light-001`，确认打印的 topic 变成 `.../property/post`，payload 带 `params`
2. `mqttx sub -t 'wbiot/light/+/property/post' -v` 确认收到新结构
3. App 连接 → 灯页面，行为和第 4 课一致（实时刷新），但底层已是规范结构 ✅

## 四、企业实践对照

| 本课 | 企业实践 |
|---|---|
| `wbiot/{productKey}/{deviceName}/...` | 阿里云 `/sys/{productKey}/{deviceName}/thing/...`、腾讯云 `$thing/up/property/{ProductID}/{DeviceName}` |
| 可读 productKey `light` | 平台分配的随机 productKey + 鉴权三元组 |
| `light.json` 手写物模型 | 平台控制台可视化定义 TSL，生成设备端 SDK |
| `params` 信封 | alink `{id,version,method,params}` 完整协议 |
| topic 集中在 `Topics` 类 | 设备端 SDK 自动按物模型生成 topic，开发者不手拼 |

## 五、课后练习

1. **通配符订阅**：用 `mqttx sub -t 'wbiot/#' -v` 观察全量；再用 `wbiot/light/+/property/post` 只看灯属性。写下两者差异
2. **加一个属性**：给灯物模型加 `color`（string，如 `"warm"/"cool"`），模拟器上报里带上，App 的 `LightState` 解析并显示
3. **第二款产品**：定义 `productKey=sensor` 的温度传感器物模型（属性 `celsius`:float），模拟器上报到 `wbiot/sensor/{id}/property/post`（为第 9 课多设备铺垫）
4. **思考题**：为什么 topic 里要同时有 `productKey` 和 `deviceName`，只用 `deviceName` 不行吗？（提示：权限、聚合订阅、同名设备）

## 六、验收标准

- [ ] 模拟器上报到 `wbiot/light/{id}/property/post`，payload 为 `{deviceId,ts,params}` 信封结构
- [ ] `mqttx sub` 用通配符能聚合订阅到灯的属性上报
- [ ] App 用 `Topics` 拼 topic、从 `params` 解析，灯页面实时刷新正常
- [ ] 能讲清物模型三要素（属性/服务/事件）分别是什么、方向如何
- [ ] 能解释 topic 里 `productKey`+`deviceName` 两级标识的意义
- [ ] 完成练习 1、4（有书面记录），练习 2/3 选做

---
✅ 验收通过后更新 `docs/PROGRESS.md`，解锁第 6 课：指令下发与请求-响应模式（用本课的 `property/set` 和 `service/{name}` topic，让 App 能控制灯、并拿到设备的响应）。
