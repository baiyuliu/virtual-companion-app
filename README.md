# Virtual Companion App — 虚拟陪伴助手

> 基于 Flutter 的跨平台（Android / iOS / macOS）AI 虚拟人陪伴应用。
> 用户上传照片与录音 → AI 克隆声音 + 生成数字人形象 → 一键开始语音对话，专为老年人与心理健康用户设计。

---

## 1. 项目概述

### 核心理念

让用户通过 AI 技术创建专属的虚拟陪伴人（家人、朋友），实现有温度的情感陪伴。虚拟人能用克隆的声音自然对话，记住历史聊天，主动发起关心提醒。

### 核心流程

```
创建 Profile → 上传照片 + 录音 → AI 克隆声音 + 生成数字人 → 实时语音对话（文字 + 语音 + 数字人动画）
```

### 功能范围

| 版本 | 功能 |
|------|------|
| **v1.0 基础版（当前）** | 单 Profile 创建、素材上传、声音克隆、数字人生成、实时对话、三层记忆、提醒系统 |
| **v2.0 扩展版（规划）** | 多 Profile 管理、后端服务、用户认证、Prompt 模板系统、多语言、长期记忆 RAG、情绪识别 |

---

## 2. 系统架构

### v1.0 — 客户端直连架构（当前）

```
┌─────────────────────────────────────────┐
│          Flutter App (Dart)              │
│                                         │
│  UI Layer (Features)                    │
│  ├── Onboarding (照片 + 录音采集)        │
│  ├── Chat (主对话界面)                   │
│  ├── Reminder (提醒配置)                │
│  └── Settings                           │
│                                         │
│  State Management (Riverpod)            │
│                                         │
│  Core Layer                             │
│  ├── API (直连云服务)                    │
│  ├── Services (录音/播放/通知/权限)      │
│  ├── Models (数据模型)                  │
│  └── Utils (记忆管理/语言适配/常量)      │
│                                         │
│  Local Storage (Hive + SharedPrefs)     │
└────────┬──────────┬──────────┬──────────┘
         │          │          │
    ┌────▼───┐ ┌───▼────┐ ┌──▼──────────┐
    │阿里云   │ │阿里云   │ │硅基智能      │
    │DashScope│ │NLS     │ │Soul 数字人   │
    │Qwen LLM│ │TTS/STT │ │Avatar API   │
    └────────┘ └────────┘ └─────────────┘
```

### v2.0 — 后端代理架构（规划）

```
Flutter App ──(REST + WebSocket)──▶ FastAPI 后端 ──▶ AI 推理服务
                                        │              ├── LLM (Qwen / Llama-3)
                                        │              ├── Voice Clone (CosyVoice2)
                                        │              └── Video (LivePortrait)
                                        ▼
                                   PostgreSQL + MinIO + Vector DB
```

> **v1.0 → v2.0 迁移路径**：添加 FastAPI 代理层，将 API Key 移至服务端，客户端仅持有用户 Token。数据从 Hive 迁移至 PostgreSQL，素材存储从本地迁移至 MinIO。

---

## 3. 技术栈

| 层次 | 技术 | 说明 |
|------|------|------|
| 前端框架 | Flutter 3.x (Dart 3.0+) | 跨平台：Android / iOS / macOS Desktop |
| 状态管理 | flutter_riverpod + riverpod_annotation | 响应式状态 + 代码生成 |
| 本地存储 | Hive (NoSQL) + SharedPreferences | 记忆系统 + 配置存储 |
| 录音 | record (AAC-LC, 16kHz mono) | 语音采集 |
| 音频播放 | just_audio + audio_waveforms | 语音播放 + 波形可视化 |
| 图片选择 | image_picker | 照片上传 |
| 网络 | dio + web_socket_channel | HTTP + WebSocket 流式对话 |
| 通知 | flutter_local_notifications + timezone | 本地定时提醒 |
| LLM 对话 | 阿里云 DashScope (Qwen-Plus ~30B) | SSE 流式生成 |
| 语音合成 | 阿里云 NLS CosyVoice | 零样本声音克隆 + TTS |
| 语音识别 | 阿里云 NLS 一句话识别 | STT |
| 数字人 | 硅基智能 Soul API | 照片建模 + Talking-head 视频 |
| 动画 | Lottie + Shimmer | 虚拟人动效 + 加载动画 |

---

## 4. 数据流设计

### 4.1 引导流程（Onboarding）

```
用户输入姓名/模式 → 上传照片 → Soul API 创建数字人 → 获得 avatar_id
                   → 录音 30s+ → Ali TTS 克隆声音 → 获得 voice_id
                   → 命名虚拟人 → 保存 Profile 至 Hive → 进入对话
```

### 4.2 对话流程（Chat Loop）

```
用户按住麦克风 → 录音 (AAC-LC 16kHz)
    ↓
Ali NLS STT → 识别文字
    ↓
保存用户消息 → 注入三层记忆上下文 → Ali Qwen LLM (SSE 流式)
    ↓
流式显示回复文字 → 保存助手消息
    ↓
Ali TTS 合成语音 (克隆声音, 0.85x 语速) → 播放
    ↓
Soul Avatar 动画同步 (呼吸动效 / Talking-head 视频)
```

### 4.3 记忆系统（三层）

```
短期记忆 (Short-term)  → 最近 20 条消息 → Hive messages_box
                         用途：LLM 上下文窗口

中期记忆 (Episodic)    → 近 7 天每日摘要 → Hive memory_box
                         用途：让虚拟人记住"昨天聊了什么"
                         生成：每日对话结束后 LLM 自动总结

长期记忆 (Long-term)   → 用户档案 → Hive profile_box
                         内容：姓名、家庭成员、健康状况、兴趣爱好、重要日期
                         用途：个性化人格注入 System Prompt
```

每次对话前，三层记忆自动合并注入 LLM System Prompt，使虚拟人具备跨会话的记忆连续性。

---

## 5. 适老化 & 心理健康设计

### 语言适配

| 特性 | 老年人模式 | 心理健康模式 |
|------|-----------|-------------|
| 语速 | TTS 0.85x（慢速） | TTS 0.85x |
| 句长 | 每句 ≤ 20 字 | 每句 ≤ 20 字 |
| 回复长度 | ≤ 3 句 | ≤ 3 句 |
| 语气 | 像子女/老朋友 | 平静稳定的情绪锚点 |
| 特殊策略 | 重要信息重复、多提往事 | 不否定感受、接纳肯定 |

### 危机检测

系统检测到用户消息包含高风险关键词（"不想活""自杀"等）时：
1. 立即中断 LLM 生成，返回预置安抚话术
2. 温柔引导联系家人
3. 不提供任何医疗建议

### UI 无障碍

- 竖屏锁定
- 基础字号 16-18px，高行高
- 大按钮（≥ 48dp 触摸区域）
- 高对比配色（自然绿 #7B8B6F + 暖米色 #F5F0EB）

---

## 6. 提醒系统

| 类型 | 默认时间 | 说明 |
|------|---------|------|
| 早安问候 | 08:00 | 每日主动关心 |
| 服药提醒 | 08:30 | 可自定义时间 |
| 午间关怀 | 12:00 | 虚拟人发起对话 |
| 运动提醒 | 15:30 | 鼓励活动 |
| 晚安问候 | 21:00 | 每日结束关心 |

基于 `flutter_local_notifications`，设备本地调度，无需服务器。支持开关控制和时间编辑。

---

## 7. 快速开始

### 环境要求

- Flutter SDK ≥ 3.3.0 / Dart ≥ 3.0
- Android SDK ≥ 21 (Android 5.0+) / iOS ≥ 13.0
- Android Studio 或 VS Code + Flutter 插件

### 安装 & 运行

```bash
# 1. 安装依赖
flutter pub get

# 2. 代码生成（Hive + Riverpod 注解）
dart run build_runner build

# 3. 配置 API Keys（见下方）

# 4. 运行
flutter run -d android    # Android
flutter run -d ios        # iOS
flutter run -d macos      # macOS Desktop
```

### 配置 API Keys

编辑 `lib/core/utils/constants.dart`：

```dart
// 阿里云 DashScope (通义千问 LLM)
static const String aliLlmApiKey = 'your_dashscope_api_key';

// 阿里云 NLS 语音服务 (TTS + STT)
static const String aliNlsAppKey         = 'your_nls_app_key';
static const String aliNlsAccessKeyId    = 'your_access_key_id';
static const String aliNlsAccessKeySecret = 'your_access_key_secret';

// 硅基智能 Soul 数字人
static const String soulApiKey = 'your_soul_api_key';
```

### API 申请

| 服务 | 控制台 | 用途 |
|------|--------|------|
| 阿里云 DashScope | https://dashscope.aliyun.com | Qwen-Plus LLM 对话生成 |
| 阿里云 NLS | https://nls-portal.console.aliyun.com | CosyVoice 声音克隆 + 语音识别 |
| 硅基智能 | https://www.guiji.ai | Soul 数字人形象生成 |

### 打包发布

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Google Play)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 8. 目录结构

```
lib/
├── main.dart                        # 入口：竖屏锁定、初始化记忆 & 通知
├── app.dart                         # MaterialApp 配置
├── core/
│   ├── api/
│   │   ├── ali_llm_api.dart         # Qwen LLM（SSE 流式 + 摘要生成）
│   │   ├── ali_tts_api.dart         # CosyVoice TTS + 声音克隆
│   │   ├── ali_stt_api.dart         # 语音识别
│   │   └── soul_avatar_api.dart     # 数字人创建 + 视频生成 + 实时会话
│   ├── models/
│   │   ├── user_profile.dart        # 用户档案 (含 UserMode 枚举)
│   │   ├── avatar_model.dart        # 虚拟人模型 (avatar_id, voice_id)
│   │   ├── chat_message.dart        # 消息模型 (MessageRole 枚举)
│   │   └── reminder_model.dart      # 提醒模型 (ReminderType 枚举)
│   ├── services/
│   │   ├── recording_service.dart   # 录音 (16kHz AAC-LC)
│   │   ├── audio_player_service.dart# 音频播放
│   │   ├── notification_service.dart# 本地通知调度
│   │   └── permission_service.dart  # 权限管理
│   └── utils/
│       ├── constants.dart           # API Keys + 系统配置 ← 必须配置
│       ├── elderly_language.dart    # System Prompt 生成 + 危机检测
│       └── memory_manager.dart      # 三层记忆管理
├── features/
│   ├── onboarding/                  # 4步引导（姓名 → 照片 → 录音 → 命名）
│   ├── chat/                        # 主对话界面（语音输入 + 流式回复 + 语音播放）
│   ├── reminder/                    # 提醒管理
│   ├── settings/                    # 设置（通知/隐私/关于）
│   ├── recording/                   # 录音组件
│   ├── photo/                       # 照片上传组件
│   ├── avatar/                      # 虚拟人动画展示
│   └── memory/                      # 记忆管理
└── shared/
    ├── theme/app_theme.dart         # 适老化主题（大字号/高对比）
    └── widgets/                     # 通用组件（加载遮罩/错误弹窗）
```

---

## 9. 安全与隐私

- **API Key**：v1.0 存储于客户端（开发阶段），v2.0 将迁移至后端代理
- **本地存储**：所有对话记录、用户档案存储于设备本地 Hive 数据库，不上传服务器
- **录音素材**：仅用于声音克隆，处理后用户可删除原始录音
- **照片素材**：仅用于生成数字人形象，不另行存储
- **数据删除**：支持一键清除所有聊天记录
- **合规**：支持用户导出 / 删除所有个人数据（GDPR）

---

## 10. 开发计划

| 阶段 | 周期 | 内容 | 状态 |
|------|------|------|------|
| Phase 1 | 4-6 周 | Flutter UI + Profile 管理 + 素材上传 | ✅ 已完成 |
| Phase 2 | 4 周 | AI 模型集成 + 声音克隆 + 对话模块 | ✅ 已完成 |
| Phase 3 | 3 周 | 提醒系统 + 记忆系统 + 适老化 | ✅ 已完成 |
| Phase 4 | 2 周 | 测试 + 安全加固 + 打包发布 | 🔄 进行中 |
| Phase 5 | 4-6 周 | 后端服务 (FastAPI) + 多 Profile + 认证 | 📋 规划中 |
| Phase 6 | 3 周 | Prompt 模板系统 + 长期记忆 RAG | 📋 规划中 |
| Phase 7 | 3 周 | 自建模型部署 (GPU) + 模型热切换 | 📋 规划中 |

---

## 11. 已知限制 & 改进方向

| 问题 | 影响 | 改进方案 |
|------|------|---------|
| API Key 客户端暴露 | 安全风险 | v2.0 后端代理 |
| 单 Profile | 功能限制 | v2.0 多 Profile 数据隔离 |
| 视频生成延迟 (>10s) | 用户体验 | 改用 Soul 实时会话 WebSocket |
| 危机检测仅关键词匹配 | 误报/漏报 | 引入分类模型 |
| 无用户认证 | 数据安全 | v2.0 手机号/Apple ID 登录 |
| 本地存储无加密 | 数据安全 | 启用 Hive 加密 Box |

---

## License

MIT License
