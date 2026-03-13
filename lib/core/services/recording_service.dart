// lib/core/services/recording_service.dart

import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000, // 阿里云STT要求16kHz
        bitRate: 128000,
        numChannels: 1,    // 单声道
      ),
      path: path,
    );
  }

  Future<String?> stopRecording() => _recorder.stop();

  Stream<Amplitude> amplitudeStream() =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  Future<bool> get isRecording => _recorder.isRecording();

  Future<void> dispose() => _recorder.dispose();
}
