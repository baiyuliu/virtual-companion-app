// lib/features/chat/chat_screen.dart
// 主对话界面

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/ali_llm_api.dart';
import '../../core/api/ali_tts_api.dart';
import '../../core/api/ali_stt_api.dart';
import '../../core/models/chat_message.dart';
import '../../core/models/avatar_model.dart';
import '../../core/services/recording_service.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/utils/memory_manager.dart';
import '../../core/utils/elderly_language.dart';
import '../avatar/avatar_widget.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final AvatarModel avatar;
  final UserMode userMode;
  final String userName;

  const ChatScreen({
    super.key,
    required this.avatar,
    required this.userMode,
    required this.userName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _llmApi    = AliLlmApi();
  final _ttsApi    = AliTtsApi();
  final _sttApi    = AliSttApi();
  final _recorder  = RecordingService();
  final _player    = AudioPlayerService();
  final _uuid      = const Uuid();
  final _scrollCtrl = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isRecording     = false;
  bool _isSpeaking      = false;
  bool _isProcessing    = false;
  String _llmBuffer     = '';

  @override
  void initState() {
    super.initState();
    _sendInitialGreeting();
  }

  // 对话开始时虚拟人主动打招呼
  Future<void> _sendInitialGreeting() async {
    final greeting = '${widget.userName}，你好呀！我在这儿呢，今天感觉怎么样？';
    await _speak(greeting);
    _addMessage(ChatMessage(
      id: _uuid.v4(),
      content: greeting,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    ));
  }

  void _addMessage(ChatMessage msg) {
    setState(() => _messages.add(msg));
    MemoryManager.saveMessage(msg);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── 录音控制 ─────────────────────────────────────────────────

  Future<void> _onMicTap() async {
    if (_isProcessing) return;

    if (_isRecording) {
      await _stopAndProcess();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showPermissionDialog();
      return;
    }
    await _recorder.startRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _stopAndProcess() async {
    final path = await _recorder.stopRecording();
    setState(() {
      _isRecording   = false;
      _isProcessing  = true;
    });

    if (path == null) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // 1. STT: 语音 → 文字
      final text = await _sttApi.recognize(path);
      if (text == null || text.trim().isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      // 2. 保存用户消息
      final userMsg = ChatMessage(
        id: _uuid.v4(),
        content: text,
        role: MessageRole.user,
        timestamp: DateTime.now(),
        isVoice: true,
      );
      _addMessage(userMsg);

      // 3. LLM 流式回复
      String fullReply = '';
      _llmBuffer = '';
      setState(() {});

      final stream = _llmApi.chatStream(
        avatarName: widget.avatar.name,
        userMessage: text,
        userName: widget.userName,
        userMode: widget.userMode,
      );

      await for (final chunk in stream) {
        fullReply += chunk;
        setState(() => _llmBuffer = fullReply);
      }

      // 4. 保存助手消息
      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        content: fullReply,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      _addMessage(assistantMsg);
      setState(() => _llmBuffer = '');

      // 5. TTS 播放
      await _speak(fullReply);

    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    try {
      final audio = await _ttsApi.synthesize(
        text: text,
        voiceId: widget.avatar.voiceId,
        speechRate: 0.85,
      );
      if (audio != null) await _player.playFromBytes(audio);
    } finally {
      setState(() => _isSpeaking = false);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('需要麦克风权限'),
        content: const Text('请在手机设置中允许使用麦克风，这样我才能听到你说话。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SafeArea(
        child: Column(
          children: [
            // ── 虚拟人展示区 ──────────────────────────────────
            Container(
              height: 260,
              color: const Color(0xFFE8DDD0),
              child: AvatarWidget(
                avatarModel: widget.avatar,
                isSpeaking: _isSpeaking,
              ),
            ),

            // ── 对话消息列表 ──────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: _messages.length +
                    (_llmBuffer.isNotEmpty ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == _messages.length && _llmBuffer.isNotEmpty) {
                    return _MessageBubble(
                      content: _llmBuffer,
                      isUser: false,
                      isStreaming: true,
                    );
                  }
                  final msg = _messages[i];
                  return _MessageBubble(
                    content: msg.content,
                    isUser: msg.role == MessageRole.user,
                  );
                },
              ),
            ),

            // ── 麦克风按钮 ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              child: Column(
                children: [
                  if (_isProcessing)
                    const Text('正在思考中…',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _onMicTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isRecording ? 80 : 68,
                      height: _isRecording ? 80 : 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? const Color(0xFFE57373)
                            : const Color(0xFF7B8B6F),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? Colors.red
                                    : const Color(0xFF7B8B6F))
                                .withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording ? '点击停止，发送语音' : '点击说话',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 消息气泡 ──────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isStreaming;

  const _MessageBubble({
    required this.content,
    required this.isUser,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF7B8B6F)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          content + (isStreaming ? '▌' : ''),
          style: TextStyle(
            fontSize: 17, // 大字体，适老化
            color: isUser ? Colors.white : const Color(0xFF333333),
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
