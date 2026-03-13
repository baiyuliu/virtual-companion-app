// lib/core/models/reminder_model.dart

enum ReminderType {
  dailyGreeting,  // 每日问候
  medication,     // 服药提醒
  exercise,       // 运动提醒
  checkIn,        // 虚拟人主动打招呼
  custom,         // 自定义
}

class ReminderModel {
  final String id;
  final ReminderType type;
  final String title;
  final String message;
  final int hour;
  final int minute;
  final bool enabled;
  final List<int> weekdays; // 1=周一...7=周日，空=每天

  ReminderModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.weekdays = const [],
  });

  ReminderModel copyWith({bool? enabled}) => ReminderModel(
    id: id,
    type: type,
    title: title,
    message: message,
    hour: hour,
    minute: minute,
    enabled: enabled ?? this.enabled,
    weekdays: weekdays,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'title': title,
    'message': message,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
    'weekdays': weekdays,
  };

  factory ReminderModel.fromMap(Map<String, dynamic> map) => ReminderModel(
    id: map['id'] as String,
    type: ReminderType.values.byName(map['type'] as String),
    title: map['title'] as String,
    message: map['message'] as String,
    hour: map['hour'] as int,
    minute: map['minute'] as int,
    enabled: map['enabled'] as bool? ?? true,
    weekdays: List<int>.from(map['weekdays'] as List? ?? []),
  );
}
