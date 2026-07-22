# 课程进度跟踪

> 规则：**严格顺序解锁** —— 上一课的验收标准全部通过后，才能开始下一课。
> 状态说明：⬜ 未开始 ｜ 🔵 进行中 ｜ ✅ 已完成（附完成日期）
> 工作模式（2026-07-22 起）：**缓冲式领跑** —— 导师提前实现并验证后续 2-3 课的参考代码（每课打 git tag `lesson-NN`，`git checkout lesson-NN` 可单独回看该课状态），学员按自己节奏逐课验证。下方状态列表示**学员验证进度**，不代表参考代码是否就绪。

## 总览

| 课程 | 主题 | 状态 | 完成日期 |
|---|---|---|---|
| 第 0 课 | 课程初始化（仓库结构、设计文档、进度表） | ✅ | 2026-07-05 |
| **阶段一：MQTT 基础与项目起步** | | | |
| 第 1 课 | IoT 与 MQTT 全景 + 环境搭建 | ✅ | 2026-07-05 |
| 第 2 课 | MQTT 协议核心机制（CLI 实验课） | ✅ | 2026-07-06 |
| 第 3 课 | Flutter 工程搭建 + 首次连接 | ✅ | 2026-07-06 |
| 第 4 课 | 设备模拟器 + 第一个智能设备 | 🔵 | |
| **阶段二：企业级核心模式** | | | |
| 第 5 课 | 企业级 Topic 架构与物模型 | ⬜ | |
| 第 6 课 | 指令下发与请求-响应模式 | ⬜ | |
| 第 7 课 | 设备在线状态：遗嘱与保留消息 | ⬜ | |
| 第 8 课 | 可靠性：QoS 实战、会话与断线重连 | ⬜ | |
| 第 9 课 | 多设备管理与场景联动 | ⬜ | |
| **阶段三：企业级进阶** | | | |
| 第 10 课 | 安全：TLS 与认证授权 | ⬜ | |
| 第 11 课 | App 架构精修：MQTT 服务层与消息路由 | ⬜ | |
| 第 12 课 | 移动端现实问题：生命周期、后台与弱网（真机） | ⬜ | |
| 第 13 课 | 服务端视角：EMQX 规则引擎与数据集成 | ⬜ | |
| **阶段四：质量与交付** | | | |
| 第 14 课 | 测试与调试 | ⬜ | |
| 第 15 课 | 收官：MQTT 5.0 新特性 + 交付 | ⬜ | |

## 学习笔记与备注

- 2026-07-05：课程初始化完成。下一步：开始第 1 课（[教学文档](lessons/lesson-01-iot-mqtt-overview.md)）。
- 2026-07-05：第 1 课完成（EMQX + MQTTX 环境就绪，完成首次收发；排错实录：ECONNREFUSED ::1 → EMQX 仅监听 IPv4，CLI 统一用 127.0.0.1）。开始第 2 课（[教学文档](lessons/lesson-02-mqtt-protocol-core.md)）。
- 2026-07-06：第 2 课完成（连接/Topic/QoS 三件套，5 个 CLI 实验全做；排错实录：keepalive 属 conn 子命令而非 sub/pub；验收问答通过，答案存 [answer-key](lessons/lesson-02-answer-key.md)）。开始第 3 课（[教学文档](lessons/lesson-03-flutter-first-connection.md)）。
- 2026-07-06：第 3 课完成（Flutter 工程 app/ 搭建，MqttService 封装 + Riverpod 集成，真机验收连上 EMQX）。技术约定：Riverpod 3.x 全程注解形式（@riverpod + build_runner）；mqtt_client 10.11.11。开始第 4 课（[教学文档](lessons/lesson-04-device-simulator.md)）。
- 2026-07-22：工作模式转为**缓冲式领跑**（见顶部说明）。已完成并入库、打 tag 的参考实现：第 4 课（`simulator/` 灯设备 + app 订阅实时展示，tag `lesson-04`，[文档](lessons/lesson-04-device-simulator.md)）、第 5 课（Topic 规范 + 物模型重构 `property/post`+`params` 信封，tag `lesson-05`，[文档](lessons/lesson-05-topic-thing-model.md)）。实测均连 EMQX 通过。第 4 课排错实录：`mqtt_client` 的 `client.updates` 必须在 `connect()` 成功之后再挂监听，连接前为 `null`、过早 `?.listen` 会静默失效收不到消息。
