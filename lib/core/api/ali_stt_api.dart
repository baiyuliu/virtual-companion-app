// lib/core/api/ali_stt_api.dart
// 阿里云一句话识别 (STT)

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

class AliSttApi {
  final Dio _dio = Dio();

  /// 将录音文件转换为文字
  /// 支持 m4a、mp3、wav 等格式，建议16kHz采样率
  Future<String?> recognize(String audioFilePath) async {
    try {
      final audioBytes = await File(audioFilePath).readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      final response = await _dio.post(
        'https://nls-gateway.cn-shanghai.aliyuncs.com/stream/v1/FlashRecognizer',
        queryParameters: {
          'appkey': AppConstants.aliNlsAppKey,
        },
        data: {
          'audio_data': base64Audio,
          'format': 'mp4', // m4a 使用 mp4 格式标识
          'sample_rate': 16000,
          'enable_punctuation_prediction': true,
          'enable_inverse_text_normalization': true, // 数字/日期规范化
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-NLS-Token': await _getToken(),
          },
        ),
      );

      final result = response.data;
      if (result['status'] == 20000000) {
        final sentences = result['flash_result']?['sentences'] as List?;
        if (sentences != null && sentences.isNotEmpty) {
          return sentences.map((s) => s['text'] as String? ?? '').join('');
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[AliSttApi] Error: $e');
      return null;
    }
  }

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
        headers: {'Authorization': 'Bearer ${AppConstants.aliLlmApiKey}'},
      ),
    );
    _cachedToken = response.data['Token']?['Id'] as String? ?? '';
    _tokenExpiry = DateTime.now().add(const Duration(hours: 23));
    return _cachedToken!;
  }
}
