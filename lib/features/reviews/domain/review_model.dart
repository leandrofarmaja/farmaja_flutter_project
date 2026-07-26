class ReviewModel {
  final String id;
  final String reservationId;
  final String userId;
  final String userName;
  final String userPhone;
  final String pharmacyId;
  final String pharmacyName;
  final double pharmacyRating; // 1.0 to 5.0
  final String? pharmacyComment;
  final double appRating; // 1.0 to 5.0
  final String? appComment;
  final DateTime createdAt;
  final String status; // 'approved', 'pending_moderation', 'rejected'
  final bool isLowRating; // pharmacyRating <= 2.0 || appRating <= 2.0
  final String? moderationNote;
  final DateTime? moderatedAt;

  ReviewModel({
    required this.id,
    required this.reservationId,
    required this.userId,
    required this.userName,
    this.userPhone = '',
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyRating,
    this.pharmacyComment,
    required this.appRating,
    this.appComment,
    required this.createdAt,
    this.status = 'approved',
    this.isLowRating = false,
    this.moderationNote,
    this.moderatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final pharmRating = (json['pharmacy_rating'] ?? json['pharmacyRating'] ?? 5.0).toDouble();
    final appRatingVal = (json['app_rating'] ?? json['appRating'] ?? 5.0).toDouble();
    final lowRating = pharmRating <= 2.0 || appRatingVal <= 2.0;

    return ReviewModel(
      id: json['id'] ?? '',
      reservationId: json['reservation_id'] ?? json['reservationId'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'Utente FarmaJá',
      userPhone: json['user_phone'] ?? json['userPhone'] ?? '',
      pharmacyId: json['pharmacy_id'] ?? json['pharmacyId'] ?? 'pharm-1',
      pharmacyName: json['pharmacy_name'] ?? json['pharmacyName'] ?? 'Farmácia',
      pharmacyRating: pharmRating,
      pharmacyComment: json['pharmacy_comment'] ?? json['pharmacyComment'],
      appRating: appRatingVal,
      appComment: json['app_comment'] ?? json['appComment'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? (lowRating ? 'pending_moderation' : 'approved'),
      isLowRating: json['is_low_rating'] ?? lowRating,
      moderationNote: json['moderation_note'] ?? json['moderationNote'],
      moderatedAt: json['moderated_at'] != null
          ? DateTime.tryParse(json['moderated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacyName,
      'pharmacy_rating': pharmacyRating,
      'pharmacy_comment': pharmacyComment,
      'app_rating': appRating,
      'app_comment': appComment,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'is_low_rating': isLowRating,
      'moderation_note': moderationNote,
      'moderated_at': moderatedAt?.toIso8601String(),
    };
  }

  ReviewModel copyWith({
    String? status,
    String? moderationNote,
    DateTime? moderatedAt,
  }) {
    return ReviewModel(
      id: id,
      reservationId: reservationId,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      pharmacyRating: pharmacyRating,
      pharmacyComment: pharmacyComment,
      appRating: appRating,
      appComment: appComment,
      createdAt: createdAt,
      status: status ?? this.status,
      isLowRating: isLowRating,
      moderationNote: moderationNote ?? this.moderationNote,
      moderatedAt: moderatedAt ?? this.moderatedAt,
    );
  }
}
