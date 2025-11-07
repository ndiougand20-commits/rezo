import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/token.dart';
import '../models/student.dart';
import '../models/high_schooler.dart';
import '../models/company.dart';
import '../models/university.dart';
import '../models/offer.dart';
import '../models/formation.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/match_response.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // For Android emulator

  // Auth
  Future<Token> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );
    if (response.statusCode == 200) {
      return Token.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Users
  Future<User> createUser(User user, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': user.email,
        'user_type': user.userType.toString().split('.').last.replaceAll('School', '_school'),
        'first_name': user.firstName,
        'last_name': user.lastName,
        'password': password,
        'password_confirm': password,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  Future<User> getUser(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<User> updateUser({
    required String token,
    String? firstName,
    String? lastName,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }
  // Students
  Future<Student> createStudent(Student student) async {
    final response = await http.post(
      Uri.parse('$baseUrl/students/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': student.userId}),
    );
    if (response.statusCode == 200) {
      return Student.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create student: ${response.body}');
    }
  }

  Future<Student> getStudent(int studentId) async {
    final response = await http.get(Uri.parse('$baseUrl/students/$studentId'));
    if (response.statusCode == 200) {
      return Student.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load student');
    }
  }

  // High Schoolers
  Future<HighSchooler> createHighSchooler(HighSchooler highSchooler) async {
    final response = await http.post(
      Uri.parse('$baseUrl/high_schoolers/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': highSchooler.userId}),
    );
    if (response.statusCode == 200) {
      return HighSchooler.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create high schooler: ${response.body}');
    }
  }

  Future<HighSchooler> getHighSchooler(int highSchoolerId) async {
    final response = await http.get(Uri.parse('$baseUrl/high_schoolers/$highSchoolerId'));
    if (response.statusCode == 200) {
      return HighSchooler.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load high schooler');
    }
  }

  // Companies
  Future<Company> createCompany(Company company) async {
    final response = await http.post(
      Uri.parse('$baseUrl/companies/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': company.userId}),
    );
    if (response.statusCode == 200) {
      return Company.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create company: ${response.body}');
    }
  }

  Future<Company> getCompany(int companyId) async {
    final response = await http.get(Uri.parse('$baseUrl/companies/$companyId'));
    if (response.statusCode == 200) {
      return Company.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load company');
    }
  }

  // Universities
  Future<University> createUniversity(University university) async {
    final response = await http.post(
      Uri.parse('$baseUrl/universities/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': university.userId}),
    );
    if (response.statusCode == 200) {
      return University.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create university: ${response.body}');
    }
  }

  Future<University> getUniversity(int universityId) async {
    final response = await http.get(Uri.parse('$baseUrl/universities/$universityId'));
    if (response.statusCode == 200) {
      return University.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load university');
    }
  }

  // Offers
  Future<Offer> createOffer(int companyId, Offer offer) async {
    final response = await http.post(
      Uri.parse('$baseUrl/companies/$companyId/offers/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': offer.title,
        'description': offer.description,
      }),
    );
    if (response.statusCode == 200) {
      return Offer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create offer: ${response.body}');
    }
  }

  Future<List<Offer>> getOffers({int skip = 0, int limit = 100}) async {
    final response = await http.get(Uri.parse('$baseUrl/offers/?skip=$skip&limit=$limit'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Offer.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load offers');
    }
  }

  // Formations
  Future<Formation> createFormation(int universityId, Formation formation) async {
    final response = await http.post(
      Uri.parse('$baseUrl/universities/$universityId/formations/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': formation.title,
        'description': formation.description,
      }),
    );
    if (response.statusCode == 200) {
      return Formation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create formation: ${response.body}');
    }
  }

  Future<List<Formation>> getFormations({int skip = 0, int limit = 100}) async {
    final response = await http.get(Uri.parse('$baseUrl/formations/?skip=$skip&limit=$limit'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Formation.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load formations');
    }
  }

  // Get profiles by user ID
  Future<Student> getStudentByUserId(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/students/user/$userId'));
    if (response.statusCode == 200) {
      return Student.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load student profile');
    }
  }

  Future<HighSchooler> getHighSchoolerByUserId(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/high_schoolers/user/$userId'));
    if (response.statusCode == 200) {
      return HighSchooler.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load high schooler profile');
    }
  }

  Future<Company> getCompanyByUserId(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/companies/user/$userId'));
    if (response.statusCode == 200) {
      return Company.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load company profile');
    }
  }

  Future<University> getUniversityByUserId(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/universities/user/$userId'));
    if (response.statusCode == 200) {
      return University.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load university profile');
    }
  }

  // Conversations
  Future<Conversation> createConversation(int participant1Id, int participant2Id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'participant1_id': participant1Id,
        'participant2_id': participant2Id,
      }),
    );
    if (response.statusCode == 200) {
      return Conversation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create conversation: ${response.body}');
    }
  }

  Future<List<Conversation>> getConversationsForUser(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/conversations/'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Conversation.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load conversations');
    }
  }

  // Messages
  Future<Message> createMessage(String content, int senderId, int conversationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'content': content,
        'sender_id': senderId,
        'conversation_id': conversationId,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
    if (response.statusCode == 200) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<List<Message>> getMessagesForConversation(int conversationId) async {
    final response = await http.get(Uri.parse('$baseUrl/conversations/$conversationId/messages/'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Message.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  Future<MatchResponse> createMatch({
    required int userId,
    int? offerId,
    int? formationId,
    required String token,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = json.encode({
      'user_id': userId,
      'offer_id': offerId,
      'formation_id': formationId,
    });

    final response = await http.post(Uri.parse('$baseUrl/api/matches/'), headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to create match: ${response.body}');
    } else {
      return MatchResponse.fromJson(json.decode(response.body));
    }
  }
}
