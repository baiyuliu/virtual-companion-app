// lib/features/onboarding/onboarding_screen.dart
// 引导页：收集照片、录音、用户信息，生成虚拟人

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/ali_tts_api.dart';
import '../../core/api/soul_avatar_api.dart';
import '../../core/models/avatar_model.dart';
import '../../core/services/recording_service.dart';
import '../../core/utils/elderly_language.dart';
import '../../core/utils/memory_manager.dart';
import '../chat/chat_screen.dart';
import '../../shared/widgets/loading_overlay.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  final _recorder  = RecordingService();
  final _ttsApi    = AliTtsApi();
  final _soulApi   = SoulAvatarApi();
  final _uuid      = const Uuid();

  int      _currentPage   = 0;
  File?    _selectedPhoto;
  String?  _voiceFilePath;
  bool     _isRecording   = false;
  bool     _isLoading     = false;
  String   _loadingMsg    = '';
  UserMode _userMode      = UserMode.elderly;

  final _nameCtrl        = TextEditingController();
  final _familyCtrl      = TextEditingController();
  final _avatarNameCtrl  = TextEditingController(text: '小美');

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _familyCtrl.dispose();
    _avatarNameCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (xfile != null) {
      setState(() => _selectedPhoto = File(xfile.path));
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecording();
      setState(() {
        _isRecording = false;
        _voiceFilePath = path;
      });
    } else {
      await _recorder.startRecording();
      setState(() => _isRecording = true);
    }
  }

  Future<void> _createAvatar() async {
    setState(() {
      _isLoading  = true;
      _loadingMsg = '正在生成您的专属陪伴人…';
    });

    try {
      String? voiceId;
      String? soulAvatarId;

      // 1. 保存用户档案
      await MemoryManager.saveUserProfile(
        userName: _nameCtrl.text,
        familyMembers: _familyCtrl.text,
      );

      // 2. 克隆声音
      if (_voiceFilePath != null) {
        setState(() => _loadingMsg = '正在学习声音特征…');
        voiceId = await _ttsApi.cloneVoice(_voiceFilePath!);
      }

      // 3. 生成数字人形象
      if (_selectedPhoto != null) {
        setState(() => _loadingMsg = '正在生成数字人形象…');
        soulAvatarId = await _soulApi.createAvatarFromPhoto(_selectedPhoto!);
      }

      // 4. 设置 Soul 性格
      if (soulAvatarId != null) {
        setState(() => _loadingMsg = '正在注入性格…');
        await _soulApi.setAvatarSoul(
          avatarId: soulAvatarId,
          personalityDescription:
              '温柔体贴，耐心倾听，说话简单易懂，适合陪伴老年人或心理需要关怀的人',
          userName: _nameCtrl.text,
        );
      }

      final avatar = AvatarModel(
        id: _uuid.v4(),
        name: _avatarNameCtrl.text,
        photoPath: _selectedPhoto?.path,
        voiceId: voiceId,
        soulAvatarId: soulAvatarId,
        createdAt: DateTime.now(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            avatar: avatar,
            userMode: _userMode,
            userName: _nameCtrl.text.isEmpty ? '朋友' : _nameCtrl.text,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('创建失败，请检查网络后重试');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      _createAvatar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: _loadingMsg,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0EB),
        body: SafeArea(
          child: Column(
            children: [
              // 进度指示
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: List.generate(4, (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? const Color(0xFF7B8B6F)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _WelcomePage(
                      nameCtrl: _nameCtrl,
                      userMode: _userMode,
                      onModeChanged: (m) => setState(() => _userMode = m),
                    ),
                    _PhotoPage(
                      selectedPhoto: _selectedPhoto,
                      onPick: _pickPhoto,
                    ),
                    _VoicePage(
                      isRecording: _isRecording,
                      hasRecorded: _voiceFilePath != null,
                      onToggle: _toggleRecording,
                    ),
                    _AvatarNamePage(
                      ctrl: _avatarNameCtrl,
                      familyCtrl: _familyCtrl,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B8B6F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: _nextPage,
                    child: Text(_currentPage < 3 ? '下一步' : '开始陪伴 ❤️'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 各步骤页面 ─────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final TextEditingController nameCtrl;
  final UserMode userMode;
  final ValueChanged<UserMode> onModeChanged;

  const _WelcomePage({
    required this.nameCtrl,
    required this.userMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('你好！', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w300)),
          const SizedBox(height: 8),
          const Text('我是你的专属陪伴人。\n先告诉我你的名字吧~',
              style: TextStyle(fontSize: 18, color: Colors.grey, height: 1.6)),
          const SizedBox(height: 32),
          TextField(
            controller: nameCtrl,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              labelText: '您的名字',
              labelStyle: const TextStyle(fontSize: 16),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('使用模式：', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              _ModeChip(
                label: '👴 老年人模式',
                selected: userMode == UserMode.elderly,
                onTap: () => onModeChanged(UserMode.elderly),
              ),
              const SizedBox(width: 12),
              _ModeChip(
                label: '💙 心理关怀模式',
                selected: userMode == UserMode.mentalHealth,
                onTap: () => onModeChanged(UserMode.mentalHealth),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7B8B6F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFF7B8B6F)
                  : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PhotoPage extends StatelessWidget {
  final File? selectedPhoto;
  final VoidCallback onPick;

  const _PhotoPage({this.selectedPhoto, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('上传一张照片', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300)),
          const SizedBox(height: 8),
          const Text('用您或亲人的照片，\n我会变成Ta的样子陪伴您~',
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.6)),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onPick,
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF7B8B6F), width: 2),
                ),
                child: selectedPhoto != null
                    ? ClipOval(
                        child: Image.file(selectedPhoto!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 48, color: Color(0xFF7B8B6F)),
                          SizedBox(height: 8),
                          Text('点击选择照片',
                              style: TextStyle(
                                  color: Color(0xFF7B8B6F), fontSize: 14)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('照片仅用于生成形象，不会上传保存',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _VoicePage extends StatelessWidget {
  final bool isRecording;
  final bool hasRecorded;
  final VoidCallback onToggle;

  const _VoicePage(
      {required this.isRecording,
      required this.hasRecorded,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('录制声音', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300)),
          const SizedBox(height: 8),
          const Text('请朗读下方文字约30秒，\n我会学习您的声音特征~',
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.6)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '「今天天气真好，阳光暖洋洋的。'
              '我最喜欢和家人一起吃饭聊天了，'
              '大家开开心心地在一起，真是幸福啊。'
              '希望每天都这么快乐，健健康康的。」',
              style: TextStyle(fontSize: 16, height: 1.8, color: Color(0xFF444444)),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording
                      ? Colors.red.shade400
                      : const Color(0xFF7B8B6F),
                ),
                child: Icon(
                  isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              isRecording
                  ? '录音中… 朗读完成后点击停止'
                  : hasRecorded
                      ? '✅ 录音完成！'
                      : '点击开始录音（建议30秒以上）',
              style: TextStyle(
                color: hasRecorded ? const Color(0xFF7B8B6F) : Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarNamePage extends StatelessWidget {
  final TextEditingController ctrl;
  final TextEditingController familyCtrl;

  const _AvatarNamePage({required this.ctrl, required this.familyCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('给TA起个名字', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300)),
          const SizedBox(height: 8),
          const Text('这是您专属陪伴人的名字~',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          TextField(
            controller: ctrl,
            style: const TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '小美',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('家人姓名（可选）',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: familyCtrl,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: '例如：女儿小红、儿子小明',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('填写家人姓名后，陪伴人会在聊天中自然提起他们哦~',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
