class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? bookingId;
  final bool read;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.bookingId,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      bookingId: json['bookingId'] as String?,
      read: json['read'] as bool,
      createdAt: json['createdAt'] as String,
    );
  }
}
