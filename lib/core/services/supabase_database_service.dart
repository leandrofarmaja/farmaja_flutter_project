
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

  static const String _prescriptionUnavailableMessage =
      'Envio de receitas indisponível. Por enquanto, apresente '
      'a receita médica directamente na farmácia, quando necessário.';

  static const String _medicineImagesBucket = 'medicamentos';
  static const int _maxMedicineImageSize = 5 * 1024 * 1024;

  static const String _reservationSelect =
      'id, medicamento_id, farmacia_id, status, '
      'codigo_reserva, url_foto_receita, criado_em, '
      'user_id, preco_kwanza, expira_em, receita_enviada, '
      'metodo_pagamento, cliente_confirmou_pagamento_em, '
      'farmacia_confirmou_pagamento_em, qr_validado_em, '
      'receita_autorizada, receita_verificada_em, '
      'medicamentos(nome_medicamento), farmacias(nome)';

  // ============================================================
  // IMAGENS DOS MEDICAMENTOS
  // ============================================================

  String _medicineImageExtension(XFile image) {
    final fileName = image.name.trim().toLowerCase();

    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      throw ArgumentError(
        'A imagem deve ter uma extensão JPEG, JPG, PNG ou WebP.',
      );
    }

    final extension = fileName.substring(dotIndex + 1);

    const allowedExtensions = <String>{
      'jpg',
      'jpeg',
      'png',
      'webp',
    };

    if (!allowedExtensions.contains(extension)) {
      throw ArgumentError(
        'Formato de imagem não permitido. '
        'Utiliza JPEG, PNG ou WebP.',
      );
    }

    return extension;
  }

  String _medicineImageContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        throw ArgumentError('Formato de imagem não suportado.');
    }
  }

  Future<String> _uploadMedicineImage({
    required XFile image,
    required String pharmacyId,
  }) async {
    if (pharmacyId.trim().isEmpty) {
      throw ArgumentError(
        'O identificador da farmácia é obrigatório para carregar a imagem.',
      );
    }

    final extension = _medicineImageExtension(image);
    final contentType = _medicineImageContentType(extension);

    final bytes = await image.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('O ficheiro da imagem está vazio.');
    }

    if (bytes.length > _maxMedicineImageSize) {
      throw Exception(
        'A imagem excede o limite permitido de 5 MB.',
      );
    }

    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}.$extension';

    final storagePath = '${pharmacyId.trim()}/$fileName';

    await _client.storage
        .from(_medicineImagesBucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    return _client.storage
        .from(_medicineImagesBucket)
        .getPublicUrl(storagePath);
  }

  Future<void> _removeUploadedMedicineImage(
    String? imageUrl,
  ) async {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return;
    }

    try {
      final uri = Uri.tryParse(imageUrl);

      if (uri == null) return;

      final marker = '/storage/v1/object/public/'
          '$_medicineImagesBucket/';

      final pathIndex = uri.path.indexOf(marker);

      if (pathIndex < 0) return;

      final storagePath = Uri.decodeComponent(
        uri.path.substring(pathIndex + marker.length),
      );

      if (storagePath.isEmpty) return;

      await _client.storage
          .from(_medicineImagesBucket)
          .remove([storagePath]);
    } catch (_) {
      // A limpeza é best-effort.
      // Não substitui o erro original da operação.
    }
  }

  // ============================================================
  // MEDICAMENTOS
  // ============================================================

  Future<List<MedicineModel>> getMedicines({
    String? query,
    String? province,
    String? pharmacyId,
    bool? onlyInStock,
    bool? genericsOnly,
  }) async {
    if (province != null && province.trim().isNotEmpty) {
      throw UnsupportedError(
        'A tabela medicamentos ainda não possui uma coluna de província.',
      );
    }

    if (genericsOnly == true) {
      throw UnsupportedError(
        'A tabela medicamentos ainda não possui informação sobre genéricos.',
      );
    }

    if (pharmacyId != null && pharmacyId.trim().isEmpty) {
      throw ArgumentError(
        'O identificador da farmácia não pode estar vazio.',
      );
    }

    try {
      var request = _client
          .from('medicamentos')
          .select(
            'id, nome_medicamento, preco_kwanza, farmacia_id, '
            'disponivel, quantidade_stock, distancia_km, '
            'receita_obrigatoria, imagem_url, '
            'farmacias(id, nome, endereco, telefone, aberta_agora, avaliacao)',
          );

      if (pharmacyId != null) {
        request = request.eq('farmacia_id', pharmacyId.trim());
      }

      final response = await request.order('nome_medicamento');
      final rows = List<Map<String, dynamic>>.from(response);

      final filteredRows = rows.where((row) {
        final stockValue = row['quantidade_stock'];
        final stockQuantity =
            stockValue is num ? stockValue.toInt() : 0;

        final available =
            row['disponivel'] == true && stockQuantity > 0;

        if (onlyInStock == true && !available) {
          return false;
        }

        if (query != null && query.trim().isNotEmpty) {
          final name = (row['nome_medicamento'] ?? '')
              .toString()
              .toLowerCase();

          if (!name.contains(query.trim().toLowerCase())) {
            return false;
          }
        }

        return true;
      });

      return filteredRows.map(_medicineFromDatabase).toList();
    } catch (e) {
      throw Exception(
        'Não foi possível carregar os medicamentos: $e',
      );
    }
  }

  Future<MedicineModel?> getMedicineById(String id) async {
    try {
      final response = await _client
          .from('medicamentos')
          .select(
            'id, nome_medicamento, preco_kwanza, farmacia_id, '
            'disponivel, quantidade_stock, distancia_km, '
            'receita_obrigatoria, imagem_url, '
            'farmacias(id, nome, endereco, telefone, aberta_agora, avaliacao)',
          )
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return _medicineFromDatabase(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception(
        'Não foi possível consultar o medicamento: $e',
      );
    }
  }

  MedicineModel _medicineFromDatabase(
    Map<String, dynamic> row,
  ) {
    final pharmacyValue = row['farmacias'];

    final pharmacy = pharmacyValue is Map
        ? Map<String, dynamic>.from(pharmacyValue)
        : <String, dynamic>{};

    final price = row['preco_kwanza'];
    final stockValue = row['quantidade_stock'];

    final stockQuantity =
        stockValue is num ? stockValue.toInt() : 0;

    final available =
        row['disponivel'] == true && stockQuantity > 0;

    final rawImageUrl = row['imagem_url']?.toString().trim();

    return MedicineModel(
      id: (row['id'] ?? '').toString(),
      pharmacyId: (row['farmacia_id'] ?? '').toString(),
      name: (row['nome_medicamento'] ?? '').toString(),
      activeIngredient: '',
      category: '',
      dosage: '',
      priceKz: price is num ? price.toDouble() : 0.0,
      pharmacyName: (pharmacy['nome'] ?? '').toString(),
      province: '',
      district: '',
      inStock: available,
      stockQuantity: stockQuantity,
      requiresPrescription: row['receita_obrigatoria'] == true,
      isGeneric: false,
      genericAlternative: null,
      description: '',
      dosageInstructions: '',
      pharmacyLatitude: 0.0,
      pharmacyLongitude: 0.0,
      imageUrl: rawImageUrl == null || rawImageUrl.isEmpty
          ? null
          : rawImageUrl,
    );
  }

  // ============================================================
  // FARMÁCIAS
  // ============================================================

  Future<List<PharmacyModel>> getPharmacies({
    String? province,
    bool? only24h,
  }) async {
    if (only24h == true) {
      throw UnsupportedError(
        'A tabela farmacias ainda não possui informação sobre funcionamento 24 horas.',
      );
    }

    try {
      var request = _client.from('farmacias').select(
        'id, nome, avaliacao, endereco, telefone, aberta_agora, '
        'owner_user_id, foto_url, provincia, municipio, bairro, '
        'latitude, longitude, subscription_status, trial_ends_at, '
        'payment_due_date, monthly_fee, last_payment_at',
      );

      if (province != null && province.trim().isNotEmpty) {
        request = request.ilike('provincia', province.trim());
      }

      final response = await request.order('nome');

      return List<Map<String, dynamic>>.from(response)
          .map(_pharmacyFromDatabase)
          .toList();
    } catch (e) {
      throw Exception(
        'Não foi possível carregar as farmácias: $e',
      );
    }
  }

  Future<List<PharmacyModel>> getAllPharmacies() {
    return getPharmacies();
  }

  Future<PharmacyModel?> getOwnedPharmacy() async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'Inicia sessão para consultar a farmácia associada à conta.',
      );
    }

    try {
      final response = await _client
          .from('farmacias')
          .select(
            'id, nome, avaliacao, endereco, telefone, aberta_agora, '
            'owner_user_id, foto_url, provincia, municipio, bairro, '
            'latitude, longitude, subscription_status, trial_ends_at, '
            'payment_due_date, monthly_fee, last_payment_at',
          )
          .eq('owner_user_id', currentUser.id);

      final rows = List<Map<String, dynamic>>.from(response);

      if (rows.isEmpty) return null;

      if (rows.length > 1) {
        throw Exception(
          'Esta conta está associada a várias farmácias. '
          'É necessário seleccionar a farmácia correcta.',
        );
      }

      return _pharmacyFromDatabase(rows.first);
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível identificar a farmácia da conta: ${e.message}',
      );
    }
  }

  Future<PharmacyModel?> getPharmacyById(String id) async {
    try {
      final response = await _client
          .from('farmacias')
          .select(
            'id, nome, avaliacao, endereco, telefone, aberta_agora, '
            'owner_user_id, foto_url, provincia, municipio, bairro, '
            'latitude, longitude, subscription_status, trial_ends_at, '
            'payment_due_date, monthly_fee, last_payment_at',
          )
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return _pharmacyFromDatabase(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception(
        'Não foi possível consultar a farmácia: $e',
      );
    }
  }

  PharmacyModel _pharmacyFromDatabase(
    Map<String, dynamic> row,
  ) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    DateTime? toDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;

      final text = value.toString().trim();
      if (text.isEmpty) return null;

      return DateTime.tryParse(text);
    }

    final rating = row['avaliacao'];
    final monthlyFee = row['monthly_fee'];

    final rawStatus =
        (row['subscription_status'] ?? 'trial')
            .toString()
            .trim()
            .toLowerCase();

    const validStatuses = <String>{
      'trial',
      'active',
      'expired',
      'blocked',
    };

    final subscriptionStatus = validStatuses.contains(rawStatus)
        ? rawStatus
        : 'unknown';

    return PharmacyModel(
      id: (row['id'] ?? '').toString(),
      name: (row['nome'] ?? '').toString(),
      province: (row['provincia'] ?? '').toString(),
      district: (row['municipio'] ?? '').toString(),
      neighborhood: (row['bairro'] ?? '').toString(),
      address: (row['endereco'] ?? '').toString(),
      phone: (row['telefone'] ?? '').toString(),
      openingHours:
          row['aberta_agora'] == true ? 'Aberta' : 'Fechada',
      isOpen24h: false,
      hasDelivery: false,
      rating: rating is num ? rating.toDouble() : 0.0,
      logoUrl: (row['foto_url'] ?? '').toString(),
      latitude: toDouble(row['latitude']),
      longitude: toDouble(row['longitude']),
      subscriptionStatus: subscriptionStatus,
      trialEndsAt: toDateTime(row['trial_ends_at']),
      paymentDueDate: toDateTime(row['payment_due_date']),
      monthlyFee: monthlyFee is num
          ? monthlyFee.toDouble()
          : 15000.0,
      lastPaymentAt: toDateTime(row['last_payment_at']),
    );
  }

  // ============================================================
  // RESERVAS DO CLIENTE
  // ============================================================

  Future<List<ReservationModel>> getReservations(
    String userId,
  ) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null || currentUser.id != userId) {
      throw Exception(
        'Só podes consultar as reservas da conta autenticada.',
      );
    }

    try {
      final response = await _client
          .from('reservas')
          .select(_reservationSelect)
          .eq('user_id', currentUser.id)
          .order('criado_em', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(_reservationFromDatabase)
          .toList();
    } catch (e) {
      throw Exception(
        'Não foi possível carregar as reservas: $e',
      );
    }
  }

  // ============================================================
  // RESERVAS DA FARMÁCIA
  // ============================================================

  Future<List<ReservationModel>> getAllReservationsForPharmacy({
    String? pharmacyName,
  }) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'Inicia sessão com a conta da farmácia.',
      );
    }

    try {
      final rpcResult = await _client.rpc(
        'listar_reservas_farmacia',
      );

      if (rpcResult is! List) {
        throw Exception(
          'O Supabase devolveu um formato inesperado para as reservas.',
        );
      }

      final reservationRows = rpcResult
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      if (reservationRows.isEmpty) {
        return <ReservationModel>[];
      }

      final pharmacyIds = reservationRows
          .map((row) => row['farmacia_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final medicineIds = reservationRows
          .map((row) => row['medicamento_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final pharmacyRows = pharmacyIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _client
                  .from('farmacias')
                  .select('id, nome')
                  .inFilter('id', pharmacyIds),
            );

      final medicineRows = medicineIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _client
                  .from('medicamentos')
                  .select('id, nome_medicamento')
                  .inFilter('id', medicineIds),
            );

      final pharmacyNames = <String, String>{
        for (final row in pharmacyRows)
          (row['id'] ?? '').toString():
              (row['nome'] ?? '').toString(),
      };

      final medicineNames = <String, String>{
        for (final row in medicineRows)
          (row['id'] ?? '').toString():
              (row['nome_medicamento'] ?? '').toString(),
      };

      final reservations = reservationRows.map((row) {
        final pharmacyId =
            (row['farmacia_id'] ?? '').toString();
        final medicineId =
            (row['medicamento_id'] ?? '').toString();

        return _reservationFromDatabase({
          ...row,
          'farmacias': {
            'nome': pharmacyNames[pharmacyId] ?? '',
          },
          'medicamentos': {
            'nome_medicamento':
                medicineNames[medicineId] ?? '',
          },
        });
      }).toList();

      if (pharmacyName != null &&
          pharmacyName.trim().isNotEmpty) {
        return reservations
            .where(
              (reservation) =>
                  reservation.pharmacyName.toLowerCase() ==
                  pharmacyName.trim().toLowerCase(),
            )
            .toList();
      }

      return reservations;
    } on PostgrestException catch (e) {
      throw Exception(
        'O Supabase não conseguiu carregar as reservas da farmácia: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível carregar as reservas da farmácia: $e',
      );
    }
  }

  Future<ReservationModel> createReservation({
    required String userId,
    required String medicineId,
    required String pharmacyId,
    required bool prescriptionUploaded,
    String? prescriptionPath,
  }) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'É necessário iniciar sessão para efectuar uma reserva.',
      );
    }

    if (currentUser.id != userId) {
      throw Exception(
        'O utilizador autenticado não corresponde ao utilizador da reserva.',
      );
    }

    if (medicineId.trim().isEmpty ||
        pharmacyId.trim().isEmpty) {
      throw ArgumentError(
        'O medicamento e a farmácia devem ser identificados.',
      );
    }

    if (prescriptionUploaded ||
        (prescriptionPath != null &&
            prescriptionPath.trim().isNotEmpty)) {
      throw UnsupportedError(
        _prescriptionUnavailableMessage,
      );
    }

    try {
      final rpcResult = await _client.rpc(
        'criar_reserva',
        params: {
          'p_medicamento_id': medicineId.trim(),
          'p_farmacia_id': pharmacyId.trim(),
          'p_receita_enviada': false,
          'p_url_foto_receita': null,
        },
      );

      final createdReservation =
          _mapFromRpcResult(rpcResult);

      final reservationId =
          createdReservation?['id']?.toString();

      if (reservationId == null || reservationId.isEmpty) {
        throw Exception(
          'O Supabase não devolveu o identificador da reserva criada.',
        );
      }

      final response = await _client
          .from('reservas')
          .select(_reservationSelect)
          .eq('id', reservationId)
          .eq('user_id', currentUser.id)
          .single();

      return _reservationFromDatabase(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception(
        'Não foi possível criar a reserva: $e',
      );
    }
  }

  Map<String, dynamic>? _mapFromRpcResult(dynamic result) {
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }

    if (result is List &&
        result.isNotEmpty &&
        result.first is Map) {
      return Map<String, dynamic>.from(result.first as Map);
    }

    return null;
  }

  DateTime? _dateTimeFromDatabase(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  ReservationModel _reservationFromDatabase(
    Map<String, dynamic> row,
  ) {
    final medicineValue = row['medicamentos'];
    final pharmacyValue = row['farmacias'];

    final medicine = medicineValue is Map
        ? Map<String, dynamic>.from(medicineValue)
        : <String, dynamic>{};

    final pharmacy = pharmacyValue is Map
        ? Map<String, dynamic>.from(pharmacyValue)
        : <String, dynamic>{};

    final price = row['preco_kwanza'];

    return ReservationModel(
      id: (row['id'] ?? '').toString(),
      medicineName:
          (medicine['nome_medicamento'] ?? '').toString(),
      pharmacyId: (row['farmacia_id'] ?? '').toString(),
      pharmacyName: (pharmacy['nome'] ?? '').toString(),
      pickupCode: (row['codigo_reserva'] ?? '').toString(),
      totalPriceKz: price is num ? price.toDouble() : 0.0,
      reservationDate: (row['criado_em'] ?? '').toString(),
      expiryDate: (row['expira_em'] ?? '').toString(),
      status:
          (row['status'] ?? 'Aguardando confirmação').toString(),
      prescriptionUploaded: row['receita_enviada'] == true,
      isReviewed: false,
      reviewRating: null,
      metodoPagamento: row['metodo_pagamento']?.toString(),
      clienteConfirmouPagamentoEm:
          _dateTimeFromDatabase(
        row['cliente_confirmou_pagamento_em'],
      ),
      farmaciaConfirmouPagamentoEm:
          _dateTimeFromDatabase(
        row['farmacia_confirmou_pagamento_em'],
      ),
      qrValidadoEm:
          _dateTimeFromDatabase(row['qr_validado_em']),
      receitaAutorizada: row['receita_autorizada'] is bool
          ? row['receita_autorizada'] as bool
          : null,
      receitaVerificadaEm:
          _dateTimeFromDatabase(
        row['receita_verificada_em'],
      ),
    );
  }

  Future<ReservationModel> _reloadReservation(
    String reservationId,
  ) async {
    final response = await _client
        .from('reservas')
        .select(_reservationSelect)
        .eq('id', reservationId)
        .single();

    return _reservationFromDatabase(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // CONFIRMAÇÃO DE PAGAMENTO — CLIENTE
  // ============================================================

  Future<ReservationModel> clienteConfirmarPagamento({
    required String reservationId,
  }) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'Inicia sessão para confirmar a compra.',
      );
    }

    if (reservationId.trim().isEmpty) {
      throw ArgumentError(
        'O identificador da reserva é obrigatório.',
      );
    }

    try {
      await _client.rpc(
        'cliente_confirmar_pagamento',
        params: {
          'p_reserva_id': reservationId.trim(),
        },
      );

      return await _reloadReservation(reservationId.trim());
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível confirmar a compra do cliente: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Falha ao confirmar a compra do cliente: $e',
      );
    }
  }

  // ============================================================
  // CONFIRMAÇÃO DE PAGAMENTO — FARMÁCIA
  // ============================================================

  Future<ReservationModel> farmaciaConfirmarPagamento({
    required String reservationId,
  }) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'Inicia sessão com a conta da farmácia para confirmar a venda.',
      );
    }

    if (reservationId.trim().isEmpty) {
      throw ArgumentError(
        'O identificador da reserva é obrigatório.',
      );
    }

    try {
      await _client.rpc(
        'farmacia_confirmar_pagamento',
        params: {
          'p_reserva_id': reservationId.trim(),
        },
      );

      return await _reloadReservation(reservationId.trim());
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível confirmar a venda da farmácia: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Falha ao confirmar a venda da farmácia: $e',
      );
    }
  }

  // ============================================================
  // CONFIRMAÇÃO DO LEVANTAMENTO
  // ============================================================

  Future<void> confirmarLevantamento(
    String reservationId,
  ) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'Inicia sessão com a conta da farmácia para confirmar o levantamento.',
      );
    }

    if (reservationId.trim().isEmpty) {
      throw ArgumentError(
        'O identificador da reserva é obrigatório.',
      );
    }

    try {
      await _client.rpc(
        'confirmar_levantamento',
        params: {
          'p_reserva_id': reservationId.trim(),
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível confirmar o levantamento: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Falha ao comunicar com o Supabase: $e',
      );
    }
  }

  // ============================================================
  // VALIDAÇÃO DO CÓDIGO DE LEVANTAMENTO
  // ============================================================

  Future<ReservationModel?> validateReservationByQrCode(
    String code,
  ) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'Inicia sessão com a conta da farmácia para validar a reserva.',
      );
    }

    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw ArgumentError(
        'O código de levantamento é obrigatório.',
      );
    }

    try {
      final result = await _client.rpc(
        'confirmar_levantamento_por_codigo',
        params: {
          'p_codigo_reserva': normalizedCode,
        },
      );

      if (result is! Map) {
        throw Exception(
          'O Supabase devolveu uma resposta inesperada.',
        );
      }

      return _reservationFromDatabase(
        Map<String, dynamic>.from(result),
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível validar o levantamento: ${e.message}',
      );
    } catch (e) {
      if (e is ArgumentError || e is Exception) {
        rethrow;
      }

      throw Exception(
        'Falha ao comunicar com o Supabase: $e',
      );
    }
  }

  // ============================================================
  // PERFIL DO UTILIZADOR
  // ============================================================

  Future<UserModel?> getUserProfile(String userId) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null || currentUser.id != userId) {
      throw Exception(
        'Só podes consultar o perfil da conta autenticada.',
      );
    }

    try {
      final response = await _client
          .from('profiles')
          .select(
            'id, email, full_name, phone, province, district, '
            'insurance_provider, role, pharmacy_name',
          )
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível carregar o perfil: ${e.message}',
      );
    }
  }

  Future<void> upsertUserProfile(UserModel user) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null || currentUser.id != user.id) {
      throw Exception(
        'Só podes actualizar o perfil do utilizador autenticado.',
      );
    }

    try {
      final existingProfile = await _client
          .from('profiles')
          .select('id')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (existingProfile == null) {
        throw Exception(
          'O perfil não existe na base de dados. '
          'Verifica o trigger de criação de perfis no Supabase.',
        );
      }

      await _client
          .from('profiles')
          .update(user.toEditableProfileJson())
          .eq('id', currentUser.id);
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível actualizar o perfil: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Falha ao actualizar o perfil: $e',
      );
    }
  }

  // ============================================================
  // OPERAÇÕES AINDA NÃO SUPORTADAS
  // ============================================================

  Never _unsupported(String operation) {
    throw UnsupportedError(
      '$operation ainda não pode ser executado. '
      'A estrutura actual do Supabase não contém as tabelas '
      'ou colunas necessárias.',
    );
  }

  Future<void> updatePharmacySubscription({
    required String pharmacyId,
    required String status,
    DateTime? nextDueDate,
  }) async {
    _unsupported('Actualização da subscrição da farmácia');
  }

  Future<void> submitPharmacyPayment(
    PharmacyPaymentModel payment,
  ) async {
    _unsupported('Registo de pagamento da farmácia');
  }

  Future<List<PharmacyPaymentModel>> getAllPharmacyPayments()
      async {
    _unsupported('Consulta dos pagamentos das farmácias');
  }

  Future<void> approvePharmacyPayment({
    required String paymentId,
    required String pharmacyId,
    int periodMonths = 1,
  }) async {
    _unsupported('Aprovação de pagamento da farmácia');
  }

  Future<void> rejectPharmacyPayment(
    String paymentId,
    String? notes,
  ) async {
    _unsupported('Rejeição de pagamento da farmácia');
  }

  // ============================================================
  // GESTÃO DE MEDICAMENTOS — RPCs SUPABASE
  // ============================================================

  Future<void> addMedicine(
    MedicineModel medicine, {
    XFile? image,
  }) async {
    if (_client.auth.currentUser == null) {
      throw Exception(
        'A sessão expirou. Inicia sessão novamente para guardar o medicamento.',
      );
    }

    if (medicine.name.trim().isEmpty) {
      throw ArgumentError(
        'O nome do medicamento é obrigatório.',
      );
    }

    if (!medicine.priceKz.isFinite ||
        medicine.priceKz < 0 ||
        medicine.stockQuantity < 0) {
      throw ArgumentError(
        'O preço e o stock devem ser valores válidos e não negativos.',
      );
    }

    String? uploadedImageUrl;

    try {
      final pharmacy = await getOwnedPharmacy().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'A consulta da farmácia excedeu 15 segundos.',
          );
        },
      );

      if (pharmacy == null || pharmacy.id.trim().isEmpty) {
        throw Exception(
          'Esta conta não tem uma farmácia associada. '
          'Confirma se a farmácia foi aprovada e associada à tua conta.',
        );
      }

      if (image != null) {
        uploadedImageUrl = await _uploadMedicineImage(
          image: image,
          pharmacyId: pharmacy.id,
        );
      }

      final result = await _client
          .rpc(
            'farclik_criar_medicamento_com_imagem',
            params: {
              'p_nome_medicamento': medicine.name.trim(),
              'p_preco_kwanza': medicine.priceKz,
              'p_quantidade_stock': medicine.stockQuantity,
              'p_receita_obrigatoria':
                  medicine.requiresPrescription,
              'p_imagem_url': uploadedImageUrl,
            },
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException(
                'O Supabase não respondeu à gravação em 20 segundos.',
              );
            },
          );

      final createdId = result?.toString().trim() ?? '';

      if (createdId.isEmpty ||
          createdId.toLowerCase() == 'false' ||
          createdId.toLowerCase() == 'null') {
        throw Exception(
          'O Supabase não devolveu o identificador do medicamento criado.',
        );
      }
    } on TimeoutException {
      await _removeUploadedMedicineImage(uploadedImageUrl);
      rethrow;
    } on PostgrestException catch (e) {
      await _removeUploadedMedicineImage(uploadedImageUrl);
      throw Exception(
        'O Supabase recusou a criação do medicamento: ${e.message}',
      );
    } catch (e) {
      await _removeUploadedMedicineImage(uploadedImageUrl);
      throw Exception(
        'Não foi possível criar o medicamento: $e',
      );
    }
  }

  Future<void> updateMedicine(
    MedicineModel medicine, {
    XFile? image,
  }) async {
    if (medicine.id.trim().isEmpty) {
      throw ArgumentError(
        'O identificador do medicamento é obrigatório.',
      );
    }

    if (medicine.name.trim().isEmpty ||
        !medicine.priceKz.isFinite ||
        medicine.priceKz < 0) {
      throw ArgumentError(
        'O nome e o preço do medicamento devem ser válidos.',
      );
    }

    String? uploadedImageUrl;

    try {
      if (_client.auth.currentUser == null) {
        throw Exception(
          'A sessão expirou. Inicia sessão novamente.',
        );
      }

      final pharmacy = await getOwnedPharmacy();

      if (pharmacy == null || pharmacy.id.trim().isEmpty) {
        throw Exception(
          'Esta conta não tem uma farmácia associada.',
        );
      }

      if (image != null) {
        uploadedImageUrl = await _uploadMedicineImage(
          image: image,
          pharmacyId: pharmacy.id,
        );
      }

      final result = await _client.rpc(
        'farclik_editar_medicamento_com_imagem',
        params: {
          'p_medicamento_id': medicine.id.trim(),
          'p_nome_medicamento': medicine.name.trim(),
          'p_preco_kwanza': medicine.priceKz,
          'p_receita_obrigatoria':
              medicine.requiresPrescription,
          'p_atualizar_imagem': image != null,
          'p_imagem_url': uploadedImageUrl,
        },
      );

      if (result != true) {
        await _removeUploadedMedicineImage(uploadedImageUrl);

        throw Exception(
          'O Supabase não confirmou a edição do medicamento.',
        );
      }
    } on PostgrestException catch (e) {
      await _removeUploadedMedicineImage(uploadedImageUrl);
      throw Exception(
        'Não foi possível editar o medicamento: ${e.message}',
      );
    } catch (e) {
      await _removeUploadedMedicineImage(uploadedImageUrl);
      rethrow;
    }
  }

  Future<void> updateMedicineStock(
    String medicineId,
    int newStock,
    bool inStock,
  ) async {
    if (medicineId.trim().isEmpty || newStock < 0) {
      throw ArgumentError(
        'O identificador do medicamento e o stock devem ser válidos.',
      );
    }

    try {
      final result = await _client.rpc(
        'farclik_atualizar_stock',
        params: {
          'p_medicamento_id': medicineId.trim(),
          'p_quantidade_stock': newStock,
        },
      );

      if (result != true) {
        throw Exception(
          'O Supabase não confirmou a actualização do stock.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível actualizar o stock: ${e.message}',
      );
    }
  }

  Future<void> updateMedicinePrice(
    String medicineId,
    double newPrice,
  ) async {
    if (medicineId.trim().isEmpty ||
        !newPrice.isFinite ||
        newPrice < 0) {
      throw ArgumentError(
        'O identificador do medicamento e o preço devem ser válidos.',
      );
    }

    try {
      final result = await _client.rpc(
        'farclik_atualizar_preco',
        params: {
          'p_medicamento_id': medicineId.trim(),
          'p_preco_kwanza': newPrice,
        },
      );

      if (result != true) {
        throw Exception(
          'O Supabase não confirmou a actualização do preço.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível actualizar o preço: ${e.message}',
      );
    }
  }

  Future<void> deleteMedicine(String medicineId) async {
    if (medicineId.trim().isEmpty) {
      throw ArgumentError(
        'O identificador do medicamento é obrigatório.',
      );
    }

    try {
      final result = await _client.rpc(
        'farclik_remover_medicamento',
        params: {
          'p_medicamento_id': medicineId.trim(),
        },
      );

      if (result != true) {
        throw Exception(
          'O Supabase não confirmou a remoção do medicamento.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível remover o medicamento: ${e.message}',
      );
    }
  }

  // ============================================================
  // RESERVAS
  // ============================================================

  Future<void> updateReservationStatus(
    String reservationId,
    String newStatus,
  ) async {
    _unsupported(
      'Actualização do estado da reserva. '
      'A política RLS actual não permite esta operação.',
    );
  }

  // ============================================================
  // RECEITAS MÉDICAS
  // ============================================================

  Future<List<PrescriptionModel>> getPrescriptionsForPharmacy()
      async {
    _unsupported('Consulta de receitas médicas');
  }

  Future<void> updatePrescriptionStatus(
    String prescriptionId,
    String status,
    String? notes,
  ) async {
    _unsupported('Actualização do estado das receitas médicas');
  }

  // ============================================================
  // AVALIAÇÕES
  // ============================================================

  Future<void> submitReview(ReviewModel review) async {
    _unsupported('Submissão de avaliações');
  }

  Future<List<ReviewModel>> getReviewsForPharmacy(
    String pharmacyId,
  ) async {
    _unsupported('Consulta de avaliações da farmácia');
  }

  Future<List<ReviewModel>> getAllReviews() async {
    _unsupported('Consulta de todas as avaliações');
  }

  Future<void> moderateReview({
    required String reviewId,
    required String status,
    String? note,
  }) async {
    _unsupported('Moderação de avaliações');
  }

  Future<void> _updatePharmacyAverageRating(
    String pharmacyId,
  ) async {
    _unsupported('Actualização da avaliação média da farmácia');
  }

  // ============================================================
  // NOTIFICAÇÕES ADMINISTRATIVAS
  // ============================================================

  Future<List<AdminNotificationModel>> getAdminNotifications()
      async {
    _unsupported('Consulta de notificações administrativas');
  }

  Future<void> markAdminNotificationRead(
    String notificationId,
  ) async {
    _unsupported('Marcação de notificações administrativas');
  }
}

final supabaseDatabaseServiceProvider =
    Provider<SupabaseDatabaseService>((ref) {
  return SupabaseDatabaseService();
});
