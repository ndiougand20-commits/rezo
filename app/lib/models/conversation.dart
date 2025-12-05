import 'message.dart';
import 'user.dart';

class Conversation {
  final int id;
  final User otherParticipant;
  final Message? lastMessage;

  Conversation({
    required this.id,
    required this.otherParticipant,
    this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      otherParticipant: User.fromJson(json['other_participant']),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
    );
  }

  // Les participants ID sont toujours utiles pour la création
  // mais pas pour l'affichage de la liste.
  // On garde toJson pour la compatibilité si besoin.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // Cette méthode n'est plus vraiment utilisée pour l'affichage,
      // mais on la garde pour la structure.
    };
  }
}
