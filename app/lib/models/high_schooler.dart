import 'user.dart';

class HighSchooler {
  final int id;
  final int userId;
  final User? user; // Optional for full user data

  HighSchooler({
    required this.id,
    required this.userId,
    this.user,
  });

  factory HighSchooler.fromJson(Map<String, dynamic> json) {
    return HighSchooler(
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
