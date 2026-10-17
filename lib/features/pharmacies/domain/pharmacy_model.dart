
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

  // Dados de subscrição: só devem refletir informação confirmada.
  final String subscriptionStatus;
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
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.subscriptionStatus = 'unknown',
    DateTime? trialEndsAt,
    DateTime? paymentDueDate,
    this.monthlyFee = 15000.0,
    this.lastPaymentAt,
  })  : trialEndsAt =
            trialEndsAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        paymentDueDate =
            paymentDueDate ?? DateTime.fromMillisecondsSinceEpoch(0);

  bool get isTrialActive =>
      subscriptionStatus == 'trial' &&
      DateTime.now().isBefore(trialEndsAt);

  bool get isSubscriptionActive =>
      (subscriptionStatus == 'active' &&
          DateTime.now().isBefore(paymentDueDate)) ||
      isTrialActive;

  bool get isBlockedOrExpired =>
      subscriptionStatus == 'blocked' ||
      subscriptionStatus == 'expired' ||
      (subscriptionStatus == 'trial' && !isTrialActive) ||
      (subscriptionStatus == 'active' &&
          !DateTime.now().isBefore(paymentDueDate));

  int get daysLeftInTrial {
    if (subscriptionStatus != 'trial' || !isTrialActive) {
      return 0;
    }

    return trialEndsAt.difference(DateTime.now()).inDays;
  }

  int get daysUntilPaymentDue {
    if (subscriptionStatus != 'active' ||
        !DateTime.now().isBefore(paymentDueDate)) {
      return 0;
    }

    return paymentDueDate.difference(DateTime.now()).inDays;
  }

  double calculateDistanceFrom(double userLat, double userLng) {
    if (latitude == 0.0 && longitude == 0.0) {
      return double.infinity;
    }

    const p = 0.017453292519943295;

    final a = 0.5 -
        cos((latitude - userLat) * p) / 2 +
        cos(userLat * p) *
            cos(latitude * p) *
            (1 - cos((longitude - userLng) * p)) /
            2;

    return 12742 * asin(sqrt(a.clamp(0.0, 1.0)));
  }

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return PharmacyModel(
      id: (json['id'] ?? '').toString(),
      name: (json['nome'] ?? json['name'] ?? '').toString(),
      province: (json['province'] ?? '').toString(),
      district: (json['municipality'] ?? json['district'] ?? '').toString(),
      address: (json['endereco'] ?? json['address'] ?? '').toString(),
      phone: (json['telefone'] ?? json['phone'] ?? '').toString(),
      openingHours:
          (json['opening_hours'] ?? json['openingHours'] ?? '').toString(),
      isOpen24h: json['is_open_24h'] == true ||
          json['isOpen24h'] == true,
      hasDelivery: json['has_delivery'] == true ||
          json['hasDelivery'] == true,
      rating: toDouble(json['avaliacao'] ?? json['rating']),
      logoUrl: (json['logo_url'] ?? json['logoUrl'] ?? '').toString(),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      subscriptionStatus: (json['subscription_status'] ??
              json['subscriptionStatus'] ??
              'unknown')
          .toString(),
      trialEndsAt: parseDate(json['trial_ends_at'] ?? json['trialEndsAt']),
      paymentDueDate:
          parseDate(json['payment_due_date'] ?? json['paymentDueDate']),
      monthlyFee: toDouble(json['monthly_fee'] ?? json['monthlyFee'] ?? 15000),
      lastPaymentAt:
          parseDate(json['last_payment_at'] ?? json['lastPaymentAt']),
    );
  }
}
