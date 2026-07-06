# WBIoT — Flutter MQTT IoT 企业级实战教学课程设计

> 状态：已批准（2026-07-05）
> 学员背景：Flutter 熟练、MQTT 零基础
> 设备：Mac（开发机 + Broker）、安卓手机、iPhone（真机调试）

## 1. 目标

通过一个贴近企业实际的智能家居项目，从零系统掌握 MQTT IoT 开发：协议原理、企业级 Topic/物模型设计、可靠性与安全、移动端工程化，最终产出一个可运行在 Android/iOS 的完整 Flutter IoT App。

## 2. 已确认的关键决策

| 决策点 | 选择 | 理由 |
|---|---|---|
| 业务场景 | 智能家居 | 覆盖企业 MQTT 绝大多数模式：属性上报/指令下发/在线状态/场景联动 |
| IoT 设备 | 纯软件模拟（Dart CLI） | 零成本，可灵活演练断网/离线/异常数据等场景 |
| 状态管理 | Riverpod 3.x（**注解 + 代码生成**） | 现代企业主流，与 MQTT 消息流/Stream 结合自然；全程用 `@riverpod` + build_runner（第 3 课起确立的约定） |
| 课程结构 | 项目驱动 + 理论穿插 | 每课约 30% 协议理论 + CLI 实验，70% 在 App 中落地 |
| Broker | EMQX（brew 本地安装） | 国内企业事实标准；无 Docker 环境，brew 版功能完整（Dashboard/认证/ACL/规则引擎） |
| MQTT 版本 | 3.1.1 主线（`mqtt_client`） | 企业现状主流；第 15 课用 `mqtt5_client` 补齐 5.0 新特性 |
| 节奏 | 每课 2-3 小时，共 15 课 | 学员每天有时间，预计 3-4 周完成 |

## 3. 技术栈

| 组件 | 选型 |
|---|---|
| App | Flutter 3.44 + Riverpod（Android/iOS） |
| MQTT 客户端库 | `mqtt_client`（10.x，第 3 课实测 10.11.11）；第 15 课引入 `mqtt5_client` |
| Broker | EMQX（Homebrew 安装，Dashboard 端口 18083） |
| 设备模拟器 | Dart CLI（`simulator/`），模拟灯/温湿度传感器/空调 |
| 调试工具 | MQTTX（GUI + CLI） |

## 4. 仓库结构（monorepo）

```
WBIoT/
├── app/                  # Flutter 智能家居 App
├── simulator/            # Dart CLI 设备模拟器
├── broker/               # EMQX 配置、ACL、TLS 证书、参考用 docker-compose.yml
├── docs/
│   ├── PROGRESS.md       # 课程进度跟踪（严格顺序解锁）
│   ├── lessons/          # 每课教学文档 lesson-NN-主题.md
│   └── superpowers/specs/  # 设计文档
└── README.md             # 项目与课程总览
```

## 5. 课程大纲（15 课 / 4 阶段）

### 阶段一：MQTT 基础与项目起步（第 1-4 课）

1. **IoT 与 MQTT 全景 + 环境搭建** — IoT 分层架构（设备-云-App）、为什么选 MQTT（对比 HTTP/WebSocket/CoAP）、发布订阅模型；安装 EMQX + MQTTX，完成第一次收发，认识 Dashboard
2. **MQTT 协议核心机制（CLI 实验课）** — CONNECT/心跳/Client ID、Topic 与通配符（+/#）、QoS 0/1/2 原理；用 MQTTX CLI 做实验逐条验证
3. **Flutter 工程搭建 + 首次连接** — 创建 `app/`（Riverpod 分层架构），引入 `mqtt_client`，实现连接/断开/状态展示页
4. **设备模拟器 + 第一个智能设备** — `simulator/` 模拟一盏灯定时上报状态，App 订阅实时展示；JSON payload 设计

### 阶段二：企业级核心模式（第 5-9 课）

5. **企业级 Topic 架构与物模型** — 参考阿里云/腾讯云 IoT 物模型规范（属性/服务/事件），设计 `{product}/{deviceId}/property/post` 等 Topic 体系并重构项目
6. **指令下发与请求-响应模式** — 下行控制、消息 ID、ACK 回执、超时重试；App 控制灯开关/亮度
7. **设备在线状态：遗嘱与保留消息** — LWT、Retained、上下线事件；设备在线/离线徽标，异常掉线演练
8. **可靠性：QoS 实战、会话与断线重连** — Clean Session、消息去重、指数退避重连；关 WiFi 弱网演练
9. **多设备管理与场景联动** — 设备列表、房间分组、"一键回家"场景、批量控制、广播 Topic 设计

### 阶段三：企业级进阶（第 10-13 课）

10. **安全：TLS 与认证授权** — TLS 单向/双向、一机一密、用户名密码、ACL；EMQX 开启安全配置，App 与模拟器改造为加密连接
11. **App 架构精修：MQTT 服务层与消息路由** — 企业级封装（单例连接、Topic 路由分发、Stream 广播）与 Riverpod 集成模式
12. **移动端现实问题：生命周期、后台与弱网** — iOS/Android 后台策略差异、心跳与省电权衡、Push 与 MQTT 配合、本地缓存（offline-first）；安卓 + iPhone 真机演练
13. **服务端视角：EMQX 规则引擎与数据集成** — 规则引擎、Webhook、共享订阅（后端负载均衡）；配置规则把传感器数据落到 HTTP endpoint，理解企业数据链路

### 阶段四：质量与交付（第 14-15 课）

14. **测试与调试** — MQTT service 单元测试（mock）、集成测试、抓包排错方法论
15. **收官：MQTT 5.0 新特性 + 交付** — 响应主题/用户属性/原因码等 5.0 特性、协议选型高频面试题、项目打磨与复盘、进阶路线图

## 6. 教学机制

- **每课文档**（`docs/lessons/lesson-NN-主题.md`）固定结构：学习目标 → 理论讲解 → 动手实战（分步骤）→ 企业实践对照 → 课后练习 → 验收标准 checklist
- **进度门禁**：`docs/PROGRESS.md` 记录每课状态（未开始/进行中/已完成+日期）。每课的验收标准全部通过后才更新状态并解锁下一课；学员说"开始第 N 课"即开课
- **教学方式**：脚手架/样板代码由 AI 生成；每课核心知识点代码采用"讲解 + 引导学员动手"模式，课后练习由学员独立完成、AI review
- **每课结束 commit 一次**，commit message 标注课程编号，git 历史即学习轨迹

## 7. 环境约束

- Mac：Flutter 3.44.4 stable、Homebrew 6.0.2、无 Docker（Broker 走 brew 安装 EMQX）
- 手机真机连接本地 Broker 时，需与 Mac 处于同一 WiFi，使用 Mac 的局域网 IP

## 8. 验证方式

- 每课按文档中"验收标准" checklist 逐项实际操作确认（如 MQTTX 能收发消息、真机 App 能连上 Mac 上的 EMQX 等），全部通过后更新 PROGRESS.md 并 commit
