// lib/features/reminder/reminder_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/reminder_model.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/loading_overlay.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _notifService = NotificationService();
  final _uuid = const Uuid();
  List<ReminderModel> _reminders = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultReminders();
  }

  void _loadDefaultReminders() {
    setState(() {
      _reminders = [
        ReminderModel(
          id: _uuid.v4(),
          type: ReminderType.dailyGreeting,
          title: '早安问候 🌅',
          message: '早上好！新的一天开始了，今天也要加油哦~',
          hour: 8,
          minute: 0,
        ),
        ReminderModel(
          id: _uuid.v4(),
          type: ReminderType.medication,
          title: '记得吃药 💊',
          message: '该吃药了，记得按时服药，身体是最重要的~',
          hour: 8,
          minute: 30,
        ),
        ReminderModel(
          id: _uuid.v4(),
          type: ReminderType.checkIn,
          title: '午间问候 ☀️',
          message: '中午好！吃饭了吗？我在想你呢~',
          hour: 12,
          minute: 0,
        ),
        ReminderModel(
          id: _uuid.v4(),
          type: ReminderType.exercise,
          title: '活动一下 🚶',
          message: '下午了，起来走走吧，对身体好~',
          hour: 15,
          minute: 30,
        ),
        ReminderModel(
          id: _uuid.v4(),
          type: ReminderType.dailyGreeting,
          title: '晚安问候 🌙',
          message: '晚上好！今天辛苦了，早点休息，我陪着你~',
          hour: 21,
          minute: 0,
        ),
      ];
    });
  }

  Future<void> _toggleReminder(ReminderModel r, bool enabled) async {
    setState(() => _loading = true);
    try {
      final updated = r.copyWith(enabled: enabled);
      if (enabled) {
        await _notifService.scheduleReminder(updated);
      } else {
        await _notifService.cancelReminder(r.id);
      }
      setState(() {
        final idx = _reminders.indexWhere((x) => x.id == r.id);
        if (idx != -1) _reminders[idx] = updated;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _editTime(ReminderModel r) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: r.hour, minute: r.minute),
    );
    if (picked == null) return;

    final updated = ReminderModel(
      id: r.id,
      type: r.type,
      title: r.title,
      message: r.message,
      hour: picked.hour,
      minute: picked.minute,
      enabled: r.enabled,
    );

    if (updated.enabled) {
      await _notifService.cancelReminder(r.id);
      await _notifService.scheduleReminder(updated);
    }

    setState(() {
      final idx = _reminders.indexWhere((x) => x.id == r.id);
      if (idx != -1) _reminders[idx] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0EB),
        appBar: AppBar(
          title: const Text('提醒设置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          backgroundColor: const Color(0xFF7B8B6F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _reminders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = _reminders[i];
            return _ReminderCard(
              reminder: r,
              onToggle: (v) => _toggleReminder(r, v),
              onEditTime: () => _editTime(r),
            );
          },
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEditTime;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onEditTime,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${reminder.hour.toString().padLeft(2, '0')}:'
        '${reminder.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onEditTime,
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: reminder.enabled
                          ? const Color(0xFF7B8B6F)
                          : Colors.grey,
                    ),
                  ),
                ),
                Text(reminder.message,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          CupertinoSwitch(
            value: reminder.enabled,
            activeColor: const Color(0xFF7B8B6F),
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
