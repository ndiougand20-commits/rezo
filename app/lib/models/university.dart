import 'user.dart';
import 'formation.dart';

class University {
  final int id;
  final int userId;
  final User? user; // Optional for full user data
  final List<Formation> formations;

  University({
    required this.id,
    required this.userId,
    this.user,
    this.formations = const [],
  });

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      id: json['id'],
      userId: json['user_id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      formations: (json['formations'] as List<dynamic>?)
              ?.map((e) => Formation.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user': user?.toJson(),
      'formations': formations.map((e) => e.toJson()).toList(),
    };
  }
}
