class PrescriptionModel {
  final String id;
  final String userId;
  final String userName;
  final String medicineName;
  final String imageUrl;
  final String status; // 'pending', 'verified', 'rejected'
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
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'Paciente FarmaJá',
      medicineName: json['medicine_name'] ?? json['medicineName'] ?? 'Medicamento com Receita',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      createdAt: json['created_at'] ?? json['createdAt'] ?? '22 Julho 2026',
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
