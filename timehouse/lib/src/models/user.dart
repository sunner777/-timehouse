class User {
  final String id;
  final String phone;
  String password;
  String nickname;
  String avatar;
  final DateTime createdAt;
  DateTime updatedAt;

  User({
    required this.id,
    required this.phone,
    required this.password,
    required this.nickname,
    required this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      password: json['password'],
      nickname: json['nickname'],
      avatar: json['avatar'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'password': password,
      'nickname': nickname,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
