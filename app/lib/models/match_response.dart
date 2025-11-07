class MatchResponse {
  final bool isNewConversation;
  final int? conversationId;

  MatchResponse({required this.isNewConversation, this.conversationId});

  factory MatchResponse.fromJson(Map<String, dynamic> json) {
    return MatchResponse(
      isNewConversation: json['is_new_conversation'],
      conversationId: json['conversation_id'],
    );
  }
}