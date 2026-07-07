import 'package:mongo_dart/mongo_dart.dart';

class User {
  final ObjectId? id;
  final String username;
  final String password; // In production, this should be a salted hash
  final String role;     // 'Admin' or 'Cashier'

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'username': username,
      'password': password,
      'role': role,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'] as ObjectId?,
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
      role: map['role'] as String? ?? 'Cashier',
    );
  }
}
