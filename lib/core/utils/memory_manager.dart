// lib/core/utils/memory_manager.dart
// 三层本地记忆系统: 短期 / 中期 / 长期

import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message.dart';
import 'constants.dart';

class MemoryManager {
  static late Box _messageBox;
  static late Box _profileBox;
  static late Box _memoryBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _messageBox = await Hive.openBox(AppConstants.hiveBoxMessages);
    _profileBox = await Hive.openBox(AppConstants.hiveBoxProfile);
    _memoryBox  = await Hive.openBox(AppConstants.hiveBoxMemory);
  }

  // ─── 短期记忆：当前会话消息 ──────────────────────────────────

  static Future<void> saveMessage(ChatMessage msg) async {
    final key = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    await _messageBox.put(key, {
      'role': msg.role,
      'content': msg.content,
      'timestamp': msg.timestamp.toIso8601String(),
    });
  }

  /// 获取最近 N 条消息（用于 LLM 上下文）
  static List<Map<String, String>> getRecentMessages({int limit = 20}) {
    final all = _messageBox.values.toList();
    final recent = all.length > limit ? all.sublist(all.length - limit) : all;
    return recent.map<Map<String, String>>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return {'role': m['role'] as String, 'content': m['content'] as String};
    }).toList();
  }

  // ─── 中期记忆：事件摘要（每日生成）───────────────────────────

  static Future<void> saveEpisodicMemory(String summary) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _memoryBox.put('episodic_$today', summary);
  }

  /// 获取最近7天的事件摘要
  static String getEpisodicContext() {
    final buffer = StringBuffer();
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now()
          .subtract(Duration(days: i))
          .toIso8601String()
          .substring(0, 10);
      final summary = _memoryBox.get('episodic_$date');
      if (summary != null) {
        buffer.writeln('$date: $summary');
      }
    }
    return buffer.toString();
  }

  // ─── 长期记忆：用户档案 ───────────────────────────────────────

  static Future<void> saveUserProfile({
    String? userName,
    String? familyMembers,
    String? healthNotes,
    String? interests,
    String? importantDates,
  }) async {
    if (userName != null)      await _profileBox.put('user_name', userName);
    if (familyMembers != null) await _profileBox.put('family_members', familyMembers);
    if (healthNotes != null)   await _profileBox.put('health_notes', healthNotes);
    if (interests != null)     await _profileBox.put('interests', interests);
    if (importantDates != null)await _profileBox.put('important_dates', importantDates);
  }

  static String getUserProfileContext() {
    final name     = _profileBox.get('user_name',       defaultValue: '');
    final family   = _profileBox.get('family_members',  defaultValue: '');
    final health   = _profileBox.get('health_notes',    defaultValue: '');
    final interest = _profileBox.get('interests',       defaultValue: '');
    final dates    = _profileBox.get('important_dates', defaultValue: '');

    return '''
用户名字: $name
家庭成员: $family
健康注意: $health
兴趣爱好: $interest
重要日期: $dates
近期事件:
${getEpisodicContext()}
''';
  }

  /// 构建完整记忆上下文，用于注入 System Prompt
  static String buildFullMemoryContext() {
    return getUserProfileContext();
  }

  /// 每天对话结束后，用 LLM 生成当日摘要并保存
  static Future<void> summarizeAndSaveToday(
      List<Map<String, String>> messages, Function(String) llmSummarize) async {
    if (messages.isEmpty) return;
    final transcript = messages
        .map((m) => '${m['role']}: ${m['content']}')
        .join('\n');
    final summary = await llmSummarize(
      '请用一句话（不超过30字）总结这段对话中用户的主要心情或发生的事情：\n$transcript',
    );
    await saveEpisodicMemory(summary);
  }

  static Future<void> clearSession() async {
    await _messageBox.clear();
  }
}
