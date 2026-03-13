// lib/core/api/soul_avatar_api.dart
// 硅基智能数字人 Soul 大模型 API
// 官网: https://www.guiji.ai
// 文档: https://docs.guiji.ai/docs/digital-human/

import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

class SoulAvatarApi {
  late final Dio _dio;

  SoulAvatarApi() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.soulApiBase,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 3),
      headers: {
        'Authorization': 'Bearer ${AppConstants.soulApiKey}',
        'Content-Type': 'application/json',
      },
    ));
  }

  // ─── 上传照片，创建数字人形象 ─────────────────────────────────
  /// 返回 avatar_id
  Future<String?> createAvatarFromPhoto(File photo) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: 'avatar_photo.jpg',
        ),
        'style': 'realistic', // realistic / anime / cartoon
      });

      final response = await _dio.post(
        '/avatar/create',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return response.data['data']?['avatar_id'] as String?;
    } catch (e) {
      // ignore: avoid_print
      print('[SoulAvatarApi] createAvatar error: $e');
      return null;
    }
  }

  // ─── 生成说话视频/视频流 ──────────────────────────────────────
  /// [text] 要说的内容，[voiceId] 阿里云声音克隆ID
  /// 返回视频URL或视频流地址
  Future<String?> generateSpeakingVideo({
    required String avatarId,
    required String text,
    String? voiceId,
  }) async {
    try {
      final response = await _dio.post('/avatar/speak', data: {
        'avatar_id': avatarId,
        'text': text,
        'voice_id': voiceId,          // 可传入阿里云克隆声音ID
        'background': 'transparent',  // 透明背景
        'resolution': '512x512',
      });

      // 轮询任务直到完成
      final taskId = response.data['data']?['task_id'] as String?;
      if (taskId == null) return null;

      return await _pollTask(taskId);
    } catch (e) {
      // ignore: avoid_print
      print('[SoulAvatarApi] generateSpeakingVideo error: $e');
      return null;
    }
  }

  // ─── 数字人实时互动流（WebRTC/WebSocket） ────────────────────
  /// 创建实时会话，返回 session_id 和 ws_url
  Future<Map<String, String>?> createRealtimeSession({
    required String avatarId,
    required String voiceId,
  }) async {
    try {
      final response = await _dio.post('/avatar/realtime/session', data: {
        'avatar_id': avatarId,
        'voice_id': voiceId,
        'mode': 'conversation',
      });

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      return {
        'session_id': data['session_id'] as String? ?? '',
        'ws_url': data['ws_url'] as String? ?? '',
      };
    } catch (e) {
      // ignore: avoid_print
      print('[SoulAvatarApi] createRealtimeSession error: $e');
      return null;
    }
  }

  // ─── 设置数字人性格 (Soul大模型) ─────────────────────────────
  Future<bool> setAvatarSoul({
    required String avatarId,
    required String personalityDescription,
    required String userName,
  }) async {
    try {
      await _dio.post('/avatar/soul/set', data: {
        'avatar_id': avatarId,
        'personality': personalityDescription,
        'user_name': userName,
        'memory_enabled': true,
        'emotion_enabled': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── 轮询异步任务 ─────────────────────────────────────────────
  Future<String?> _pollTask(String taskId, {int maxAttempts = 30}) async {
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final res = await _dio.get('/tasks/$taskId');
        final status = res.data['data']?['status'] as String?;
        if (status == 'succeeded') {
          return res.data['data']?['video_url'] as String?;
        } else if (status == 'failed') {
          return null;
        }
      } catch (_) {}
    }
    return null;
  }
}
