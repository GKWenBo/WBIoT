# WBIoT — Flutter MQTT IoT 企业级实战课程

一个"边学边做"的 MQTT IoT 教学项目：以**智能家居 App** 为主线，从 MQTT 协议零基础学到企业级实战，最终产出可运行在 Android/iOS 的完整 Flutter IoT 应用。

## 课程信息

- **学员起点**：Flutter 熟练，MQTT 零基础
- **课程规模**：15 课 / 4 阶段，每课 2-3 小时
- **技术栈**：Flutter 3.44 + Riverpod ｜ mqtt_client ｜ EMQX（本地 Broker）｜ Dart CLI 设备模拟器 ｜ MQTTX
- **课程设计**：[设计文档](docs/superpowers/specs/2026-07-05-mqtt-iot-course-design.md)
- **学习进度**：[PROGRESS.md](docs/PROGRESS.md)（严格顺序解锁：完成上一课才开始下一课）

## 仓库结构

```
WBIoT/
├── app/                  # Flutter 智能家居 App（第 3 课创建）
├── simulator/            # Dart CLI 设备模拟器（第 4 课创建）
├── broker/               # EMQX 配置、ACL、TLS 证书等（第 10 课起使用）
├── docs/
│   ├── PROGRESS.md       # 课程进度跟踪
│   ├── lessons/          # 每课教学文档
│   └── superpowers/specs/ # 课程设计文档
└── README.md
```

## 课程大纲

| 阶段 | 课程 |
|---|---|
| 一、MQTT 基础与项目起步 | 1. IoT 与 MQTT 全景 + 环境搭建 ｜ 2. 协议核心机制 ｜ 3. Flutter 工程 + 首次连接 ｜ 4. 设备模拟器 |
| 二、企业级核心模式 | 5. Topic 架构与物模型 ｜ 6. 指令下发与请求-响应 ｜ 7. 遗嘱与保留消息 ｜ 8. QoS/会话/重连 ｜ 9. 多设备与场景联动 |
| 三、企业级进阶 | 10. TLS 与认证授权 ｜ 11. MQTT 服务层架构 ｜ 12. 生命周期/后台/弱网（真机） ｜ 13. EMQX 规则引擎 |
| 四、质量与交付 | 14. 测试与调试 ｜ 15. MQTT 5.0 + 交付复盘 |

## 快速开始

从第 1 课开始：[docs/lessons/lesson-01-iot-mqtt-overview.md](docs/lessons/lesson-01-iot-mqtt-overview.md)
