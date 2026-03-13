// lib/core/api/ali_tts_api.dart
// 阿里云 CosyVoice TTS + 声音克隆

import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

class AliTtsApi {
  final Dio _dio = Dio();

  // ─── 声音克隆：上传录音 → 获取 voice_id ──────────────────────
  /// 上传15-30秒音频，返回克隆声音ID
  Future<String?> cloneVoice(String audioFilePath) async {
    try {
      final token = await _getToken();
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'voice_sample.m4a',
        ),
      });

      // 阿里云 CosyVoice 自定义音色接口
      final response = await _dio.post(
        'https://dashscope.aliyuncs.com/api/v1/services/audio/tts/customization',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConstants.aliLlmApiKey}',
            'X-NLS-Token': token,
          },
        ),
      );

      return response.data['data']?['voice_id'] as String?;
    } catch (e) {
      // ignore: avoid_print
      print('[AliTtsApi] Clone voice error: $e');
      return null;
    }
  }

  // ─── 语音合成：文字 → 音频字节 ───────────────────────────────
  /// [voiceId] 为克隆声音ID，若为null则使用默认温柔老人声
  Future<Uint8List?> synthesize({
    required String text,
    String? voiceId,
    double speechRate = 0.85, // 适老化：稍慢
    double volume = 1.0,
    String format = 'mp3',
  }) async {
    try {
      final token = await _getToken();

      final response = await _dio.post<List<int>>(
        'https://nls-gateway.cn-shanghai.aliyuncs.com/stream/v1/tts',
        queryParameters: {
          'appkey': AppConstants.aliNlsAppKey,
          'token': token,
        },
        data: {
          'text': text,
          'voice': voiceId ?? 'cosyvoice-v1-longnv', // 默认: 温柔女声
          'format': format,
          'sample_rate': 16000,
          'speech_rate': ((speechRate - 1.0) * 500).toInt(), // [-500, 500]
          'pitch_rate': 0,
          'volume': (volume * 50).toInt(),
          'enable_subtitle': false,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-NLS-Token': token,
          },
          responseType: ResponseType.bytes,
        ),
      );

      return Uint8List.fromList(response.data!);
    } catch (e) {
      // ignore: avoid_print
      print('[AliTtsApi] Synthesize error: $e');
      return null;
    }
  }

  // ─── 获取 NLS Token（有效期24小时，实际可缓存）───────────────
  String? _cachedToken;
  DateTime? _tokenExpiry;

  Future<String> _getToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken!;
    }

    final response = await _dio.post(
      'https://nls-meta.cn-shanghai.aliyuncs.com/pop/2018-05-18/tokens',
      options: Options(
        headers: {
          'Authorization':
              'Bearer ${AppConstants.aliLlmApiKey}',
        },
      ),
    );

    _cachedToken = response.data['Token']?['Id'] as String? ?? '';
    _tokenExpiry = DateTime.now().add(const Duration(hours: 23));
    return _cachedToken!;
  }
}
