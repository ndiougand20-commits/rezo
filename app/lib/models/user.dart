enum UserType { student, highSchool, company, university }

class User {
  final int id;
  final String email;
  final UserType userType;
  final String firstName;
  final String lastName;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.userType,
    required this.firstName,
    required this.lastName,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Convert backend format (snake_case) to enum format (camelCase)
    String backendUserType = json['user_type'];
    String enumUserType = backendUserType.replaceAll('_school', 'School');

    return User(
      id: json['id'],
      email: json['email'],
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == enumUserType,
      ),
      firstName: json['first_name'],
      lastName: json['last_name'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_type': userType.toString().split('.').last.replaceAll('School', '_school'),
      'first_name': firstName,
      'last_name': lastName,
      'is_active': isActive,
    };
  }
}
