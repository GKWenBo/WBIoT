# 第 1 课：IoT 与 MQTT 全景 + 环境搭建

> 预计课时：2-3 小时
> 前置条件：无（本课是起点）
> 本课产出：本机跑起企业级 MQTT Broker（EMQX），用 MQTTX 完成第一次消息收发，并能在 Dashboard 中观察到这一切

---

## 一、学习目标

完成本课后，你应该能够：

1. 说清楚一条"手机 App 控制家里的灯"的指令在企业 IoT 架构中经过哪些环节
2. 解释为什么 IoT 场景选 MQTT 而不是 HTTP / WebSocket
3. 理解发布/订阅模型，以及它相比"客户端-服务器"模型解耦了什么
4. 在 Mac 上运行 EMQX Broker，并用 MQTTX 完成发布和订阅
5. 看懂 EMQX Dashboard 的核心指标（连接数、订阅数、消息速率）

## 二、理论讲解

### 2.1 企业 IoT 架构分层：一条指令的完整旅程

想象你在公司做智能家居 App，用户在手机上点了"开灯"。这条指令的旅程：

```
┌─────────┐    ┌──────────────┐    ┌──────────────┐    ┌─────────┐
│ 应用层   │    │  平台层(云)   │    │   网络层      │    │ 设备层   │
│ 手机App  │───▶│ IoT接入平台   │───▶│ WiFi/4G/NB   │───▶│ 灯(MCU) │
│ Web后台  │    │ MQTT Broker  │    │              │    │ 传感器   │
└─────────┘    │ 规则引擎/存储  │    └──────────────┘    └─────────┘
               └──────────────┘
```

- **设备层**：灯、传感器、空调里的小芯片（MCU，如 ESP32），资源极其有限（几百 KB 内存）
- **网络层**：WiFi、4G、NB-IoT 等，特点是**不稳定**——设备可能随时掉线
- **平台层**：企业的 IoT 云平台，核心就是 **MQTT Broker**（消息枢纽）+ 规则引擎 + 设备管理 + 数据存储。国内典型：阿里云 IoT、腾讯云 IoT、涂鸦、或自建 EMQX 集群
- **应用层**：你的 Flutter App、运营后台

> 💼 **企业视角**：App 开发者的日常工作范围是"应用层 ↔ 平台层"这一段：连 Broker、订阅设备数据、下发指令。但只有理解全链路，你才能在联调时和嵌入式/后端同事对得上话——这正是本课程用"模拟器 + 本地 Broker"还原全链路的原因。

### 2.2 为什么是 MQTT？——和 HTTP、WebSocket 比一比

| 维度 | HTTP 轮询 | WebSocket | MQTT |
|---|---|---|---|
| 通信模式 | 请求-响应（拉） | 双向长连接 | 发布/订阅（推） |
| 最小开销 | 数百字节报文头 | 中等 | **固定头最小仅 2 字节** |
| 服务端推送 | 不支持（只能轮询） | 支持 | 支持 |
| 消息可靠性分级 | 无 | 无（需自己实现） | **QoS 0/1/2 三级** |
| 断线场景设计 | 无 | 无 | **遗嘱消息、会话保持、心跳** |
| 一对多广播 | 无 | 需自己实现 | **Topic 天然支持** |
| 适用场景 | 常规 API | 网页实时通信 | **弱网、低功耗、海量设备** |

MQTT 1999 年由 IBM 工程师发明，最初用于**石油管道传感器通过卫星链路回传数据**——天生为"网络差、带宽贵、设备弱"设计。这三个词就是 IoT 的日常。

关键结论：
- **HTTP** 适合 App 调后端业务接口（登录、拉设备列表），IoT 项目里它和 MQTT 是**共存**关系，不是替代
- **WebSocket** 在 MQTT 体系里反而常作为 MQTT 的**传输通道**（MQTT over WebSocket，用于浏览器端）
- **MQTT** 负责一切"实时、双向、设备相关"的通信：状态上报、指令下发、在线离线

### 2.3 发布/订阅模型：解耦是核心

传统客户端-服务器模型：App 必须知道设备在哪、设备必须在线才能通信。
发布/订阅模型：双方都只和 **Broker** 打交道，通过 **Topic**（主题，一个字符串地址，如 `home/livingroom/light/status`）间接通信。

```
灯(发布者)  ── publish("home/light/status", "on") ──▶  ┌────────┐
                                                      │ Broker │
App(订阅者) ◀── 收到 "on" ── subscribe("home/light/status") ─┘
```

三重解耦（面试高频考点）：

1. **空间解耦**：发布者和订阅者互相不知道对方存在（App 不需要设备的 IP）
2. **时间解耦**：双方不必同时在线（配合持久会话/保留消息，后续课程细讲）
3. **同步解耦**：发送后不阻塞等待，异步处理

### 2.4 核心名词速览（本课混个脸熟，后续课程逐个深挖）

| 名词 | 一句话解释 |
|---|---|
| Broker | 消息中转服务器（本课程用 EMQX） |
| Client | 一切连上 Broker 的程序——App、设备、后端服务，地位平等 |
| Topic | 消息的"频道地址"，`/` 分层的字符串 |
| Payload | 消息正文，MQTT 不关心格式（企业常用 JSON） |
| QoS | 消息可靠性等级 0/1/2（第 2 课重点） |
| Keep Alive | 心跳间隔，Broker 靠它判断客户端死活（第 2 课） |
| 遗嘱 (LWT) | 客户端异常掉线时 Broker 代发的"讣告"（第 7 课） |

## 三、动手实战

### 步骤 1：安装并启动 EMQX

```bash
brew install emqx
emqx start          # 启动
emqx ctl status     # 确认状态：应显示 "is started"
```

打开 Dashboard：浏览器访问 <http://localhost:18083>
默认账号 `admin` / 密码 `public`（首次登录会要求改密码，改完记到密码管理器）。

> 💼 **企业视角**：生产环境的 EMQX 是多节点集群 + LB，跑在 K8s/云主机上，仓库 `broker/` 目录后续会放一份参考用的 docker-compose.yml。本地单节点与生产功能一致，学习完全够用。

### 步骤 2：安装 MQTTX（GUI + CLI）

```bash
brew install --cask mqttx        # 图形客户端
brew install emqx/mqttx/mqttx-cli  # 命令行客户端（备选：npm install -g mqttx-cli）
mqttx --version
```

MQTTX 是 EMQ 出品的调试工具，**企业里联调 MQTT 的标配**，地位类似 HTTP 界的 Postman。

### 步骤 3：第一次发布/订阅（GUI）

1. 打开 MQTTX，新建连接：Name `local-sub`，Host `mqtt://127.0.0.1`，Port `1883`，其余默认 → Connect
2. 连接成功后，订阅 Topic：`wbiot/hello`
3. 再新建第二个连接 `local-pub`，连接后向 `wbiot/hello` 发布消息：`{"msg": "hello mqtt"}`
4. 切回 `local-sub`，你应该看到消息到达 ✅

**你刚刚完成了一次完整的 MQTT 通信**：两个互不认识的客户端，通过 Broker + Topic 传递了消息。

### 步骤 4：换命令行再来一遍（CLI）

开两个终端窗口：

```bash
# 终端 1：订阅（# 是多层通配符，订阅 wbiot 下所有主题，第 2 课细讲）
mqttx sub -t 'wbiot/#' -h 127.0.0.1 -p 1883 -v

# 终端 2：发布
mqttx pub -t 'wbiot/hello' -m '{"msg": "hello from cli"}' -h 127.0.0.1 -p 1883
```

终端 1 应打印出 topic 和消息。CLI 在写脚本模拟设备、CI 联调时非常常用。

> ⚠️ **为什么用 `127.0.0.1` 而不是 `localhost`**：EMQX 默认只监听 IPv4（`0.0.0.0:1883`），而 mqttx 是 Node.js 程序，在 macOS 上会把 `localhost` 优先解析为 IPv6 的 `::1`——连一个没人监听的地址，于是报 `ECONNREFUSED ::1:1883`。写明确的 IPv4 地址可绕开歧义。
>
> 💼 **企业视角**：`ECONNREFUSED` 类问题的标准排查三步：① 服务进程活着吗（`emqx ctl status`）→ ② 端口有人监听吗、监听在哪个协议栈/地址上（`lsof -nP -iTCP:1883 -sTCP:LISTEN`，注意 IPv4/IPv6 列）→ ③ 客户端实际连的是哪个地址（读错误信息里的 IP）。"localhost 解析成 ::1 但服务只听 IPv4" 是跨语言、跨平台的高频坑。

### 步骤 5：在 Dashboard 里观察

访问 <http://localhost:18083>，找到以下信息：

1. **监控（Monitoring → Overview）**：连接数（Connections）、订阅数（Subscriptions）、消息收发速率
2. **连接管理（Monitoring → Clients）**：能看到 `local-sub` 等客户端，点开看 Keep Alive、协议版本、IP
3. **订阅关系（Monitoring → Subscriptions）**：谁订阅了哪个 Topic

> 💼 **企业视角**：值班排查"设备怎么掉线了/消息没收到"，第一步就是上 Dashboard 查客户端连接状态和订阅关系。现在多点点，混熟。

### 步骤 6（预告）：记下 Mac 的局域网 IP

```bash
ipconfig getifaddr en0
```

从第 3 课起，手机上的 Flutter App 要通过这个 IP 连接 Mac 上的 EMQX（手机与 Mac 须在同一 WiFi）。

## 四、企业实践对照

| 本课学习环境 | 企业生产环境 |
|---|---|
| brew 单节点 EMQX | EMQX 集群（K8s）或云 IoT 平台（阿里云/腾讯云） |
| 无认证匿名连接 | 一机一密 + TLS 8883 端口（第 10 课实现） |
| 手动 MQTTX 调试 | MQTTX + 自动化脚本 + 平台监控告警 |
| Topic 随手起名 `wbiot/hello` | 严格的 Topic 规范与 ACL 权限（第 5、10 课实现） |

## 五、课后练习

1. **模拟温度上报**：写一条 `mqttx pub` 命令（配合 shell 循环），每 2 秒向 `wbiot/sensor/temperature` 发布一条 JSON：`{"value": 25.5, "ts": <当前时间戳>}`，并用 GUI 订阅观察
2. **通配符初体验**：分别订阅 `wbiot/+` 和 `wbiot/#`，然后向 `wbiot/a` 和 `wbiot/a/b` 各发一条消息，记录哪个订阅收到了哪条（把结论写下来，第 2 课对答案）
3. **Dashboard 侦查**：在 Dashboard 中找到你 CLI 客户端的 Keep Alive 值是多少秒

## 六、验收标准

- [ ] 能不看笔记向别人讲清：一条"开灯"指令从 App 到设备经过哪些层
- [ ] 能说出 MQTT 对比 HTTP 的 3 个以上优势，以及两者在企业项目中如何分工
- [ ] EMQX 在本机运行，Dashboard 可正常访问
- [ ] 用 MQTTX GUI 和 CLI 各完成一次发布/订阅
- [ ] 在 Dashboard 中找到自己的客户端连接和订阅关系
- [ ] 完成 3 道课后练习，第 2 题有书面结论

---
✅ 验收全部通过后，在 `docs/PROGRESS.md` 更新状态，解锁 [第 2 课：MQTT 协议核心机制](lesson-02-mqtt-protocol-core.md)（文档将在开课时生成）。
