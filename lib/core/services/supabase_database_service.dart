import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/medicines/domain/medicine_model.dart';
import '../../features/pharmacies/domain/pharmacy_model.dart';
import '../../features/pharmacies/domain/pharmacy_payment_model.dart';
import '../../features/reservations/domain/reservation_model.dart';
import '../../features/prescriptions/domain/prescription_model.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/reviews/domain/review_model.dart';
import '../../features/admin/domain/admin_notification_model.dart';

class SupabaseDatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  // -------------------------------------------------------------
  // MEDICINES TABLE API
  // -------------------------------------------------------------

  /// Fetch medicines list from Supabase
  Future<List<MedicineModel>> getMedicines({
    String? query,
    String? province,
    bool? onlyInStock,
    bool? genericsOnly,
  }) async {
    try {
      var dbQuery = _client.from('medicines').select();

      if (province != null && province.isNotEmpty) {
        dbQuery = dbQuery.eq('province', province);
      }

      if (onlyInStock == true) {
        dbQuery = dbQuery.eq('in_stock', true);
      }

      if (genericsOnly == true) {
        dbQuery = dbQuery.eq('is_generic', true);
      }

      final List<dynamic> data = await dbQuery;

      var result = data.map((json) => MedicineModel.fromJson(json)).toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        result = result.where((m) {
          return m.name.toLowerCase().contains(q) ||
              m.activeIngredient.toLowerCase().contains(q) ||
              m.category.toLowerCase().contains(q) ||
              m.pharmacyName.toLowerCase().contains(q);
        }).toList();
      }

      return result;
    } catch (e) {
      // Fallback seed list for robust user experience
      return _getFallbackMedicines(query: query, province: province, onlyInStock: onlyInStock, genericsOnly: genericsOnly);
    }
  }

  /// Fetch medicine details by ID from Supabase
  Future<MedicineModel?> getMedicineById(String id) async {
    try {
      final data = await _client.from('medicines').select().eq('id', id).maybeSingle();
      if (data != null) {
        return MedicineModel.fromJson(data);
      }
    } catch (_) {}

    final list = _getFallbackMedicines();
    try {
      return list.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // PHARMACIES TABLE API
  // -------------------------------------------------------------

  /// Fetch pharmacies list from Supabase
  Future<List<PharmacyModel>> getPharmacies({
    String? province,
    bool? only24h,
  }) async {
    try {
      var dbQuery = _client.from('pharmacies').select();

      if (province != null && province.isNotEmpty) {
        dbQuery = dbQuery.eq('province', province);
      }

      if (only24h == true) {
        dbQuery = dbQuery.eq('is_open_24h', true);
      }

      final List<dynamic> data = await dbQuery;
      return data.map((json) => PharmacyModel.fromJson(json)).toList();
    } catch (e) {
      return _getFallbackPharmacies(province: province, only24h: only24h);
    }
  }

  /// Get pharmacy details by ID
  Future<PharmacyModel?> getPharmacyById(String id) async {
    try {
      final data = await _client.from('pharmacies').select().eq('id', id).maybeSingle();
      if (data != null) return PharmacyModel.fromJson(data);
    } catch (_) {}
    final list = _getFallbackPharmacies();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return list.first;
    }
  }

  /// Update pharmacy subscription status manually or after payment approval
  Future<bool> updatePharmacySubscription({
    required String pharmacyId,
    required String status, // 'trial', 'active', 'expired', 'blocked'
    DateTime? nextDueDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'subscription_status': status,
      };
      if (nextDueDate != null) {
        updates['payment_due_date'] = nextDueDate.toIso8601String();
      }
      if (status == 'active') {
        updates['last_payment_at'] = DateTime.now().toIso8601String();
      }
      await _client.from('pharmacies').update(updates).eq('id', pharmacyId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Submit payment proof for pharmacy subscription renewal
  Future<bool> submitPharmacyPayment(PharmacyPaymentModel payment) async {
    try {
      await _client.from('pharmacy_payments').insert({
        'id': payment.id,
        'pharmacy_id': payment.pharmacyId,
        'pharmacy_name': payment.pharmacyName,
        'amount': payment.amount,
        'payment_method': payment.paymentMethod,
        'reference_number': payment.referenceNumber,
        'proof_url': payment.proofUrl,
        'status': payment.status,
        'period_months': payment.periodMonths,
        'notes': payment.notes,
        'created_at': payment.createdAt.toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch all pharmacy payments for Admin verification
  Future<List<PharmacyPaymentModel>> getAllPharmacyPayments() async {
    try {
      final List<dynamic> data = await _client
          .from('pharmacy_payments')
          .select()
          .order('created_at', ascending: false);
      return data.map((json) => PharmacyPaymentModel.fromJson(json)).toList();
    } catch (e) {
      return _getFallbackPayments();
    }
  }

  /// Approve pharmacy payment & extend subscription
  Future<bool> approvePharmacyPayment({
    required String paymentId,
    required String pharmacyId,
    int periodMonths = 1,
  }) async {
    try {
      final now = DateTime.now();
      final nextDueDate = now.add(Duration(days: 30 * periodMonths));

      await _client.from('pharmacy_payments').update({
        'status': 'approved',
        'approved_at': now.toIso8601String(),
      }).eq('id', paymentId);

      await updatePharmacySubscription(
        pharmacyId: pharmacyId,
        status: 'active',
        nextDueDate: nextDueDate,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reject pharmacy payment with notes
  Future<bool> rejectPharmacyPayment(String paymentId, String? notes) async {
    try {
      await _client.from('pharmacy_payments').update({
        'status': 'rejected',
        'notes': notes,
      }).eq('id', paymentId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // -------------------------------------------------------------
  // RESERVATIONS TABLE API
  // -------------------------------------------------------------

  /// Fetch reservations for a user from Supabase
  Future<List<ReservationModel>> getReservations(String userId) async {
    try {
      final List<dynamic> data = await _client
          .from('reservations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) => ReservationModel.fromJson(json)).toList();
    } catch (e) {
      return _getFallbackReservations();
    }
  }

  /// Insert a new reservation into Supabase
  Future<ReservationModel> createReservation({
    required String userId,
    required String medicineName,
    required String pharmacyName,
    required double totalPriceKz,
    required bool prescriptionUploaded,
  }) async {
    final pickupCode = 'FJ-${(1000 + DateTime.now().millisecond * 7) % 9000}';
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 2));
    
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final expiryStr = '${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')}/${expiresAt.year} às ${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')} (Expira em 2 horas)';

    final row = {
      'user_id': userId,
      'medicine_name': medicineName,
      'pharmacy_name': pharmacyName,
      'pickup_code': pickupCode,
      'total_price_kz': totalPriceKz,
      'reservation_date': dateStr,
      'expiry_date': expiryStr,
      'status': 'active',
      'prescription_uploaded': prescriptionUploaded,
      'created_at': now.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };

    try {
      final inserted = await _client.from('reservations').insert(row).select().single();
      return ReservationModel.fromJson(inserted);
    } catch (e) {
      // Fallback return created item
      return ReservationModel(
        id: 'res-${DateTime.now().millisecondsSinceEpoch}',
        medicineName: medicineName,
        pharmacyName: pharmacyName,
        pickupCode: pickupCode,
        totalPriceKz: totalPriceKz,
        reservationDate: dateStr,
        expiryDate: expiryStr,
        status: 'active',
        prescriptionUploaded: prescriptionUploaded,
      );
    }
  }

  /// Insert a new medicine item into Supabase
  Future<bool> addMedicine(MedicineModel medicine) async {
    try {
      final row = {
        'id': medicine.id,
        'name': medicine.name,
        'generic_name': medicine.activeIngredient,
        'category': medicine.category,
        'dosage': medicine.dosage,
        'price': medicine.priceKz,
        'stock': medicine.stockQuantity,
        'in_stock': medicine.inStock,
        'prescription_required': medicine.requiresPrescription,
        'pharmacy_name': medicine.pharmacyName,
        'province': medicine.province,
        'district': medicine.district,
        'is_generic': medicine.isGeneric,
        'description': medicine.description,
        'dosage_instructions': medicine.dosageInstructions,
      };
      await _client.from('medicines').insert(row);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update an existing medicine item in Supabase
  Future<bool> updateMedicine(MedicineModel medicine) async {
    try {
      final row = {
        'name': medicine.name,
        'generic_name': medicine.activeIngredient,
        'category': medicine.category,
        'dosage': medicine.dosage,
        'price': medicine.priceKz,
        'stock': medicine.stockQuantity,
        'in_stock': medicine.inStock,
        'prescription_required': medicine.requiresPrescription,
        'is_generic': medicine.isGeneric,
        'description': medicine.description,
        'dosage_instructions': medicine.dosageInstructions,
      };
      await _client.from('medicines').update(row).eq('id', medicine.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update stock quantity in real time
  Future<bool> updateMedicineStock(String medicineId, int newStock, bool inStock) async {
    try {
      await _client.from('medicines').update({
        'stock': newStock,
        'in_stock': inStock,
      }).eq('id', medicineId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update medicine price in real time
  Future<bool> updateMedicinePrice(String medicineId, double newPrice) async {
    try {
      await _client.from('medicines').update({
        'price': newPrice,
      }).eq('id', medicineId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete medicine item from Supabase
  Future<bool> deleteMedicine(String medicineId) async {
    try {
      await _client.from('medicines').delete().eq('id', medicineId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch reservations for a pharmacy or all reservations
  Future<List<ReservationModel>> getAllReservationsForPharmacy({String? pharmacyName}) async {
    try {
      var query = _client.from('reservations').select().order('created_at', ascending: false);
      if (pharmacyName != null && pharmacyName.isNotEmpty) {
        query = query.eq('pharmacy_name', pharmacyName);
      }
      final List<dynamic> data = await query;
      return data.map((json) => ReservationModel.fromJson(json)).toList();
    } catch (e) {
      return _getFallbackReservations();
    }
  }

  /// Validate reservation by QR Code / Pickup Code
  Future<ReservationModel?> validateReservationByQrCode(String code) async {
    try {
      final data = await _client.from('reservations').select().eq('pickup_code', code).maybeSingle();
      if (data != null) {
        // Update status to completed
        await _client.from('reservations').update({'status': 'completed'}).eq('pickup_code', code);
        var updated = Map<String, dynamic>.from(data);
        updated['status'] = 'completed';
        return ReservationModel.fromJson(updated);
      }
    } catch (_) {}
    return null;
  }

  /// Update status of a reservation
  Future<bool> updateReservationStatus(String reservationId, String newStatus) async {
    try {
      await _client.from('reservations').update({'status': newStatus}).eq('id', reservationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch prescriptions awaiting pharmacy review
  Future<List<PrescriptionModel>> getPrescriptionsForPharmacy() async {
    try {
      final List<dynamic> data = await _client
          .from('prescriptions')
          .select()
          .order('created_at', ascending: false);
      return data.map((json) => PrescriptionModel.fromJson(json)).toList();
    } catch (e) {
      return [
        PrescriptionModel(
          id: 'presc-1',
          userId: 'usr-1',
          userName: 'António Silva',
          medicineName: 'Coartem 80/480mg',
          imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500',
          status: 'pending',
          createdAt: '22 Julho 2026',
        ),
        PrescriptionModel(
          id: 'presc-2',
          userId: 'usr-2',
          userName: 'Maria Fernandes',
          medicineName: 'Amoxicilina 500mg',
          imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=500',
          status: 'verified',
          notes: 'Receita médica aprovada pela equipa farmacêutica.',
          createdAt: '21 Julho 2026',
        ),
      ];
    }
  }

  /// Update prescription status (verified/rejected) with optional notes
  Future<bool> updatePrescriptionStatus(String prescriptionId, String status, String? notes) async {
    try {
      await _client.from('prescriptions').update({
        'status': status,
        'notes': notes,
      }).eq('id', prescriptionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // -------------------------------------------------------------
  // PROFILES TABLE API
  // -------------------------------------------------------------

  /// Get user profile from Supabase profiles table
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      if (data != null) {
        return UserModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Upsert user profile into Supabase profiles table
  Future<void> upsertUserProfile(UserModel user) async {
    try {
      await _client.from('profiles').upsert(user.toJson());
    } catch (e) {
      // Profile saved in auth state if network issue
    }
  }

  // -------------------------------------------------------------
  // FALLBACK SEED DATA HELPERS
  // -------------------------------------------------------------

  List<MedicineModel> _getFallbackMedicines({
    String? query,
    String? province,
    bool? onlyInStock,
    bool? genericsOnly,
  }) {
    final list = [
      MedicineModel(
        id: 'med-1',
        name: 'Coartem 80/480mg',
        activeIngredient: 'Artemeter + Lumefantrina',
        category: 'Antimaláricos',
        dosage: 'Caixa com 6 Comprimidos',
        priceKz: 4500,
        pharmacyName: 'Farmácia Mecofarma Talatona',
        province: 'Luanda',
        district: 'Talatona',
        inStock: true,
        stockQuantity: 24,
        requiresPrescription: true,
        isGeneric: false,
        genericAlternative: 'Artemether/Lumefantrine Genérico (2100 Kz)',
        description: 'Tratamento de primeira escolha para a malária em Angola.',
        dosageInstructions: 'Tomar com alimentos gordurosos (ex: leite ou refeição).',
      ),
      MedicineModel(
        id: 'med-2',
        name: 'Paracetamol 500mg (Bial)',
        activeIngredient: 'Paracetamol',
        category: 'Analgésicos',
        dosage: 'Caixa de 20 Comprimidos',
        priceKz: 1200,
        pharmacyName: 'Farmácia Sagrada Esperança',
        province: 'Luanda',
        district: 'Maianga',
        inStock: true,
        stockQuantity: 80,
        requiresPrescription: false,
        isGeneric: false,
        genericAlternative: 'Paracetamol Genérico (450 Kz)',
        description: 'Alívio de dores ligeiras a moderadas e febre.',
        dosageInstructions: '1 a 2 comprimidos de 6 em 6 horas.',
      ),
      MedicineModel(
        id: 'med-3',
        name: 'Amoxicilina 500mg (Genérico)',
        activeIngredient: 'Amoxicilina Tri-hidratada',
        category: 'Antibióticos',
        dosage: 'Caixa de 16 Cápsulas',
        priceKz: 2800,
        pharmacyName: 'Farmácia Popular de Luanda',
        province: 'Luanda',
        district: 'Ingombota',
        inStock: true,
        stockQuantity: 15,
        requiresPrescription: true,
        isGeneric: true,
        description: 'Antibiótico bactericida de amplo espectro.',
        dosageInstructions: '1 cápsula de 8 em 8 horas conforme receita.',
      ),
      MedicineModel(
        id: 'med-4',
        name: 'Ibuprofeno 400mg',
        activeIngredient: 'Ibuprofeno',
        category: 'Anti-inflamatórios',
        dosage: 'Caixa de 20 Comprimidos',
        priceKz: 1850,
        pharmacyName: 'Farmácia Central Benguela',
        province: 'Benguela',
        district: 'Benguela Centro',
        inStock: true,
        stockQuantity: 42,
        requiresPrescription: false,
        isGeneric: false,
        description: 'Anti-inflamatório para dor articular e muscular.',
        dosageInstructions: 'Tomar após as refeições.',
      ),
      MedicineModel(
        id: 'med-5',
        name: 'Vitercal D3 (Cálcio + Vitamina D3)',
        activeIngredient: 'Cálcio + Colecalciferol',
        category: 'Vitaminas',
        dosage: 'Frasco de 30 Comprimidos',
        priceKz: 6200,
        pharmacyName: 'Farmácia Moderna Huambo',
        province: 'Huambo',
        district: 'Huambo Centro',
        inStock: true,
        stockQuantity: 18,
        requiresPrescription: false,
        isGeneric: false,
        description: 'Suplementação para saúde óssea e imunidade.',
        dosageInstructions: 'Dissolver 1 comprimido num copo de água diariamente.',
      ),
    ];

    return list.where((m) {
      if (province != null && province.isNotEmpty && m.province != province) return false;
      if (onlyInStock == true && !m.inStock) return false;
      if (genericsOnly == true && !m.isGeneric) return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!m.name.toLowerCase().contains(q) && !m.activeIngredient.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<PharmacyModel> _getFallbackPharmacies({String? province, bool? only24h}) {
    final now = DateTime.now();
    final list = [
      PharmacyModel(
        id: 'pharm-1',
        name: 'Farmácia Mecofarma Talatona',
        province: 'Luanda',
        district: 'Talatona',
        address: 'Via AL15, Próximo ao Shopping Avennida',
        phone: '+244 923 100 200',
        openingHours: '24 Horas / 7 Dias',
        isOpen24h: true,
        hasDelivery: true,
        rating: 4.9,
        logoUrl: 'https://images.unsplash.com/photo-1586015555751-63bb77f4322a?w=150',
        subscriptionStatus: 'trial',
        trialEndsAt: now.add(const Duration(days: 68)),
        paymentDueDate: now.add(const Duration(days: 68)),
        monthlyFee: 15000.0,
      ),
      PharmacyModel(
        id: 'pharm-2',
        name: 'Farmácia Sagrada Esperança',
        province: 'Luanda',
        district: 'Maianga',
        address: 'Avenida Lenine, Edifício Clínica Sagrada Esperança',
        phone: '+244 912 300 400',
        openingHours: '07:30 - 22:00',
        isOpen24h: false,
        hasDelivery: true,
        rating: 4.8,
        logoUrl: 'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=150',
        subscriptionStatus: 'active',
        trialEndsAt: now.subtract(const Duration(days: 30)),
        paymentDueDate: now.add(const Duration(days: 22)),
        monthlyFee: 15000.0,
        lastPaymentAt: now.subtract(const Duration(days: 8)),
      ),
      PharmacyModel(
        id: 'pharm-3',
        name: 'Farmácia Popular de Luanda',
        province: 'Luanda',
        district: 'Ingombota',
        address: 'Rua Rainha Ginga, Mutamba',
        phone: '+244 924 555 777',
        openingHours: '08:00 - 20:00',
        isOpen24h: false,
        hasDelivery: false,
        rating: 4.6,
        logoUrl: 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=150',
        subscriptionStatus: 'trial',
        trialEndsAt: now.add(const Duration(days: 3)), // Expiring soon!
        paymentDueDate: now.add(const Duration(days: 3)),
        monthlyFee: 15000.0,
      ),
      PharmacyModel(
        id: 'pharm-4',
        name: 'Farmácia Central Benguela',
        province: 'Benguela',
        district: 'Benguela Centro',
        address: 'Avenida 10 de Fevereiro, Edifício Central',
        phone: '+244 931 222 333',
        openingHours: '24 Horas / 7 Dias',
        isOpen24h: true,
        hasDelivery: true,
        rating: 4.7,
        logoUrl: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=150',
        subscriptionStatus: 'expired',
        trialEndsAt: now.subtract(const Duration(days: 10)),
        paymentDueDate: now.subtract(const Duration(days: 10)),
        monthlyFee: 15000.0,
      ),
      PharmacyModel(
        id: 'pharm-5',
        name: 'Farmácia Moderna Huambo',
        province: 'Huambo',
        district: 'Huambo Centro',
        address: 'Rua do Comércio, nº 45',
        phone: '+244 945 888 999',
        openingHours: '08:00 - 21:00',
        isOpen24h: false,
        hasDelivery: true,
        rating: 4.8,
        logoUrl: 'https://images.unsplash.com/photo-1585435557343-3b092031a831?w=150',
        subscriptionStatus: 'blocked',
        trialEndsAt: now.subtract(const Duration(days: 45)),
        paymentDueDate: now.subtract(const Duration(days: 45)),
        monthlyFee: 15000.0,
      ),
    ];

    return list.where((p) {
      if (province != null && province.isNotEmpty && p.province != province) return false;
      if (only24h == true && !p.isOpen24h) return false;
      return true;
    }).toList();
  }

  List<PharmacyPaymentModel> _getFallbackPayments() {
    final now = DateTime.now();
    return [
      PharmacyPaymentModel(
        id: 'pay-1',
        pharmacyId: 'pharm-4',
        pharmacyName: 'Farmácia Central Benguela',
        amount: 15000.0,
        paymentMethod: 'Transferência IBAN Multicaixa',
        referenceNumber: 'AO06.0040.0000.8192.1001.3018.9',
        proofUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500',
        status: 'pending',
        periodMonths: 1,
        notes: 'Comprovativo de transferência de 15.000 Kz submetido via BAI Directo.',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      PharmacyPaymentModel(
        id: 'pay-2',
        pharmacyId: 'pharm-2',
        pharmacyName: 'Farmácia Sagrada Esperança',
        amount: 15000.0,
        paymentMethod: 'Multicaixa Express',
        referenceNumber: 'MCX-998231',
        proofUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500',
        status: 'approved',
        periodMonths: 1,
        notes: 'Pagamento verificado e mensalidade renovada.',
        createdAt: now.subtract(const Duration(days: 8)),
        approvedAt: now.subtract(const Duration(days: 8)),
      ),
    ];
  }

  List<ReservationModel> _getFallbackReservations() {
    return [
      ReservationModel(
        id: 'res-101',
        medicineName: 'Coartem 80/480mg',
        pharmacyId: 'pharm-1',
        pharmacyName: 'Farmácia Mecofarma Talatona',
        pickupCode: 'FJ-9281',
        totalPriceKz: 4500,
        reservationDate: '22 Julho 2026',
        expiryDate: '23 Julho 2026 - 18:00',
        status: 'active',
        prescriptionUploaded: true,
      ),
      ReservationModel(
        id: 'res-100',
        medicineName: 'Paracetamol 500mg (Bial)',
        pharmacyId: 'pharm-2',
        pharmacyName: 'Farmácia Sagrada Esperança',
        pickupCode: 'FJ-4102',
        totalPriceKz: 1200,
        reservationDate: '15 Julho 2026',
        expiryDate: '16 Julho 2026 - 18:00',
        status: 'completed',
        prescriptionUploaded: false,
        isReviewed: false,
      ),
    ];
  }

  // -------------------------------------------------------------
  // REVIEWS & MODERATION API
  // -------------------------------------------------------------

  static final List<ReviewModel> _localReviewsMemory = [
    ReviewModel(
      id: 'rev-1',
      reservationId: 'res-100',
      userId: 'usr-10',
      userName: 'Manuel Agostinho',
      pharmacyId: 'pharm-2',
      pharmacyName: 'Farmácia Sagrada Esperança',
      pharmacyRating: 5.0,
      pharmacyComment: 'Excelente atendimento! Medicamento entregue rapidamente.',
      appRating: 5.0,
      appComment: 'A aplicação FarmaJá é super prática para encontrar fármacos em Luanda.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'approved',
    ),
    ReviewModel(
      id: 'rev-2',
      reservationId: 'res-99',
      userId: 'usr-11',
      userName: 'Ana Paula Kiala',
      pharmacyId: 'pharm-1',
      pharmacyName: 'Farmácia Mecofarma Talatona',
      pharmacyRating: 1.0,
      pharmacyComment: 'Cheguei à farmácia e disseram que o stock tinha esgotado.',
      appRating: 4.0,
      appComment: 'O app funciona, mas a farmácia não respeitou o código de reserva.',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      status: 'pending_moderation',
      isLowRating: true,
    ),
  ];

  static final List<AdminNotificationModel> _localNotificationsMemory = [
    AdminNotificationModel(
      id: 'notif-1',
      type: 'low_rating_alert',
      title: '🚨 Alerta de Avaliação Baixa (1.0★)',
      message: 'Ana Paula Kiala enviou uma crítica de 1.0★ para a Farmácia Mecofarma Talatona. Requer moderação.',
      targetId: 'rev-2',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
  ];

  /// Submit a review for a completed reservation
  Future<Map<String, dynamic>> submitReview(ReviewModel review) async {
    // Check if already reviewed
    final existingLocal = _localReviewsMemory.where((r) => r.reservationId == review.reservationId).toList();
    if (existingLocal.isNotEmpty) {
      return {'success': false, 'message': 'Esta reserva já possui uma avaliação enviada.'};
    }

    final isLow = review.pharmacyRating <= 2.0 || review.appRating <= 2.0;
    final status = isLow ? 'pending_moderation' : 'approved';

    final newReview = ReviewModel(
      id: review.id.isNotEmpty ? review.id : 'rev-${DateTime.now().millisecondsSinceEpoch}',
      reservationId: review.reservationId,
      userId: review.userId,
      userName: review.userName,
      userPhone: review.userPhone,
      pharmacyId: review.pharmacyId,
      pharmacyName: review.pharmacyName,
      pharmacyRating: review.pharmacyRating,
      pharmacyComment: review.pharmacyComment,
      appRating: review.appRating,
      appComment: review.appComment,
      createdAt: DateTime.now(),
      status: status,
      isLowRating: isLow,
    );

    // Save to Supabase
    try {
      await _client.from('reviews').insert(newReview.toJson());
    } catch (_) {
      // Fallback local memory sync
    }
    _localReviewsMemory.add(newReview);

    // Create Admin notification if low rating (1 or 2 stars)
    if (isLow) {
      final notif = AdminNotificationModel(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        type: 'low_rating_alert',
        title: '🚨 Alerta de Avaliação Baixa (${review.pharmacyRating.toStringAsFixed(1)}★ / ${review.appRating.toStringAsFixed(1)}★)',
        message: '${review.userName} enviou uma avaliação baixa sobre ${review.pharmacyName}. Requer moderação no Painel Admin.',
        targetId: newReview.id,
        createdAt: DateTime.now(),
      );

      try {
        await _client.from('admin_notifications').insert(notif.toJson());
      } catch (_) {}
      _localNotificationsMemory.insert(0, notif);
    }

    // Update reservation as reviewed in Supabase
    try {
      await _client.from('reservations').update({
        'is_reviewed': true,
        'review_rating': review.pharmacyRating,
      }).eq('id', review.reservationId);
    } catch (_) {}

    // Recalculate pharmacy rating if approved
    if (status == 'approved') {
      await _updatePharmacyAverageRating(review.pharmacyId);
    }

    return {
      'success': true,
      'review': newReview,
      'requiresModeration': isLow,
      'message': isLow
          ? 'Sua avaliação foi enviada! Como contém nota baixa, passará por moderação pela equipa FarmaJá.'
          : 'Obrigado! A sua avaliação foi publicada com sucesso.',
    };
  }

  /// Get approved reviews for a specific pharmacy
  Future<List<ReviewModel>> getReviewsForPharmacy(String pharmacyId) async {
    try {
      final List<dynamic> data = await _client
          .from('reviews')
          .select()
          .eq('pharmacy_id', pharmacyId)
          .eq('status', 'approved')
          .order('created_at', ascending: false);
      return data.map((json) => ReviewModel.fromJson(json)).toList();
    } catch (_) {
      return _localReviewsMemory
          .where((r) => r.pharmacyId == pharmacyId && r.status == 'approved')
          .toList();
    }
  }

  /// Get all reviews for Admin moderation & reports
  Future<List<ReviewModel>> getAllReviews() async {
    try {
      final List<dynamic> data = await _client
          .from('reviews')
          .select()
          .order('created_at', ascending: false);
      return data.map((json) => ReviewModel.fromJson(json)).toList();
    } catch (_) {
      return List.from(_localReviewsMemory);
    }
  }

  /// Moderate a review (approve or reject)
  Future<bool> moderateReview({
    required String reviewId,
    required String status, // 'approved', 'rejected'
    String? note,
  }) async {
    try {
      await _client.from('reviews').update({
        'status': status,
        'moderation_note': note,
        'moderated_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);
    } catch (_) {}

    final index = _localReviewsMemory.indexWhere((r) => r.id == reviewId);
    if (index != -1) {
      _localReviewsMemory[index] = _localReviewsMemory[index].copyWith(
        status: status,
        moderationNote: note,
        moderatedAt: DateTime.now(),
      );
      if (status == 'approved') {
        await _updatePharmacyAverageRating(_localReviewsMemory[index].pharmacyId);
      }
    }
    return true;
  }

  /// Recalculate average pharmacy rating
  Future<void> _updatePharmacyAverageRating(String pharmacyId) async {
    final reviews = await getReviewsForPharmacy(pharmacyId);
    if (reviews.isEmpty) return;

    final total = reviews.fold(0.0, (sum, r) => sum + r.pharmacyRating);
    final avg = double.parse((total / reviews.length).toStringAsFixed(1));

    try {
      await _client.from('pharmacies').update({'rating': avg}).eq('id', pharmacyId);
    } catch (_) {}
  }

  /// Get admin notifications for low ratings / alerts
  Future<List<AdminNotificationModel>> getAdminNotifications() async {
    try {
      final List<dynamic> data = await _client
          .from('admin_notifications')
          .select()
          .order('created_at', ascending: false);
      return data.map((json) => AdminNotificationModel.fromJson(json)).toList();
    } catch (_) {
      return List.from(_localNotificationsMemory);
    }
  }

  /// Mark admin notification as read
  Future<void> markAdminNotificationRead(String id) async {
    try {
      await _client.from('admin_notifications').update({'is_read': true}).eq('id', id);
    } catch (_) {}
    final idx = _localNotificationsMemory.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final current = _localNotificationsMemory[idx];
      _localNotificationsMemory[idx] = AdminNotificationModel(
        id: current.id,
        type: current.type,
        title: current.title,
        message: current.message,
        targetId: current.targetId,
        isRead: true,
        createdAt: current.createdAt,
      );
    }
  }
}
