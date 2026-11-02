
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_database_service.dart';

class PharmacyNotificationService {
  final SupabaseDatabaseService _dbService;

  PharmacyNotificationService(this._dbService);

  SupabaseClient get _client => _dbService.client;

  Future<int> getUnreadCount(String pharmacyId) async {
    if (_client.auth.currentUser == null) {
      throw Exception('Inicia sessão com a conta da farmácia.');
    }

    if (pharmacyId.trim().isEmpty) {
      throw ArgumentError('O identificador da farmácia é obrigatório.');
    }

    final response = await _client
        .from('notificacoes_farmacias')
        .select('id')
        .eq('farmacia_id', pharmacyId.trim())
        .isFilter('lida_em', null);

    return response.length;
  }

  RealtimeChannel subscribeToNewNotifications({
    required String pharmacyId,
    required void Function(PostgresChangePayload payload) onInsert,
  }) {
    if (pharmacyId.trim().isEmpty) {
      throw ArgumentError('O identificador da farmácia é obrigatório.');
    }

    final channel = _client
        .channel('farmacia-notificacoes-${pharmacyId.trim()}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notificacoes_farmacias',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'farmacia_id',
            value: pharmacyId.trim(),
          ),
          callback: onInsert,
        );

    channel.subscribe();
    return channel;
  }

  Future<int> markAsRead() async {
    if (_client.auth.currentUser == null) {
      throw Exception('Inicia sessão com a conta da farmácia.');
    }

    final result = await _client.rpc(
      'marcar_notificacoes_farmacia_lidas',
    );

    if (result is num) {
      return result.toInt();
    }

    throw Exception(
      'O Supabase devolveu uma resposta inesperada ao marcar notificações.',
    );
  }
}
