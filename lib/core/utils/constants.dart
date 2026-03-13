// lib/core/utils/constants.dart
// ⚠️  请替换为您的真实 API Keys，不要提交到 Git

class AppConstants {
  AppConstants._();

  // ─── 阿里云 DashScope (通义千问 LLM) ─────────────────────────
  static const String aliLlmApiKey = 'YOUR_DASHSCOPE_API_KEY';
  static const String aliLlmBaseUrl = 'https://dashscope.aliyuncs.com/api/v1';
  // Qwen-Plus = 约30B参数，性价比最优；也可换 qwen-max / qwen-turbo
  static const String aliLlmModel = 'qwen-plus';

  // ─── 阿里云 NLS 语音服务 ──────────────────────────────────────
  static const String aliNlsAppKey = 'YOUR_NLS_APP_KEY';
  static const String aliNlsAccessKeyId = 'YOUR_ACCESS_KEY_ID';
  static const String aliNlsAccessKeySecret = 'YOUR_ACCESS_KEY_SECRET';
  // TTS WebSocket endpoint
  static const String aliTtsWsUrl =
      'wss://nls-gateway.cn-shanghai.aliyuncs.com/ws/v1';
  // STT REST endpoint
  static const String aliSttRestUrl =
      'https://nls-gateway.cn-shanghai.aliyuncs.com/stream/v1/tts';

  // ─── 硅基智能 Soul 数字人 ─────────────────────────────────────
  // 官网: https://www.guiji.ai   文档: https://docs.guiji.ai
  static const String soulApiKey = 'YOUR_SOUL_API_KEY';
  static const String soulApiBase = 'https://api.guiji.ai/v1';

  // ─── 本地记忆 Hive Box 名称 ───────────────────────────────────
  static const String hiveBoxMessages = 'messages_box';
  static const String hiveBoxProfile  = 'profile_box';
  static const String hiveBoxMemory   = 'memory_box';
  static const String hiveBoxReminder = 'reminder_box';

  // ─── 对话上下文窗口 ───────────────────────────────────────────
  static const int shortTermMemoryLimit = 20;    // 最近20条消息
  static const int episodicMemoryDays   = 7;     // 近7天事件摘要

  // ─── 老年/心理健康模式默认值 ──────────────────────────────────
  static const double defaultSpeechRate  = 0.85; // TTS语速 (1.0=正常)
  static const int    maxSentenceLength  = 25;   // 单句最大字数提示
  static const bool   enableCrisisDetect = true; // 危机词汇检测

  // ─── 紧急联系 ─────────────────────────────────────────────────
  /// 检测到以下关键词时触发紧急通知
  static const List<String> crisisKeywords = [
    '不想活', '死了算了', '自杀', '结束生命',
    '没有意义', '太痛苦了', '伤害自己',
  ];
}
