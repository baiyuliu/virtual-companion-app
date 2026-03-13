// lib/core/services/audio_player_service.dart

import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Stream<PlayerState> get stateStream => _player.playerStateStream;
  bool get isPlaying => _player.playing;

  Future<void> playFromBytes(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await file.writeAsBytes(bytes);
    await _player.setFilePath(file.path);
    await _player.play();
  }

  Future<void> playFromFile(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> stop() => _player.stop();
  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();

  Future<void> dispose() => _player.dispose();
}
