// lib/core/models/avatar_model.dart

class AvatarModel {
  final String id;
  final String name;
  final String? photoPath;      // 本地照片路径
  final String? voiceId;        // 阿里云克隆声音ID
  final String? soulAvatarId;   // 硅基/Soul虚拟人ID
  final String? avatarVideoUrl; // 虚拟人视频流URL
  final String personality;     // 性格描述
  final DateTime createdAt;

  AvatarModel({
    required this.id,
    required this.name,
    this.photoPath,
    this.voiceId,
    this.soulAvatarId,
    this.avatarVideoUrl,
    this.personality = '温柔体贴，善解人意，总是耐心倾听',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'photoPath': photoPath,
    'voiceId': voiceId,
    'soulAvatarId': soulAvatarId,
    'avatarVideoUrl': avatarVideoUrl,
    'personality': personality,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AvatarModel.fromMap(Map<String, dynamic> map) => AvatarModel(
    id: map['id'] as String,
    name: map['name'] as String,
    photoPath: map['photoPath'] as String?,
    voiceId: map['voiceId'] as String?,
    soulAvatarId: map['soulAvatarId'] as String?,
    avatarVideoUrl: map['avatarVideoUrl'] as String?,
    personality: map['personality'] as String? ?? '温柔体贴',
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}
