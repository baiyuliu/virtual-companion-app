// lib/core/models/chat_message.dart
import 'package:hive_flutter/hive_flutter.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isVoice;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isVoice = false,
  });

  String get roleString => role == MessageRole.user ? 'user' : 'assistant';

  Map<String, String> toApiMap() => {
    'role': roleString,
    'content': content,
  };
}
