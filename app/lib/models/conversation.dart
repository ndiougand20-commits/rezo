import 'message.dart';

class Conversation {
  final int id;
  final int participant1Id;
  final int participant2Id;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.messages = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      participant1Id: json['participant1_id'],
      participant2Id: json['participant2_id'],
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => Message.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant1_id': participant1Id,
      'participant2_id': participant2Id,
      'messages': messages.map((e) => e.toJson()).toList(),
    };
  }
}
