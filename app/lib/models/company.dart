import 'user.dart';
import 'offer.dart';

class Company {
  final int id;
  final int userId;
  final User? user; // Optional for full user data
  final List<Offer> offers;

  Company({
    required this.id,
    required this.userId,
    this.user,
    this.offers = const [],
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      userId: json['user_id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      offers: (json['offers'] as List<dynamic>?)
              ?.map((e) => Offer.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user': user?.toJson(),
      'offers': offers.map((e) => e.toJson()).toList(),
    };
  }
}
