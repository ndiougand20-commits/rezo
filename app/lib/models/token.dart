import 'user.dart';

class Token {
  final String accessToken;
  final String tokenType;
  final User user;

  Token({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}
