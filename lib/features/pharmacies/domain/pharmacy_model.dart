import 'dart:math';

class PharmacyModel {
  final String id;
  final String name;
  final String province;
  final String district;
  final String address;
  final String phone;
  final String openingHours;
  final bool isOpen24h;
  final bool hasDelivery;
  final double rating;
  final String logoUrl;
  final double latitude;
  final double longitude;

  // Subscription Fields
  final String subscriptionStatus; // 'trial', 'active', 'expired', 'blocked'
  final DateTime trialEndsAt;
  final DateTime paymentDueDate;
  final double monthlyFee;
  final DateTime? lastPaymentAt;

  PharmacyModel({
    required this.id,
    required this.name,
    required this.province,
    required this.district,
    required this.address,
    required this.phone,
    required this.openingHours,
    required this.isOpen24h,
    required this.hasDelivery,
    required this.rating,
    required this.logoUrl,
    this.latitude = -8.8383,
    this.longitude = 13.2344,
    this.subscriptionStatus = 'trial',
    DateTime? trialEndsAt,
    DateTime? paymentDueDate,
    this.monthlyFee = 15000.0,
    this.lastPaymentAt,
  })  : trialEndsAt = trialEndsAt ?? DateTime.now().add(const Duration(days: 90)),
        paymentDueDate = paymentDueDate ?? DateTime.now().add(const Duration(days: 90));

  bool get isTrialActive =>
      subscriptionStatus == 'trial' && DateTime.now().isBefore(trialEndsAt);

  bool get isSubscriptionActive =>
      (subscriptionStatus == 'active' && DateTime.now().isBefore(paymentDueDate)) || isTrialActive;

  bool get isBlockedOrExpired =>
      subscriptionStatus == 'blocked' ||
      subscriptionStatus == 'expired' ||
      (!isTrialActive && subscriptionStatus == 'trial') ||
      (subscriptionStatus == 'active' && DateTime.now().isAfter(paymentDueDate));

  int get daysLeftInTrial {
    if (subscriptionStatus != 'trial') return 0;
    final diff = trialEndsAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  int get daysUntilPaymentDue {
    final diff = paymentDueDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  double calculateDistanceFrom(double userLat, double userLng) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((latitude - userLat) * p) / 2 +
        cos(userLat * p) * cos(latitude * p) *
            (1 - cos((longitude - userLng) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      province: json['province'] ?? 'Luanda',
      district: json['municipality'] ?? json['district'] ?? 'Talatona',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      openingHours: json['opening_hours'] ?? json['openingHours'] ?? '08:00 - 20:00',
      isOpen24h: json['is_open_24h'] ?? json['isOpen24h'] ?? false,
      hasDelivery: json['has_delivery'] ?? json['hasDelivery'] ?? true,
      rating: (json['rating'] ?? 4.8).toDouble(),
      logoUrl: json['logo_url'] ?? json['logoUrl'] ?? '',
      latitude: (json['latitude'] ?? -8.8383).toDouble(),
      longitude: (json['longitude'] ?? 13.2344).toDouble(),
      subscriptionStatus: json['subscription_status'] ?? json['subscriptionStatus'] ?? 'trial',
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.tryParse(json['trial_ends_at']) ?? DateTime.now().add(const Duration(days: 90))
          : DateTime.now().add(const Duration(days: 90)),
      paymentDueDate: json['payment_due_date'] != null
          ? DateTime.tryParse(json['payment_due_date']) ?? DateTime.now().add(const Duration(days: 90))
          : DateTime.now().add(const Duration(days: 90)),
      monthlyFee: (json['monthly_fee'] ?? json['monthlyFee'] ?? 15000.0).toDouble(),
      lastPaymentAt: json['last_payment_at'] != null ? DateTime.tryParse(json['last_payment_at']) : null,
    );
  }
}
