// lib/core/api/ali_llm_api.dart
// 阿里云通义千问 Qwen-Plus (约30B参数) 对话接口

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../utils/elderly_language.dart';
import '../utils/memory_manager.dart';

class AliLlmApi {
  late final Dio _dio;

  AliLlmApi() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.aliLlmBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Authorization': 'Bearer ${AppConstants.aliLlmApiKey}',
        'Content-Type': 'application/json',
      },
    ));
  }

  /// 流式对话（SSE）
  /// 返回 Stream<String>，每次 yield 一个文字片段
  Stream<String> chatStream({
    required String avatarName,
    required String userMessage,
    required String userName,
    required UserMode userMode,
  }) async* {
    // 危机检测
    if (ElderlyLanguageAdapter.containsCrisisSignal(userMessage)) {
      yield ElderlyLanguageAdapter.crisisResponse(userName);
      return;
    }

    // 构建记忆上下文
    final memoryContext = MemoryManager.buildFullMemoryContext();

    // 构建 System Prompt
    final systemPrompt = ElderlyLanguageAdapter.buildSystemPrompt(
      avatarName: avatarName,
      userName: userName,
      memoryContext: memoryContext,
      mode: userMode,
    );

    // 获取历史消息
    final history = MemoryManager.getRecentMessages(
      limit: AppConstants.shortTermMemoryLimit,
    );

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await _dio.post<ResponseBody>(
        '/services/aigc/text-generation/generation',
        data: {
          'model': AppConstants.aliLlmModel,
          'input': {'messages': messages},
          'parameters': {
            'result_format': 'message',
            'incremental_output': true,   // 流式输出
            'temperature': 0.8,
            'max_tokens': 256,            // 老人模式回复不需要太长
          },
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'X-DashScope-SSE': 'enable'},
        ),
      );

      String buffer = '';
      await for (final chunk in response.data!.stream) {
        final text = utf8.decode(chunk);
        buffer += text;
        // SSE 格式: "data: {...}\n\n"
        final lines = buffer.split('\n');
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.startsWith('data:')) {
            final jsonStr = line.substring(5).trim();
            if (jsonStr == '[DONE]') return;
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              final output = json['output'] as Map<String, dynamic>?;
              final choices = output?['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final delta = (choices[0] as Map)['message']?['content'] as String?;
                if (delta != null && delta.isNotEmpty) {
                  yield delta;
                }
              }
            } catch (_) {}
          }
        }
        buffer = lines.last;
      }
    } on DioException catch (e) {
      yield '抱歉，我现在有点累了，等会儿再聊好吗？';
      // ignore: avoid_print
      print('[AliLlmApi] Error: ${e.message}');
    }
  }

  /// 非流式，用于生成摘要（日记忆）
  Future<String> generateSummary(String prompt) async {
    try {
      final response = await _dio.post(
        '/services/aigc/text-generation/generation',
        data: {
          'model': AppConstants.aliLlmModel,
          'input': {
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          },
          'parameters': {
            'result_format': 'message',
            'max_tokens': 60,
          },
        },
      );
      final output = response.data['output'] as Map<String, dynamic>;
      final choices = output['choices'] as List;
      return (choices[0] as Map)['message']['content'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}
