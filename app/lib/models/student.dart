import 'user.dart';

class Student {
  final int id;
  final int userId;
  final User? user; // Optional for full user data

  Student({
    required this.id,
    required this.userId,
    this.user,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      userId: json['user_id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user': user?.toJson(),
    };
  }
}
