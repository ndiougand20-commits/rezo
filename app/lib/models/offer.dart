class Offer {
  final int id;
  final String title;
  final String description;
  final int companyId;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.companyId,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      companyId: json['company_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'company_id': companyId,
    };
  }
}
