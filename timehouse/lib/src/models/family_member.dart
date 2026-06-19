class FamilyMember {
  final String id;
  final String userId;
  final String nickname;
  final String? avatar;
  final String role;
  final DateTime joinedAt;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.nickname,
    this.avatar,
    required this.role,
    required this.joinedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      nickname: json['nickname'],
      avatar: json['avatar'],
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'nickname': nickname,
      'avatar': avatar,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}
