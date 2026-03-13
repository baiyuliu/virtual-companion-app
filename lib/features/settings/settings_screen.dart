// lib/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import '../../core/utils/memory_manager.dart';
import '../reminder/reminder_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF7B8B6F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: '提醒与通知', children: [
            _Tile(
              icon: Icons.alarm,
              title: '提醒设置',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReminderScreen())),
            ),
          ]),

          _Section(title: '数据与隐私', children: [
            _Tile(
              icon: Icons.delete_outline,
              title: '清除聊天记录',
              subtitle: '清除本次会话的对话内容',
              onTap: () => _confirmClear(context),
            ),
          ]),

          _Section(title: '关于', children: [
            _Tile(
              icon: Icons.info_outline,
              title: '版本',
              subtitle: 'v1.0.0',
              onTap: null,
            ),
          ]),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清除记录'),
        content: const Text('确定要清除聊天记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await MemoryManager.clearSession();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _Tile(
      {required this.icon,
      required this.title,
      this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7B8B6F)),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 13))
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
