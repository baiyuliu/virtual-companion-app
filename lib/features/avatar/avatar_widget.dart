// lib/features/avatar/avatar_widget.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/models/avatar_model.dart';

class AvatarWidget extends StatefulWidget {
  final AvatarModel avatarModel;
  final bool isSpeaking;

  const AvatarWidget({
    super.key,
    required this.avatarModel,
    required this.isSpeaking,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheCtrl;

  @override
  void initState() {
    super.initState();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景光晕
          AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (_, __) => Container(
              width: 180 + _breatheCtrl.value * 20,
              height: 180 + _breatheCtrl.value * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B8B6F).withOpacity(
                    0.08 + _breatheCtrl.value * 0.06),
              ),
            ),
          ),

          // 虚拟人头像/视频
          if (widget.avatarModel.avatarVideoUrl != null)
            // 实际项目中替换为视频播放器 (video_player 包)
            _VideoAvatarPlaceholder(isSpeaking: widget.isSpeaking)
          else if (widget.avatarModel.photoPath != null)
            _PhotoAvatar(
              path: widget.avatarModel.photoPath!,
              isSpeaking: widget.isSpeaking,
            )
          else
            _DefaultAvatar(
              name: widget.avatarModel.name,
              isSpeaking: widget.isSpeaking,
            ),

          // 说话动效
          if (widget.isSpeaking)
            Positioned(
              bottom: 10,
              child: Lottie.asset(
                'assets/animations/speaking_wave.json',
                width: 80,
                height: 30,
                // fallback: 如果动画文件不存在显示文字
                errorBuilder: (_, __, ___) => const Text(
                  '💬',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoAvatar extends StatelessWidget {
  final String path;
  final bool isSpeaking;

  const _PhotoAvatar({required this.path, required this.isSpeaking});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSpeaking
              ? const Color(0xFF7B8B6F)
              : Colors.white,
          width: isSpeaking ? 3 : 2,
        ),
        image: DecorationImage(
          image: AssetImage(path),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  final String name;
  final bool isSpeaking;

  const _DefaultAvatar({required this.name, required this.isSpeaking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF7B8B6F),
        border: Border.all(
          color: isSpeaking ? Colors.orange : Colors.white,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '❤',
          style: const TextStyle(
            fontSize: 56,
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

class _VideoAvatarPlaceholder extends StatelessWidget {
  final bool isSpeaking;
  const _VideoAvatarPlaceholder({required this.isSpeaking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black12,
      ),
      child: const Center(
        child: Text('🎬', style: TextStyle(fontSize: 48)),
      ),
    );
  }
}
