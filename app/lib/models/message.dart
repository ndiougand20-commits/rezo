class Message {
  final int id;
  final String content;
  final int senderId;
  final int conversationId;
  final String timestamp;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.conversationId,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      senderId: json['sender_id'],
      conversationId: json['conversation_id'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_id': senderId,
      'conversation_id': conversationId,
      'timestamp': timestamp,
    };
  }
}
