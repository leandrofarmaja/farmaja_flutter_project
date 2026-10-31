import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  SupabaseStorageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String prescriptionsBucket = 'receitas-medicas';
  static const String avatarsBucket = 'avatars';
  static const String pharmacyLogosBucket = 'pharmacies';

  /// O envio de receitas médicas está temporariamente indisponível.
  ///
  /// Nesta fase, o cliente deve apresentar a receita presencialmente
  /// na farmácia, quando esta for exigida.
  ///
  /// O método é mantido para compatibilidade com chamadas existentes.
  Future<String> uploadPrescription({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    throw StateError(
      'O envio de receitas médicas está indisponível. '
      'Apresente a receita directamente na farmácia, quando exigida.',
    );
  }

  /// Envia a fotografia do perfil.
  ///
  /// Este método não simula URLs caso ocorra uma falha.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    _validateAuthenticatedUser(userId);

    if (fileBytes.isEmpty) {
      throw ArgumentError('O ficheiro do avatar está vazio.');
    }

    final safeFileName = _sanitizeFileName(fileName);
    final path = '$userId/avatars/$safeFileName';

    await _client.storage.from(avatarsBucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );

    return path;
  }

  /// Devolve um URL temporário para um objecto de um bucket privado.
  ///
  /// O URL expira após o tempo indicado.
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 300,
  }) async {
    if (path.trim().isEmpty) {
      throw ArgumentError('O caminho do ficheiro é obrigatório.');
    }

    return _client.storage.from(bucket).createSignedUrl(
          path,
          expiresInSeconds,
        );
  }

  /// Mantido para compatibilidade com chamadas existentes.
  ///
  /// Só funciona com objectos de buckets públicos.
  String getPublicUrl(String bucket, String path) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  void _validateAuthenticatedUser(String userId) {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'Inicia sessão antes de enviar ficheiros.',
      );
    }

    if (currentUser.id != userId) {
      throw Exception(
        'O utilizador autenticado não corresponde ao proprietário do ficheiro.',
      );
    }
  }

  String _sanitizeFileName(String fileName) {
    final normalized = fileName.trim().replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        );

    if (normalized.isEmpty || normalized == '.' || normalized == '..') {
      throw ArgumentError('O nome do ficheiro é inválido.');
    }

    return normalized;
  }
}
