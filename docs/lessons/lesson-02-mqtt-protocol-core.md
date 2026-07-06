# 第 2 课：MQTT 协议核心机制（CLI 实验课）

> 预计课时：2-3 小时
> 前置条件：第 1 课已完成（EMQX 运行中、MQTTX GUI/CLI 可用）
> 本课特点：**全程不写 App 代码**，用 CLI + Dashboard 把协议机制逐条做实验验证。这些机制是后面 13 课所有代码的地基，也是企业面试 MQTT 必考三件套：**连接、Topic、QoS**

---

## 一、学习目标

完成本课后，你应该能够：

1. 描述 MQTT 连接建立的报文交换（CONNECT → CONNACK）及关键参数：Client ID、Keep Alive
2. 解释 Client ID 冲突（互踢）的后果，并说出企业的防冲突策略
3. 熟练使用 Topic 通配符 `+` 和 `#`，并能说清它们的限制
4. 画出 QoS 0/1/2 各自的报文交换序列，说清三者的语义与代价
5. 解释"有效 QoS 就低原则"，并用实验验证

## 二、理论讲解

### 2.1 报文长什么样：MQTT 的"信封"

MQTT 报文 = **固定头**（最小仅 2 字节，这就是"轻量"的来源）+ 可变头 + 载荷。共 14 种报文类型，本课先认识 8 种：

| 报文 | 方向 | 作用 |
|---|---|---|
| CONNECT / CONNACK | 客户端 → Broker / Broker → 客户端 | 建立连接 / 应答（含返回码） |
| PUBLISH | 双向 | 传消息（我们一直在用的就是它） |
| PUBACK | 双向 | QoS 1 的确认 |
| SUBSCRIBE / SUBACK | 客户端 → Broker / 应答 | 订阅 / 应答（含授予的 QoS） |
| PINGREQ / PINGRESP | 客户端 → Broker / 应答 | 心跳 |

> 你在第 1 课练习里已经见过实物：`mqttx sub -v` 打印的 `mqtt-packet: Packet { cmd: 'publish', qos: 0, retain: false ... }` 就是一个 PUBLISH 报文的解剖图。

### 2.2 连接的建立：CONNECT 里的关键参数

客户端发起 TCP 连接后，第一个 MQTT 报文必须是 CONNECT，其中重要字段：

- **Client ID**：客户端在 Broker 上的唯一身份。**同一 Broker 上两个客户端用相同 Client ID 连接，后连的会把先连的踢下线**——如果两端都配了自动重连，就会无限互踢，表现为"设备疯狂上下线"。这是企业 IoT 事故排行榜常客（本课实验 1 亲手复现）
- **Keep Alive**：心跳周期（秒）。客户端保证每隔 Keep Alive 至少发一个报文（没业务消息就发 PINGREQ）；Broker 超过 **1.5 × Keep Alive** 没收到任何报文，判定客户端死亡并断开（然后触发遗嘱——第 7 课）
- **Clean Session**：是否清除会话状态（离线消息的关键，第 8 课专门讲）
- **用户名/密码、遗嘱**：第 10 课、第 7 课的主角

Broker 用 CONNACK 应答，返回码 0 表示成功，非 0 表示拒绝（协议版本不符、认证失败等）。

### 2.3 Topic 与通配符：订阅的"正则表达式"

Topic 规则：

- 用 `/` 分层，UTF-8 字符串，**大小写敏感**（`Wbiot/light` 和 `wbiot/light` 是两个主题）
- 不建议以 `/` 开头（会产生一个空层级），避免空格
- `$` 开头的是系统保留主题（如 `$SYS/...`，Broker 自身的运行数据）

两个通配符（**只能用于订阅，不能用于发布**）：

| 通配符 | 含义 | `wbiot/room1/light/status` 匹配吗？ |
|---|---|---|
| `+` | **恰好一层** | `wbiot/+/light/status` ✅ ｜ `wbiot/+` ❌（层数不够） |
| `#` | **任意多层（含 0 层），必须在末尾** | `wbiot/#` ✅ ｜ `wbiot/room1/#` ✅ |

> 💼 **企业视角**：裸订阅 `#`（全量消息）在生产环境是禁忌——一个客户端拖垮 Broker 出口带宽。企业用 ACL 限制每类客户端能订阅的 Topic 范围（第 10 课实现）。

### 2.4 QoS：三档"快递服务"

QoS 是 MQTT 可靠性的核心，定义在**每一跳**（发布端→Broker，Broker→订阅端是独立的两段）：

**QoS 0 —— 至多一次（fire and forget）**

```
发送方 ──PUBLISH──▶ 接收方        （发完就忘，丢了就丢了）
```

**QoS 1 —— 至少一次（可能重复）**

```
发送方 ──PUBLISH──▶ 接收方
发送方 ◀──PUBACK─── 接收方        （没收到 PUBACK 就重发，重发报文带 DUP 标记）
```

代价：消息可能重复到达 → **接收方业务必须幂等**（比如"开灯"指令收到两次结果一样，没事；"余额+10"收到两次就是事故）。

**QoS 2 —— 恰好一次（四次握手）**

```
发送方 ──PUBLISH──▶ 接收方
发送方 ◀──PUBREC─── 接收方        （我收到了）
发送方 ──PUBREL───▶ 接收方        （确认吧）
发送方 ◀──PUBCOMP── 接收方        （完成）
```

代价：4 个报文 + 双方都要维护消息状态，吞吐量大幅下降。

**有效 QoS 就低原则**：订阅时也会声明一个 QoS（SUBACK 里授予）。消息实际到达订阅端的 QoS = **min(发布 QoS, 订阅 QoS)**。发布端 QoS 2 + 订阅端 QoS 0 = 实际 QoS 0。本课实验 4 验证。

> 💼 **企业选型口诀**：高频传感器数据用 **QoS 0**（丢一两帧无所谓，下一帧马上来）；指令下发、计费、告警用 **QoS 1 + 业务幂等**；**QoS 2 生产上很少用**（性能代价大，且端到端"恰好一次"仍需业务层配合，不如 QoS 1 + 幂等划算）。

## 三、动手实战（5 个实验）

> 保持 EMQX 运行，Dashboard（<http://localhost:18083>）开在旁边随时观察。所有命令用 `127.0.0.1`。
> 提示：`mqttx sub --help` / `mqttx pub --help` 可随时查参数。

### 实验 0：对答案 —— 第 1 课练习 2 的通配符结论

你上节课记录的 `wbiot/+` vs `wbiot/#` 实验结论，和 2.3 节的表格对一下：
`wbiot/+` 只收到 `wbiot/a`（一层）；`wbiot/#` 两条都收到（`wbiot/a` 和 `wbiot/a/b`）。对上了就过，对不上把实验重做一遍，找出当时哪一步观察错了。

### 实验 1：Client ID 互踢（企业事故复现）

```bash
# 终端 1：指定 Client ID 订阅
mqttx sub -t 'wbiot/#' -h 127.0.0.1 -p 1883 -i sensor-001

# 终端 2：用同一个 Client ID 再连
mqttx sub -t 'wbiot/#' -h 127.0.0.1 -p 1883 -i sensor-001
```

**观察**：终端 1 的连接被断开（Connection closed / disconnect）。去 Dashboard → Monitoring → Clients 看：`sensor-001` 只有一条连接记录，"已连接时间"很短——它是新的那个。

**思考**：如果两个客户端都开了自动重连会发生什么？（无限互踢。这就是为什么 Client ID 必须全局唯一）

### 实验 2：心跳观察

> ⚠️ 注意：`mqttx sub`/`pub` 子命令**不提供** keepalive 参数（写错会报 `unknown option`）。做连接层实验要用 `mqttx conn`——它只建连接、不收发消息，正好最纯粹。各子命令支持的参数以 `mqttx <命令> --help` 为准。

```bash
# 建一条 Keep Alive = 30 秒的裸连接，--debug 显示底层报文日志
mqttx conn -h 127.0.0.1 -p 1883 -i hb-test -k 30 --debug
```

观察两处：

1. **终端日志**：连接时能看到 `sendPacket :: packet: { cmd: 'connect' }`（CONNECT 报文实物）和 `_setupPingTimer :: keepalive 30 (seconds)`（心跳定时器启动）；挂住不动等约 30 秒，会看到 `_checkPing` 心跳周期触发——这就是"没有业务消息时连接靠什么活着"的答案
2. **Dashboard → Monitoring → Clients → 点开 `hb-test`**：Keep Alive 字段显示 30；连接会一直保持，因为客户端在按时发 PINGREQ

### 实验 3：通配符匹配矩阵

终端 1、2、3 分别订阅（都加 `-v` 显示 topic）：

```bash
mqttx sub -t 'wbiot/+' -h 127.0.0.1 -p 1883 -v            # A
mqttx sub -t 'wbiot/#' -h 127.0.0.1 -p 1883 -v            # B
mqttx sub -t 'wbiot/+/status' -h 127.0.0.1 -p 1883 -v     # C
```

终端 4 依次发布到这 4 个主题：

```bash
for t in wbiot/light wbiot/light/status wbiot/room1/light/status wbiot; do
  mqttx pub -t "$t" -m "{\"to\":\"$t\"}" -h 127.0.0.1 -p 1883
done
```

**先在纸上预测每个订阅各收到哪几条，再看实际结果**：

| 发布到 | A `wbiot/+` | B `wbiot/#` | C `wbiot/+/status` |
|---|---|---|---|
| `wbiot/light` | ? | ? | ? |
| `wbiot/light/status` | ? | ? | ? |
| `wbiot/room1/light/status` | ? | ? | ? |
| `wbiot` | ? | ? | ? |

（最后一行是陷阱题：`#` 含 0 层，所以 `wbiot/#` 能匹配 `wbiot` 本身；`+` 不能。）

### 实验 4：QoS 就低原则

```bash
# 终端 1：以 QoS 1 订阅
mqttx sub -t 'wbiot/qos-test' -h 127.0.0.1 -p 1883 -q 1 -v

# 终端 2：分别以 QoS 0、1、2 发布
mqttx pub -t 'wbiot/qos-test' -m 'q0' -h 127.0.0.1 -p 1883 -q 0
mqttx pub -t 'wbiot/qos-test' -m 'q1' -h 127.0.0.1 -p 1883 -q 1
mqttx pub -t 'wbiot/qos-test' -m 'q2' -h 127.0.0.1 -p 1883 -q 2
```

**观察**订阅端打印的每条消息的 `qos` 字段：应该是 `0, 1, 1`——第三条发布用了 QoS 2，但订阅只声明了 QoS 1，被"就低"成 1。

### 实验 5：QoS 2 四次握手放大镜

Dashboard → Monitoring → Metrics（或 Overview 的报文统计），先记下 `packets.pubrec.*` / `packets.pubrel.*` / `packets.pubcomp.*` 的当前值，然后：

```bash
# 订阅端也用 QoS 2，保证全程 QoS 2
mqttx sub -t 'wbiot/qos2' -h 127.0.0.1 -p 1883 -q 2 -v &
mqttx pub -t 'wbiot/qos2' -m 'exactly-once' -h 127.0.0.1 -p 1883 -q 2
```

再刷新指标：PUBREC/PUBREL/PUBCOMP 各增加了（发布段和投递段各一轮）。一条消息，背后 8 个协议报文——现在你对"QoS 2 昂贵"有体感了。

## 四、企业实践对照

| 机制 | 本课实验 | 企业实践 |
|---|---|---|
| Client ID | 手写 `sensor-001` 互踢复现 | 规范如 `{productKey}.{deviceId}`；App 端常加随机后缀防多开互踢，设备端反而故意用固定 ID 让新连接顶掉僵尸连接——两种策略都存在，按场景选 |
| Keep Alive | 30 秒观察心跳 | 移动网络下需考虑运营商 NAT 超时（约 5 分钟），常见取 60~300 秒；太短费电费流量，太长掉线发现慢（第 12 课结合 App 后台细讲） |
| 通配符 | 裸 `#` 随便订 | ACL 严格限制订阅范围，裸 `#` 只有运维排查账号可用（第 10 课实现） |
| QoS | 三档全试 | 传感器上报 QoS 0；指令/告警/计费 QoS 1 + 幂等；QoS 2 基本不用 |

## 五、课后练习

1. **验证"通配符不能用于发布"**：试着 `mqttx pub -t 'wbiot/+' -m 'x' ...`，记录发生了什么（客户端报错？Broker 断开连接？）
2. **就低原则反向实验**：订阅端 `-q 2`、发布端 `-q 1`，先预测订阅端收到的 qos 值再验证
3. **思考题（写 3-5 句书面结论）**：为什么企业普遍用"QoS 1 + 业务幂等"而不是 QoS 2？从报文数量、Broker 内存状态、极端情况下的兜底三个角度说
4. **（选做）** 订阅 `$SYS/#` 看看 EMQX 通过系统主题暴露了哪些运行数据（若没消息，去 Dashboard 检查系统主题的发布周期配置）

## 六、验收标准

- [ ] 实验 0：通配符结论与标准答案一致
- [ ] 实验 1：成功复现互踢，能说出"为什么自动重连会导致无限互踢"和一种企业防冲突策略
- [ ] 实验 3：矩阵 12 格全部预测正确（或错了之后能解释错在哪），能口述 `+`/`#` 的区别与"只能订阅不能发布"
- [ ] 实验 4/5：能不看文档画出 QoS 0/1/2 的报文序列，能解释有效 QoS 就低原则
- [ ] 完成课后练习 1-3（第 3 题有书面结论）

---
✅ 验收全部通过后，更新 `docs/PROGRESS.md`，解锁第 3 课：Flutter 工程搭建 + 首次连接（终于要写代码了）。
