class Family {
  final String id;
  final String name;
  final String role;
  final int memberCount;
  final int photoCount;
  final DateTime createdAt;

  Family({
    required this.id,
    required this.name,
    required this.role,
    required this.memberCount,
    required this.photoCount,
    required this.createdAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'].toString(),
      name: json['name'],
      role: json['role'] ?? 'member',
      memberCount: json['memberCount'] ?? 0,
      photoCount: json['photoCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'memberCount': memberCount,
      'photoCount': photoCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
