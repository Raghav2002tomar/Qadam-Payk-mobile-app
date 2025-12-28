class AppNotification {
  final int id;
  final String title;
  final String description;
  final int type;
  final String createdAt;
  final String? image;

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    this.image,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['notification_type'],
      createdAt: json['created_at'] ?? '',
      image: json['image'], // future-ready
    );
  }
}
