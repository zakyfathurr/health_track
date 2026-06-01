class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] as String,
    name: map['name'] as String,
    email: map['email'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? createdAt,
  }) => UserModel(
    uid: uid ?? this.uid,
    name: name ?? this.name,
    email: email ?? this.email,
    createdAt: createdAt ?? this.createdAt,
  );
}
