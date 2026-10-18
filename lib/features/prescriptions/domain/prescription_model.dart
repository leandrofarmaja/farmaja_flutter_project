
class PrescriptionModel {
  final String id;
  final String userId;
  final String userName;
  final String medicineName;
  final String imageUrl;
  final String status;
  final String? notes;
  final String createdAt;

  PrescriptionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.medicineName,
    required this.imageUrl,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      userName: (json['user_name'] ?? json['userName'] ?? '').toString(),
      medicineName:
          (json['medicine_name'] ?? json['medicineName'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      notes: json['notes']?.toString(),
      createdAt:
          (json['created_at'] ?? json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'medicine_name': medicineName,
      'image_url': imageUrl,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}
