class User {
  final int id;

  String nickname;
  String username;

  String? description;

  String? fingerprint;
  String x25519PublicKey;

  String? avatarId;

  User({
    required this.id,
    required this.nickname,
    required this.username,
    required this.x25519PublicKey,
    this.fingerprint,
    this.description,
    this.avatarId,
  });

  String getDesc() =>
      (description?.isNotEmpty == true) ? description! : "No description";

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nickname: json['nickname'],
      username: json['username'],
      x25519PublicKey: json['x25519PublicKey'],
      description: json['description'],
      avatarId: json['avatarId'],
    );
  }

  User copyWith({
    int? id,
    String? nickname,
    String? username,
    String? description,
    String? fingerprint,
    String? x25519PublicKey,
    String? avatarId,
  }) {
    User user = User(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      username: username ?? this.username,
      description: description ?? this.description,
      fingerprint: fingerprint ?? this.fingerprint,
      x25519PublicKey: x25519PublicKey ?? this.x25519PublicKey,
      avatarId: avatarId ?? this.avatarId,
    );
    return user;
  }
}
