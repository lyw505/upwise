class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActiveDate: json['last_active_date'] != null 
          ? DateTime.parse(json['last_active_date'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_active_date': lastActiveDate?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.avatarUrl == avatarUrl &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.lastActiveDate == lastActiveDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      avatarUrl,
      createdAt,
      updatedAt,
      currentStreak,
      longestStreak,
      lastActiveDate,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, currentStreak: $currentStreak)';
  }
}
