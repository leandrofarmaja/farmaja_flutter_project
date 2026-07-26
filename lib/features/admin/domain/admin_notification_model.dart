class AdminNotificationModel {
  final String id;
  final String type; // 'low_rating_alert', 'payment_pending'
  final String title;
  final String message;
  final String targetId; // reviewId or paymentId
  final bool isRead;
  final DateTime createdAt;

  AdminNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    return AdminNotificationModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'low_rating_alert',
      title: json['title'] ?? 'Alerta de Avaliação Baixa',
      message: json['message'] ?? '',
      targetId: json['target_id'] ?? json['targetId'] ?? '',
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'target_id': targetId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
