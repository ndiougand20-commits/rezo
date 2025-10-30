class Formation {
  final int id;
  final String title;
  final String description;
  final int universityId;

  Formation({
    required this.id,
    required this.title,
    required this.description,
    required this.universityId,
  });

  factory Formation.fromJson(Map<String, dynamic> json) {
    return Formation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      universityId: json['university_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'university_id': universityId,
    };
  }
}
