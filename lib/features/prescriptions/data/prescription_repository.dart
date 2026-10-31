import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class PrescriptionRepository {
  PrescriptionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _bucket = 'receitas-medicas';

  /// O envio de receitas está temporariamente indisponível.
  /// A receita deve ser apresentada presencialmente na farmácia.
  Future<String> uploadPrescription({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    throw StateError(
      'O envio de receitas médicas está indisponível. '
      'Apresente a receita directamente na farmácia, quando exigida.',
    );
  }

  /// Cria a reserva através da função SQL existente.
  ///
  /// Nesta fase, as reservas são criadas sem envio de receita.
  /// O parâmetro prescriptionPath é mantido para compatibilidade,
  /// mas não deve ser utilizado para novos envios.
  Future<Map<String, dynamic>> createReservation({
    required String medicineId,
    required String pharmacyId,
    String? prescriptionPath,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'Inicia sessão para criar uma reserva.',
      );
    }

    final path = prescriptionPath?.trim();
    final hasPrescription = path != null && path.isNotEmpty;

    if (hasPrescription && !path.startsWith('${user.id}/')) {
      throw ArgumentError(
        'O caminho da receita não pertence ao utilizador autenticado.',
      );
    }

    final result = await _client.rpc(
      'criar_reserva',
      params: {
        'p_medicamento_id': medicineId,
        'p_farmacia_id': pharmacyId,
        'p_receita_enviada': hasPrescription,
        'p_url_foto_receita': hasPrescription ? path : null,
      },
    );

    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }

    if (result is List && result.isNotEmpty && result.first is Map) {
      return Map<String, dynamic>.from(result.first as Map);
    }

    throw const FormatException(
      'A reserva foi processada, mas a resposta não tem o formato esperado.',
    );
  }

  String _extension(String fileName) {
    final name = fileName.trim().split('/').last;
    final dot = name.lastIndexOf('.');

    if (dot < 0 || dot == name.length - 1) {
      return '';
    }

    return name.substring(dot + 1).toLowerCase();
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
