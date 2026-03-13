// lib/core/models/user_profile.dart
import '../utils/elderly_language.dart';

class UserProfile {
  final String name;
  final UserMode mode;
  final String? avatarId;
  final String? emergencyContact; // 紧急联系人电话
  final String familyMembers;
  final String healthNotes;
  final String interests;

  UserProfile({
    required this.name,
    this.mode = UserMode.elderly,
    this.avatarId,
    this.emergencyContact,
    this.familyMembers = '',
    this.healthNotes = '',
    this.interests = '',
  });

  UserProfile copyWith({
    String? name,
    UserMode? mode,
    String? avatarId,
    String? emergencyContact,
    String? familyMembers,
    String? healthNotes,
    String? interests,
  }) => UserProfile(
    name: name ?? this.name,
    mode: mode ?? this.mode,
    avatarId: avatarId ?? this.avatarId,
    emergencyContact: emergencyContact ?? this.emergencyContact,
    familyMembers: familyMembers ?? this.familyMembers,
    healthNotes: healthNotes ?? this.healthNotes,
    interests: interests ?? this.interests,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'mode': mode.name,
    'avatarId': avatarId,
    'emergencyContact': emergencyContact,
    'familyMembers': familyMembers,
    'healthNotes': healthNotes,
    'interests': interests,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    name: map['name'] as String? ?? '朋友',
    mode: UserMode.values.byName(map['mode'] as String? ?? 'elderly'),
    avatarId: map['avatarId'] as String?,
    emergencyContact: map['emergencyContact'] as String?,
    familyMembers: map['familyMembers'] as String? ?? '',
    healthNotes: map['healthNotes'] as String? ?? '',
    interests: map['interests'] as String? ?? '',
  );
}
